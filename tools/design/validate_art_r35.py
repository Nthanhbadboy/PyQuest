#!/usr/bin/env python3
"""Read-only provenance/link checks for the synchronized design atlas."""
from pathlib import Path
from PIL import Image
from html.parser import HTMLParser
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'docs/design/art-sync-r35'
CODE = ROOT / 'docs/design/art-refresh-r33/code'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def git_bytes(sha, path):
    return subprocess.check_output(['git', 'show', f'{sha}:{path}'], cwd=ROOT)


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []

    def handle_starttag(self, tag, attrs):
        for key, value in attrs:
            if key in ('href', 'src') and value:
                self.links.append(value)


def main():
    catalog = json.loads((BASE / 'catalog.json').read_text())
    assert catalog['count'] == len(catalog['assets']) == 16
    assert len({a['id'] for a in catalog['assets']}) == 16
    for asset in catalog['assets']:
        path = (BASE / asset['path']).resolve()
        raw = path.read_bytes()
        assert digest(raw) == asset['sha256'] and len(raw) == asset['bytes'], path
        with Image.open(path) as im:
            im.load()
            assert list(im.size) == asset['dimensions'], path
        assert not asset['runtime_ready'] and not asset['production_approved']
        if asset['source_commit']:
            assert git_bytes(asset['source_commit'], asset['source_path']) == raw
        if asset.get('layout'):
            assert (BASE / asset['layout'].split('#')[0]).exists()
    for item in catalog['exact_code_imports']:
        raw = (ROOT / item['path']).read_bytes()
        assert raw == git_bytes(catalog['source_code_commit'], item['path'])
        assert digest(raw) == item['sha256']
        blob = subprocess.check_output(['git', 'rev-parse', f"{catalog['source_code_commit']}:{item['path']}"], cwd=ROOT, text=True).strip()
        assert blob == item['git_blob']
    assert len(catalog['exact_code_imports']) == 20
    assert not subprocess.check_output(['git', 'diff', '--name-only', 'a331ac1', catalog['source_code_commit'], '--', 'app'], cwd=ROOT)
    original = json.loads((CODE / 'manifest.json').read_text())
    manifests = list(CODE.rglob('manifest.json'))
    assert len(manifests) == 4
    for p in manifests:
        json.loads(p.read_text())
    pins = 0
    for item in original['design_input_pins'] + original['source_identity_pins'] + original['references']:
        commit = item.get('commit', item.get('source_commit', original['design_revision_sha']))
        source = item.get('source_path', item['path'])
        raw = git_bytes(commit, source)
        assert digest(raw) == item['sha256'], source
        assert subprocess.check_output(['git', 'rev-parse', f'{commit}:{source}'], cwd=ROOT, text=True).strip() == item['git_blob']
        pins += 1
    for artifact in original['screen_artifacts']:
        image = CODE / artifact['path']
        assert digest(image.read_bytes()) == artifact['sha256']
        with Image.open(image) as im:
            im.load()
            assert list(im.size) == artifact['dimensions_px']
        for prompt, sha in zip(artifact['prompt_paths'], artifact['prompt_sha256']):
            assert digest((CODE / prompt).read_bytes()) == sha
    for item in json.loads((BASE / 'derived-sources.json').read_text()):
        assert digest((BASE / item['path']).read_bytes()) == item['sha256']
        if 'crop_box_ltrb' in item:
            assert digest((ROOT / item['source_path']).read_bytes()) == item['source_sha256']
        else:
            assert git_bytes(item['source_commit'], item['source_path']) == (BASE / item['path']).read_bytes()
    correction = catalog['correction_provenance']
    assert digest((BASE / correction['prompt']).read_bytes()) == correction['prompt_sha256']
    for item in correction['inputs']:
        assert digest((BASE / item['path']).read_bytes()) == item['sha256']
    links = 0
    docs = list(BASE.glob('*.md')) + [
        ROOT / 'docs/design/coordination/reviews/PQD-003-r35.md',
        ROOT / 'docs/implementation/coordination/tasks/PQC-017.md',
        ROOT / 'docs/implementation/coordination/tasks/PQC-018.md',
        ROOT / 'docs/design/ART_DIRECTION_2_5D.md',
        ROOT / 'docs/design/coordination/tasks/PQD-003.md',
    ]
    for p in docs + list(BASE.rglob('*.html')):
        if p.suffix == '.md':
            targets = re.findall(r'!?\[[^\]]*\]\(([^)\s]+)\)', p.read_text())
        else:
            parser = Links()
            parser.feed(p.read_text())
            targets = parser.links
            for script in re.findall(r'<script(?:\s[^>]*)?>(.*?)</script>', p.read_text(), flags=re.S):
                subprocess.run(['node', '--check'], input=script, text=True, check=True)
        for target in targets:
            if '://' in target or target.startswith('#'):
                continue
            assert (p.parent / target.split('#')[0]).resolve().exists(), (p, target)
            links += 1
    subprocess.run(['node', '--check', str(BASE / 'atlas.js')], check=True)
    before = json.loads((BASE / 'evidence/original-layouts.json').read_text())
    after = json.loads((BASE / 'evidence/synced-layouts.json').read_text())
    atlas = json.loads((BASE / 'evidence/atlas-checks.json').read_text())
    assert before['cases'] == 56 and before['horizontalOverflowCases'] == 28
    assert after['cases'] == 64 and after['horizontalOverflowCases'] == 0
    assert not after['debugIDVisibleCases'] and not after['errors']
    assert atlas['activeImagesDecoded'] == 16 and atlas['layoutTargets'] == 13
    assert atlas['smallENScale2FooterCases'] == 8 and not atlas['errors']
    captures = []
    for p in sorted((BASE / 'evidence').glob('*.png')):
        with Image.open(p) as im:
            im.load()
            dims = list(im.size)
        captures.append({'path': str(p.relative_to(BASE)), 'dimensions': dims, 'sha256': digest(p.read_bytes())})
    subprocess.run(['git', 'diff', '--check'], cwd=ROOT, check=True)
    report = {'date': '2026-10-18', 'activeImages': 16, 'exactCodeFiles': 20,
              'originalManifests': len(manifests), 'originalSourcePinsVerified': pins,
              'localLinks': links, 'javascriptSyntax': 'passed',
              'runtimeDiffFromA331ToE3': 'none', 'runtimeTestsRun': False,
              'screenshots': captures,
              'preservedDirtyPaths': catalog['preserved_dirty_paths']}
    (BASE / 'evidence/static-checks.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k != 'screenshots'}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
