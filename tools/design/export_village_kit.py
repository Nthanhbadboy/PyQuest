#!/usr/bin/env python3
"""Rebuild review exports from the six supplied PNG masters; never modify app art.

Install tools/design/requirements.txt, then run from any working directory.
These are opaque card illustrations, not transparent isometric map sprites.
"""
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
KIT = ROOT / 'docs/design/village-kit'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def font(size, bold=False):
    name = 'Nunito-Bold.ttf' if bold else 'Nunito-Medium.ttf'
    return ImageFont.truetype(str(ROOT / 'app/assets/fonts' / name), size)


def validate_baselines(kit, assets):
    """Fail before writing anything; current runtime must never become the before-set."""
    lock = json.loads((kit / 'baseline-lock.json').read_text())
    locked = {a['id']: a for a in lock['assets']}
    ids = [a['id'] for a in assets]
    if (len(locked) != len(lock['assets']) or len(set(ids)) != len(ids)
            or set(ids) != set(locked)):
        raise ValueError('Baseline lock and asset IDs do not match')
    manifest_path = kit / 'manifest.json'
    recorded = {}
    if manifest_path.exists():
        previous = json.loads(manifest_path.read_text())['assets']
        recorded = {a['id']: a for a in previous}
        if len(recorded) != len(previous) or set(recorded) != set(locked):
            raise ValueError('Existing manifest asset IDs do not match baseline lock')
    for asset in assets:
        aid = asset['id']
        entry = locked[aid]
        expected_path = f'baseline/{aid}.webp'
        expected_source = f"app/assets/images/{asset['baseline']}"
        if entry['path'] != expected_path or entry['source_path'] != expected_source:
            raise ValueError(f'Baseline path mismatch: {aid}')
        path = kit / expected_path
        if not path.is_file() or digest(path) != entry['sha256']:
            raise ValueError(f'Missing or corrupted immutable baseline: {aid}. Restore from Git; do not copy runtime.')
        if recorded and (recorded[aid]['baseline_sha256'] != entry['sha256']
                         or recorded[aid]['baseline_path'] != expected_path
                         or recorded[aid]['baseline_source'] != expected_source):
            raise ValueError(f'Manifest disagrees with baseline lock: {aid}')
    return locked


def export():
    spec = json.loads((KIT / 'art-direction.json').read_text())
    locked = validate_baselines(KIT, spec['assets'])
    for folder in ['exports', 'evidence']:
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
        # Baseline metadata is pinned independently of the regenerable manifest.
        # Never read or write app thumbnails here, even after runtime integration.
        baseline = locked[aid]
        manifest['assets'].append({**asset,
            'source': str(source.relative_to(KIT)), 'source_sha256': digest(source),
            'source_size': [1024, 1024], 'alpha': False,
            'baseline_source': baseline['source_path'],
            'baseline_path': baseline['path'],
            'baseline_sha256': baseline['sha256'],
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
