# r46 — artwork, provenance và phần production còn thiếu

## Đã tạo / đã dùng

| Asset | Vai trò trong study | Giới hạn |
|---|---|---|
| [workbench.png](assets/workbench.png) | Một environment mới: xưởng mở nhìn ra vườn, bàn gỗ, kệ dụng cụ, mái teal; backdrop của board live | PNG opaque, props/bóng bake; camera minh họa, không phải geometry đã calibrate |
| [hedge-tile.png](assets/hedge-tile.png) | Một prop bụi cây có mặt trên/mặt bên/bóng; lặp như texture ô đặt được | PNG opaque có cỏ nền; không phải alpha sprite/atlas. Chi tiết lá/viền còn dày so vớiW01, cần cleanup khi xuất production |
| [Robo token legacy](../first-play-prototype/art/robo.svg) | Ký hiệu nhỏ cho bút và vị trí Robo, giữ identity của study trước | SVG cũ chỉ là semantic token; **không** công nhận là actor2,5D final hoặc đủ CastRegistry/rig |
| Water/soil/gem/chest | CSS primitives cho ô và bút, hit semantics tách khỏi art | Temporary symbols, không gọi là production art2,5D hoàn chỉnh. Phải thay bởi tile pack đồng bộ |
| Nunito Medium/Bold | Font local hiện có của repo | Không thêm font/dependency hoặc sửa app assets |

Hai ảnh mới sinh bằng Arena image generation, reference trực tiếp là
[r45 hedge garden](../maze-trail-r45/assets/hedge-trail.png); neo phong cách gốc là
[W01 canonical](../art-refresh-r33/concepts/w01-village.jpg). Đã mở xem cả hai ảnh,
W01 và baseline26–28. [Prompt record](assets/provenance.json) ghi prompt và nguồn;
không có webstock, không claimCC0/exclusive license/hand-painted.

## Khớp và chưa khớp

- **Khớp hướng:** xưởng thuộc cùng vườn, gỗ có thớ và khối, mái teal, ánh sáng ấm
  trên trái, contact shadow; không chuyển toàn scene thành flatSVG/dashboard.
- **Chưa production:** hedge lá có nét đậm hơnW01; table vẽ phối cảnh nhưng board
  live chính diện để thao tác, không claim bốn góc board trùng mặt bàn trong ảnh.
  Sự tách lớp này là layout study của mini-game, không phải render pipeline final.
- Phần1×/2× dùng chung geometry cell. Text/label không bake; marker/icon không
  dùng vùng alpha của ảnh để hit-test. Boardbackground không chứa hidden solution.

## Danh mục cần xuất trước runtime skin order

1. Room shell/backwall/cửa/garden glimpse tách khỏi kệ/bàn/stool/foreground.
   Camera/pivot/footprint theo cùngW01; shadow receiver và occluder rõ.
2. Board frame9-slice; soilA/B, wall variants/endcaps, water edge/corner/center,
   gem, chestclosed/open; spritealpha sạch và contactshadow riêng.
3. Robo đúng cast ởscale ô48–64, idle/move/bonk/sink/win; biểu cảm đọc ởsize nhỏ,
   pivot feet và bbox không đi sang hitcell khác. Bỏ legacySVG token khi pack sẵn.
4. Tilecamera rõdepth nhưng gameplay vẫn orthogonal, không làm lệch ô nhìn/ôchạm.
   Cần test partial occlusion, water clarity, gem/chest contrast với đất.
5. Capturein-runtimeVI/EN200%, touch/keyboard/assistive semantics; native IME,
   repositoryload/savefailure, dirtyback, lifecycle/revision race bằng tests thật.

**Không xuất giả layer bằng crop một ảnh opaque.** Không lấy image background,
CSS depth hoặc PASSbrowser làm runtimeartready. Không mở orderCODE mới trongr46;
018đãART_SCOPE_COMPLETE theo scope cũ, không bị giao lại danh sách này tự động.
