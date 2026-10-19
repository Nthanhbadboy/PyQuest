#!/usr/bin/env python3
"""Exercise orchestration with fake SDK/git commands, not Flutter or credentials."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / 'ci/internal_preview_checks.sh'
STUB = '''#!/usr/bin/env python3
import json,os,sys
name=os.path.basename(sys.argv[0]);args=sys.argv[1:]
if name=='git':
 if 'rev-parse' in args: print(os.environ['SOURCE_SHA'])
 sys.exit(0)
if name=='dart': sys.exit(int(os.environ.get('FAIL_FORMAT','0')))
if '--machine' in args:
 print(json.dumps({'frameworkVersion':os.environ.get('FAKE_VERSION','3.47.7'),'frameworkRevision':'abaf9c523780a608bd46686fd5e53740a07077f8','dartSdkVersion':'3.13.5'}));sys.exit(0)
if args[0]=='analyze':sys.exit(int(os.environ.get('FAIL_ANALYZE','0')))
if args[0]=='test':
 if any('lesson_board_integration' in a for a in args) and os.environ.get('FAIL_INTEGRATION'):
  print('00:02 +0 -7: Some tests failed.');sys.exit(1)
 count=12 if any('settings_sheet' in a for a in args) else 7 if any('lesson_board_integration' in a for a in args) else 10 if '--tags' in args else 422
 print(f'00:01 +{count}: All tests passed!')
sys.exit(0)
'''


class HarnessTests(unittest.TestCase):
    def run_harness(self, extra=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for p in ['app', 'ci', 'bin', 'evidence']:
                (root / p).mkdir()
            for name in ['flutter', 'dart', 'git']:
                p = root / 'bin' / name
                p.write_text(STUB)
                p.chmod(0o700)
            for name in ['test_l10n_evidence.py', 'l10n_evidence.py']:
                (root / 'ci' / name).write_text("print('fake localization helper')\n")
            env = dict(os.environ, PATH=str(root / 'bin') + os.pathsep + os.environ['PATH'],
                       EVIDENCE_DIR=str(root / 'evidence'), SOURCE_SHA='a'*40, WORKFLOW_SHA='b'*40)
            env.update(extra or {})
            result = subprocess.run(['bash', str(SCRIPT)], cwd=root / 'app', env=env, capture_output=True, text=True)
            status = (root / 'evidence/status.txt').read_text()
            counts = root / 'evidence/test-counts.json'
            return result.returncode, status, json.loads(counts.read_text()) if counts.exists() else None

    def test_all_gates_and_real_count_extraction(self):
        code, status, counts = self.run_harness()
        self.assertEqual(code, 0, status)
        self.assertEqual(counts['ordinary']['passed'], 422)
        self.assertEqual(counts['integration']['passed'], 7)
        self.assertIn('tracked_source_unchanged=0', status)

    def test_format_failure_does_not_skip_other_diagnostics_or_pass(self):
        code, status, counts = self.run_harness({'FAIL_FORMAT': '1'})
        self.assertEqual(code, 1)
        self.assertIn('format=1', status)
        self.assertIn('render=0', status)
        self.assertEqual(counts['settings']['passed'], 12)

    def test_analyzer_failure_is_not_masked_by_passing_tests(self):
        code, status, _ = self.run_harness({'FAIL_ANALYZE': '1'})
        self.assertEqual(code, 1)
        self.assertIn('analyze=1', status)
        self.assertIn('count_gate=0', status)

    def test_failed_suite_keeps_actual_pass_and_fail_counts(self):
        code, status, counts = self.run_harness({'FAIL_INTEGRATION': '1'})
        self.assertEqual(code, 1)
        self.assertEqual(counts['integration']['passed'], 0)
        self.assertEqual(counts['integration']['failed'], 7)
        self.assertIn('count_gate=1', status)

    def test_wrong_sdk_stops_before_dependencies_and_tests(self):
        code, status, counts = self.run_harness({'FAKE_VERSION': 'wrong'})
        self.assertEqual(code, 1)
        self.assertIn('sdk_pin=1', status)
        self.assertNotIn('pub_get=', status)
        self.assertIsNone(counts)


if __name__ == '__main__':
    unittest.main(verbosity=2)
