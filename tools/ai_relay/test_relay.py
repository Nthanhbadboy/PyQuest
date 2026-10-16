#!/usr/bin/env python3
"""Tests for the PyQuest AI-tutor relay — run with plain Python 3, no network.

The upstream provider is replaced by a local stub, so these tests prove the
plumbing (key handling, allowlist, caps, error mapping) without any account,
any key and without inventing a provider response.
"""

from __future__ import annotations

import json
import os
import threading
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from relay import MAX_TOKENS_CAP, RelayConfig, build_server, filter_request

FAILURES: list[str] = []
CHECKS = 0


def check(label: str, condition: bool, detail: str = "") -> None:
    global CHECKS
    CHECKS += 1
    if condition:
        print(f"  PASS  {label}")
    else:
        print(f"  FAIL  {label} {detail}")
        FAILURES.append(label)


class StubUpstream(BaseHTTPRequestHandler):
    """Pretends to be the provider API and records what it received."""

    received: list[dict] = []
    status = 200
    body = {
        "choices": [{"message": {"role": "assistant", "content": "print('Xin chào') rồi chạy thử nhé!"},
                     "finish_reason": "stop"}]
    }

    def log_message(self, *args) -> None:  # keep the test output clean
        return

    def do_POST(self) -> None:  # noqa: N802 - http.server API
        length = int(self.headers.get("Content-Length") or 0)
        payload = json.loads(self.rfile.read(length).decode("utf-8"))
        type(self).received.append({"payload": payload, "authorization": self.headers.get("Authorization")})
        if type(self).status != 200:
            message = json.dumps({"error": "stub refuses"}).encode()
            self.send_response(type(self).status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(message)))
            self.end_headers()
            self.wfile.write(message)
            return
        raw = json.dumps(type(self).body).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)


def post(url: str, payload, headers: dict | None = None) -> tuple[int, dict]:
    data = payload if isinstance(payload, bytes) else json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json", **(headers or {})})
    try:
        with urllib.request.urlopen(req, timeout=10) as res:
            return res.status, json.loads(res.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or "{}")


def main() -> int:
    print("== relay config ==")
    try:
        RelayConfig(env={}).validate()
        check("refuses to start with no RELAY_API_KEY", False, "(validate() did not exit)")
    except SystemExit:
        check("refuses to start with no RELAY_API_KEY", True)

    upstream = ThreadingHTTPServer(("127.0.0.1", 0), StubUpstream)
    threading.Thread(target=upstream.serve_forever, daemon=True).start()
    upstream_url = f"http://127.0.0.1:{upstream.server_address[1]}"

    env = {
        "RELAY_API_KEY": "test-key-not-real",
        "UPSTREAM_BASE": upstream_url,
        "RELAY_MODELS": "gpt-4o-mini",
        "RELAY_RATE_LIMIT": "50",
    }
    relay = build_server(RelayConfig(env=env), host="127.0.0.1", port=0)
    threading.Thread(target=relay.serve_forever, daemon=True).start()
    base = f"http://127.0.0.1:{relay.server_address[1]}"

    print("== what the app sends: no key at all ==")
    body = {
        "model": "gpt-4o-mini",
        "messages": [{"role": "system", "content": "You are a tutor."}, {"role": "user", "content": "Giải thích giúp mình."}],
        "temperature": 0.4,
        "max_tokens": 700,
        "stream": False,
    }
    status, res = post(f"{base}/v1/chat/completions", body)  # deliberately no Authorization header
    check("app request without Authorization is accepted (200)", status == 200, f"got {status} {res}")
    content = res.get("choices", [{}])[0].get("message", {}).get("content", "")
    check("answer is passed back to the app", "Xin chào" in content, content[:60])
    check("response contains no API key", "test-key-not-real" not in json.dumps(res, ensure_ascii=False))
    check("upstream got the key from the relay only",
          StubUpstream.received and StubUpstream.received[-1]["authorization"] == "Bearer test-key-not-real")
    check("upstream got the child's question",
          "Giải thích giúp mình." in json.dumps(StubUpstream.received[-1]["payload"], ensure_ascii=False))

    print("== limits ==")
    status, res = post(f"{base}/v1/chat/completions", {**body, "model": "gpt-4o-expensive"})
    check("model outside the allowlist is refused (400)", status == 400, f"got {status}")
    status, _ = post(f"{base}/v1/chat/completions", {**body, "messages": []})
    check("empty messages refused (400)", status == 400, f"got {status}")
    status, _ = post(f"{base}/v1/chat/completions", b"{not json")
    check("invalid JSON refused (400)", status == 400, f"got {status}")
    status, _ = post(f"{base}/v1/chat/completions", {**body, "max_tokens": 100000})
    check("max_tokens is capped at the upstream",
          StubUpstream.received[-1]["payload"]["max_tokens"] == MAX_TOKENS_CAP)
    status, _ = post(f"{base}/v1/chat/completions", b"x" * (70 * 1024))
    check("oversized body refused (413)", status == 413, f"got {status}")

    print("== provider failures are forwarded, never invented ==")
    StubUpstream.status = 401
    status, res = post(f"{base}/v1/chat/completions", body)
    check("provider 401 surfaces as 401", status == 401, f"got {status}")
    check("error payload carries no key", "test-key-not-real" not in json.dumps(res, ensure_ascii=False))
    StubUpstream.status = 200

    print("== rate limiting ==")
    limited_env = {**env, "RELAY_RATE_LIMIT": "2"}
    limited = build_server(RelayConfig(env=limited_env), host="127.0.0.1", port=0)
    threading.Thread(target=limited.serve_forever, daemon=True).start()
    limited_base = f"http://127.0.0.1:{limited.server_address[1]}"
    codes = [post(f"{limited_base}/v1/chat/completions", body)[0] for _ in range(3)]
    check("third request in a minute is rate limited (429)", codes[-1] == 429, str(codes))

    print("== request filtering keeps the shape the provider expects ==")
    clean, err = filter_request({"model": "gpt-4o-mini", "messages": [{"role": "user", "content": "hi"}],
                                "max_tokens": 700, "temperature": 0.4, "stream": True}, RelayConfig(env=env))
    check("stream is forced off and caps applied", err is None and clean["stream"] is False and clean["max_tokens"] == 700)
    clean, err = filter_request({"model": "gpt-4o-mini", "messages": [{"role": "user", "content": 5}]}, RelayConfig(env=env))
    check("non-string content refused", clean is None and err is not None, str(err))

    print("== health check ==")
    with urllib.request.urlopen(f"{base}/healthz", timeout=10) as res:
        health = json.loads(res.read().decode())
    check("healthz reports the allowed model", health.get("models") == ["gpt-4o-mini"], str(health))

    relay.shutdown()
    limited.shutdown()
    upstream.shutdown()

    print(f"\n{CHECKS - len(FAILURES)}/{CHECKS} checks passed")
    if FAILURES:
        print("FAILED: " + "; ".join(FAILURES))
        return 1
    print("RESULT: PASS (no real provider, no credentials — plumbing only)")
    return 0


if __name__ == "__main__":
    os.environ.setdefault("RELAY_MODELS", "gpt-4o-mini")
    raise SystemExit(main())
