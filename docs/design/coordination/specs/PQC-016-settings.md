# PQC-016 — Settings: lựa chọn ngôn ngữ rõ ràng, lưu trung thực

Revision1, 2026-10-17. **READY_FOR_CODE** theo quyền Lead; prerequisite015 đã ACCEPTED
@556f92d. Đây là lát cắt Settings dùng được, không redesign toàn app trong một patch.
[Copy VI/EN](PQC-016-copy.json) là source thiết kế; code đưa vào ARB/generated thật.

## 1. Source baseline và mục tiêu

Đã đọc exact556f92d: app/lib/app/settings_sheet.dart có ChoiceChipVI/EN gọisetLang,
selected theo settings.lang (effective), toàn copySettings và parent dialog viết
cứngVI. Python info sheet cùng file lấy bulletVI từ simulated_runtime.dart.

Giữ public showSettingsSheet/showPythonLimits, visualPQPanel/palette/font/chunky
buttons/sheet entry. Không thay ảnh/art/theme global. Đổi phần lựa chọn thành3rows
**Theo hệ thống / Tiếng Việt / English**, selected theo preference, không effective.
Từ mànSettings thật, trẻ/phụ huynh đổi ngay và biết có lưu được hay không.

## 2. Bố cục / tương tác

Trong sheet cuộn hiện có, thứ tự:
1. Tiêu đềSettings đã dịch.
2. **Language panel đặt trước togglepanel** để tìm ngôn ngữ dễ: title;3radio-style
   rows full width; active-language line; fallback note nếu cần; save state/retry;
   lời giải thích phạm vi bản dịch hiện tại.
3. Togglepanel hiệu ứng/nhạc/êm dịu, vẫn giữ chức năng cũ.
4. AboutPython, resetprogress, footer. Giữ reset tách rõ với tone danger.

Language rows xếp dọc, không chật3chips ngang; tap target tối thiểu48logicalpx,
label wrap không ellipsis, cảrow chạm được. Selected có radio/check + outline rõ,
không chỉ dựa màu. Tên Tiếng Việt/English là autonym không dịch, không dùng cờ.
System row title dịch theo effective locale. Không tạo modalpicker thứ hai hoặc
nútApply riêng. Tap đã selected đangidle làno-op; retry dùng nútRetry rõ.

Giữ keys language_vi/language_en để tương thích; thêm language_system,
language_save_error, language_retry và language_effective. Không phụ thuộc label
VI để test lookup lựa chọn trongEN. Có semantics label + checked/selected đúng,
focus keyboard/activation qua controlFlutter sẵn có, không duplicate semantics.
ToggleRow cũng có label/toggled/action cho reader; không đổi chungPQToggle ở nơi khác.

## 3. State contract — dùng API014/015, không viết lại resolver

- Dùng settings.localePreference cho selected; đúng1row. Theo systemOSvi: selected
  system, **không** selectedvi. settings.localeResolution.languageCode là active line.
- Dùng LocalePreference.system/vi/en và await setLocalePreference; không gọi legacy
  setLang cho picker mới (adapter đó throw khi savefail, không diễn đạt modesystem).
- Áp dụng lựa chọn ngay trong phiên; sheet/current Navigator không bị đóng/recreate
  hoặc cần restart. Root015 tự nhận notify. Không setRootKey để force refresh.
- System theo OS-change/resume, manual không bịghiđè. Fallback note chỉ khi
  preference=system và usedEnglishFallback=true; selectedvẫn system, activeEnglish.
  Không suy từ devicecountry/IP; không phân tíchBCP47 thêm ởUI.
- Mỗi tap mới gọi một write. Cho phép đổi lựa chọn tiếp khi write đangpending;
  service014 đã serialize. UI theo latest request, không cho completion cũ đặt lại
  spinner/error/status của lựa chọn mới. Không thêm queue hoặcservicefieldmới.
- Stateful widget/localrequest token nếu cần để biểu diễn saving; guard mounted.
  Pending của lựa chọnlatest → dòngSaving, không block toànsheet/không làm mấtfocus.
- Lỗi latest: lựa chọn phiên giữ nguyên, errorinline bằng locale hiện dùng +Retry.
  Nội dung không lộ SQL/stack. Retry gọi setLocalePreference với preference hiện tại;
  thành công hết error, không đảo về giá trịDBcũ ngay trong phiên.
- Đọc localePreferenceSaveError làm nguồn lỗi truth; completion stale không được hiện
  snackbar “lưu lỗi” củarequestcũ. Không tuyên bốSaved trước write hoàn tất.
- **Implicit system/rawnull không phải lỗi.** localePreferenceSaved=false lúc default
  chưa từng ghi là bình thường. Không tự persist system khi mởsheet, không hiện
  error chỉ vìsavedfalse. Chỉ có Saving/Error/Retry; không cần bannerSaved vĩnh viễn.
- Reopen sheet cùng phiên saufailedwrite vẫn thấy error từservice; restart đọc thựcDB
  (có thể trở về lựa chọn đã lưu trước đó). Không bịa persistence từ lựa chọn trênUI.
- Localechange không gọi resetAllProgress/reward/reloadservices; không đổi audio/
  calm values, không đổi transcript/learnerinput hoặcPythonliteral.

## 4. Nội dung được port và phần không port

