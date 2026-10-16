#!/usr/bin/env python3
"""Recompute PQC-007 facts from pinned Git blobs; stdlib, read-only, no Flutter.
Run from repo root. JSON goes to stdout; no working-tree source is trusted.
WebP header dimensions are not a full codec/decode or device-memory measurement.
"""
import hashlib
import json
import re
import struct
import subprocess

CODE = '3b59f0b538f4bd94c49bf3076ae24f1c1dd8f428'
DESIGN = '86513ca29910896ef21961d9489f00414dc5262f'


def blob(ref, path):
    return subprocess.check_output(['git', 'show', f'{ref}:{path}'])


def text(path):
    return blob(CODE, path).decode()


def webp_size(data):
    assert data[:4] == b'RIFF' and data[8:12] == b'WEBP'
    pos = 12
    while pos + 8 <= len(data):
        kind, size = data[pos:pos+4], struct.unpack_from('<I', data, pos+4)[0]
        body = data[pos+8:pos+8+size]
        if kind == b'VP8X':
            return (int.from_bytes(body[4:7], 'little')+1, int.from_bytes(body[7:10], 'little')+1)
        if kind == b'VP8 ':
            assert body[3:6] == b'\x9d\x01\x2a'
            return tuple(n & 0x3fff for n in struct.unpack_from('<HH', body, 6))
        if kind == b'VP8L':
            assert body[0] == 0x2f
            bits = int.from_bytes(body[1:5], 'little')
            return ((bits & 0x3fff)+1, ((bits >> 14) & 0x3fff)+1)
        pos += 8 + size + size % 2
    raise ValueError('No supported WebP dimension header')


def asset(ref, path):
    data = blob(ref, path)
    w, h = webp_size(data)
    return dict(path=path, bytes=len(data), width=w, height=h,
                sha256=hashlib.sha256(data).hexdigest(), rgba8_bytes=w*h*4)


def cover(image, box):
    scale = max(box[0]/image[0], box[1]/image[1])
    w, h = image[0]*scale, image[1]*scale
    return dict(width=w, height=h, left=(box[0]-w)/2, top=(box[1]-h)/2,
                visible_width_percent=box[0]/w*100, visible_height_percent=box[1]/h*100)


main = 'app/lib/modules/main_map/main_map_screen.dart'
image_size = tuple(map(int, re.search(r'kMapImageSize = Size\((\d+), (\d+)\)', text(main)).groups()))
modules = [('main_quest', 'main_quest/main_quest_module'), ('robot_maze', 'robot_maze/robot_maze_module'),
           ('dragon_jump', 'dragon_jump/dragon_jump_module'), ('catch_stars', 'catch_stars/catch_stars_module'),
           ('bug_hunter', 'bug_hunter/bug_hunter_module'), ('achievement_house', 'achievements/achievement_house_module')]
rects, thumbs = [], []
for ident, module in modules:
    path = f'app/lib/modules/{module}.dart'
    source = text(path)
    rect = [float(x) for x in re.search(r'hitBox: Rect.fromLTRB\(([^)]+)\)', source)[1].split(',')]
    assert 0 <= rect[0] < rect[2] <= 1 and 0 <= rect[1] < rect[3] <= 1
    anchor = [float(x) for x in re.search(r'labelAnchor: Offset\(([^)]+)\)', source)[1].split(',')]
    rects.append(dict(id=ident, source=path, normalized_ltrb=rect, label_anchor=anchor))
    thumbs.append(asset(CODE, 'app/' + re.search(r"thumbnail: '([^']+)'", source)[1]))
prototype = asset(DESIGN, 'docs/design/first-play-prototype/art/village.webp')
manifest = json.loads(blob(DESIGN, 'docs/design/first-play-prototype/manifest.json'))
record = next(x for x in manifest['assets'] if x['path'] == 'art/village.webp')
for field in ['bytes', 'width', 'height', 'sha256']:
    assert prototype[field] == record[field], field
