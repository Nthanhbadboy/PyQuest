# Thiết kế hình ảnh PyQuest — tình trạng đến r43

**2026-10-18 · Chưa hoàn tất toàn bộ.** Không dùng số concept hoặc HTML PASS để
nói app đã được redesign xong. Ba mức tách riêng: concept → screen/interaction study
→ runtime art pack +after-runtime evidence.

## Mới nhất: chọn chương/bài học

![Vườn học việc, screen study r43](chapter-journey-r43/evidence/desktop-overview.jpg)

**Đã giao r43:** [Vườn học việc](chapter-journey-r43/index.html),
[README/evidence](chapter-journey-r43/README.md). Một scene2,5D mới,14trạng thái,
12lesson từsource, browser168case/2.340fontassertions/15flows +17JSmodelchecks đạt.
Đây là phần thiếu của baseline12/42trong [audit r41](runtime-gap-r41/README.md),
không đổi/ghi đè bảng audit lịch sử hoặc ảnh runtime baseline.

## Đã có và giới hạn

| Nhóm | Thiết kế đang có | Không được coi là đã xong |
|---|---|---|
| Làng / nhà / thế giới mở rộng | [16canonicalconcept r35](art-sync-r35/catalog.json), các study [r34](art-refresh-r34/index.html), [r40](art-review-r40/index.html) | Không toàn bộ room interaction, animation hay runtime layers |
| Hải đồ / travel / visit permissions | [W08r37](world-travel-r37/index.html) | Không multiplayer/presence hoặc Flutter travel đã port |
| Nhà Thành Tích | [W14r39](achievement-house-r39/index.html) | Cabinet/detail, không đủ cả4phòng |
| Nhiệm vụ hằng ngày / năng lượng | [r41](daily-energy-r41/index.html) | Fixture claim/rest, không thực thi game authority |
| Main Quest chọn chặng/bài | [r43](chapter-journey-r43/index.html) | Không LessonScreen/Tutor board đã đổi skin, không thêm playablechapter2 |
| Shared welcome/settings, pet/shop, Creator, minigame concepts | [CODE018 review r40](art-review-r40/README.md) — art scope complete | Screen studies có giới hạn; B02 prose editor không phải MazeCreator |
| Bài học / bảng Tutor | [Board study](tutor-board-prototype/index.html), W13concept; runtime011review [r42](coordination/reviews/PQD-003-r42.md) | 011chưaaccepted; không lấy art để thay formatter/analyzer/Flutter tests |
| Gameplay/result và các entry sheets | [First-play](first-play-prototype/index.html), [result](result-adventure-prototype/index.html), [r40](art-review-r40/index.html) | Nhiều surface còn partial, chưa screen-by-screen hoàn chỉnh cùng skin |

## Thứ tự DESIGN tiếp tục (không giao CODE trùng việc)

1. **Chọn màn Maze** — baseline05/41: map chọnlevel, stars/completed/locked, entry
   cost, luyện lại, lỗi dữ liệu và deep-link; không chỉ vẽ một sceneRobot.
2. **Maze Creator thật** — baseline26–28: grid/cell/brush/spawn/goal, validation,
   test/run và dirty-save states. Không dùng B02prose mock làm bằng chứng đủ.
3. **Hoàn thiện các màn partial** từ [18nhóm audit](runtime-gap-r41/coverage.json):
   gameplay Maze/Dragon/Stars, kết quả, activityentry, welcome; lesson states phải
   phối hợp011để không trộn source correction với skin redesign.
4. **Splash và rà soát các surface mở rộng** còn thiếu state/interactions, rồi
   xuất runtime art pack thật: layers/alpha/pivots/footprints/hitbounds/occluders/rig.
   Mọi nhóm vẫn cần port và after-runtime captures theo work order riêng.

Không gán phần trăm hoàn thành giả khi phạm vi screen/production khác nhau.
Các links trên là nguồn cụ thể để xem, không lời hứa rằng toàn app đã triển khai.
PQC-018 không bị mở lại; CODE giữ correction011r42 riêng. Không giao taskFlutter mới
trongr43. DESIGN không tự watcher/background làm việc sau khi kết thúc lượt.
