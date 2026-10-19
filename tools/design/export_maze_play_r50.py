#!/usr/bin/env python3
"""Rebuild study-only white-matte cutouts; requires Pillow, never changes app assets."""
from collections import deque
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2] / 'docs/design/maze-play-r50/assets'


def cutout(source, target, size):
    im = Image.open(ROOT / source).convert('RGBA')
    width, height = im.size
    pixels = im.load()
    queue = deque([(x, y) for x in range(width) for y in (0, height-1)] +
                  [(x, y) for y in range(height) for x in (0, width-1)])
    seen = set(queue)
    while queue:
        x, y = queue.popleft()
        red, green, blue, alpha = pixels[x, y]
        if min(red, green, blue) < 232 or max(red, green, blue)-min(red, green, blue) > 24:
            continue
        pixels[x, y] = (red, green, blue, 0)
        for xx, yy in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0 <= xx < width and 0 <= yy < height and (xx,yy) not in seen:
                seen.add((xx,yy))
                queue.append((xx,yy))
    bbox = im.getbbox()
    im = im.crop(bbox)
    im.thumbnail(size, Image.Resampling.BICUBIC)
    im.save(ROOT / target)
    print(target, 'source bbox:', bbox, 'output size:', im.size)


if __name__ == '__main__':
    cutout('robo-portrait.png', 'robo-token.png', (320,380))
    cutout('hedge-block.png', 'hedge-token.png', (256,256))
