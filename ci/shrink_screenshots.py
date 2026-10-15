#!/usr/bin/env python3
"""Downscale emulator screenshots to keep the repository light."""
import pathlib
from PIL import Image

for p in sorted(pathlib.Path('docs/screenshots').glob('*.png')):
    try:
        im = Image.open(p)
        if im.width > 540:
            h = round(im.height * 540 / im.width)
            im = im.convert('RGB').resize((540, h), Image.LANCZOS)
            im.save(p, optimize=True)
        print(p.name, im.size, p.stat().st_size)
    except Exception as e:  # keep going; a broken capture should not hide others
        print('skip', p, e)
