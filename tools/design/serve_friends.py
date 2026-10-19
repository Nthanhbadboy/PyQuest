#!/usr/bin/env python3
"""Serve docs/design only, with P06 at the live-preview entry; no app/backend."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from functools import partial
import argparse

class Preview(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(302)
            self.send_header('Location', '/friends-showcase-prototype/')
            self.end_headers()
            return
        super().do_GET()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8003)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2] / 'docs' / 'design'
    ThreadingHTTPServer(('0.0.0.0', args.port), partial(Preview, directory=str(root))).serve_forever()
