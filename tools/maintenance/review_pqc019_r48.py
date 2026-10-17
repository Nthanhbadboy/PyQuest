#!/usr/bin/env python3
"""Independent, exact-SHA source/policy review of the PQC-019 CODE handoff.
Runs only already-hash-matched Python checks and a fake Flutter shell test.
PyYAML is an external local verification dependency; no SDK/CI/network use.
"""
import ast
import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import yaml

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/design/coordination/reviews/PQD-010-r48'
ORDER = 'b785205349059b0be584989623aada2360ef79c9'
BASE = '71b0fd3fd8fb07c73596ce089fa2e68f6fe87964'
FINAL = 'de01a490743982356ad5240d77ea99e9dbf8c7f5'
TASK = 'docs/implementation/coordination/tasks/PQC-019.md'


def git(*args, check=True):
    return subprocess.run(['git', *args], cwd=ROOT, check=check, capture_output=True)


def blob(sha, path):
    return git('show', f'{sha}:{path}').stdout


def digest(data):
    return hashlib.sha256(data).hexdigest()


manifest = json.loads(blob(ORDER, 'docs/design/coordination/reviews/PQD-010-r47/patch-manifest.json'))
implementation = git('rev-parse', '1a673ff5').stdout.decode().strip()
assert git('rev-parse', FINAL+'^').stdout.decode().strip() == implementation
assert git('rev-parse', implementation+'^').stdout.decode().strip() == BASE
assert git('diff', '--name-only', implementation, FINAL).stdout.decode().splitlines() == [TASK]
changed = set(git('diff', '--name-only', BASE, FINAL).stdout.decode().splitlines())
assert changed == {e['path'] for e in manifest['files']}
assert len(changed) == 13
assert git('diff', BASE, FINAL, '--', 'app', 'docs/implementation/coordination/tasks/PQC-011.md').stdout == b''
assert git('diff', '--check', BASE, FINAL).stdout == b''
results = []
for entry in manifest['files']:
    p = entry['path']
    if entry['before_sha256'] is None:
        assert git('cat-file', '-e', f'{BASE}:{p}', check=False).returncode != 0
    else:
        assert digest(blob(BASE, p)) == entry['before_sha256']
    assert digest(blob(implementation, p)) == entry['after_sha256'], p
    final_hash = digest(blob(FINAL, p))
    assert final_hash == entry['after_sha256'] or p == TASK, p
    results.append({'path': p, 'sha256': final_hash, 'patch_match': p != TASK})
original_task = blob(implementation, TASK).decode()
final_task = blob(FINAL, TASK).decode()
expected_prefix = original_task.replace('**READY_FOR_CODE — bounded documentation / packaging-policy sync**', '**APPLIED_SOURCE_ONLY — local checks PASS**')
assert final_task.startswith(expected_prefix + '\n## CODE handoff — applied source-only (2026-10-18)\n')
assert len(final_task.splitlines()) - len(original_task.splitlines()) == 27

# Reuse only the two pure comparison helpers pinned in the order commit.
# Never import the historical verifier module: that would rewrite its receipt.
module = ast.parse(blob(ORDER, 'tools/maintenance/validate_r47_delivery.py').decode())
functions = [node for node in module.body if isinstance(node, ast.FunctionDef) and node.name in {'normalize_workflow', 'criteria'}]
assert len(functions) == 2
scope = {'yaml': yaml, 'copy': copy, 're': re}
exec(compile(ast.Module(body=functions, type_ignores=[]), '<pinned-r47-pure-helpers>', 'exec'), scope)
for p in ['.github/workflows/ci.yml', '.github/workflows/build-debug-apk.yml']:
    assert scope['normalize_workflow'](blob(BASE, p).decode()) == scope['normalize_workflow'](blob(FINAL, p).decode())
old = scope['criteria'](blob(BASE, 'docs/ROADMAP.md').decode(), '- [ ] ')
new = scope['criteria'](blob(FINAL, 'docs/ROADMAP.md').decode(), '- **Tiêu chí kế hoạch:** ')
assert len(old) == 64 and old == new

OUT.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='pqc019-r48-') as folder:
    tree = Path(folder)
    for p in sorted(changed | {'docs/implementation/coordination/tasks/PQC-011.md'}):
        target = tree / p
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(blob(FINAL, p))
    tests = subprocess.run([sys.executable, 'tools/maintenance/test_release_policy.py'], cwd=tree, text=True, capture_output=True)
    (OUT / 'independent-tests.log').write_text(tests.stdout + tests.stderr)
    assert tests.returncode == 0 and 'Ran 12 tests' in tests.stderr and '\nOK\n' in tests.stderr
    policy = subprocess.run([sys.executable, 'tools/maintenance/check_release_policy.py'], cwd=tree, text=True, capture_output=True)
    assert policy.returncode == 0, policy.stderr
    report = json.loads(policy.stdout)
    assert report['result'] == 'PASS_STATIC_POLICY_ONLY' and not report['errors']
    assert sum(w['apk_commands'] for w in report['workflows']) == 3

receipt = {
    'date': '2026-10-18', 'result': 'PASS_EXACT_CODE_SOURCE_AND_LOCAL_POLICY_ONLY',
    'order_sha': ORDER, 'base_sha': BASE, 'implementation_sha': implementation,
    'reviewed_sha': FINAL, 'changed_files': 13,
    'preimages_existing': 9, 'preimages_expected_absent': 4,
    'implementation_postimages_match': 13, 'final_unchanged_postimages': 12,
    'final_task_delta': 'Status READY_FOR_CODE → APPLIED_SOURCE_ONLY +27-line handoff; independently read',
    'files': results, 'workflow_yaml_and_unrelated_gates': 'PASS / UNCHANGED (2 files)',
    'criteria_preserved': 64, 'independent_tests': 12, 'fake_flutter_shell_cases': 6,
    'policy': report, 'app_and_pqc011_unchanged': True,
    'disposition': 'PQC-019 ACCEPTED_WITH_LIMITS — DOCS_AND_KEYLESS_POLICY_SCOPE_COMPLETE',
    'flutter_execution': 'NOT_RUN', 'apk_build_or_inspection': 'NOT_RUN',
    'ci_dispatch_or_rerun': False, 'credentials_read_or_rotated': False,
    'code_worktree_clean': 'Reported by CODE; not observable from remote Git',
    'limits': ['No new runtime/device/voice acceptance', 'Keyless workflow does not revoke old keys or artifacts',
               'PQC-011 still WAITING_FOR_PINNED_SDK_EVIDENCE; PQC-018 remains ART_SCOPE_COMPLETE'],
}
(OUT / 'receipt.json').write_text(json.dumps(receipt, ensure_ascii=False, indent=2)+'\n')
print(json.dumps({k: v for k, v in receipt.items() if k != 'files'}, ensure_ascii=False, indent=2))
