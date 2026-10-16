#!/usr/bin/env python3
"""PyQuest AI-tutor relay — the only place that ever holds the provider API key.

Why this file exists
--------------------
A Flutter app ships its assets and binary to every device, so an API key inside
the app is a published key. The app therefore talks to *this* relay (or any
equivalent service you run) and the relay adds the secret on the server side:

    Flutter app  --(no key, HTTPS)-->  relay (holds key)  -->  provider API

Endpoints
---------
GET  /healthz              -> {"ok": true, "provider": "...", "model": "..."}
POST /v1/chat/completions  -> forwards an OpenAI-compatible chat request

Safety rules implemented here
-----------------------------
* refuses to start without RELAY_API_KEY (fail closed, no anonymous upstream calls);
* model allowlist, so a tampered client cannot request an expensive model;
* caps the request body size and the number of completion tokens;
* never echoes the key to the client and never logs message content;
* simple per-IP rate limit to keep one device from draining the quota.

Run locally (no provider account needed if UPSTREAM_BASE points at a stub):
    RELAY_API_KEY=... UPSTREAM_BASE=https://api.openai.com python3 relay.py

Environment:
    RELAY_API_KEY     required, the provider key (server-side secret)
    RELAY_MODELS      optional, comma-separated allowlist (default gpt-4o-mini)
    UPSTREAM_BASE     optional, default https://api.openai.com
    RELAY_PORT        optional, default 8080
    RELAY_HOST        optional, default 0.0.0.0
    RELAY_RATE_LIMIT  optional, requests per minute per IP (default 30)
"""

from __future__ import annotations

import json
import os
import sys
import threading
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MAX_BODY_BYTES = 64 * 1024
MAX_TOKENS_CAP = 900
UPSTREAM_TIMEOUT = 30


class RelayConfig:
    def __init__(self, env: dict[str, str] | None = None) -> None:
        env = os.environ if env is None else env
        self.api_key = (env.get("RELAY_API_KEY") or "").strip()
        self.models = tuple(m.strip() for m in (env.get("RELAY_MODELS") or "gpt-4o-mini").split(",") if m.strip())
        self.upstream_base = (env.get("UPSTREAM_BASE") or "https://api.openai.com").rstrip("/")
        self.port = int(env.get("RELAY_PORT") or 8080)
        self.host = env.get("RELAY_HOST") or "0.0.0.0"
        self.rate_limit = int(env.get("RELAY_RATE_LIMIT") or 30)

    @property
    def upstream_url(self) -> str:
        return f"{self.upstream_base}/v1/chat/completions"

    def validate(self) -> None:
        if not self.api_key:
            raise SystemExit(
                "RELAY_API_KEY is not set. The relay refuses to start without it: "
                "an app without a key must never reach the provider directly."
            )
        if not self.models:
            raise SystemExit("RELAY_MODELS must list at least one model.")


class _RateLimiter:
    """Cheap per-IP limiter; enough to protect a hobby relay."""

    def __init__(self, per_minute: int) -> None:
        self.per_minute = per_minute
        self._hits: dict[str, list[float]] = {}
        self._lock = threading.Lock()

    def allow(self, ip: str) -> bool:
        now = time.time()
        with self._lock:
            window = [t for t in self._hits.get(ip, []) if now - t < 60]
            if len(window) >= self.per_minute:
                self._hits[ip] = window
                return False
            window.append(now)
            self._hits[ip] = window
            return True


def filter_request(payload: dict, cfg: RelayConfig) -> tuple[dict | None, str | None]:
    """Returns (clean_payload, error_message). Enforces the allowlist and caps."""
    if not isinstance(payload, dict):
        return None, "body must be a JSON object"
    model = payload.get("model")
    if model not in cfg.models:
        return None, f"model not allowed: {model!r}"
    messages = payload.get("messages")
    if not isinstance(messages, list) or not messages:
        return None, "messages must be a non-empty list"
    for m in messages:
        if not isinstance(m, dict) or m.get("role") not in {"system", "user", "assistant"}:
            return None, "each message needs a role and content"
        if not isinstance(m.get("content"), str):
            return None, "message content must be a string"
    max_tokens = payload.get("max_tokens")
    if not isinstance(max_tokens, int) or max_tokens <= 0 or max_tokens > MAX_TOKENS_CAP:
        max_tokens = MAX_TOKENS_CAP
    temperature = payload.get("temperature")
    if not isinstance(temperature, (int, float)) or not 0 <= float(temperature) <= 2:
        temperature = 0.4
    return {
        "model": model,
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": float(temperature),
        "stream": False,
    }, None


class Handler(BaseHTTPRequestHandler):
    server_version = "PyQuestRelay/1.0"
    protocol_version = "HTTP/1.1"
    cfg: RelayConfig
    limiter: _RateLimiter

    # ---------------------------------------------------------------- helpers
    def _send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _client_ip(self) -> str:
        return self.headers.get("X-Forwarded-For", self.client_address[0]).split(",")[0].strip()

    def log_message(self, fmt: str, *args) -> None:  # noqa: D102 - keep content out of logs
        sys.stderr.write("[relay] %s\n" % (fmt % args))

    # ------------------------------------------------------------------ routes
    def do_GET(self) -> None:  # noqa: N802 - http.server API
        if self.path.rstrip("/") in ("/healthz", ""):
            self._send_json(200, {"ok": True, "models": list(self.cfg.models), "upstream": self.cfg.upstream_base})
            return
        self._send_json(404, {"error": "not found"})

    def do_POST(self) -> None:  # noqa: N802 - http.server API
        if self.path.rstrip("/") != "/v1/chat/completions":
            self._send_json(404, {"error": "not found"})
            return
        if not self.limiter.allow(self._client_ip()):
            self._send_json(429, {"error": "rate limited"})
            return
        length = int(self.headers.get("Content-Length") or 0)
        if length <= 0 or length > MAX_BODY_BYTES:
            self._send_json(413, {"error": "body too large or empty"})
            return
        raw = self.rfile.read(length)
        try:
            payload = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            self._send_json(400, {"error": "invalid JSON"})
            return
        clean, error = filter_request(payload, self.cfg)
        if clean is None:
            self._send_json(400, {"error": error})
            return

        req = urllib.request.Request(
            self.cfg.upstream_url,
            data=json.dumps(clean).encode("utf-8"),
            headers={
                # The key is added HERE, on the server. It never reaches the app.
                "Authorization": f"Bearer {self.cfg.api_key}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=UPSTREAM_TIMEOUT) as res:
                body = res.read()
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                self.wfile.write(body)
        except urllib.error.HTTPError as e:
            # Provider errors are forwarded without any part of the key.
            self._send_json(e.code, {"error": f"upstream {e.code}"})
        except urllib.error.URLError:
            self._send_json(502, {"error": "upstream unreachable"})
        except TimeoutError:
            self._send_json(504, {"error": "upstream timeout"})


def build_server(cfg: RelayConfig, host: str | None = None, port: int | None = None) -> ThreadingHTTPServer:
    """Binds a relay. `port=0` means "any free port" (used by the tests)."""
    handler = type("BoundHandler", (Handler,), {"cfg": cfg, "limiter": _RateLimiter(cfg.rate_limit)})
    bind_host = cfg.host if host is None else host
    bind_port = cfg.port if port is None else port
    return ThreadingHTTPServer((bind_host, bind_port), handler)


def main(argv: list[str]) -> int:
    cfg = RelayConfig()
    cfg.validate()
    server = build_server(cfg)
    print(f"[relay] listening on {cfg.host}:{cfg.port} -> {cfg.upstream_url}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("[relay] stopping")
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
