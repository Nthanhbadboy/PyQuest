# r35 — Quyết định đồng bộ mỹ thuật, nguồn ảnh và phần còn thiếu

2026-10-18. **Catalog chung không phải giấy duyệt production.** W01 vẫn là neo chính.
16ảnh active đã có một nơi để xem, hash/source rõ và quy tắc dùng chung; không có
16assetproduction, camera calibrated, sprite/alpha/geometry hoặc toàn UI đã hoàn tất.

## 1. Thứ tự nguồn

1. ART_DIRECTION_2_5D + bốn tài liệu gốc: luật bắt buộc.
2. `catalog.json` r35: chọn **đúng ảnh active**; W14 correction thay bảnfrontal.
3. W01: camera/world material/light; exterior và interior phải cùng họ. W13/W11
   là nguồn secondary cho chức năng/identity, không thay W01 làm neo tổng.
4. Code source CastRegistry/painters/lesson/game rules: nhân vật và luật. Không
   chỉnh code/đáp án/scene role theo tranh AI. Generic robot trongMaze/result chưa
   thànhRobo chỉ vì có mắt robot.
5. Prompt/provenance gốc giữ nguyên; historical status không phủ quyết review mới.

## 2. Bảng quyết định cho cả16 ảnh

| ID | Active/source | Quyết định cần đọc trước khi vẽ tiếp |
|---|---|---|
| W01 village |r33published|Neo chính; ánh sáng ấm trêntrái, ivory/walnut/teal/jade/turquoise; không lấy contact sheet làm asset |
| W02 home |r33published corrected copy trongr35|Nhà2tầng là nghiên cứu riêng; preview vẫn có nền/support/cửa chưa rõ, **không mẫu blueprint xây thật** |
| W08 atlas |r33published corrected copy trongr35|Tháp đã cùng silhouette; độrealism/detail cao hơn nhiều nội thất, cần calibrate tiếp; geography không là runtime map |
| W07 interior |r34|Khối phòng/bàn/ghế tốt; cửa nhìn xuống mái khác, cần sửa ngưỡng/sàn trước production |
| W03 project |r34|Điều kiện khác chi phí; preview nền cỏ/nối cửa cần sửa; mẫu nhà1tầng này **không cùng blueprint** vớiW02 |
| W09 visit |r34|Khách đơn, private door đóng; không suy owneronline. Revoked/offline phải bỏ nội dung, không chỉ banner |
| W10 pet |r34|Miu mèo cam ở sân là identity cho pose nghỉ018; mèo xám shop là companion khác, vẫn cần chung tỷ lệ/anatomy family |
| W10b shop |r34|Không bake giá, không bánAIchưa hỗ trợ; mắt/anatomy cần calibrate, không thayMiu bằng mèo này |
| W12 Creator |r34|Workbench nối editor018; cơ cấu là prop không physicstest; không đổi engine theo đường bi |
| W12b gifts |r34|Góc quà không thayfriend list. Gift không cấp skill medal, onlinepresence không có trongảnh |
| W05 Maze |r34|Grid AI không phảileveldata; blankpanelbake/robot cần tách/chỉnh. Không pixel-mapcollision |
| W05 Dragon |r34|Side-view là chủ đích luật, không épiso. Render mềm hơnlinework nội thất; cần chuẩn vật liệu/rig |
| W06 result |r34|Bục trống không giảwin; robot khácMaze, cần unified actor sheet trước runtime |
| W13 Tutor |CODEe3giữconcept|Nova theo source, khôngRobo. Scene/keylight/stonewood phù hợp hướng; boardframe vẫn phối cảnh, readablecode overlay riêng |
| W14 achievements |**r35correction**|Đổi frontal/candle thànhcutaway3/4+daylight; tủ/bục trống choempty. Không dùng bản trophybake gốc làm backgroundempty |
| W11 Arena |CODEe3giữconcept|Robo teal/brass theo source; không đổi thànhivory genericrobot chỉ để giốngMaze. Grid/actorzone minh họa, khôngrulesregistry |

Từng đường dẫn/hash/dimensions và nhận xét nằm trong [catalog](catalog.json). Xem
[gallery](index.html) rồi nút **Mở ảnh đủ kích thước** cho từng mục. W02/W08 dùng copy
byte-for-byte từae7289f: hai file ởworkingtree đường cũ đang làselected-original,
được giữ nguyên để không mất thay đổi sẵn; không dùng chúng làmactive reference.

## 3. Các sửa thực sự đã làm ởr35

- Nhập20file góiCODE nguyênbyte, sourcee3ec5f1; không import runtime/taskghiđè.
- W14newimage từoriginalCODE +W01; originals giữ nguyên. Prompt vàinput/outputhash
  lưu riêng. Khoảng trốnghash trướcrestyle ởCODE vẫn làunknown, không dựng lại.
- W13/W11 chỉ cropmargins cho **layout**; fullconcept giữ nguyên, cropbox trong
  derived-sources.json. Không gọi crop là newart hoặcproductionlayer.
- Cả3layout cófontNunito chung, khungpaper/wood, scene không bịpanel phủ; responsive
  wraps/min-width0, inphonecontrols vẫndisabledmock. W13bỏdebugstepID.
- W14táchtaxonomy earned/locked/secret khỏi **empty thật**. BảnCODEgốc chỉ cótaxonomy
  dù tênselector làempty; empty mới không vẽ/ghi nhận achievement nào.

Không chỉnh toàn bộ16ảnh thànhfinalstyle trongr35. Vẫn cần geometry/character/material
calibration nêu ởbảng; CODE không được coi tất cảconcept làapprovedstyle alternatives.

## 4. Giao các ảnh còn thiếu

[PQC-018](../../implementation/coordination/tasks/PQC-018.md):9ảnh theoA5+B4.
A:journal/settings/welcome/CatchStars/BugHunter.
B:friends-invites/Creator-editor/built-room/pet-rest.

Các trạng thái khác như refund/disconnect/concurrentedit, inputeditor/keyboard,
character rigs/layers vàđườngđi vẫn làbacklogproduction.018khôngđóngtoànapp.
Correctioncácảnhcũ doDESIGN quản lýriêng, không yêu cầuCODE tự ghiđèmaster.

**Bắt buộc Code xem đầy đủ16ảnh active vàcácbốcục đãđồngbộ trước khi vẽ018.**
Ghi observations vàreferencehash thật trongreviewed-inputs.json cùngcommitart;
không ACK-only. Đừng chỉ đọcmanifest rồi ghiđãxemảnh.