exports = [asset(DESIGN, 'docs/design/first-play-prototype/'+x['path']) for x in manifest['assets'] if x['path'].endswith('_512.webp')]
geometry = []
for box in [(390, 844), (360, 640)]:
    dest = cover(image_size, box)
    hits = []
    for rect in rects:
        l, t, r, b = rect['normalized_ltrb']
        hits.append(dict(id=rect['id'], width=(r-l)*dest['width'], height=(b-t)*dest['height'],
                         left=dest['left']+l*dest['width'], top=dest['top']+t*dest['height']))
    geometry.append(dict(viewport=box, original_cover=dest, original_hits=hits,
                         prototype_cover=cover((prototype['width'], prototype['height']), box),
                         hypothetical_square_cover=cover((1024, 1024), box)))
source_paths = [main, 'app/lib/core/settings_service.dart', 'app/lib/shared/widgets/chunky_button.dart',
                'app/lib/shared/widgets/common.dart', 'app/lib/modules/main_map/activity_sheet.dart',
                'app/lib/modules/robot_maze/maze_play_screen.dart', 'app/lib/modules/robot_maze/maze_models.dart',
                'app/lib/modules/robot_maze/maze_board.dart', 'app/lib/shared/widgets/result_screen.dart',
                'app/lib/modules/tutor/tutor_panel.dart', 'app/lib/shared/characters/dialogue.dart',
                'app/test/activity_sheet_thumbnails_test.dart', 'app/test/render/render_screens_test.dart']
source_paths += [r['source'] for r in rects]
patterns = r'introSeen|setIntroSeen|welcome_next|kMapImageSize|_coverRect|hitBox:|labelAnchor:|GestureDetector|Semantics|Focus|calmMode|EnergyPill|hintCells|commandLimit|withinLimit|commandCount\(_program\) <|ResultStat\(|onPressed: running|Future<void>.delayed|didChangeAppLifecycleState|ChunkySize.small =>|padding: EdgeInsets.only|openLessonId|highlighted:|_unlocked\(|_open\(Lesson|spendEnergy|activityOpened|levelCompleted|recordLevelResult|showRewardToasts|CastDialogue.line|abstract final class CastDialogue|showPQSheet|currentSize|precacheImage'
anchors = {}
for path in dict.fromkeys(source_paths):
    data = blob(CODE, path)
    anchors[path] = dict(sha256=hashlib.sha256(data).hexdigest(), lines=len(data.splitlines()),
                        matches=[dict(line=i, text=s.strip()) for i, s in enumerate(data.decode().splitlines(), 1) if re.search(patterns, s)])
files = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', CODE, 'app/lib']).decode().splitlines()
scan = {pattern: [] for pattern in ['disableAnimations', 'accessibilityFeatures', 'textScaler', 'textScaleFactor', 'maximumSizeBytes', 'didChangeAppLifecycleState']}
for path in files:
    if not path.endswith('.dart'):
        continue
    for i, line in enumerate(text(path).splitlines(), 1):
        for pattern in scan:
            if pattern in line:
                scan[pattern].append(f'{path}:{i}:{line.strip()}')
legacy_bytes = sum(x['bytes'] for x in thumbs)
new_bytes = sum(x['bytes'] for x in exports)
app_js = blob(DESIGN, 'docs/design/first-play-prototype/app.mjs').decode()
points = [dict(id=i, x=float(x)/100, y=float(y)/100) for i, x, y in re.findall(r"\{id:'([^']+)'.*?x:(\d+),y:(\d+)", app_js)]
assert len(points) == 6
print(json.dumps(dict(code_commit=CODE, design_commit=DESIGN, method='Pinned Git blobs, source text and header math; not a Flutter run',
                     map_image=asset(CODE, 'app/assets/images/island_map.webp'), geometry=geometry,
                     normalized_module_rects=rects, prototype_scene=prototype, prototype_point_anchors=points,
                     thumbnails=thumbs, exports=exports,
                     totals=dict(before_bytes=legacy_bytes, after_bytes=new_bytes, reduction_bytes=legacy_bytes-new_bytes,
                                 before_rgba8_bytes=sum(x['rgba8_bytes'] for x in thumbs), after_rgba8_bytes=sum(x['rgba8_bytes'] for x in exports)),
                     source_anchors=anchors, source_scans=scan,
                     bug_unlock_lesson=json.loads(blob(CODE, 'app/assets/data/bug_hunter_puzzles.json'))['packs'][0]['requires_lesson']), ensure_ascii=False, indent=2))
