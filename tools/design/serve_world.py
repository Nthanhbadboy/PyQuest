#!/usr/bin/env python3
"""Serve only docs/design, with the living-world prototype at the preview entry."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from functools import partial
import argparse

class Preview(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(302)
            self.send_header('Location', '/living-world-prototype/')
            self.end_headers()
            return
        super().do_GET()

if __name__ == '__main__':
    p=argparse.ArgumentParser(); p.add_argument('--port',type=int,default=8001); a=p.parse_args()
    directory=Path(__file__).resolve().parents[2]/'docs'/'design'
    ThreadingHTTPServer(('0.0.0.0',a.port),partial(Preview,directory=str(directory))).serve_forever()
