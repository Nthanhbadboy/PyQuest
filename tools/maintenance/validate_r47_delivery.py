#!/usr/bin/env python3
"""Validate the r47 delivery locally, including an isolated exact-CODE patch trial.
Requires PyYAML for syntax/structural comparison, not an app/CI dependency.
No branch switching, Flutter SDK, network calls, CI trigger or APK inspection.
"""
import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile

import yaml
from check_release_policy import WORKFLOWS, check_tree

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/design/coordination/reviews/PQD-010-r47'
BASE = 'c68bdcd73b400c4d449216023a54499b202bda1d'
CODE = '71b0fd3fd8fb07c73596ce089fa2e68f6fe87964'


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def normalize_workflow(text):
    """Remove only allowed packaging differences; all other YAML must match."""
    data = yaml.load(text, Loader=yaml.BaseLoader)
    assert isinstance(data, dict) and 'on' in data and 'jobs' in data
    data = copy.deepcopy(data)
    # Workflow title has no scheduling or security semantics.
    data.pop('name', None)
    for job in data['jobs'].values():
        for step in job.get('steps', []):
            if 'name' in step:
                step['name'] = step['name'].replace(' (keyless preview)', '')
            env = step.get('env', {})
            if 'GEMINI_API_KEY' in env:
                assert env.pop('GEMINI_API_KEY') == '${{ secrets.GEMINI_API_KEY }}'
                if not env:
                    del step['env']
            if 'run' in step:
                lines = []
                for line in step['run'].splitlines():
                    if line.strip() == "printf 'gemini_voice=disabled; provider_key=not_injected; distribution=preview_not_store_release\\n'":
                        continue
                    if 'flutter build apk' in line:
                        line = re.sub(r' --dart-define=(?:"GEMINI_API_KEY=[^"]*"|GEMINI_API_KEY="[^"]*"|GEMINI_API_KEY=)', '', line)
                    lines.append(line)
                step['run'] = '\n'.join(lines)
            if step.get('with', {}).get('name') == 'pyquest-debug-keyless-preview':
                step['with']['name'] = 'pyquest-debug-voice-diagnostics'
    return data


def criteria(text, prefix):
    pattern = '^' + re.escape(prefix) + r'(.*(?:\n  [^\n]+)*)'
    return re.findall(pattern, text, re.M)


def links(text):
    return set(re.findall(r'\]\(([^\s)]+)\)', text))


def test_tree(root, name):
    result = subprocess.run([sys.executable, 'tools/maintenance/test_release_policy.py'],
                            cwd=root, text=True, capture_output=True)
    (OUT / f'{name}-tests.log').write_text(result.stdout + result.stderr)
    assert result.returncode == 0, result.stderr
    assert 'Ran 12 tests' in result.stderr and '\nOK\n' in result.stderr
    policy = check_tree(root)
    assert not policy['errors'], policy
    return policy


manifest = json.loads((OUT / 'patch-manifest.json').read_text())
assert manifest['code_base'] == CODE
assert len(manifest['files']) == 13
patch = OUT / 'code-sync.patch'
assert digest(patch.read_bytes()) == manifest['patch_sha256']
assert git('branch', '--show-current').decode().strip() == 'arena/00838eb9-pyquest'
# Source and checks, not runtime acceptance.
design_policy = test_tree(ROOT, 'design')
workflow_checks, changed_links = [], 0
for path in WORKFLOWS:
    before = git('show', f'{BASE}:{path}').decode()
    after = (ROOT / path).read_text()
    assert normalize_workflow(before) == normalize_workflow(after), ('DESIGN workflow gates changed', path)
    workflow_checks.append({'tree': 'DESIGN', 'path': path, 'yaml': 'PASS', 'unrelated_structure': 'UNCHANGED'})
old_criteria = criteria(git('show', f'{BASE}:docs/ROADMAP.md').decode(), '- [ ] ')
new_criteria = criteria((ROOT / 'docs/ROADMAP.md').read_text(), '- **Tiêu chí kế hoạch:** ')
assert len(old_criteria) == 64 and old_criteria == new_criteria

