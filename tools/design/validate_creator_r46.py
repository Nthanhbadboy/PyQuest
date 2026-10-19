#!/usr/bin/env python3
"""Read-only source/artifact/link/scope checks for the r46 design package.
Writes only its own static receipt. Does NOT execute Dart/Flutter or call GitHub/CI.
"""
import hashlib
import json
import re
import struct
import subprocess
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'docs/design/maze-creator-r46'
SHA = '71b0fd3fd8fb07c73596ce089fa2e68f6fe87964'
DESIGN_BASE = '30a562f56faf85bbf7b3c7811b24eb56c007f7bc'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

manifest = json.loads((BASE / 'manifest.json').read_text())
pins = json.loads((BASE / 'source-manifest.json').read_text())
assert pins['code_sha'] == manifest['code_pin'] == SHA
assert manifest['design_base'] == DESIGN_BASE
assert manifest['runtime_authorized'] is False
assert pins['runtime_execution'] is False and pins['source_equivalence_claim'] is False
sources = {}
for pin in pins['sources']:
    body = git('show', f"{SHA}:{pin['path']}")
    assert hashlib.sha256(body).hexdigest() == pin['sha256'], pin['path']
    assert git('rev-parse', f"{SHA}:{pin['path']}").decode().strip() == pin['blob']
    assert len(body.splitlines()) == pin['lines']
    sources[pin['path']] = body.decode()
assert len(sources) == 8
workshop = sources['app/lib/modules/robot_maze/maze_workshop_screen.dart']
template = re.search(r'static const _template = (\[.*?\]);', workshop).group(1)
assert json.loads(template.replace("'", '"')) == pins['source_template']
assert 'const [4, 5, 6]' in workshop and 'v.clamp(3, 20)' in workshop
assert 'maxLength: 28' in workshop
assert 'int _limit = 10;' in workshop and 'bool _loops = true;' in workshop
assert json.loads(sources['app/assets/config/game_config.json'])['energy_costs']['creator_mode'] == 0
assert "EnergyCostChip(cost: 0)" in sources['app/lib/modules/robot_maze/robot_maze_module.dart']
excerpts = (BASE / 'SOURCE_EXCERPTS.md').read_text()
excerpt_count = 0
for source, start, end, block in re.findall(r'## `([^`]+)` L(\d+)–(\d+)\n\n```text\n(.*?)\n```', excerpts, re.S):
    lines = sources[source].splitlines()
    expected = '\n'.join(f'{i+1}:' + (' ' + lines[i] if lines[i] else '') for i in range(int(start)-1, int(end)))
    assert block == expected, (source, start, end)
    excerpt_count += 1
assert excerpt_count >= 15
counts = {}
for group in ['artifacts', 'references', 'evidence']:
    for item in manifest[group]:
        p = ROOT / item['path']
        assert p.is_file() and sha(p) == item['sha256'], item['path']
    counts[group] = len(manifest[group])
for image in manifest['art']:
    p = BASE / image['path']
    data = p.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    assert list(struct.unpack('>II', data[16:24])) == image['dimensions']
    assert image['production_ready'] is False and image['opaque'] is True

browser = json.loads((BASE / 'evidence/browser-checks.json').read_text())
model = json.loads((BASE / 'evidence/model-checks.json').read_text())
assert browser['result'] == model['result'] == 'PASS'
assert browser['cases'] == 240 and browser['fontChecks'] == 4908
assert browser['cellChecks'] == 16 and browser['invalidCases'] == 0
assert not browser['errors'] and not browser['externalRequests'] and not browser['failures']
assert len(browser['flows']) == 23 and len(browser['shots']) == 14
assert model['checks'] == 36 and model['propertyOperations'] == 4000
assert all((BASE / 'evidence' / shot).is_file() for shot in browser['shots'])