Toàn visible copy ở settings_sheet.dart: title/toggles/language/status, Aboutbutton,
resetbutton/footer, parent-gate dialog và Pythoninfo sheet. Localize bằng
AppLocalizations.of(context) đọc trong build/dialog builder để live update; tránh
capture String/l10n cũ vào closure rồi không rebuild khi OS đổi.

Parent-gate giữ multiplication/validation/reset semantics cũ; không giảm gate,
không tự reset khi đổi locale; controller/nội dung đang nhập không mất khi dialog
rebuild. Mathquestion typed a/b, không đổi đáp án theo ngôn ngữ.

Pythoninfo có7supported +6limits bullets: port copy theo catalog, **giữ semantics
runtime và code literals**. Không sửa simulated_runtime.dart/engine/grader/limits.
Ví dụ f-string giữ nguyên code f"Xin chào {ten}" trong cảVI/EN, truyền qua typed
placeholderexample để không nhầm ICUbrace với interpolation. Source limits hiện
100000steps,50depth,10000outputchars; không thay cap để khớpUI. CatalogEnglish phải
nói rõ mô phỏng/subset, không hứa fullPython.

Footer chỉ nói progress lưu trên thiết bị; bỏ khẳng định bao quát cũ “mọi dữ liệu
chỉ lưu máy/không thu thập thông tin” vì task này không audit dataflowAI/voice.
Không coi đổi footer là thay chính sách hay triển khai analytics. Scope note nói
Settings/framework đã đổi, phần khác đang dịch; không claim toàn app/voice đãlocalize.

## 5. Layout/accessibility acceptance

- 360×640 và390×844, VI/EN, sheet cuộn tới đủ controls; khôngoverflow/che nội dung.
- Component harness với textscale2.0 khôngoverflow/mất lựa chọn/Retry. App root hiện
  clamp1.2: giữ nguyên trong016, ghi rõ scale2test là uncappedharness, không claim đã
  bỏcap toàn app hoặc đã testTalkBack thiết bị. Chuyển globaltextscale thuộc gói riêng.
- Semantics kiểm nodecontrol thật: selected đúng1, localized labels, retryaction;
  framework-managed semantics, không extraensureSemantics+addTearDown.
- Saving/error/fallback là vùng text thích ứng; trạng thái quan trọng có semantic
  announcement thích hợp, không spam announce mỗi frame/pump. Không bake text vàoart.
- Không yêu cầu screenshot mới để thay assertions; có thể bổ sung scopedrender dùng
  pipeline hiện có nếu cầnreviewlayout, không đổi publisher/CI trong016.

## 6. Test matrix hữu hạn — code phải lập xong trước khi push vòng đầu

1. Rootthật+Settings thật, defaultsystemOSvi; chỉsystemselected, activeTiếngViệt,
   DBkeynull; tương tự unsupportedOS → activeEnglish/fallbacknote/selectedsystem.
2. TapEN/VI/system quaUI; framework/root + sheet copy đổi ngay; sameNavigator/route
   còn mở, togglevalues/progress khôngđổi. Autonyms/keys tồn tại cảVI/EN.
3. System reacts OSchange/resume, manual giữ; tapvềsystem dùng OScurrent. Tái dùng
   helperroot015, không thay acceptedtests hoặc copyresolvervàotestharness.
4. ChọnEN quaUI, close/reopen sheet rồi actualAppServices/app recreation trên DBfile
   giữEN. Chọnsystem lưu literal'system', không phải resolvedvi/en.
5. Savefailure thật qua SQLite trigger hoặc repository fixture điều khiển được:
   sessionchoice giữ, UIerror/Retry, DBgiữold; bỏfault rồiRetry thành công/reopenđúng.
   SettingsServiceerrors dùngAPIaccepted, không thêmtesthook production để fakepass.
6. Rapid choices/late completion: UIlatestwinner, không staleerror/success; dispose
   sheet khiwritepending khôngsetStateafterdispose/unhandledfuture. Có thể dùng
   controllableDatabaseFactory/repositoryởtest; không rewriteAppServices để inject.
7. Parent dialog vàPythoninfo VI/EN, đủ7+6bullets khôngrawVIleak ởEN (trừautonym/code
   literals). OSchange ởsystem trongparentdialog giữ textfieldinput. Cancel/wronganswer
   khôngreset; correctanswer gọi resetflowcũ. Không hạparentgate để test dễ hơn.
8. Smallsize/scale/semantics ở§5. Giữ394ordinary+10render baseline khôngskip/lược tests.

NativeI/O ởtester.runAsync, pumps/asserttrongwidgetzone, finallyunmount→dispose→close.
Không pumpAndSettle vô hạn trênapp có animation lặp; chờ đúngtransition hữu hạn.
Nếu không cóSDKlocal: nói rõ; dùngCI/evidenceexisting và đọc firstexception, không
đoán nhiều vòng. ChỉfullCI bàn giao khi patch đủscope; khôngcommitACK-only.

## 7. Allowlist / output

Xem workorder016. Không runtime resolver/root/services/voice/lesson/CI/deps mới.
ARB mới làmgeneratedbytes thay đổi là đúng016; gen2lần+commit output và exactSHA
CIevidence hiện có vẫn phải pass. Không yêu cầu giữ hash015 sau khi thêm message.

Bàn giao summarybehavior, paths/keyinventory, tests actualresults, exactSHA/run/
checks và giới hạn thực. Lead review rồi giao011, không hỏi user chọn lại task.
