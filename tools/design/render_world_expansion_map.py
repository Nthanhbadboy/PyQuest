#!/usr/bin/env python3
"""Render the expansion information architecture, NOT an app screenshot.
Uses existing tools/design/requirements.txt and the project's OFL Nunito fonts.
"""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/design/experience-blueprint/world-expansion-map.png'
FONTS = ROOT / 'docs/design/tutor-board-prototype/fonts'
W, H = 1800, 1520
im = Image.new('RGB', (W, H), '#f5f7f5')
d = ImageDraw.Draw(im)
INK, MUTED = '#153d47', '#4c646c'


def font(size, bold=False):
    return ImageFont.truetype(str(FONTS / ('Nunito-ExtraBold.ttf' if bold else 'Nunito-Medium.ttf')), size)


def text(x, y, value, width, size=24, bold=False, color=INK, max_height=130):
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
    assert len(lines) * (size + 8) <= max_height, (value, lines)
    for i, line in enumerate(lines):
        assert x + d.textlength(line, font=f) <= W - 30
        d.text((x, y + i * (size + 8)), line, font=f, fill=color)


def box(x, y, w, h, label, title, body, fill):
    d.rounded_rectangle((x, y, x+w, y+h), 22, fill=fill, outline='#c5d4d5', width=2)
    text(x+22, y+18, label, w-44, 17, True, MUTED, 30)
    text(x+22, y+48, title, w-44, 29, True, INK, 85)
    text(x+22, y+98, body, w-44, 22, color=MUTED, max_height=h-105)


def arrow(points, color='#44717b'):
    d.line(points, fill=color, width=4, joint='curve')
    x,y = points[-1]; a,b = points[-2]; angle=math.atan2(y-b,x-a)
    d.polygon([(x,y), (x-14*math.cos(angle-.48),y-14*math.sin(angle-.48)),
               (x-14*math.cos(angle+.48),y-14*math.sin(angle+.48))], fill=color)

text(60,32,'PYQUEST / WORLD EXPANSION / R32',1680,20,True)
text(60,78,'Một thế giới để chơi, học và lớn lên cùng.',1680,46,True, max_height=75)
text(60,150,'SƠ ĐỒ THIẾT KẾ • KHÔNG PHẢI ẢNH APK • KHÔNG TỰ MỞ SCOPE RUNTIME',1680,20,color=MUTED)

# Connections are navigation choices, never mandatory knowledge/paid gates.
arrow([(900,400),(900,440)])
arrow([(620,550),(560,550)])
arrow([(1180,550),(1240,550)])
arrow([(900,670),(900,730)])
arrow([(310,670),(310,730)])
arrow([(1490,670),(1490,730)])
arrow([(560,835),(620,835)])
arrow([(310,950),(310,1000)])
arrow([(900,950),(900,1000)])
arrow([(1180,1090),(1210,1090),(1210,900),(1240,900)])

box(620,210,560,190,'W08 · HẢI ĐỒ','Biết mình đang đi đâu',
    'Vùng công cộng / đảo cá nhân / gói nội dung.\nTravel có cancel, có đường về.', '#deedf7')
box(60,440,500,230,'W05 / W13','Chơi hoặc học ngay',
    'Mini-game · Creator · Main Quest\nTutor hỗ trợ, không là cửa bắt buộc.\nLuật và kết quả thuộc hoạt động.', '#e2f0e3')
box(620,440,560,230,'W01 · LÀNG CÔNG CỘNG','Khám phá và tiếp tục',
    'Cảnh 2.5D + địa điểm thật + một việc dở.\nKhông XP toàn cục, không paywall hub.\nDanh sách điểm đến thay thế pan.', '#d5eee9')
box(1240,440,500,230,'W09 / W11 / W12','Bạn bè · So tài · Sáng tạo',
    'Luyện tập khác người thật.\nCùng chơi khác quyền cùng sửa.\nVisit phải có hoạt động thực chất.', '#f3e4ee')
box(60,730,500,220,'W06 · KẾT QUẢ','Được ghi nhận đúng',
    'Số liệu thật, lời khen có lý do.\nGrant theo rule / nhận không trùng.\nChơi tiếp, trở về hoặc nghỉ.', '#faedce')
box(620,730,560,220,'W04 / W03','Theo một dự án',
    'Điều kiện giữ lại ≠ vật liệu sẽ tiêu.\nThiếu gì → tới nguồn kiếm được.\nPending / retry / restart có receipt.', '#e3ebf6')
box(1240,730,500,220,'W02 / W10','Nhà, sân và thú của mình',
    'Đi lại, sắp đồ, chơi với pet.\nThú nền vẫn hoạt động khi thiếu AI.\nKhông chỉ trang profile có ảnh.', '#e8f0dc')
box(60,1000,500,190,'W14 · TRƯNG BÀY','Thành tích có nguồn',
    'Badge giữ lại, không làm tiền xây.\nQuà xã hội không là skill title.', '#f3e8d9')
box(620,1000,560,190,'W07 · MỞ RỘNG','Xây xong phải dùng được',
    'Phòng → sân/vườn → bến → đảo.\nPreview không trừ; commit chỉ một lần.', '#deeee5')
text(1260,1015,'BA RANH GIỚI PHẢI GIỮ',460,20,True)
text(1260,1055,'Làng công cộng ≠ nhà riêng\nĐảo cá nhân ≠ Side Map trả phí\nAI đề xuất ≠ quyền thực thi',460,22,color=MUTED,max_height=130)

d.rounded_rectangle((60,1240,1740,1410),20,fill='#153d47')
text(84,1258,'ĐƯA THAY ĐỔI VÀO APK THEO LÁT CẮT THẬT',1625,21,True,'#f5f7f5',40)
text(84,1305,'R1 UI làng → R2 nhà + dự án → R3 bố trí + pet nền → R4 đất / bến / đảo',1625,25,True,'#ffffff',45)
text(84,1353,'R5 visit thật · R6 Arena / đội · R7 local AI / commerce: gate riêng, không chặn UI và chơi solo.',1625,22,color='#d5e5e6',max_height=40)
text(60,1432,'Thiết kế chi tiết W01–W14: docs/design/WORLD_EXPANSION_REDESIGN.md • 2026-10-18',1680,19,color=MUTED,max_height=30)
text(60,1465,'Mũi tên là lựa chọn điều hướng, không phải điều kiện bắt buộc để chơi hoặc tiến bộ.',1680,19,color=MUTED,max_height=30)
OUT.parent.mkdir(parents=True, exist_ok=True)
im.save(OUT, optimize=True)
print(OUT.relative_to(ROOT))
