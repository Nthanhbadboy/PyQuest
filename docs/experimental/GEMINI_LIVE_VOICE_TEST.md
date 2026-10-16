# PyQuest — kiểm thử Gemini Live voice trên máy thật

Tài liệu này dành cho người chạy thử APK. AI Tutor voice là tính năng thử nghiệm:
nó chỉ hoạt động ở bản build có `GEMINI_API_KEY` và cần quyền micro.

## Build

Từ thư mục gốc của repo:

```bash
cd app
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=KEY_CUA_BAN
```

Không commit key, không dán key vào issue/chat/PR. `--dart-define` được nhúng
thẳng vào APK nên chỉ dùng cho bản thử nghiệm nội bộ; trước khi phát hành rộng
phải đổi sang token ngắn hạn qua server trung gian và xoay vòng key đã dùng.

Bản Release trên CI lấy key từ repository secret `GEMINI_API_KEY`
(xem `.github/workflows/ci.yml`, job `apk`).

## Các bước kiểm tra

1. Vào một bài học Main Quest, mở **AI Tutor** (nút trong bài hoặc trên bản đồ).
2. Trong thẻ voice, chọn **Kai** hoặc **Lumi**, chạm **Bắt đầu trò chuyện**.
3. Cấp quyền micro. Chờ câu chào: trợ lý phải **nói thành tiếng**, không chỉ hiện chữ.
4. Sau khi trợ lý nói xong, đặt một câu hỏi bằng lời (vi hoặc en).
   **Yêu cầu chấp nhận**: trợ lý phải nói tiếp câu trả lời — không chỉ câu chào.
5. Đặt thêm 2–3 câu liên tiếp. Mỗi câu đều phải có âm thanh.
6. Chat phải hiện **cả hai phía**: `Bé: …` và `Kai: …` (hoặc `Lumi: …`),
   không bị nhân đôi một câu thành hai bong bóng.
7. Nói đè khi trợ lý đang nói: trợ lý phải dừng và nghe lại (barge-in).
   Với tai nghe thì barge-in hoạt động tốt hơn, vì loa ngoài có thể bị micro thu lại.
8. Chạm **Dừng trò chuyện**: trợ lý nói nốt câu đang phát rồi mới tắt micro.

## Đọc log khi có lỗi

Log của phiên voice có tiền tố `[PyQuestVoice]`, chỉ chứa số đếm và kích thước
(không chứa nội dung câu nói của bé, không chứa key):

```bash
adb logcat -s flutter | grep PyQuestVoice
```

Các dòng cần nhìn và ý nghĩa:

| Dòng log | Ý nghĩa |
| --- | --- |
| `setupComplete received` | Phiên Live đã mở, cấu hình được chấp nhận |
| `server audio chunks=N bytes=M` | Model đã trả về âm thanh (M > 0 thì mới có tiếng) |
| `audio stream playing` | flutter_sound đã vào trạng thái phát |
| `playback started bytes=…` | Âm thanh đầu tiên của lượt đã tới loa |
| `microphone reopened (…)` | Micro được trả lại cho bé sau lượt nói |
| `dropped NB slice: device not accepting data` | Đệm của máy chưa nhận thêm; pump tự phục hồi |
| `server ERROR …` / `turnComplete without audio` | Phía server trả lỗi hoặc trả lời chỉ bằng chữ |

## Checklist

- [ ] `flutter analyze --no-fatal-infos` sạch, `flutter test` xanh.
- [ ] Quyền micro chỉ được hỏi khi bật voice.
- [ ] Câu chào **có âm thanh**.
- [ ] Mỗi câu hỏi tiếp theo **có âm thanh** (đây là lỗi đã sửa — bắt buộc kiểm tra).
- [ ] Chat hiển thị đủ cả hai phía, không trùng lặp.
- [ ] Không có âm thanh thì UI vẫn nói thật (trạng thái "chỉ trả lời bằng chữ"),
      không giả vờ là đã có tiếng.
- [ ] Micro từ chối / thiếu key / mất mạng / lỗi quota: Tutor vẫn dùng được, không crash.
- [ ] Xem hạn mức dùng trong Google AI Studio; không mặc định là miễn phí không giới hạn.

Không tuyên bố "chạy được trên máy" nếu chưa chạy hết checklist trên máy thật.
Các kiểm thử tự động (`app/test/tutor_voice_wire_test.dart`,
`tutor_voice_pump_test.dart`, `tutor_voice_session_test.dart`) chỉ chứng minh
giao thức và vòng đời phát nhạc, không chứng minh phiên Gemini thật.
