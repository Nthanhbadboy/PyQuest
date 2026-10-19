#!/usr/bin/env python3
"""Render a product planning diagram, not a screenshot or app UI. Pillow + existing Nunito."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/design/experience-blueprint/experience-map.png'
FONTS = ROOT / 'docs/design/tutor-board-prototype/fonts'
W, H = 1680, 1280
im = Image.new('RGB', (W, H), '#f7f4ec')
d = ImageDraw.Draw(im)
INK, MUTED, TEAL = '#193e45', '#53706f', '#256f63'


def font(size, bold=False):
    return ImageFont.truetype(str(FONTS / ('Nunito-ExtraBold.ttf' if bold else 'Nunito-Medium.ttf')), size)


def text(x, y, value, size=24, color=INK, bold=False):
    f = font(size, bold)
    assert x + d.textlength(value, font=f) <= W - 40, value
    d.text((x, y), value, font=f, fill=color)


def block(x, y, value, width, size=23, color=INK, bold=False, max_height=200):
    f = font(size, bold)
    lines = []
    for paragraph in value.split('\n'):
        line = ''
        for word in paragraph.split():
            candidate = (line + ' ' + word).strip()
            if d.textlength(candidate, font=f) > width:
                assert line, word
                lines.append(line)
                line = word
            else:
                line = candidate
        lines.append(line)
    height = len(lines) * (size + 9)
    assert height <= max_height, (value, height, max_height)
    for i, line in enumerate(lines):
        text(x, y + i * (size + 9), line, size, color, bold)
    return height


text(64, 38, 'PYQUEST  /  EXPERIENCE BLUEPRINT 01', 20, TEAL, True)
text(1030, 38, 'SƠ ĐỒ THIẾT KẾ • KHÔNG PHẢI APP', 18, MUTED, True)
text(64, 94, 'Chơi, sáng tạo và có bạn cùng khám phá.', 56, INK, True)
text(64, 176, 'Tutor hỗ trợ mọi hành trình — không bắt mọi trò chơi đi qua bài học.', 27, MUTED)
text(64, 248, 'VÒNG LẶP TRẢI NGHIỆM  /  CÁC NHÁNH LÀ LỰA CHỌN, KHÔNG PHẢI CỔNG BẮT BUỘC', 18, TEAL, True)

stages = [
    ('Khám phá', 'Làng, hoạt động\nvà nơi đang chơi dở', '#dfebe0'),
    ('Chơi & tạo', 'Mini-game, sáng tạo\nhoặc học cùng Tutor', '#e0eaf0'),
    ('Được ghi nhận', 'Kết quả có thật\nLời khen có lý do', '#fae8c2'),
    ('Trưng bày', 'Huy hiệu, tác phẩm\nvà bộ sưu tập', '#eee3f1'),
    ('Có bạn', 'Thăm, khen, hợp tác\nhoặc chơi một mình', '#f4e2d8'),
    ('Thử thách mới', 'Kỷ lục, so tài\nhoặc nghỉ một chút', '#dbece8'),
]
for i, (title, body, color) in enumerate(stages):
    x, y, cw, ch = 64 + i * 260, 290, 244, 234
    d.rounded_rectangle((x, y, x + cw, y + ch), radius=22, fill=color)
    d.ellipse((x + 20, y + 19, x + 56, y + 55), fill='#ffffff')
    text(x + 29, y + 22, str(i + 1), 20, TEAL, True)
    block(x + 20, y + 76, title, cw - 40, 25, bold=True, max_height=70)
    block(x + 20, y + 149, body, cw - 40, 21, color=MUTED, max_height=90)
    if i < 5:
        mid = y + 117
        d.line((x + cw + 3, mid, x + cw + 13, mid), fill=TEAL, width=2)
        d.polygon([(x + cw + 13, mid), (x + cw + 8, mid - 4), (x + cw + 8, mid + 4)], fill=TEAL)

d.rounded_rectangle((64, 555, 1608, 617), radius=16, fill='#e9eee4')
text(90, 571, 'Không fake bạn / thứ hạng • Không ép cày liên tục • Nghỉ chơi không mất thành tích', 23, TEAL, True)
text(64, 659, 'DESIGN LÀM NGAY  /  KHÔNG CHỜ BA GÓI NỀN CỦA CODE', 20, TEAL, True)

packages = [
    ('P05 / ƯU TIÊN ĐẦU', 'Kết quả & vinh danh', 'Thắng, thử lại, kỷ lục\nPhần thưởng và Nhà Thành Tích\nMột lựa chọn tiếp theo rõ ràng', 'Đã có prototype • chưa port Flutter', '#dfebe0'),
    ('P06 / TIẾP THEO', 'Bạn bè & trưng bày', 'Hồ sơ, lời mời, thăm tác phẩm\nQuyền chia sẻ, chặn và báo cáo\nKhông có bạn vẫn chơi trọn vẹn', 'Thiết kế trước • online cần dịch vụ thật', '#e0eaf0'),
    ('P07 / TIẾP THEO', 'Arena & Creator League', 'Luyện tập khác thi đấu người thật\nĐối kháng, sáng tạo, đồng đội\nLuật, kết quả và bảng xếp hạng', 'Thiết kế trước • kết quả cần xác minh', '#fae8c2'),
]
for i, (label, title, body, footer, color) in enumerate(packages):
    x, y, cw = 64 + i * 524, 706, 496
    d.rounded_rectangle((x, y, x + cw, y + 257), radius=22, fill=color)
    text(x + 24, y + 20, label, 18, TEAL, True)
    text(x + 24, y + 58, title, 29, INK, True)
    block(x + 24, y + 111, body, cw - 48, 22, color=MUTED, max_height=110)
    text(x + 24, y + 220, footer, 18, TEAL, True)

text(64, 1007, 'HAI LUỒNG SONG SONG', 19, TEAL, True)
d.line((838, 1055, 838, 1165), fill='#cbd8cc', width=2)
text(64, 1054, 'DESIGN ĐI TRƯỚC MỘT LUỒNG HOÀN CHỈNH', 21, INK, True)
block(64, 1097, 'Luồng + trạng thái + copy VI/EN + art + mẫu bấm thử.\nP08 mini-game và bộ giao diện dùng chung đi cùng.', 725, 23, color=MUTED, max_height=80)
text(888, 1054, 'CODE: PQC-010 / 014 / 015', 21, INK, True)
block(888, 1097, 'Bảng giảng độc lập; resolver / migration;\nnền đa ngôn ngữ Flutter. Không đổi phạm vi.', 700, 23, color=MUTED, max_height=80)
d.line((64, 1202, 1608, 1202), fill='#cbd8cc', width=2)
text(64, 1223, 'Nền chung: 2.5D • đa ngôn ngữ • dễ đọc • ít chuyển động • quyền riêng tư • không XP toàn cục', 21, MUTED)
OUT.parent.mkdir(parents=True, exist_ok=True)
im.save(OUT, optimize=True)
print(f'Wrote {OUT.relative_to(ROOT)} ({W}x{H}) — planning diagram only')
