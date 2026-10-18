# OpenCode — chỉ chuyển thông điệp qua browser sau mỗi lượt

Cập nhật2026-10-17 theo chỉ đạo trực tiếp của người dùng. Bản này **thay thế** thiết
kế watcher/router GitHub ở commit e4c2895. Không cài runner, không đổi CI ở đây.

## Vai trò

- **DESIGN / Lead**: thiết kế, quản lý phát triển toàn app, chia/ưu tiên task, giao
  CODE, review evidence, yêu cầu sửa, nghiệm thu và quyết định task tiếp theo.
- **CODE**: triển khai đúng task/allowlist của Lead, kiểm thử, publish code/evidence,
  báo khó khăn và trả bàn giao. Không tự coi CI xanh là nghiệm thu.
- **OpenCode bên ngoài**: chờ lượt chat kết thúc, lấy block chuyển tin cuối cùng,
  gửi **nguyên thông điệp** vào đúng khung chat browser. Không sửa repo, không đọc
  và suy luận GitHub thay hai agent, không chọn task, không review hay cấp quyền.
- **Người dùng**: theo dõi, có thể can thiệp riêng; không phải người chọn task/phê
  duyệt thường xuyên. Lead tiếp tục trong mục tiêu được giao đến khi app sẵn sàng
  cho người dùng dùng thử/đánh giá. Không tự nhận app hoàn tất khi thiếu evidence.

Design branch: `arena/00838eb9-pyquest`.
Code branch hiện tại: `arena/4253d4f1-pyquest`.
`arena/0d4fcb38-pyquest` là nhánh CODE trước, không phải đích push/fast-forward
của phiên mới. Work order hiện hành: [PQC-020 revision2](specs/PQC-020-R2.md).
Nhánh `arena/b813b575-pyquest` là lịch sử. Người vận hành gắn DESIGN/CODE với đúng
khung chat; OpenCode không suy session ID từ tên nhánh. Chưa kiểm thử browser relay
bên ngoài từ phiên này; tài liệu không phải xác nhận đã gửi tin thành công.

## Hợp đồng cuối lượt — một block, một người nhận

Hai agent kết thúc mỗi lượt cần chuyển tiếp bằng đúng một block:

```text
[CHUYEN_TIN]
MA_TIN: <ID duy nhất, giữ nguyên nếu gửi lại>
NGUOI_NHAN: DESIGN hoặc CODE
THONG_DIEP:
<Nội dung đầy đủ để người nhận làm bước kế tiếp: task, SHA đã push nếu có,
file bàn giao, việc cần thực hiện, phần đã làm/chưa xác minh.>
[/CHUYEN_TIN]
```

OpenCode chỉ chuyển nguyên phần THONG_DIEP kèm MA_TIN, không chuyển các commentary
trung gian, không diễn giải lại, không thêm yêu cầu do mình nghĩ ra. Chỉ dispatch sau
khi lượt nguồn kết thúc và lượt đích không còn chạy. Không bắt buộc hai agent luân
phiên: NGUOI_NHAN có thể là chính agent vừa hoàn thành lượt.

Giữ MA_TIN đã gửi để tránh trùng; chưa rõ gửi thành công thì kiểm tra chat trước
khi gửi lại. Agent nhận MA_TIN đã xử lý phải nói rõ và trỏ kết quả, không làm lại.
Nếu người dùng ngắt lượt/chỉ đạo mới, ưu tiên chỉ đạo đó, không đẩy tiếp block cũ.
Nếu thiếu block, không tự đoán task/người nhận; nhắc ngay phiên nguồn bổ sung block
một lần. Nếu browser mất phiên hoặc không gửi được, báo lỗi vận chuyển, không giả
đã đánh thức. Không tự tạo commit ACK hoặc framework điều phối trong repo.

## Vòng phát triển đến khi hoàn thành app

1. Lead thiết kế/giao task rõ scope và acceptance → chuyển CODE.
2. CODE triển khai/test/publish → chuyển DESIGN với exact SHA/evidence.
3. Lead tự fetch/đọc source/CI, review:
   - Cần sửa: publish findings cụ thể → chuyển CODE.
   - Đạt: publish ACCEPTED → chủ động chuẩn bị/giao task kế tiếp.
4. Nếu Lead chưa kịp thiết kế task kế tiếp trong lượt nghiệm thu, chuyển **DESIGN**
   với thông điệp tiếp tục quản lý/thiết kế. Không đợi commit mới để tự thức dậy.
5. Nếu CODE bị chặn bởi thiết kế hoặc phạm vi, chuyển DESIGN để Lead quyết định;
   không mặc định bắt người dùng chọn cách sửa hoặc duyệt từng task.
6. Xong một task không phải xong app. Lead quản lý dependency và kế hoạch dài hạn,
   tiếp tục các màn chính/phụ, Tutor có bảng, mini-games, progression và tương tác
   xã hội theo tầm nhìn. Không tự thu nhỏ app thành chỉ board/localization.

GitHub/CI đều do hai agent kiểm tra khi đến lượt. Nếu phải chờ CI, agent chịu trách
nhiệm dùng công cụ chờ phù hợp trong lượt; nếu cần kết thúc lượt, tự ghi thông điệp
cho chính mình với exact SHA/run và bước tiếp theo. OpenCode không cần watcher CI,
không tự đoán kết quả hay điều phối theo check_run. Agent tránh chuỗi lượt chỉ poll:
ưu tiên hoàn thành việc hữu ích còn lại và bounded wait; không tạo commit chờ/ACK.

## Quyền quyết định và điều kiện kết thúc

Lead được chủ động chuẩn bị/mở work order tiếp theo trong mục tiêu đã giao; không
xin người dùng chọn roadmap mỗi vòng. CODE vẫn chỉ triển khai task đã được Lead
publish với allowlist cụ thể, không lấy quyền Lead làm quyền sửa toàn repo tùy ý.
Hai agent không vượt giới hạn môi trường/bảo mật, không bịa credentials, không
triển khai dịch vụ trả phí/public hoặc tuyên bố kiểm thử thiết bị khi chưa thực hiện.
Nếu thiếu điều kiện ngoài khả năng agent, Lead ghi giới hạn thật và tiếp tục phần
khả thi thay vì fake success. Người dùng có thể can thiệp bất kỳ lúc nào.

Chỉ khi Lead đã rà soát toàn bộ phạm vi bàn giao, bằng chứng tích hợp, các luồng
người dùng và giới hạn còn lại mới thông báo app sẵn sàng dùng thử/đánh giá. Không
đánh dấu hoàn tất chỉ vì task cuối xanh. Khi thực sự không còn bước tự làm được,
Lead ghi rõ lý do dừng; OpenCode không tự invent một việc mới để kéo dài vòng chat.

## Kiểm tra vận chuyển (do người vận hành xác nhận)

- Chỉ một tin sau final, không gửi commentary hoặc gửi giữa lượt đích đang chạy.
- Giữ nguyên SHA/path/nội dung, gửi đúng DESIGN hoặc CODE.
- Chuyển được từ DESIGN về DESIGN khi Lead cần tiếp tục thiết kế.
- Retry/reload browser không làm gửi trùng một MA_TIN.
- Lượt bị người dùng ngắt không phát block cũ như một lượt đã hoàn thành.

Không giao OpenCode quyền sửa/chọn task bằng cách làm các phép kiểm tra này.
