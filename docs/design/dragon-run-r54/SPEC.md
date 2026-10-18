# Dragon Jump r54 — gameplay, collision feedback và kết quả

2026-10-18 · DESIGN_STUDY_DELIVERED · **runtime NOT_AUTHORIZED**.
CODE pin `6dc8ca8feeed54cc0fa6a82109e3a59d24a16153`; DESIGN base137bb20.
Không sửa app/CI/SDK/deps hoặc giao CODE việc ngoàiPQC-020.

## 1. Nguồn đã đọc và điều chỉnh hướng mỹ thuật

Đọc DragonGame/DragonPainter, DragonHomeScreen/DragonPlayScreen/DragonShop,
energy config/spendEnergy, LevelRecord và shared result.10files có SHA256 trong
[source-manifest](source-manifest.json), trích đoạn trong[SOURCE_NOTES](SOURCE_NOTES.md).
Đã mở baseline `docs/screenshots/21_dragon_play.jpg`: runtime lịch sử, **không biết
buildSHA**, không lấy nó làm matched-before của6dc8ca8 hoặc runtime after-redesign.

ConceptW05r34 có các platform/hố dung nham, nhưng **source không có luật rơi hố**.
R54 thay bằng đường chạy liên tục. Giữ r34 như lịch sử, không làm lại canonicalW01.
Bốn ảnh mới: backdrop, Pip, basalt rock, beetle. Hedge r50 được reuse. Chữ/HUD/coin
positions/stars/collision không bake trong art. Đây không phải actor atlas production.

## 2. Luật hiện có — không phải đề xuất mới

| Luật source | Hiện trong study |
|---|---|
| Cost arcade_run=2 | Entry/replay mỗi lượt trừ2 trong **RAM**; không trừ thêm mỗi lầnnhảy |
| Ready → jump | Tap đầu bắt đầu và nhảy; Back khi ready vềsảnh, không refundcost đãentry |
| Tim | Mặc định3, cóheart thêm1; không coi4tim là mặc định |
| Nhảy | Mặc định2; cówings là3. Resetbudget khi chạmđất |
| Physics | v đầu900, cácairjump800, gravity2700; speed250→540, tăng5/s |
| Time step | Frameclamp0..0.25, substep tối đa1/60; browser khôngchứng minhDartparity |
| Collision | Body x(-20,20), y(pipY+8,pipY+52); obstacle inset12%..88%,4%..86% |
| Obstacle | rock48×44, bush74×38, pillar36×84, beetle46×32/lift70..100 |
| Hit | Mất1tim; còn tim thì bảo vệ1.5s vàvy>=450; hết tim kếtthúc |
| Magnet | Bán kính130, hút420units/s; không thay giá pickup |
| Coin/gem | Coin+1; gem tănggems và+5 vào **g.coins**; không thêm lần nữa khi tínhđiểm |
| Score | floor(distance/50)+3×g.coins; configcoin_value không thay côngthức hardcode này |
| Stars |150/300/500 điểm, boundary>=; zero-star hợp lệ |
| Finish | coins+=runCoins; runs+=1; chỉstars>0 mớiemit levelCompleted('run') |
| Record | Score/stars best được giữ bởiprogress outcome; dưới150 không tạo recordmới |
| Pause/finish | Resume khôngcharge. “Kết thúc lượt” trongpause đi qua_finish, **không vứt xu** |
| Replay | Lượt mới cần2năng lượng, reloadloadout. Không biến replayarcade thành replaylesson miễn phí |

UI hiện “xu lượt này”, “xu trongTổRồng”, “kỷlục đãghi nhận” riêng. Gemcount làthốngkê
thànhphần, khôngbonus thứhai. Zero-star/no priorrecord hiển “Chưa cókỷlục”, không
biến `best=r?.highScore ?? score` trongsource thành lời hứa record đãđược lưu.
Skillcopy chỉ nhắc events/state, không badge chứng nhận Python mastery.

## 3. Bố cục và input

- Home: Pip trongcảnh, record/wallet, energy thật ởruntime tươnglai, mộtCTAentry,
  cáchchơi và loadout read-only.16fixtures là dữliệuRAM, không đọc tài khoản.
- Playing: headergọn, HUDhearts/score/runcoins, canvasđầychiều rộng; dockNhảy ởngoài
  canvas, không phải scrolltới nútnhảy khi đangchạy. Tapstage hoặcSpace/↑/Enter trên
  stage; không nhận keyrepeat hoặckeyboard trongselect/input/dialog.
