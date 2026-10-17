#!/usr/bin/env python3
"""Read-only local art review server; never serves app sources or Git metadata."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit
import argparse

ROOT = Path(__file__).resolve().parents[2]
ALLOWED = tuple((ROOT / p).resolve() for p in (
    'docs/design', 'app/assets/fonts', 'docs/implementation/coordination/tasks'
))


class ArtHandler(SimpleHTTPRequestHandler):
    landing = '/docs/design/art-review-r36/index.html'

    def do_GET(self):
        path = unquote(urlsplit(self.path).path)
        if path == '/':
            self.send_response(302)
            self.send_header('Location', self.landing)
            self.end_headers()
            return
        target = (ROOT / path.lstrip('/')).resolve()
        if not any(target.is_relative_to(base) for base in ALLOWED):
            self.send_error(404)
            return
        super().do_GET()

    def do_HEAD(self):
        path = unquote(urlsplit(self.path).path)
        target = (ROOT / path.lstrip('/')).resolve()
        if not any(target.is_relative_to(base) for base in ALLOWED):
            self.send_error(404)
            return
        super().do_HEAD()

    def list_directory(self, path):
        self.send_error(404)
        return None


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8000)
    parser.add_argument('--landing', choices=('r36', 'w08', 'r38', 'w14', 'r40'), default='r36')
    args = parser.parse_args()
    if args.landing == 'w08':
        ArtHandler.landing = '/docs/design/world-travel-r37/index.html'
    if args.landing == 'r38':
        ArtHandler.landing = '/docs/design/art-review-r38/index.html'
    if args.landing == 'w14':
        ArtHandler.landing = '/docs/design/achievement-house-r39/index.html'
    if args.landing == 'r40':
        ArtHandler.landing = '/docs/design/art-review-r40/index.html'
    handler = partial(ArtHandler, directory=str(ROOT))
    ThreadingHTTPServer(('0.0.0.0', args.port), handler).serve_forever()
