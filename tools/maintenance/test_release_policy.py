#!/usr/bin/env python3
"""Local regressions; the shell test uses a fake Flutter executable, never the SDK."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

from check_release_policy import EMPTY_DEFINE, WORKFLOWS, build_commands, check_tree, check_workflow

ROOT = Path(__file__).resolve().parents[2]


class ReleasePolicyTests(unittest.TestCase):
    def test_current_tree(self):
        self.assertEqual(check_tree(ROOT)['errors'], [])

    def test_release_and_debug_explicit_empty(self):
        for mode in ['release', 'debug', '"$BUILD_MODE"']:
            self.assertEqual(check_workflow(f'run: flutter build apk --{mode} {EMPTY_DEFINE}'), [])

    def test_env_secret_rejected(self):
        text = f'GEMINI_API_KEY: ${{{{ secrets.GEMINI_API_KEY }}}}\nrun: flutter build apk --release {EMPTY_DEFINE}'
        self.assertTrue(check_workflow(text))

    def test_nonempty_literal_rejected(self):
        self.assertTrue(check_workflow('run: flutter build apk --release --dart-define=GEMINI_API_KEY=not-a-key'))

    def test_shell_substitution_rejected(self):
        for value in ['$GEMINI_API_KEY', '${GEMINI_API_KEY}', '$OTHER_VALUE']:
            self.assertTrue(check_workflow(f'run: flutter build apk --release --dart-define="GEMINI_API_KEY={value}"'))

    def test_missing_empty_define_rejected(self):
        self.assertTrue(check_workflow('run: flutter build apk --debug'))

    def test_define_file_rejected(self):
        for flag in ['--dart-define-from-file=other.json', '--dart-define-from-file other.json']:
            self.assertTrue(check_workflow(f'run: flutter build apk --release {EMPTY_DEFINE} {flag}'))

    def test_duplicate_and_split_defines_rejected(self):
        for extra in [EMPTY_DEFINE, '--dart-define=GEMINI_API_KEY=not-a-key', '--dart-define GEMINI_API_KEY=not-a-key']:
            self.assertTrue(check_workflow(f'run: flutter build apk --release {EMPTY_DEFINE} {extra}'))

    def test_added_unprotected_build_rejected(self):
        self.assertTrue(check_workflow(f'flutter build apk --release {EMPTY_DEFINE}\nflutter build apk --debug'))

    def test_missing_literal_command_requires_manual_review(self):
        self.assertTrue(check_workflow('run: bash build.sh'))

    def test_redirection_status_commands_not_build_arguments(self):
        text = f'flutter build apk --release {EMPTY_DEFINE} >> ../apk.txt 2>&1; echo "build=$?"'
        self.assertEqual(build_commands(text), [['flutter', 'build', 'apk', '--release', EMPTY_DEFINE]])

    def test_bash_expansion_does_not_pass_environment_key(self):
        # Execute only extracted build command prefixes with a fake executable.
        # The sentinel is synthetic. No real environment credentials are inherited.
        import re
        with tempfile.TemporaryDirectory(prefix='r47-policy-') as directory:
            folder = Path(directory)
            fake = folder / 'flutter'
            fake.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
            fake.chmod(0o700)
            cases = 0
            for path in WORKFLOWS:
                text = (ROOT / path).read_text()
                for match in re.finditer(r'\bflutter\s+build\s+apk\b[^\n]*', text):
                    command = match.group().split(' >>', 1)[0]
                    for mode in ['release', 'debug']:
                        result = subprocess.run(['/bin/bash', '-euc', command], check=True,
                                                capture_output=True, text=True, cwd=folder,
                                                env={'PATH': str(folder) + ':/usr/bin:/bin',
                                                     'GEMINI_API_KEY': 'SYNTHETIC_SENTINEL_NOT_A_KEY',
                                                     'BUILD_MODE': mode})
                        args = result.stdout.splitlines()
                        self.assertEqual(args.count(EMPTY_DEFINE), 1)
                        self.assertNotIn('SYNTHETIC_SENTINEL_NOT_A_KEY', result.stdout)
                        self.assertEqual([x for x in args if 'GEMINI_API_KEY' in x], [EMPTY_DEFINE])
                        cases += 1
            self.assertEqual(cases, 6)


if __name__ == '__main__':
    unittest.main(verbosity=2)
