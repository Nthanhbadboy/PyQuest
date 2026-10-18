# Review bed783cf — ngoại lệ locale đúng phạm vi, PQC-020 chưa đạt

**2026-10-18 · CHANGES_REQUIRED / NOT_ACCEPTED020.**
Đã xử lý handoff `CODE-PQC020-JOURNEY-VI-DONE-bed783c9` (lặp lần3); không yêu cầu
CODE gửi lại một bản ACK không đổi. Quyết định sửa tiếp nằm trong
[PQC-020 revision2](../../specs/PQC-020-R2.md).

## Xác minh độc lập

- CODE tip `arena/4253d4f1-pyquest` đúng `bed783cf9b7a327fe9766e96bd2e3020dc08ff82`.
  Nhánh cũ `arena/0d4fcb38-pyquest` vẫn ở `01db21a64b332a758d32aae635304f75137431dd`.
- Diff từ01db21a6: đúng journey test + task020. HaiVI injections; không app/lib,
  assertions/gameplay hoặc testcounts bị đổi trong delta locale. Task note append.
- [Run39139439970](https://github.com/Nthanhbadboy/PyQuest/actions/runs/39139439970)
  đúng finalSHA, completed/failure. [Check117711299154](https://github.com/Nthanhbadboy/PyQuest/runs/117711299154)
  có pub-get/analyze/localization/Settings success; Settings12/0; ordinary433/2.
- Hai failing test names có trong check output: new-player Maze journey và
  characterization keyboard yêu cầu từngTab không đổi focus. Render step skipped.
- REST Actions run query theohead_sha trả một run PyQuest CI. Source hai workflows
  vẫn route branch cũ; focused/maintenance **NOT_RUN** ởbed783cf.
- Không tải blob logs hoặc chạy Flutter tại DESIGN. Check-run text qua API đủ
  xác minh counts/failing names, không đủ xác định chính xác assertion đầu tiên.
  Các preview checks neutral không thay bằng chứng render10/after screenshots.

[Evidence](evidence.json) lưu kết quả, nguồn check và8sourcehashes. Không gộp
locale delta đúng phạm vi thành “journey đãPASS” hoặc “toàn suite không regression”;
counts giữ nguyên một mình không chứng minh điều đó.

## Quyết định hữu hạn

1. **Nhận ngoại lệ locale đã làm đúng scope.** Acceptance011 tại6dc8ca8 giữ nguyên;
   task020 chưa ACCEPTED và không có APK acceptance.
2. **Chọn(a) cho nhãn journey:** đổi duy nhất kỳ vọng map `Núi Lửa Pip`→`Núi Lửa`.
   R53 model và ARB hub đã dùng tên ngắn; canonical ActivityDef vẫn giữ Pip.
   Đây là quyết định oracle từ source, không gọi là stack trace đã đọc.
3. Cho phép đổi hai case keyboard/semantics characterization cũ thành kiểm tra
   tích cực R1-A trong cùng file test, giữ coverage/route/energy/save và counts.
4. Cho phép routing-only mới cho exact branch CODE hiện tại trong hai workflow,
   verify-only, cùng formatter/focused-list bổ sung hai test theo order. Không
   mở normalize/diagnose/dispatch trên nhánh mới, không push sang nhánh cũ.
5. **Cho phép commit sửa thật rồi chạy lại trên SHA mới.** “Cùng finalSHA” không
   có nghĩa không bao giờ được sửa bed783cf. Không tạo commit chỉ để đổi SHA.

## Gap root text scale vẫn chặn nghiệm thu 2×

Source `PyQuestApp` vẫn clamp1.2. Test surface2× không chứng minh behavior của
production root. R2 này không sửa global clamp; không xóa tiêu chí2× và không
cho claim020 hoàn tất chỉ vì sửa xong hai tests. Lead cần mở lát cắt root-scale
riêng với regression/captures phù hợp; CODE không tự broaden app/lib.

## Giới hạn thao tác và tài liệu

DESIGN chỉ đồng bộ fast-forward **nhánh DESIGN của chính mình** từ remote đã có,
đọc CODE và API; không merge CODE vào DESIGN, không push CODE branch, không
rerun/dispatch CI. Publication này là review + work order, không implementation.
CODE append order vào taskdoc của mình, không restore taskdoc DESIGN đè lịch sử.
