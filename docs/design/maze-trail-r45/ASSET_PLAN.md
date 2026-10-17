# Asset plan — Robo hedge trail r45

**Concept + screen study, không phải runtime art pack.**

Delivered `assets/hedge-trail.png`: opaque848×1264, một scene AI-generated theo
canonical W01 r33. Đã mở full-size: khối cây/tường/đường đá đọc rõ; năm landing
nối được với nhau, cầu có điểm tiếp đất, Workshop cùng họ vật liệu. Không có chữ,
sao, số màn hoặc giá bake vào ảnh. [Prompt](assets/prompt.txt) và manifest ghi nguồn.

Camera ba phần tư chỉ là xấp xỉ trong concept. Không claim 3Dscene/calibratedcamera,
alpha layers, actor rig, animated sprites, collision hay pathfinding. Không claim CC0
hoặc quyền độc quyền. Hai JPEGw02/w08dirty không được dùng làm reference.

## Anchors của UI trên map canvas

| Control | Center X/Y | Ý nghĩa |
|---|---|---|
| point0 | .28/.14 | Màn1hoặc6 |
| point1 | .72/.295 | Màn2hoặc7 |
| point2 | .29/.48 | Màn3hoặc8 |
| point3 | .73/.65 | Màn4hoặc9 |
| point4 | .29/.84 | Màn5hoặc10 |
| Workshop | .76/.91 | Chỉ label/entry overlay; font2× chuyển xuống flow dock |

Đây là composition anchors, không world coordinates/hit mask/footprint. Hai trang
đổi số màn trên cùng art có chủ đích: route-book abstraction, không tuyên bố hai
level có cùng maze geometry. Phác đồ detail lấy rows nguồn riêng của từng level.

## Các lớp cần xuất trước production

1. Ground/path/plazas; stone retaining walls và contact shadows.
2. Hedge sections có footprint; phân foreground occlusion với background hedge.
3. Water riêng với bank masks; bridge deck/rail/front occluder và shadow riêng.
4. Workshop đầy đủ silhouette/roof/post/desk, có actor entrance và occlusion order.
5. Chest, flowers và corner foliage tách; không đưa chest minh họa vào gameplaygoal.
6. Robo lấy đúng canonical cast asset, không tự sinh một robot mới trong ảnh này.
7. Metadata: dimensions, pivot/contact point, footprint, hitbounds, safe areas,
   alpha export, atlas và measured alignment với W01. Animation là scope riêng.

Chưa xuất những layer trên. Không cắt opaquePNG thành vài crop rồi gọi là layerpack.
Source row diagram cũng chưa phải bộ tiles gameplay mới; không thay board bằng ảnh
maze vô tình chứa đường giải. Editor/Creator và actual gameplay skin phải có design
và runtime order riêng. Không đổi engine/deps để đạt concept này.

Khung review/CSS ban đầu fork từ r43, lưu local trong gói mới; không sửa stylesheet
hoặc manifest của r43. References có hash của W01, hai baseline05/41 và CSS nguồn.
