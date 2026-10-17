# PyQuest — kiểm thử Gemini Live voice trên máy thật

Tài liệu này dành cho người chạy thử APK. AI Tutor voice là tính năng thử nghiệm:
nó chỉ hoạt động ở bản build có `GEMINI_API_KEY` và cần quyền micro.

## Build và quyền phân phối — cập nhật r47

**APK CI mới không dùng để kiểm thử voice có xác thực.** Cả hai workflow
`ci.yml` và `build-debug-apk.yml` không đọc Gemini repository secret, và truyền
`--dart-define=GEMINI_API_KEY=` khi build. Không thêm lại secret vào workflow để
bật voice. APK keyless có thể dùng để kiểm tra luồng thiếu key/fallback, nhưng
không chứng minh PCM/audio session thật hoạt động.

Source vẫn còn đường thử nghiệm cục bộ có key. Chỉ chạy trên môi trường/thiết bị
được phép, dùng credential thử nghiệm riêng và không upload/phân phối APK đó.
Cấu hình credential ngoài repository theo quy trình bảo mật cục bộ; không gửi key
vào chat/issue/PR, không ghi vào shell history hoặc log. Không có credential nào
được yêu cầu hoặc đọc trong đợt r47.

Dart-define đặt giá trị vào APK; biến môi trường, repository secret hay build
`--release` **không biến nó thành bí mật được bảo vệ trên client**. Đường phân phối
voice phải dùng token ngắn hạn/server mediation và được nghiệm thu riêng.

Các workflow cũ từng truyền Gemini key khi secret tồn tại. Sửa workflow không
thay đổi APK cũ hoặc tự xoay key; chủ tài khoản cần kiểm tra phạm vi phân phối và
thu hồi/xoay credential đã đưa vào bản chia sẻ nếu có. Chưa kết luận key đã lộ.
Xem [source/evidence/release policy](../PROJECT_STATUS.md).

## Các bước kiểm tra

1. Vào một bài học Main Quest, mở **AI Tutor** (nút trong bài hoặc trên bản đồ).
2. Trong thẻ voice, chọn **Kai** hoặc **Lumi**, chạm **Bắt đầu trò chuyện**.
3. Cấp quyền micro. Chờ câu chào: trợ lý phải **nói thành tiếng**, không chỉ hiện chữ.
4. Sau khi trợ lý nói xong, đặt một câu hỏi bằng lời (vi hoặc en).
   **Yêu cầu chấp nhận**: trợ lý phải nói tiếp câu trả lời — không chỉ câu chào.
5. Đặt thêm 2–3 câu liên tiếp. Mỗi câu đều phải có âm thanh.
6. Chat phải hiện **cả hai phía**, và mỗi dòng phải đứng **đúng tên người nói**:
   dòng của bé nằm bên phải, nhãn **Bé** (kèm icon micro vì câu nói được đọc thành
   lời); dòng của trợ lý nằm bên trái, có portrait + tên **Kai/Lumi**. Không được
   nhân đôi một câu thành hai bong bóng khi câu đang được đọc dở.
   **Lỗi cũ bắt buộc phải không còn:** câu chào của trợ lý hiện ra với nhãn của bé
   („Bé: Chào bạn") — câu chào là của trợ lý, và phải có đúng một dòng.
7. Nói đè khi trợ lý đang nói: trợ lý phải dừng và nghe lại (barge-in), và câu đã
   nói dở vẫn ở lại chat với nhãn **bị ngắt lời**. Với tai nghe thì barge-in hoạt
   động tốt hơn, vì loa ngoài có thể bị micro thu lại.
8. Nếu tiếng từ loa vọng vào micro, phiên bản này **bỏ** dòng đó (log
   `dropped … as playback echo`) thay vì ghi thành câu của bé. Đặt một câu ngắn
   **ngay sau** khi trợ lý im lặng: bé vẫn phải được nghe và hiện đúng tên.
9. Chạm **Dừng trò chuyện**: trợ lý nói nốt câu đang phát rồi mới tắt micro;
   transcript còn lại phải ở trạng thái đã chốt (không có dòng "đang nghe dở").

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
| `dropped a NB-word transcription as playback echo` | Tiếng loa vọng lại micro, **không** được ghi thành câu của bé |
| `server interrupted=true; queued audio dropped, assistant text kept` | Bé nói đè: bỏ âm thanh chưa phát, giữ câu đã nói và đánh dấu bị ngắt lời |
| `feeding without a confirmed playing state` | Máy không báo "đang phát"; pump vẫn đưa âm thanh đi thay vì im lặng |
| `session closing events=… audioBytes=… errors=… echoDropped=…` | Tóm tắt một phiên: bao nhiêu sự kiện, bao nhiêu byte audio, bao nhiêu lỗi |

`errors` / `echoDropped` là số đếm, không bao giờ là lời nói của bé; key bị che bằng
`GeminiLiveWire.redactSecrets`.

## Checklist

- [ ] `flutter analyze --no-fatal-infos` sạch, `flutter test` xanh.
- [ ] Quyền micro chỉ được hỏi khi bật voice.
- [ ] Câu chào **có âm thanh**.
- [ ] Mỗi câu hỏi tiếp theo **có âm thanh** (đây là lỗi đã sửa — bắt buộc kiểm tra).
- [ ] Chat hiển thị đủ cả hai phía, **đúng vai**: câu chào mang tên trợ lý chứ không
      phải tên bé, không trùng lặp, câu bị ngắt lời có nhãn "bị ngắt lời".
- [ ] Bé vẫn được nghe và được ghi đúng tên ngay sau khi trợ lý im lặng (echo không
      nuốt lời thật của bé).
- [ ] Không có âm thanh thì UI vẫn nói thật (trạng thái "chỉ trả lời bằng chữ"),
      không giả vờ là đã có tiếng.
- [ ] Micro từ chối / thiếu key / mất mạng / lỗi quota: Tutor vẫn dùng được, không crash.
- [ ] Xem hạn mức dùng trong Google AI Studio; không mặc định là miễn phí không giới hạn.

Không tuyên bố "chạy được trên máy" nếu chưa chạy hết checklist trên máy thật.
Các kiểm thử tự động (`app/test/tutor_voice_wire_test.dart`,
`tutor_voice_pump_test.dart`, `tutor_voice_session_test.dart`) chỉ chứng minh
giao thức và vòng đời phát nhạc, không chứng minh phiên Gemini thật.
