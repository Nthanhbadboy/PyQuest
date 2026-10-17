"""Validate the r42 source archive, not the Dart program or Flutter tests."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


manifest = json.loads((HERE / 'manifest.json').read_text())
pin = manifest['code_pin']
parent = manifest['parent']
assert pin == '2ea5e5004e98df4aec8c1132a56b8d60bf4ddf5e'
assert parent == '4fe3b7d0a1bf5f6dface1b04cbc4e2d7ee9d451f'
assert git('rev-parse', pin + '^').decode().strip() == parent
expected = {
    'app/lib/modules/main_quest/lesson_screen.dart',
    'app/lib/modules/tutor/board/authored_board_repository.dart',
    'app/test/board/authored_board_repository_test.dart',
    'app/test/lesson_board_integration_test.dart',
    'docs/implementation/coordination/tasks/PQC-011.md',
}
assert set(git('diff', '--name-only', parent, pin).decode().splitlines()) == expected
assert {f['path'] for f in manifest['files']} == expected
for row in manifest['files']:
    raw = (HERE / 'source' / row['path']).read_bytes()
    assert raw == git('show', pin + ':' + row['path']), row['path']
    assert hashlib.sha256(raw).hexdigest() == row['sha256'], row['path']
    assert git('rev-parse', pin + ':' + row['path']).decode().strip() == row['blob']
patch = json.loads((HERE / 'correction.patch.json').read_text())
assert patch['patch'].encode('utf-8') == git('diff', parent, pin)
checks = json.loads((HERE / 'check-runs.json').read_text())
runs = json.loads((HERE / 'workflow-runs.json').read_text())
status = json.loads((HERE / 'commit-status.json').read_text())
assert checks['total_count'] == 0 and checks['check_runs'] == []
assert runs['total_count'] == 0 and runs['workflow_runs'] == []
assert status['sha'] == pin and status['total_count'] == 0 and status['statuses'] == []
assert manifest['executables'] == {'flutter': None, 'dart': None}
assert 'while (binding.hasScheduledFrame)' in (HERE / 'flutter-pump-and-settle.txt').read_text()
links = 0
for doc in [HERE / 'README.md', HERE.parent / 'PQD-003-r42.md']:
    for target in re.findall(r'\]\(([^)]+)\)', doc.read_text()):
        if '://' in target or target.startswith('#'):
            continue
        assert (doc.parent / target.split('#')[0]).exists(), (doc, target)
        links += 1
receipt = {
    'result': 'PASS_SOURCE_ARCHIVE_ONLY',
    'code_pin': pin,
    'parent': parent,
    'source_files_byte_and_git_blob_verified': len(expected),
    'exact_patch_verified': True,
    'local_doc_links_checked': links,
    'github_metadata': {'checks': 0, 'workflow_runs': 0, 'status_entries': 0},
    'runtime_format_analyze_flutter_tests': 'NOT_RUN',
    'ci_triggered': False,
    'scope': 'Archive/pin/metadata/link integrity only; not correctness or test execution.',
}
(HERE / 'static-checks.json').write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps(receipt, indent=2))
