#!/usr/bin/env python3
"""Offline integrity checks; not Flutter runtime/visual-regression evidence."""
import hashlib
import json
from pathlib import Path
import unittest

from PIL import Image, ImageStat

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
        for a in self.assets:
            self.assertEqual(sha(ROOT / a['baseline_source']), a['baseline_sha256'])
            self.assertEqual(sha(KIT / a['baseline_path']), a['baseline_sha256'])

    def test_review_is_not_shipped(self):
        self.assertEqual(self.manifest['status'], 'design-review-not-runtime')
        self.assertNotIn('village-kit', (ROOT / 'app/pubspec.yaml').read_text())
        self.assertTrue((KIT / 'evidence/asset-review.jpg').is_file())
        self.assertTrue((KIT / 'index.html').is_file())
        for a in self.assets:
            self.assertIsNone(a['anchor'])  # No made-up footpoint/terrain placement.


if __name__ == '__main__':
    unittest.main(verbosity=2)
