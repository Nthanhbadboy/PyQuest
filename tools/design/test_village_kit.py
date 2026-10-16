#!/usr/bin/env python3
"""Offline integrity checks; not Flutter runtime/visual-regression evidence."""
import hashlib
import json
from pathlib import Path
import unittest
import shutil
import tempfile
from unittest import mock

from PIL import Image, ImageFont, ImageStat

import export_village_kit as exporter

ROOT = Path(__file__).resolve().parents[2]
KIT = ROOT / 'docs/design/village-kit'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


class VillageKitTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((KIT / 'manifest.json').read_text())
        cls.assets = cls.manifest['assets']

    def test_six_real_activity_modules(self):
        self.assertEqual({a['module'] for a in self.assets}, {
            'main_quest', 'robot_maze', 'dragon_jump', 'catch_stars',
            'bug_hunter', 'achievements'})
        self.assertEqual(len(self.assets), 6)
        self.assertEqual(len({a['id'] for a in self.assets}), 6)
        for a in self.assets:
            folder = ROOT / 'app/lib/modules' / a['module']
            modules = '\n'.join(p.read_text() for p in folder.glob('*module.dart'))
            all_source = '\n'.join(p.read_text() for p in folder.glob('*.dart'))
            aid = a['activity_id']
            # ActivityDef may use a literal or a module-local named constant.
            expressions = {
                'dragon_jump': 'kDragonGameId',
                'catch_stars': 'kStarsGameId',
                'bug_hunter': 'BugHunterContent.gameId',
            }
            if aid in expressions:
                expression = expressions[aid]
                self.assertIn(f'id: {expression},', modules)
                self.assertIn(f"{expression.split('.')[-1]} = '{aid}'", all_source)
            else:
                self.assertIn(f"id: '{aid}'", modules)
            self.assertIn(f"thumbnail: 'assets/images/{a['baseline']}'", modules)

    def test_master_integrity(self):
        for a in self.assets:
            with self.subTest(asset=a['id']):
                path = KIT / a['source']
                self.assertEqual(sha(path), a['source_sha256'])
                with Image.open(path) as im:
                    self.assertEqual(im.size, (1024, 1024))
                    self.assertEqual(im.format, 'PNG')
                    self.assertGreater(max(ImageStat.Stat(im.convert('RGB')).stddev), 25)

    def test_exports_size_format_budget_and_hash(self):
        total = 0
        for a in self.assets:
            self.assertFalse(a['alpha'])
            self.assertEqual(len(a['variants']), 2)
            for v in a['variants']:
                with self.subTest(path=v['path']):
                    path = KIT / v['path']
                    self.assertEqual(sha(path), v['sha256'])
                    self.assertEqual(path.stat().st_size, v['bytes'])
                    self.assertLess(v['bytes'], 100_000)
                    total += v['bytes']
                    with Image.open(path) as im:
                        self.assertEqual(im.size, (v['width'], v['height']))
                        self.assertEqual(im.format, 'WEBP')
                        self.assertEqual(im.mode, 'RGB')
        self.assertLess(total, 600_000)

    def test_baselines_unchanged(self):
        locked = exporter.validate_baselines(KIT, self.assets)
        for a in self.assets:
            self.assertEqual(a['baseline_sha256'], locked[a['id']]['sha256'])
            self.assertEqual(sha(KIT / a['baseline_path']), locked[a['id']]['sha256'])

    def test_runtime_state_is_known_not_necessarily_approved(self):
        # A match is integrity only, not art approval or authorization to ship.
        # Code branch must additionally assert the *selected* variant once authorized.
        for a in self.assets:
            self.assertIn(sha(ROOT / a['baseline_source']), {
                a['baseline_sha256'], a['variants'][1]['sha256']})

    def test_review_is_not_shipped(self):
        self.assertEqual(self.manifest['status'], 'design-review-not-runtime')
        self.assertNotIn('village-kit', (ROOT / 'app/pubspec.yaml').read_text())
        self.assertTrue((KIT / 'evidence/asset-review.jpg').is_file())
        self.assertTrue((KIT / 'index.html').is_file())
        for a in self.assets:
            self.assertIsNone(a['anchor'])  # No made-up footpoint/terrain placement.


class ExportBaselineRegressionTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.kit = self.root / 'kit'
        shutil.copytree(KIT, self.kit)
        self.assets = json.loads((self.kit / 'manifest.json').read_text())['assets']

    def hashes(self):
        return {str(p.relative_to(self.kit)): sha(p)
                for p in self.kit.rglob('*') if p.is_file()}

    def assert_rejected_without_writes(self):
        before = self.hashes()
        with mock.patch.object(exporter, 'KIT', self.kit):
            with self.assertRaises(ValueError):
                exporter.export()
        self.assertEqual(self.hashes(), before)

    def test_missing_baseline_fails_without_writes(self):
        (self.kit / self.assets[-1]['baseline_path']).unlink()
        self.assert_rejected_without_writes()

    def test_corrupted_baseline_fails_without_writes(self):
        (self.kit / self.assets[-1]['baseline_path']).write_bytes(b'not the before image')
        self.assert_rejected_without_writes()

    def test_changed_manifest_hash_cannot_bless_corrupted_baseline(self):
        p = self.kit / self.assets[0]['baseline_path']
        p.write_bytes(b'new runtime pretending to be the baseline')
        manifest = json.loads((self.kit / 'manifest.json').read_text())
        manifest['assets'][0]['baseline_sha256'] = sha(p)
        (self.kit / 'manifest.json').write_text(json.dumps(manifest))
        self.assert_rejected_without_writes()

    def test_duplicate_id_fails_without_writes(self):
        p = self.kit / 'baseline-lock.json'
        lock = json.loads(p.read_text())
        lock['assets'].append(lock['assets'][0])
        p.write_text(json.dumps(lock))
        self.assert_rejected_without_writes()

    def test_export_after_runtime_change_preserves_baseline_and_is_repeatable(self):
        for asset in self.assets:
            runtime = self.root / asset['baseline_source']
            runtime.parent.mkdir(parents=True, exist_ok=True)
            runtime.write_bytes((self.kit / asset['variants'][1]['path']).read_bytes())
        baseline_hashes = {a['id']: sha(self.kit / a['baseline_path']) for a in self.assets}
        font_dir = ROOT / 'app/assets/fonts'
        def real_font(size, bold=False):
            return ImageFont.truetype(str(font_dir / ('Nunito-Bold.ttf' if bold else 'Nunito-Medium.ttf')), size)
        with mock.patch.object(exporter, 'KIT', self.kit), \
             mock.patch.object(exporter, 'ROOT', self.root), \
             mock.patch.object(exporter, 'font', side_effect=real_font):
            exporter.export()
            first = self.hashes()
            exporter.export()
            self.assertEqual(self.hashes(), first)
        manifest = json.loads((self.kit / 'manifest.json').read_text())
        for a in manifest['assets']:
            self.assertEqual(sha(self.kit / a['baseline_path']), baseline_hashes[a['id']])
            self.assertEqual(a['baseline_sha256'], baseline_hashes[a['id']])
            self.assertEqual(sha(self.root / a['baseline_source']), a['variants'][1]['sha256'])


if __name__ == '__main__':
    unittest.main(verbosity=2)
