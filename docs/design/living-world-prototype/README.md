# P04 — Làng có đời sống, thế giới có chân trời

**Mẫu HTML có tương tác. Thoại soạn sẵn, NPC hư cấu, không AI/voice/multiplayer thật.**
Không thay runtime Flutter, nguồn chấm bài hay progress/energy của app.

## Mở mẫu

Từ root repo:

```sh
python3 tools/design/serve_world.py --port 8001
```

Server bind0.0.0.0, chỉ serve docs/design; root redirect tới living-world-prototype.
Cần serve cả docs/design vì mẫu tái dùng art/fonts và bảng của P03 qua relative URLs;
**không** serve riêng folder P04. Không có CDN/backend request.

- **Làng của mình:** xem Mây/Bo đi dạo và vào/ra nhà; pause sinh hoạt; chọn ba landmark
  đại diện. Tháp Python mở bảng thật của P03; hai nhà khác nói rõ chưa có nội thất.
  Không ngầm bỏ ba activity khác của app: chúng chưa được wire trong slice này.
- **Tutor:** câu mở đầu lấy biến thể ngẫu nhiên từ script; khi đổi context/nhấn hỏi,
  tiếp tục bằng biến thể tiếp theo. Có thể thu gọn hoặc gọi lại bằng avatar. Không
  có autoplay lời nói/voice hay cá nhân hóa dựa trên lịch sử thật của trẻ.
- **Bến thuyền/Hải đồ:** chọn một trong ba đảo, xem đường đi, lên thuyền, hủy hoặc
  tới bến. Làng Tán Lá và Đảo Sao Mai là concept, **chưa có game/playable village**.
- **Bảng của Tutor:** P03 được giữ trong một iframe cùng origin, không reload khi
  rời/đến. Code/note/ink giữ trong phiên; hidden frame được gửi pause. Đi thuyền bị
  hủy khi điều hướng/ẩn trang, không tiếp tục cập bến âm thầm.
- Tab Làng của mình là **quay về nhanh** bến home, không bắt xem chuyến thuyền trở về.
  “Đón lại từ đầu” reset thế giới/clock, không xóa bài/nét đang làm trên bảng.
- OS reduced-motion OR setting tắt ambient, thuyền cập bến ngay. Pause sinh hoạt chỉ
  dừng NPC, không khóa lớp học. Không cập nhật live announcements theo từng bước NPC.

## Cấu trúc

- world-engine.mjs: greetings/routes/waypoint state thuần, có unit tests.
- world.mjs: rendering/scheduler, travel cancel, same-origin iframe bridge.
- world.css/index.html: responsive scene/card/Tutor dock, keyboard-accessible list.
- art/: ảnh quần đảo mới + SVG trẻ/thuyền. Assets P03 tham chiếu tương đối, không copy.
- manifest.json: hashes/provenance/source dependencies. Không ghi quyền độc quyền/CC0.
- evidence/:7 JPEG thật từ browser và browser-check.json; không phải Flutter screenshots.

Quần đảo: nguồn AI-generated1264×848, JPEG173,234B →WebP127,302B; pixel RGBA8 lý thuyết
4,287,488B (không phải số RAM/GPU đo). Nền là ảnh liền, không layered scene/navmesh.
Waypoint chỉ cho prototype. Mèo, trẻ và thuyền là hình đơn với transform, chưa sprite cycle.

## Chạy checks

```sh
node --test tools/design/test_living_world.mjs
# Với server8001 + Playwright Core và Chromium:
NODE_PATH=/path/to/node_modules node tools/design/smoke_living_world.cjs
```

Sandbox: `NODE_PATH=/home/user/.cache/art-review/node_modules` và
`LD_LIBRARY_PATH=/tmp/chromium-libs/lib`; có thể override BROWSER_EXECUTABLE_PATH/GALLERY_URL.
Không cần Flutter SDK để chạy prototype tests. Xem tools/design/package.json cho npm versions.

8 tests world: greetings, normalized routes/docks/reversal, cancel-safe state calculation,
NPC approach/inside/leave/rest. Tổng chạy lại27 tests P02/P03/P04 PASS.
Browser PASS desktop1440×1100,390×844,360×640: NPC move/enter/pause, dialogue variation,
selection/travel/cancel/arrival, input giữ qua iframe, hidden playback pause, OS motion,
selected targets48px, không overflow kể cả board embedded, keyboard selection, noHTTP/JS errors.
P03 standalone browser suite cũng chạy lại sau thay đổi bridge và PASS.

Chưa kiểm: thiết bị/TalkBack/stylus, font scale2, battery/frame budget, collision/occlusion
production, AI/voice/learner-work storage hoặc child usability. Lời nói được soạn sẵn không phải AI
hiểu hình/nét. Không tạo fake XP, mở khóa, online players hoặc reward khi đi thuyền.

## Handoff

`../LIVING_WORLD_DIRECTION.md` là quyết định sáng tạo và ràng buộc. PQD-003 revision3
nhận thêm world context, nhưng bảng Tutor vẫn là việc code ưu tiên; không mở runtime
hoặc biến request này thành một orchestration framework. Mẫu P03 dùng thêm `?embedded=1`
để vào lớp trực tiếp/ẩn header; đường standalone vẫn giữ nguyên.

## Ngôn ngữ

Cài đặt → Theo hệ thống / Tiếng Việt / English. UI, Tutor script và board cùng lựa
chọn, parent/iframe đồng bộ ngay cả khi storage bị chặn; không reset input/ink/route.
Chỉ preference lưu ở localStorage; bài/nét vẫn chỉ trong phiên. Xem
`../shared-l10n/README.md` cho thêm 9 unit tests, browser locale suite và evidence;
`../LANGUAGE_AND_LOCALIZATION.md` là contract toàn app, chưa phải Flutter đã localize.
