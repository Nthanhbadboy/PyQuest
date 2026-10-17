# Asset plan — Python Tower garden

**Concept +screen study, chưa production export.**

- Delivered: `assets/tower-garden.png`, opaque848×1264, một scene độc lập AI-generated.
- Reference: `../art-refresh-r33/concepts/w01-village.jpg`, canonicalW01, không lấy hai
  JPEGw02/w08dirty. Prompt lưu [assets/prompt.txt](assets/prompt.txt); hashes trongmanifest.
- Đã mở xem full-size: đường đá nối được, ba landing rõ, desk có chân/bóng, khối và
  foliage nhất quán. Roof bị crop có chủ đích trong close-up; **không** dùng ảnh này
  làm full-tower sprite. Không sinh text/numbers/costs/locks vào artwork.
- Không claim original3Dscene, calibrated orthographic camera, animation, alpha,
  editable paint layers, CC0 hoặc độc quyền. Đây là hình sinh từ reference dự án.

## Screen anchors — chỉ composition HTML

| UI | X/Y chuẩn hóa trên scene | Ghi chú |
|---|---|---|
| Bệ1–4 | .73/.38 | Bên phải sân tháp |
| Bệ5–8 | .29/.555 | Giữa-trái |
| Bệ9–12 | .75/.73 | Dưới-phải |
| Sân tập | .50/.89 | Desk phía trước |
| Sân tập ởfont2× | .26/.86 | Labelreflow, không movement trong world |

Các số này là tâm DOMoverlay, **không** pixel hitmask/actor anchor/nav calibration.
Group range/progress, badge và cả control riêng trênHTML; scene image có alt mô tả.

## Export cần làm trước runtime art pack

1. Background atmosphere và vùng biển; không chữ.
2. Terrain/retaining walls, connected path và three blank landings thành ground layer.
3. Tower full silhouette (cả mái), doorway phía trước/sau tách để actor đi qua;
   kiểm lại yaw/elevation vớiW01 và đặt footprint.
4. Props riêng: fountain, bench/book stack, practice desk/stool, lamp; contact shadows
   riêng; không vẽ lại font UI lên tấm biển trong texture.
5. Foliage front occluders/cornerleaves tách alpha để không che controls/actor.
6. Runtime metadata: dimensions, pivot, groundcontact, footprint, occluder order,
   hit bounds +safe areas cho360/390 vàtext2×; sprites/atlas có provenance.
7. Actor không có trongimage này: lấy đúng existingCast asset nếuport, không ghép
   arbitrary mascot. Animation/rig/phong cách pose phải được review riêng.

Chưa có layer nào trong danh sách production trên được xuất. Không tự tách opaque
PNG thành các crop rồi gọi layer pack hoàn chỉnh. Không đổi engine/deps để dựng3D.
