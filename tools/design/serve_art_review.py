#!/usr/bin/env python3
"""Read-only local art review server; never serves app sources or Git metadata."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit
import argparse

ROOT = Path(__file__).resolve().parents[2]
ALLOWED = tuple((ROOT / p).resolve() for p in (
    'docs/design', 'docs/screenshots', 'app/assets/fonts', 'docs/implementation/coordination/tasks'
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
    parser.add_argument('--landing', choices=('r36', 'w08', 'r38', 'w14', 'r40', 'r41', 'r43', 'r45', 'r46', 'r50', 'r51', 'r52', 'r53', 'r54', 'r55', 'r56'), default='r36')
    args = parser.parse_args()
    if args.landing == 'w08':
        ArtHandler.landing = '/docs/design/world-travel-r37/index.html'
    if args.landing == 'r38':
        ArtHandler.landing = '/docs/design/art-review-r38/index.html'
    if args.landing == 'w14':
        ArtHandler.landing = '/docs/design/achievement-house-r39/index.html'
    if args.landing == 'r40':
        ArtHandler.landing = '/docs/design/art-review-r40/index.html'
    if args.landing == 'r41':
        ArtHandler.landing = '/docs/design/runtime-gap-r41/index.html'
    if args.landing == 'r43':
        ArtHandler.landing = '/docs/design/chapter-journey-r43/index.html'
    if args.landing == 'r45':
        ArtHandler.landing = '/docs/design/maze-trail-r45/index.html'
    if args.landing == 'r46':
        ArtHandler.landing = '/docs/design/maze-creator-r46/index.html'
    if args.landing == 'r50':
        ArtHandler.landing = '/docs/design/maze-play-r50/index.html'
    if args.landing == 'r51':
        ArtHandler.landing = '/docs/design/maze-python-r51/index.html'
    if args.landing == 'r52':
        ArtHandler.landing = '/docs/design/maze-result-r52/index.html'
    if args.landing == 'r53':
        ArtHandler.landing = '/docs/design/r1-village-r53/index.html'
    if args.landing == 'r54':
        ArtHandler.landing = '/docs/design/dragon-run-r54/index.html'
    if args.landing == 'r55':
        ArtHandler.landing = '/docs/design/catch-stars-r55/index.html'
    if args.landing == 'r56':
        ArtHandler.landing = '/docs/design/arrival-entrance-r56/index.html'
    handler = partial(ArtHandler, directory=str(ROOT))
    ThreadingHTTPServer(('0.0.0.0', args.port), handler).serve_forever()
