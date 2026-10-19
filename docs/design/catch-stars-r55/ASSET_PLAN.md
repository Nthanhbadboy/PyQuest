# Art & production gap — Catch Stars r55

**Study art only.** Không thay `app/assets`, painter, pubspec hoặc game rules.
[Provenance/hash](assets/provenance.json) ghi8file và4referencehash. Bốn ảnh nguồn
được tạo mới bằng Arena image generation cho tài sản trong study, không phải ảnh
stock/native alpha hoặc cam kết độc quyền. Không dùng nguồn ngoài web mới ởr55.

## Lớp hình đang dùng

| Layer | Study | Còn thiếu trước production |
|---|---|---|
| Sky/observatory | `observatory-sky.png` →WebP; không bake faller/jar | Táchsky/moon/island/building nếu cầnparallax; palette/contrast trênthiếtbị |
| Catcher | `jar-source.png` →`jar-token.png`, white edge-matte | Native alpha, kính thực, rim/front/back riêng; catch/idle/hit poses |
| Star | `star-source.png` →`star-token.png`; regular30/golden48 logical | Hai variant/atlas rõ, glow riêng, rotations không làm đổicollision |
| Comet | procedural shaded orb +70-unit trail | Tactile comet sprite/trail animation, không khẳng định đãvẽ mới đủ5sprite |
| Rainbow | star +3 procedural rings | Bộring/catch FX tách layer, reduced-motion treatment |
| Meteor | `meteor-source.png` →`meteor-token.png`, trail50 riêng | Pose/rotation/impact frames vàsilhouette contrast |
| Robo | reuse r50 `robo-token.png` theo hash, không copyduplicate | Native alpha khôngflooroval; idle/peek/surprised/celebrate; cast identity giữ |
| Cloud | procedural rounded volumes | Cloud alpha riêng/shadow anchors phù hợp jar2.5D |
| Atlas | SVG points/edges từ8constellations nguồn | Vector/native painter asset contract; locked/lit semantics, scalablepoints |

Jar model sinh ra **cao hơn yêu cầu**. Study nén art thành92×62 để đọc như bowl;
đây làproxy, không native ratio/approvedproduction silhouette. Kính nhìntrong
nhưng phần thân làmàu opaque: flood-fill bỏwhite edge, không tạo refraction.
Cần redraw short/wide jar và rim layers; không dùng compositing này làm final.
Robo r50 cóovalshadow tại chân: ởđây vẫnlàsinglepose, không gọianimation/3D rig.

Nền mới giữfamily teal/brass/stone vàphầnsky thoáng; observatory trongảnh còn lớn
hơnbrief “lower12%”. Renderer fitheight/right thay vìcover/crop: tạiphonethấp nó
nhỏlại, không chiếmtoànbộ bênphải nhưcover banđầu. Bầu trời kéoextended edgecolumn
đểfillwidth, sourcePNG khôngbị sửa/bakeactor. Không claimnền tách đủbuildinglayer.

## Quy tắc kích thước

Gameplaywidth400. Spritewidth theo viewportwidth/400, không theo fontsize hoặc
chiềucaocòn lại. Worldy400×600→stagey riêng, proposalD55-P1 trong[SPEC](SPEC.md).
Rimjar92, bodyproxy62height; Robo52×61; star30,golden48,meteor32,cometdiameter22,
rainbowrings26/21/16radius. Actor nhỏ nhất vẫn tương đươngpixel-size từsource,
không phóngHUD rồi thu hẹp lane thànhcột giữa. Text HUD/feedback làDOMscalable.

Không xu/gem/portal/house/NPCwalking/currency/trophyobject mới. Điểm tạo 3 mốc sao kết quả nguồn,
không ngầm biếnstarart thànhcurrency muađất. Atlas8mẫu đúngsource, chưa lessonastronomy.

## Rebuild & integrity

`tools/design/build_stars_r55.py` chỉ đọc pinCODE vàghi study. RequiresPillow.
Thuật toánmatte: edge-connected white minRGB232/chroma26, erode1px/blur0.35,
crop/thumbnail512. Derivative làstudy matte, không nativealpha. Rebuild không
regenerateAIảnh; hashPNGnguồn cótrongprovenance. `catalog.json` tríchDart bằngregex
cóassert đủ8entry; ENtranslations minhthị. Staticvalidator còn soVI/geometry gốc.

Runtime cần thêm packedatlas/scaledassets/licensesreview, optical/collider anchors,
image decode memory đo thật và captureFlutter. ByteWebP hoặc RAF JS khôngsuyra60fps.
