"""Re-export the selected W01 without repainting or upscaling (requires Pillow)."""
from pathlib import Path
import hashlib
import json
import subprocess
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
p = ROOT / 'docs/design/r1-village-r53'
s = ROOT / 'docs/design/art-refresh-r33/concepts/w01-village.jpg'
assert hashlib.sha256(s.read_bytes()).hexdigest() == '2b33ad2a3eb826e6068241dc801f94e1794139ebda9c44f55c4380169e5ebd99'
p.joinpath('assets').mkdir(parents=True, exist_ok=True)
Image.open(s).save(p / 'assets/village-r53.webp', quality=88, method=6)
landmarks = [
    ('main_quest', .48, .29, [.385, .11, .61, .34]),
    ('robot_maze', .23, .445, [.025, .31, .47, .46]),
    ('dragon_jump', .82, .33, [.63, .235, .98, .39]),
    ('catch_stars', .80, .515, [.72, .38, .98, .51]),
    ('bug_hunter', .22, .64, [.06, .46, .36, .65]),
    ('achievement_house', .80, .68, [.66, .535, .98, .71]),
]
manifest = {
    'revision': 53, 'code_pin': '6dc8ca8feeed54cc0fa6a82109e3a59d24a16153',
    'asset': {
        'path': 'assets/village-r53.webp', 'source': str(s.relative_to(ROOT)),
        'source_sha256': hashlib.sha256(s.read_bytes()).hexdigest(),
        'sha256': hashlib.sha256((p / 'assets/village-r53.webp').read_bytes()).hexdigest(),
        'size': [853, 1844], 'bytes': (p / 'assets/village-r53.webp').stat().st_size,
        'decoded_rgba_bytes': 853 * 1844 * 4, 'alpha': False,
        'role': 'approved static scene ONLY for R1-A; not layered world assets',
        'provenance': 'WebP export of user-selected AI-generated W01; no redraw or upscaling',
    },
    'layout': {
        'fit': 'width; aspect ratio preserved; vertical scroll; no cover crop',
        'marker_width_fraction': .32, 'minimum_target_px': 48,
        'directory_default_at_text_scale': 1.5,
        'markers': [{'id': i, 'anchor': [x, y], 'art_bounds': b} for i, x, y, b in landmarks],
    },
    'unavailable_routes': ['private_home', 'dock', 'travel', 'friends', 'arena'],
    'runtime_authority': 'PQC-020 revision1 only; not blanket R1/R4 authorization',
}
p.joinpath('manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
paths = [
    'app/lib/modules/main_map/main_map_screen.dart', 'app/lib/modules/main_map/activity_sheet.dart',
    'app/lib/app/activity.dart', 'app/lib/app/activity_registry.dart',
    'app/lib/modules/main_quest/main_quest_module.dart', 'app/lib/modules/bug_hunter/bug_hunter_module.dart',
    'app/lib/core/settings_service.dart', 'app/lib/app/locale_binding.dart',
    'app/test/activity_sheet_thumbnails_test.dart', 'app/test/render/render_screens_test.dart',
]
p.joinpath('source-manifest.json').write_text(json.dumps({
    'code_pin': manifest['code_pin'],
    'files': [{'path': x, 'sha256': hashlib.sha256(subprocess.check_output(
        ['git', 'show', manifest['code_pin'] + ':' + x], cwd=ROOT)).hexdigest()} for x in paths],
}, indent=2) + '\n')
print(json.dumps(manifest['asset'], indent=2))
