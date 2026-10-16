#!/usr/bin/env python3
"""Downscale emulator screenshots and store them as JPEG to keep the repo light."""
import pathlib
from PIL import Image

for p in sorted(pathlib.Path('docs/screenshots').glob('*.png')):
    try:
        im = Image.open(p).convert('RGB')
        if im.width > 540:
            im = im.resize((540, round(im.height * 540 / im.width)), Image.LANCZOS)
        out = p.with_suffix('.jpg')
        im.save(out, 'JPEG', quality=86, optimize=True)
        p.unlink()
        print(out.name, im.size, out.stat().st_size)
    except Exception as e:  # keep going; a broken capture should not hide others
        print('skip', p, e)
