"""Review archive integrity ONLY; no Dart/Flutter execution or network calls."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


m = json.loads((HERE / 'manifest.json').read_text())
pin, parent = m['code_pin'], m['parent']
assert pin == '71b0fd3fd8fb07c73596ce089fa2e68f6fe87964'
assert parent == '2ea5e5004e98df4aec8c1132a56b8d60bf4ddf5e'
assert git('rev-parse', pin + '^').decode().strip() == parent
paths = {'app/test/lesson_board_integration_test.dart', 'docs/implementation/coordination/tasks/PQC-011.md'}
assert set(git('diff', '--name-only', parent, pin).decode().splitlines()) == paths
assert {r['path'] for r in m['files']} == paths
for r in m['files']:
    data = (HERE / 'source' / r['path']).read_bytes()
    assert data == git('show', pin + ':' + r['path'])
    assert hashlib.sha256(data).hexdigest() == r['sha256']
    assert git('rev-parse', pin + ':' + r['path']).decode().strip() == r['blob']
assert json.loads((HERE / 'correction.patch.json').read_text())['patch'].encode() == git('diff', parent, pin)
for file, key in [('check-runs.json', 'check_runs'), ('workflow-runs.json', 'workflow_runs')]:
    j = json.loads((HERE / file).read_text())
    assert j['total_count'] == 0 and j[key] == []
repo_test = 'app/test/board/authored_board_repository_test.dart'
assert git('show', pin + ':' + repo_test) == git('show', parent + ':' + repo_test)
old = git('show', parent + ':app/test/lesson_board_integration_test.dart').decode()
new = git('show', pin + ':app/test/lesson_board_integration_test.dart').decode()
start = '    final List<MapEntry<Size, PqLang>> cases'
end = '    await tester.runAsync(() => services.settings.setLang(PqLang.vi));'
assert old[old.index(start):].split(end)[0] == new[new.index(start):].split(end)[0]
assert m['executables'] == {'flutter': None, 'dart': None}
links = 0
for doc in [HERE / 'README.md', HERE.parent / 'PQD-003-r44.md']:
    for link in re.findall(r'\]\(([^)]+)\)', doc.read_text()):
        if '://' in link or link.startswith('#'):
            continue
        f = (doc.parent / link.split('#')[0]).resolve()
        assert f.exists() or f == HERE / 'static-checks.json', (doc, link)
        links += 1
receipt = {'result': 'PASS_SOURCE_ARCHIVE_ONLY', 'code_pin': pin, 'source_files': 2,
           'exact_patch_verified': True, 'default_scale_matrix_unchanged': True,
           'repository_rootBundle_AssetManifest_tests_unchanged': True,
           'local_doc_links': links, 'github_checks': 0, 'github_workflow_runs': 0,
           'format_analyze_flutter_tests': 'NOT_RUN', 'ci_triggered': False,
           'scope': 'Git/source archive integrity, not runtime correctness or test execution'}
(HERE / 'static-checks.json').write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps(receipt, indent=2))