- Text1/1.3/2× thật: nhãn/HUD/nút tăngfont, không FittedBox/transformscale. Controls
  >=48logicalpx; vật cản không phải nút nên không dùng48px để đổi collider.
- Một scrollowner cho Home/Result. Pauseoverlay cóscroll riêng khi dài, **ưu tiên
  Resume/Finish trước phần mô tả**. Ởpause ẩnHUD và dockNhảy disabled để không chiếm
  diện tích. Header vẫn cóResume; không nhốt người dùng sau một đoạncopy dài.
- Calmmode bỏbobtrangtrí; không giảm tốcphysics/khó game. Không flash sprite nhanh
  khihit: viềnbảovệ vàcaption/thayđổi tim đủ rõ. Không có âm thanh/haptic trongHTML.
- Kếtquả có0..3sao DOM, current score, distance/coins/gems, wallet vàrecord riêng,
  mốc150/300/500, receiptstatus, lờiđộngviên và replay/home/village.

## 4. Đề xuất mới — không nói Flutter đã có

**D54-P1 — responsive camera:** khiUI lớn làm vùnggame thấp, giữfullwidth thay vì
letterbox nhỏ actor. Logicalwidth400, height=viewportheight/width×400. Ground=0.8H;
cameraLift=max(0,pipY+80-ground) để head66units còn cáchméptrên>=14. Backgroundgiữ
aspect, cropquietedges vàaligntoptrack0.75 với ground; khi thiếu trời, kéo hàngpixel
trêncùng. Camera không đổi worldy/collider/speed. Đây làthiết kế, chưa validate
motioncomfort/touch/device/Flutter; cần gate riêng trướcport. Không sử dụng pixel
art để suy collider. Chưa có parallaxlayer/foregroundocclusion thật.

**D54-P2 — background pause và input:** visibilitychange tựpause, quay lại không
 tựresume. Source đang dừngtick khiroutekhôngcurrent; không có chứng cứ device
background lifecycle đãđược xử lý hoàn chỉnh. Testbrowser chỉ dispatchvisibility,
không được gọi là kiểmAndroidlifecycle.

**D54-P3 — receipt pending/unknown:** `_finish` gọi riêngcoinincrement,runincrement,
event; method không có transactionbao cả chuỗi. Study không khẳngđịnh exactlyonce
đãcó. Pending giữresult; unknown ghi“chưa xác nhận”, action“đối chiếu” là read/reconcile
đềxuất, không phát lại coinwrite. Replay bịchặn tới confirmation.

Có thểvềsảnh mà giữreceipt trongRAM, rồi mởlại; không épđợi vôhạn trongresult. Tuy
nhiên **RAM không bền qua reload/processdeath**. Runtime tươnglai cần authority,
receiptid/lưu bền và reconcile thực trước khi cho rờiapp mà claim đãgiữresult.
Home chặn lượt mới tronglúc receiptchưa rõ. Village chỉ mởsauconfirmed trongstudy.
Ackmock dùngattemptid+objectidentity vàdedupSet đểdemo stale/doublecallback;
không phải transactionid hoặc securityboundary. Khi chơi live, confirmationmẫu sau
950ms; reviewfreeze chờnútphản hồi ngoàiđiệnthoại. Không cóserver/DBwrite.

**D54-P4 — kếtquả rõ nghĩa:** trướcconfirmation không show“kỷlục mới/xu đãvào ví”.
Sauconfirmed phân biệtfirst/better/tie/lower/zero-star. Skillreminder khôngmastery.
Đềxuất này không tự đổi rewardpipeline hoặcsource thresholds.

## 5. Giới hạn analogue

JS dùngseedLCG đểtest lặp, **không cùng RNG DartRandom**. Cóphysics/collision/pickup
source-derived đểthửinteraction; khôngcompiler/engineport/goldenparity, khôngmonetary
wallet. Bỏparticle system/overanimation1.3s/hat renderer/audio vàgameplayparallax;
actor chỉmộtpose translate/bob. Cácstyle mới chưa là spriteanimation.
Loadoutfixture cóheart/wings/magnet;8shopprices đượcsourcepin nhưng shopchỉđọc,
khôngbuy/equip/consume coins. Không thêm lênlevel mới hoặcmởquyền mua từstudy.

Trước runtimeorder: actorposes/pivots/alpha/shadows, terrainvariants vàpillar thật;
Dartparity/source tests, frame/memory/device, touch/semantics/locale/resize,
persistence/reconciliation/migration vàsameSHA afterFluttercaptures. BrowserPASS
không nhận020 hoặcDragonruntime. Không buildAPK trongr54.