links = []
for file in list(BASE.rglob('*.md')) + list(BASE.rglob('*.html')) + list(BASE.rglob('*.css')):
    text = file.read_text()
    targets = re.findall(r'\]\(([^\s)]+)\)', text)
    targets += re.findall(r'(?:href|src)=["\']([^"\']+)["\']', text)
    targets += re.findall(r'url\(["\']?([^\s)"\']+)', text)
    for target in targets:
        if target.startswith(('#', 'http:', 'https:', 'data:', 'mailto:')):
            continue
        dest = (file.parent / unquote(urlsplit(target).path)).resolve()
        assert dest.is_relative_to(ROOT) and dest.is_file(), (file, target)
        links.append(f'{file.relative_to(ROOT)} → {target}')
# Dynamic Robo image URL is also checked, not just static HTML.
assert (BASE / '../first-play-prototype/art/robo.svg').resolve().is_file()

css = (BASE / 'style.css').read_text()
pairs = [('#233b36', '#f7efd9'), ('#fff7e6', '#304f52'), ('#ffffff', '#286d66'),
         ('#713728', '#fae2d3'), ('#4e5949', '#e5d9b9'), ('#6e563b', '#f7efd9'),
         ('#255f3e', '#dfedde'), ('#922e27', '#fff0e8'), ('#59604c', '#f7efd9')]
def luminance(color):
    channels = [int(color[i:i+2], 16)/255 for i in (1, 3, 5)]
    linear = [v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4 for v in channels]
    return sum(a*b for a, b in zip(linear, (.2126, .7152, .0722)))
contrast = []
for fg, bg in pairs:
    assert (fg in css or fg == '#ffffff' and 'color:white' in css) and bg in css
    lo, hi = sorted([luminance(fg), luminance(bg)])
    ratio = (hi+.05)/(lo+.05)
    assert ratio >= 4.5, (fg, bg, ratio)
    contrast.append({'foreground': fg, 'background': bg, 'ratio': round(ratio, 2)})

allowed_files = {
    'docs/design/VISUAL_DESIGN_STATUS.md', 'docs/design/coordination/tasks/PQD-008.md',
    'docs/design/coordination/tasks/PQD-009.md', 'tools/design/serve_art_review.py',
    'tools/design/test_creator_r46.cjs', 'tools/design/check_creator_r46.cjs',
    'tools/design/validate_creator_r46.py',
}
preexisting = {
    'docs/design/art-refresh-r33/concepts/w02-home-expansion.jpg',
    'docs/design/art-refresh-r33/concepts/w08-archipelago.jpg',
}
changed = set(git('diff', DESIGN_BASE, '--name-only').decode().splitlines())
changed |= set(git('ls-files', '--others', '--exclude-standard').decode().splitlines())
unexpected = sorted(p for p in changed if not p.startswith('docs/design/maze-creator-r46/') and p not in allowed_files | preexisting)
assert not unexpected, unexpected
staged = set(git('diff', '--cached', '--name-only').decode().splitlines())
assert not staged & preexisting, 'Do not stage the two preexisting JPEG edits'
assert git('branch', '--show-current').decode().strip() == 'arena/00838eb9-pyquest'
for codefile in ['model.js', 'study.js']:
    text = (BASE / codefile).read_text()
    assert not re.search(r'\b(?:localStorage|sessionStorage|indexedDB|fetch|XMLHttpRequest|WebSocket)\s*[.(]', text)
    assert 'localhost' not in text and '127.0.0.1' not in text
receipt = {
    'date': '2026-10-18', 'result': 'PASS_SOURCE_ARTIFACT_LINK_SCOPE_ONLY',
    'code_pin': SHA, 'design_base': DESIGN_BASE, 'source_pins': len(sources),
    'exact_excerpt_blocks': excerpt_count, **counts, 'local_links': len(links),
    'captures': len(browser['shots']), 'contrast_tokens': contrast,
    'unexpected_files': unexpected, 'preexisting_dirty_jpegs_excluded': True,
    'runtime_authorized': False, 'flutter_execution': 'NOT_RUN', 'ci_triggered': False,
    'limits': ['Static token contrast only, not all art pixels or a full accessibility audit',
               'HTML/JS evidence is not Dart engine parity, Python execution, or database verification',
               'Source observations and proposed safeguards do not open a CODE work order'],
}
(BASE / 'evidence/static-receipt.json').write_text(json.dumps(receipt, ensure_ascii=False, indent=2)+'\n')
print(json.dumps(receipt, ensure_ascii=False, indent=2))
