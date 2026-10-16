#!/usr/bin/env python3
"""Rebuild review exports from the six supplied PNG masters; never modify app art.

Install tools/design/requirements.txt, then run from any working directory.
These are opaque card illustrations, not transparent isometric map sprites.
"""
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[2]
KIT = ROOT / 'docs/design/village-kit'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def font(size, bold=False):
    name = 'Nunito-Bold.ttf' if bold else 'Nunito-Medium.ttf'
    return ImageFont.truetype(str(ROOT / 'app/assets/fonts' / name), size)


def export():
    spec = json.loads((KIT / 'art-direction.json').read_text())
    for folder in ['exports', 'baseline', 'evidence']:
        (KIT / folder).mkdir(exist_ok=True)
    manifest = {k: v for k, v in spec.items() if k != 'assets'}
    manifest['assets'] = []
    for asset in spec['assets']:
        aid = asset['id']
        source = KIT / 'source' / f'{aid}.png'
        with Image.open(source) as im:
            assert im.size == (1024, 1024), (source, im.size)
            im = im.convert('RGB')
            variants = []
            for size in [256, 512]:
                path = KIT / 'exports' / f'{aid}_{size}.webp'
                im.resize((size, size), Image.Resampling.LANCZOS).save(
                    path, 'WEBP', quality=88, method=6)
                variants.append({'path': str(path.relative_to(KIT)),
                                 'width': size, 'height': size,
                                 'bytes': path.stat().st_size, 'sha256': digest(path)})
        baseline_source = ROOT / 'app/assets/images' / asset['baseline']
        baseline = KIT / 'baseline' / f'{aid}.webp'
        # Exact copy of existing app thumbnail: clear distinction from new art.
        baseline.write_bytes(baseline_source.read_bytes())
        manifest['assets'].append({**asset,
            'source': str(source.relative_to(KIT)), 'source_sha256': digest(source),
            'source_size': [1024, 1024], 'alpha': False,
            'baseline_source': str(baseline_source.relative_to(ROOT)),
            'baseline_path': str(baseline.relative_to(KIT)),
            'baseline_sha256': digest(baseline),
            'variants': variants, 'anchor': None,
            'review_notes': 'Background and shadow baked in. Do not use as a walkable maze, hitbox or layered terrain tile.'})
    (KIT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')

    # This is an art-review board, explicitly NOT a screenshot of the running app.
    board = Image.new('RGB', (1800, 1690), '#F6F4EE')
    draw = ImageDraw.Draw(board)
    draw.rounded_rectangle((55, 54, 310, 102), radius=24, fill='#E0E8DB')
    draw.text((77, 63), 'PYQUEST / ART LAB', font=font(23, True), fill='#36584B')
    draw.text((60, 126), 'Một thế giới nhỏ. Nhiều điều để khám phá.', font=font(52, True), fill='#203C36')
    draw.text((62, 204), 'VILLAGE KIT 01   /   6 ĐỊA ĐIỂM   /   2.5D DIORAMA', font=font(24), fill='#6D7F73')
    for i, asset in enumerate(manifest['assets']):
        x, y = 60 + i % 3 * 570, 290 + i // 3 * 650
        draw.rounded_rectangle((x, y, x+540, y+614), radius=26, fill='#FFFFFF')
        with Image.open(KIT / asset['source']) as im:
            image = im.convert('RGB').resize((510, 510), Image.Resampling.LANCZOS)
            mask = Image.new('L', image.size, 0)
            ImageDraw.Draw(mask).rounded_rectangle((0, 0, 509, 509), 20, fill=255)
            board.paste(image, (x+15, y+15), mask)
        draw.text((x+25, y+541), asset['name'], font=font(29, True), fill='#203C36')
        draw.text((x+25, y+582), asset['module'] + '  /  1024 px master', font=font(17), fill='#6D7F73')
    draw.line((60, 1610, 1740, 1610), fill='#D9DFD4', width=2)
    draw.text((60, 1630), 'DESIGN REVIEW • Không phải ảnh runtime • Nền liền, không có alpha • AI-generated', font=font(22), fill='#52695E')
    board.save(KIT / 'evidence/asset-review.jpg', quality=91, optimize=True)
    total = sum(v['bytes'] for a in manifest['assets'] for v in a['variants'])
    print(f"Exported {len(manifest['assets'])} masters → 12 WebP variants ({total:,} bytes); app assets untouched.")


if __name__ == '__main__':
    export()
