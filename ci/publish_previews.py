#!/usr/bin/env python3
"""Ship preview renders as check runs (base64 JPEG chunks) so they can be
inspected from environments that cannot reach Actions artifact storage."""
import base64, io, json, os, pathlib, subprocess, sys
from PIL import Image

CHUNK = 60000
src = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'app/build/previews')
repo = os.environ['GITHUB_REPOSITORY']
sha = os.environ['GITHUB_SHA']
for p in sorted(src.glob('*.png')):
    im = Image.open(p).convert('RGB')
    if im.width > 480:
        im = im.resize((480, round(im.height * 480 / im.width)), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, 'JPEG', quality=80, optimize=True)
    data = base64.b64encode(buf.getvalue()).decode()
    chunks = [data[i:i + CHUNK] for i in range(0, len(data), CHUNK)]
    for i, c in enumerate(chunks):
        payload = {
            'name': f'preview|{p.stem}|{i}|{len(chunks)}',
            'head_sha': sha,
            'status': 'completed',
            'conclusion': 'neutral',
            'output': {'title': p.stem, 'summary': f'chunk {i + 1}/{len(chunks)}', 'text': c},
        }
        with open('/tmp/preview_payload.json', 'w') as f:
            json.dump(payload, f)
        subprocess.run(['gh', 'api', f'repos/{repo}/check-runs', '--method', 'POST', '--input', '/tmp/preview_payload.json', '--silent'], check=False)
    print(p.name, len(chunks), 'chunk(s)')