with tempfile.TemporaryDirectory(prefix='pyquest-r47-code-') as directory:
    tree = Path(directory)
    originals = {}
    for entry in manifest['files']:
        p = entry['path']
        assert not p.startswith('app/'), p
        if entry['before_sha256'] is not None:
            content = git('show', f'{CODE}:{p}')
            assert digest(content) == entry['before_sha256'], p
            file = tree / p
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(content)
            originals[p] = content.decode()
    # Not in the patch: verify the unchanged 011 disposition remains available.
    p = 'docs/implementation/coordination/tasks/PQC-011.md'
    file = tree / p
    file.parent.mkdir(parents=True, exist_ok=True)
    blocker = git('show', f'{CODE}:{p}')
    file.write_bytes(blocker)
    subprocess.run(['git', 'apply', '--check', str(patch)], cwd=tree, check=True)
    subprocess.run(['git', 'apply', str(patch)], cwd=tree, check=True)
    assert file.read_bytes() == blocker
    for entry in manifest['files']:
        p = entry['path']
        assert digest((tree / p).read_bytes()) == entry['after_sha256'], p
        if p.endswith('.md'):
            for target in links((tree / p).read_text()) - links(originals.get(p, '')):
                if target.startswith(('https://', '#')):
                    continue
                dest = (Path(p).parent / target.split('#')[0])
                resolved = (tree / dest).resolve()
                assert resolved.is_relative_to(tree)
                if not resolved.exists():
                    subprocess.run(['git', 'cat-file', '-e', f'{CODE}:{resolved.relative_to(tree)}'], cwd=ROOT, check=True)
                changed_links += 1
    code_policy = test_tree(tree, 'code-patch')
    for path in WORKFLOWS:
        assert normalize_workflow(originals[path]) == normalize_workflow((tree / path).read_text()), ('CODE workflow gates changed', path)
        workflow_checks.append({'tree': 'CODE patch trial', 'path': path, 'yaml': 'PASS', 'unrelated_structure': 'UNCHANGED'})
    assert criteria(originals['docs/ROADMAP.md'], '- [ ] ') == criteria((tree / 'docs/ROADMAP.md').read_text(), '- **Tiêu chí kế hoạch:** ')

# Verify all pinned GitHub document URLs in the portable status file against local objects.
pinned_links = []
for sha, path in re.findall(r'https://github.com/Nthanhbadboy/PyQuest/blob/([0-9a-f]{40})/([^\s)]+)', (ROOT / 'docs/PROJECT_STATUS.md').read_text()):
    git('cat-file', '-e', f'{sha}:{path}')
    pinned_links.append({'sha': sha, 'path': path})
assert len(pinned_links) == 3
assert git('diff', BASE, '--', 'app', 'docs/implementation/coordination/tasks/PQC-011.md') == b''
preexisting = {'docs/design/art-refresh-r33/concepts/w02-home-expansion.jpg', 'docs/design/art-refresh-r33/concepts/w08-archipelago.jpg'}
allowed = set(e['path'] for e in manifest['files']) | {
    'tools/maintenance/validate_r47_delivery.py', 'docs/design/CROSS_BRANCH_COLLABORATION.md',
    'docs/design/coordination/tasks/PQD-010.md',
}
changed = set(git('diff', BASE, '--name-only').decode().splitlines()) | set(git('ls-files', '--others', '--exclude-standard').decode().splitlines())
assert not [p for p in changed if p not in allowed | preexisting and not p.startswith('docs/design/coordination/reviews/PQD-010-r47/')], changed
assert not preexisting & set(git('diff', '--cached', '--name-only').decode().splitlines())
receipt = {
    'date': '2026-10-18', 'result': 'PASS_LOCAL_DOCS_AND_PACKAGING_POLICY_ONLY',
    'design_base': BASE, 'code_pin': CODE, 'code_remote_patch_applied': False,
    'design_policy': design_policy, 'code_patch_policy': code_policy,
    'unit_tests_per_tree': 12, 'fake_flutter_shell_cases_per_tree': 6,
    'yaml_parser': f'PyYAML {yaml.__version__} (cache only, not app/CI dependency)',
    'workflow_comparisons': workflow_checks, 'criteria_preserved_per_tree': 64,
    'patch_apply_check': 'PASS', 'patch_apply_in_temporary_tree': 'PASS',
    'patch_files_hash_verified': 13, 'new_code_document_links_checked': changed_links,
    'pinned_status_links': pinned_links, 'app_and_pqc011_unchanged': True,
    'preexisting_jpegs_not_staged': True, 'flutter_execution': 'NOT_RUN',
    'ci_triggered': False, 'apk_build_or_inspection': 'NOT_RUN',
    'real_credentials_read': False, 'old_artifacts_or_keys_revoked': False,
    'delivery_hashes': [{'path': p, 'sha256': digest((ROOT / p).read_bytes())} for p in sorted(allowed) if (ROOT / p).is_file()],
}
(OUT / 'receipt.json').write_text(json.dumps(receipt, ensure_ascii=False, indent=2)+'\n')
print(json.dumps({k: v for k, v in receipt.items() if k != 'delivery_hashes'}, ensure_ascii=False, indent=2))
