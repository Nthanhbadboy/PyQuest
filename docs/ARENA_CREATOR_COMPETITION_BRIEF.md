# PyQuest — Arena, Creator League và quy tắc trải nghiệm thi đấu
> Tài liệu bàn giao ý tưởng cho lần rà soát/viết lại tài liệu sản phẩm. Đây là phần bổ sung về gameplay, không thay thế Product Vision, Game Design, Technical Architecture, Roadmap hoặc Master Prompt gốc.

## 1. Mục tiêu cốt lõi

PyQuest không chỉ là ứng dụng dạy cú pháp Python hoặc tập hợp câu hỏi trắc nghiệm. Đây là game học lập trình qua phiêu lưu, sáng tạo, mô phỏng, thi đấu, sưu tầm thành tích và mở rộng thế giới.

Trẻ cần được:
- Học một khái niệm.
- Dùng nó để tạo ra thứ gì đó có thể hoạt động.
- Chạy thử, quan sát kết quả, sửa và nâng cấp.
- Mang sản phẩm/kỹ năng vào thử thách hoặc giải đấu.
- Nhận điểm, thứ hạng, danh hiệu và thành tích để có động lực quay lại.

Không được làm mất những vòng lặp gameplay này khi tinh gọn tài liệu hoặc ưu tiên kiến trúc kỹ thuật.

## 2. Arena là trung tâm nhiều bộ môn

Arena không phải chỉ là một trò chọn đáp án cú pháp. Đây là trung tâm gồm nhiều loại thử thách và giải đấu; mỗi bộ môn có cách chơi, điều kiện thắng và cách tính điểm phù hợp.

### 2.1. Đấu trường luyện tập
- Người chơi vượt thử thách với đối thủ do AI điều khiển.
- Đối thủ có tên nhân vật, ngoại hình và vai trò trong thế giới PyQuest.
- Mục đích là luyện tập, vượt cấp, hoàn thành điều kiện hoặc giành quyền tham gia giải.
- Giao diện hướng tới người chơi không dùng nhãn kỹ thuật gây hiểu nhầm; trình bày nhân vật như một đối thủ trong game.

### 2.2. Đấu trường thi đấu
- Dùng cho các cuộc thi có thứ hạng, điểm, giải theo mùa/tuần và danh hiệu.
- Khi là cuộc thi giữa người thật, phải hiển thị đúng trạng thái và danh tính/tên hiển thị của người thật; không giả mạo người chơi hoặc tuyên bố đang thi đấu toàn cầu nếu dữ liệu không chứng minh điều đó.
- Màn hình trận có thể hiển thị tên nhân vật/thí sinh, điểm realtime, thanh tiến độ, vị trí và trạng thái hơn-thua.
- Không cần đưa giải thích về công nghệ điều khiển đối thủ lên giao diện thi đấu.

### 2.3. Điểm và thanh tiến độ realtime
Mục đích chính của điểm/thanh tiến độ trực tiếp là giúp trẻ thấy diễn biến: mình đang dẫn, bị vượt hay sắp hoàn thành mục tiêu. Không biến việc này thành một bài toán phải chứng minh công bằng tuyệt đối.

- Mê cung/đua tốc độ: tiến độ dựa trên quãng đường, mục tiêu, vật phẩm hoặc checkpoint thực sự hoàn thành.
- Đấu thú/robot: có thể dùng máu, năng lượng, điểm kỹ năng hoặc mục tiêu đạt được.
- Thử thách theo lượt: điểm thay đổi sau hành động hoặc câu trả lời có kết quả.
- Giải sáng tạo được chấm: có thể hiển thị điểm tạm tính/tiến độ đánh giá; kết quả cuối cùng chỉ chốt sau khi mô phỏng và chấm xong.
- Không bắt mọi bộ môn dùng chung một công thức. Mỗi giải có luật chấm riêng, đủ rõ để người chơi hiểu cách thắng/thua.
- Không cần ép tất cả người chơi hoặc sản phẩm giống hệt nhau. Sự khác biệt trong sáng tạo là một phần của gameplay.

## 3. Creator Pro League — giải sáng tạo chuyên nghiệp

Đây là một nhánh quan trọng của Arena, không được rút gọn thành bài trắc nghiệm Python.

### Vòng lặp gameplay
1. **Vẽ và sáng tạo:** trẻ tự vẽ hoặc tùy chỉnh hình dáng, màu sắc, khuôn mặt, phụ kiện và ngoại hình.
2. **Lắp ghép:** kết hợp các bộ phận/module để tạo robot, con vật, phương tiện hoặc sinh vật của riêng mình.
3. **Lập trình:** dùng khối lệnh trực quan hoặc đoạn code phù hợp cấp độ để điều khiển sản phẩm.
4. **Chạy thử:** sản phẩm chạy trong mô phỏng; trẻ nhìn thấy code biến thành hành động thực tế.
5. **Sửa và nâng cấp:** thay đổi thiết kế, logic hoặc chiến thuật rồi thử lại.
6. **Nộp bài/thi đấu:** đưa sản phẩm vào thử thách theo chủ đề và luật cụ thể.
7. **Chấm điểm và vinh danh:** hệ thống đánh giá kết quả, xếp hạng, trao danh hiệu và cộng điểm vào bảng xếp hạng tuần/mùa.

### Ví dụ bộ môn
- **Maze Championship:** thiết kế nhân vật/robot và lập trình tìm đường, tránh bẫy, lấy vật phẩm, về đích.
- **Creator Pro League:** vẽ/lắp ghép robot hoặc sinh vật, lập trình hành vi để hoàn thành đề bài.
- **AI Pet Battle:** tạo thú cưng và lập trình quy tắc hành vi/chiến thuật để tham gia đấu trường.
- Có thể mở rộng thêm các bộ môn sáng tạo khác khi gameplay đã hỗ trợ.

### Chấm điểm
Không cần giả định có công bằng tuyệt đối giữa các tác phẩm khác nhau. Cần có luật và tiêu chí đủ rõ để người chơi biết mình được đánh giá dựa trên điều gì.

Có thể kết hợp:
- **Chỉ số khách quan từ mô phỏng:** hoàn thành nhiệm vụ hay không, thời gian, đường đi, số lỗi va chạm, vật phẩm thu thập, tài nguyên sử dụng, độ ổn định và các số liệu phù hợp với từng đề.
- **Đánh giá theo tiêu chí:** độ sáng tạo, thiết kế, cách giải quyết vấn đề, chất lượng logic/code và mức đáp ứng đề bài.
- AI có thể hỗ trợ đánh giá các tiêu chí sáng tạo/chất lượng; không nên thay thế những dữ kiện có thể đo trực tiếp bằng kết quả mô phỏng.
- Trọng số phụ thuộc bộ môn và có thể khác giữa các giải. Công bố tiêu chí và trọng số đủ để người chơi hiểu cách tính.
- Điểm realtime có thể là điểm tạm tính; điểm chính thức được chốt khi đánh giá hoàn tất.
- Không âm thầm thay đổi điểm để ép một kết quả thắng/thua cụ thể.

## 3A. Ba nhánh hoạt động trong Arena

Arena cần có ít nhất ba nhánh rõ ràng, không gộp mọi thứ thành một kiểu thi đấu:

### A. Đối kháng trực tiếp
- Người chơi điều khiển sản phẩm/nhân vật của mình thi trực tiếp với một đối thủ trong cùng trận hoặc cùng thử thách.
- Ví dụ: đua mê cung, đua vượt chướng ngại, đấu thú hoặc đấu robot chiến thuật.
- Điểm, thanh tiến độ, vị trí, máu/năng lượng hoặc mục tiêu hoàn thành cập nhật trong lúc chơi để người chơi nhìn thấy diễn biến hơn-thua.
- Kết quả trận quyết định thắng/thua, điểm giải, thứ hạng và phần thưởng tương ứng.
- Tùy khả năng sản phẩm, đối thủ có thể là nhân vật do hệ thống điều khiển trong chế độ luyện tập hoặc người chơi thật trong giải trực tuyến. Phải thể hiện trung thực loại trận; không giả mạo người thật.

### B. Tích lũy sản phẩm / bộ sưu tập sáng tạo
- Người chơi tạo nhiều sản phẩm theo thời gian: nhân vật, thú cưng, robot, phương tiện, bản thiết kế, chương trình điều khiển hoặc tác phẩm khác.
- Có thể vẽ, tùy chỉnh và lắp ghép bộ phận; lập trình sản phẩm; lưu phiên bản; thử nghiệm; nâng cấp; đặt tên; xem lịch sử và trưng bày bộ sưu tập.
- Sản phẩm không chỉ là skin hoặc đồ trang trí: khi phù hợp, chúng có logic/hành vi do code điều khiển và có thể được dùng trong các thử thách.
- Có mục tiêu tích lũy như hoàn thành bộ sưu tập, mở khóa bộ phận, đạt cấp sáng tạo, hoàn thành chủ đề hoặc sở hữu các tác phẩm có đặc tính khác nhau.
- Có thể tổ chức thử thách đánh giá từng tác phẩm hoặc cả bộ sưu tập. Điểm/danh hiệu gắn với tiêu chí của thử thách, không mặc định số lượng nhiều là chất lượng cao.
- Nhánh này vẫn có giá trị với trẻ không muốn đối kháng trực tiếp; không bắt buộc mọi tác phẩm phải tham gia thi đấu.

### C. Giải đồng đội
- Cho phép người chơi tham gia đội, cùng thực hiện mục tiêu và tích lũy thành tích tập thể.
- Các vai trò có thể bổ trợ nhau, ví dụ: người thiết kế, người lắp ghép, người viết logic/code, người thử nghiệm và người tối ưu chiến thuật. Không nhất thiết phải khóa vai trò cứng; cách chia việc tùy định dạng giải.
- Định dạng giải có thể gồm cùng nhau giải mê cung, phối hợp nhiều sản phẩm, xây dựng một tác phẩm chung, vượt chuỗi nhiệm vụ hoặc cộng điểm từ các thành viên trong một khoảng thời gian.
- Điểm đội có thể dựa trên kết quả nhiệm vụ, tiến độ chung, chất lượng sản phẩm hoặc tổng thành tích thành viên theo luật cụ thể. Nêu rõ thành tích cá nhân và thành tích đội để người chơi thấy đóng góp của mình.
- Hỗ trợ danh hiệu cá nhân lẫn danh hiệu tập thể: thành viên đội vô địch, đội sáng tạo xuất sắc, đội hoàn thành thử thách, danh hiệu theo mùa.
- Giải đồng đội có thể triển khai sau các chế độ đơn người, nhưng phải được giữ trong tầm nhìn sản phẩm; không được loại bỏ chỉ vì chưa thuộc phiên bản đầu.

## 4. Danh hiệu, điểm tuần và thành tích lâu dài

Arena phải tạo ra động lực theo nhiều cấp:
- Điểm của trận/thử thách.
- Thứ hạng trong từng bộ môn.
- Điểm đóng góp vào bảng xếp hạng tuần.
- Giải theo mùa và danh hiệu lưu trong hồ sơ.
- Danh hiệu hiếm gắn với thành tích thực sự hoặc thử thách đặc biệt.

Ví dụ tên danh hiệu (tên có thể được bản địa hóa): Maze Master, Master Creator, AI Beast Tamer, Weekly Champion, Legendary Inventor.

Không nhất thiết mọi danh hiệu dùng cùng điều kiện. Có thể trao danh hiệu vì tốc độ, sáng tạo, chiến thuật, hoàn thành bộ sưu tập hoặc thành tích theo mùa. Cần tránh để một loại điểm duy nhất khiến các bộ môn khác mất ý nghĩa.


### 4.1. Danh hiệu độc quyền, quan hệ với Tutor và nhiều bảng xếp hạng

PyQuest cần có hệ thống vinh danh nhiều tầng. Không ép mọi thành tích vào một bảng duy nhất, nhưng các thành tích đủ điều kiện vẫn có thể đóng góp vào điểm tổng sắp chung.

#### Danh hiệu độc quyền của Side Maps
- Một Side Map/Secret Isle có thể sở hữu bộ danh hiệu độc quyền gắn với thế giới, cốt truyện, kỹ năng và thử thách riêng của nơi đó.
- Mở khóa hoặc mua quyền truy cập map chỉ mở cơ hội tham gia; không tự động trao danh hiệu vốn đại diện cho thành tích. Người chơi phải đạt mốc, hoàn thành thử thách hoặc thỏa điều kiện được công bố.
- Danh hiệu độc quyền phải giữ được ý nghĩa riêng của map và được lưu trong hồ sơ/bộ sưu tập danh hiệu. Có thể ghi nhận rõ danh hiệu đến từ thế giới nào.
- Không được biến việc mua ngọc hoặc mua map thành cách mua thẳng thứ hạng thi đấu, điểm thành tích hay danh hiệu vốn phải kiếm bằng kỹ năng. Nếu có vật phẩm trả phí, phải phân biệt rõ vật phẩm sở hữu với thành tích đạt được.

#### Danh hiệu riêng do Tutor trao tặng
- Các Tutor là nhân vật trong thế giới, có thể xây dựng quan hệ với người chơi thông qua học tập, trò chuyện, giúp đỡ nhân vật, hoàn thành nhiệm vụ hoặc tiến bộ ở lĩnh vực họ hướng dẫn.
- Tutor có thể trao danh hiệu riêng khi người chơi đạt mốc quan hệ hoặc hoàn thành một nhiệm vụ/cột mốc đặc biệt. Danh hiệu có thể mang tên và câu chuyện riêng của Tutor, làm cho phần thưởng có cảm xúc và có tính sưu tầm.
- Không nhất thiết mọi Tutor đều dùng chung điều kiện. Điều kiện nên gắn với tính cách, lĩnh vực và câu chuyện của nhân vật; người chơi cần hiểu cách nhận danh hiệu.
- Quan hệ tốt với Tutor phải được xây dựng bằng tương tác và thành tích trong game, không phải mua hàng hoặc trả tiền để được nhân vật yêu quý.

#### Nhiều bảng xếp hạng, một hồ sơ thành tích
- **Bảng tuần:** thành tích trong tuần hiện tại, làm mới theo lịch được công bố.
- **Bảng tháng:** thành tích trong tháng, có phần thưởng/danh hiệu tháng nếu áp dụng.
- **Bảng thi đấu:** kết quả theo trận, bộ môn, giải hoặc mùa thi đấu.
- **Bảng hoạt động:** các nhóm hoạt động như khám phá, hoàn thành nhiệm vụ, sáng tạo, sưu tầm hoặc đóng góp đồng đội.
- **Bảng chuyên môn:** xếp hạng riêng theo từng bộ môn để người giỏi sáng tạo không bị đánh giá chỉ bằng thành tích đua tốc độ, và ngược lại.
- **Bảng đội:** thành tích tập thể, đóng góp đội và danh hiệu đội theo giải/mùa.
- **Tổng sắp chung:** quy đổi điểm đóng góp từ các nhánh theo quy tắc đã công bố, tạo một góc nhìn tổng thể nhưng không thay thế các bảng chuyên biệt.

#### Quy tắc quy đổi điểm
- Mỗi loại hoạt động có thể có điểm gốc, hệ số hoặc giới hạn đóng góp riêng; công thức cần được công bố đủ rõ và tránh để một hoạt động lặp vô hạn thống trị mọi bảng.
- Danh hiệu có thể đóng góp điểm tổng sắp khi có quy tắc rõ ràng, nhưng sở hữu danh hiệu không tự động đồng nghĩa với điểm vô hạn hoặc vị trí cố định.
- Điểm tuần/tháng phải tách kỳ và quy tắc reset khỏi điểm thành tích lâu dài trong hồ sơ. Danh hiệu vĩnh viễn đã kiếm được không bị xóa chỉ vì kỳ xếp hạng kết thúc.
- Bảng xếp hạng người thật chỉ hiển thị dữ liệu thi đấu thật. Bảng luyện tập với nhân vật hư cấu phải được trình bày đúng bản chất, không giả làm bảng xếp hạng người thật.
- Vì PyQuest hướng tới trẻ em, cần tránh thiết kế bảng xếp hạng gây áp lực quá mức; có thể cung cấp bảng bạn bè/đội hoặc mục tiêu cá nhân bên cạnh bảng cạnh tranh rộng hơn.

## 5. Ngôn ngữ sản phẩm — quy tắc bắt buộc

**Cấm dùng từ “bot” trong toàn bộ nội dung sản phẩm và giao diện người chơi.** Tránh từ này trong nhãn, tên chế độ, lời thoại, thông báo, tutorial, tooltip, tên đối thủ, bảng xếp hạng và nội dung bản địa hóa.

Cách thể hiện phù hợp:
- Chế độ luyện tập: gọi là “Đối thủ”, đặt tên nhân vật phù hợp thế giới PyQuest.
- Chế độ thi đấu: hiển thị tên người chơi/thí sinh, nhân vật, điểm, tiến độ và thứ hạng.
- Giải sáng tạo: hiển thị tên tác giả, tác phẩm, điểm đánh giá và danh hiệu.
- AI là công nghệ phía sau; giao diện không cần phơi bày thuật ngữ kỹ thuật.
- Không giả mạo đối thủ do AI điều khiển thành người thật. Tên nhân vật và bối cảnh có thể mang tính hư cấu trong chế độ luyện tập, nhưng không được tuyên bố đó là người thật hoặc thành tích toàn cầu thật.

## 6. Kết nối với vòng lặp học tập và thế giới PyQuest

- Main Quest vẫn là tuyến học cốt lõi miễn phí.
- Mini-game không chỉ để giải trí hoặc nhận thưởng; phải cho trẻ áp dụng kiến thức đã học.
- Khối lệnh trực quan phù hợp với người mới; có thể mở dần sang Python thật khi phù hợp.
- Không yêu cầu xây dựng trình chạy Python đầy đủ ngay từ phiên bản đầu để giữ ý tưởng sáng tạo. Có thể bắt đầu bằng tập lệnh/khối lệnh giới hạn và mô phỏng an toàn, nhưng không được vì vậy mà xóa bỏ tầm nhìn mở rộng.
- Side Maps / Secret Isles có thể mở rộng nội dung, bộ môn, chủ đề, vật phẩm, danh hiệu và trải nghiệm nâng cao theo mô hình thương mại đã mô tả trong tài liệu sản phẩm.
- Thành tích từ Arena liên kết với hồ sơ, bộ sưu tập danh hiệu và bảng xếp hạng tuần/mùa.


### 6.1. Các nhánh độc lập; dependency chung được giới hạn rõ ràng

Đây là nguyên tắc kiến trúc sản phẩm bắt buộc:

- **Mỗi nhánh là một hoạt động độc lập.** Đối kháng trực tiếp, tích lũy/bộ sưu tập sản phẩm, giải sáng tạo chuyên nghiệp và giải đồng đội có tiến trình, luật chơi, điều kiện tham gia, cách chấm điểm và phần thưởng riêng. Người chơi không phải hoàn thành một nhánh để được chơi nhánh khác, trừ điều kiện kiến thức/mở khóa đã quy định.
- **Dependency về kiến thức đi từ Main Quest đến các nhánh hoạt động.** Người chơi phải vượt qua một số map Main Quest tương ứng để học đủ kiến thức trước khi mở khóa hoặc đủ điều kiện tham gia từng bộ môn. Mỗi bộ môn chỉ yêu cầu các map/kiến thức thật sự cần cho gameplay của nó; không khóa tất cả hoạt động sau khi hoàn thành toàn bộ Main Quest.
- **Điểm tổng sắp và danh hiệu là lớp liên kết chung.** Thành tích của từng nhánh được quy đổi theo quy tắc của nhánh đó thành điểm đóng góp và/hoặc danh hiệu; hệ thống tổng hợp chúng vào hồ sơ và bảng tổng sắp tuần/mùa. Đây là cầu nối chung giữa các nhánh, không phải lý do để buộc tiến trình chơi của chúng phụ thuộc lẫn nhau.
- Không yêu cầu người chơi phải sở hữu sản phẩm mới được đấu đối kháng nếu chế độ đó có phương án tham gia riêng; không bắt người thích sưu tầm phải thi đấu; không bắt thành viên muốn thi đồng đội phải hoàn thành Creator Pro League trước, trừ khi giải cụ thể yêu cầu kiến thức hoặc sản phẩm tương ứng.
- Giữ dữ liệu, tiến trình, luật và vòng lặp của từng nhánh tách biệt ở mức thiết kế. Chỉ chia sẻ những dịch vụ nền thật sự cần thiết như hồ sơ, mở khóa kiến thức, điểm tổng sắp và danh hiệu; tránh tạo dependency chéo không cần thiết.
- Khi thiết kế roadmap, có thể triển khai các nhánh ở thời điểm khác nhau nhưng phải giữ chúng trong tầm nhìn sản phẩm. “Chưa triển khai” không đồng nghĩa với “phụ thuộc vào nhánh khác” hoặc “bị loại bỏ”.


### 6.2. Ba quy tắc sản phẩm cốt lõi: điểm, mở khóa kiến thức và lượt mini-game

#### Dependency 1 — Mọi thành tích quy về điểm tổng sắp
- Các nhánh vẫn độc lập về gameplay, nhưng thành tích của chúng có thể quy đổi theo quy tắc tương ứng thành điểm đóng góp cho hệ thống tổng sắp chung.
- Bảng tuần, tháng, thi đấu, hoạt động, chuyên môn và đồng đội là các bảng/góc xếp hạng khác nhau; không phải các hệ thống điểm hoàn toàn tách rời. Cần quy định rõ loại điểm và kỳ tính của từng bảng.
- Danh hiệu vẫn giữ ý nghĩa sưu tầm và thể hiện thành tích; những danh hiệu được quy định có điểm thưởng có thể đóng góp vào tổng sắp. Không mặc định mọi danh hiệu đều cho điểm như nhau.
- Không để một nhánh có thể cày lặp vô hạn rồi chiếm toàn bộ bảng tổng sắp. Điểm, hệ số và giới hạn đóng góp cần phù hợp với từng loại hoạt động.

#### Dependency 2 — Main Quest mở khóa hoạt động theo kiến thức đã học
- Mỗi hoạt động xác định trước những kiến thức cần thiết, sau đó ánh xạ đến các map Main Quest dạy và kiểm tra các kiến thức đó.
- Người chơi phải hoàn thành đủ những map tương ứng mới được mở khóa hoạt động. Khi chưa đủ điều kiện, giao diện phải nói rõ còn thiếu map nào hoặc cần học năng lực gì, đồng thời cho phép đi thẳng đến map liên quan.
- Không bắt người chơi hoàn thành toàn bộ Main Quest để mở mọi thứ. Điều kiện chỉ cần bao phủ kiến thức thực sự cần cho hoạt động cụ thể.
- Ngọc, mua Side Map hoặc quảng cáo không thay thế điều kiện kiến thức của hoạt động yêu cầu kỹ năng đó.

#### Mini-game giải trí — điểm có giới hạn lượt và quảng cáo có giới hạn
- Mini-game giải trí là hoạt động ngắn để thư giãn giữa các chặng học; vẫn có thể thưởng điểm và thành tích phù hợp.
- Mỗi mini-game có số lượt chơi miễn phí trong một khoảng thời gian xác định. Khi hết lượt miễn phí, người chơi có thể dừng lại hoặc tự nguyện xem quảng cáo để nhận thêm lượt.
- Số lượt xem quảng cáo để nhận lượt chơi thêm cũng phải có giới hạn rõ ràng; hết giới hạn thì không tiếp tục cấp lượt qua quảng cáo trong kỳ đó.
- Quảng cáo vừa là nguồn doanh thu vừa tạo khoảng nghỉ ngắn, không được lặp liên tục, chặn Main Quest, buộc trẻ xem để tiếp tục học hoặc gây áp lực phải xem.
- Không dùng quảng cáo để bán điểm, danh hiệu, thứ hạng hoặc thay thế kỹ năng. Điểm từ mini-game phải có mức trần/hạn mức phù hợp để không thể cày lặp rồi thống trị bảng tổng sắp.
- Với sản phẩm hướng tới trẻ em, cách triển khai quảng cáo, nội dung quảng cáo, sự đồng ý của phụ huynh và giới hạn tần suất phải được rà soát theo chính sách nền tảng và quy định áp dụng trước khi phát hành. Không giả định mọi định dạng quảng cáo thưởng đều được phép ở mọi thị trường.

## 7. Hướng triển khai theo giai đoạn (không phải lý do loại bỏ tầm nhìn)

- **Giai đoạn đầu:** module lắp ghép có sẵn, tùy chỉnh ngoại hình, khối lệnh giới hạn, mô phỏng đơn giản, điểm và kết quả xác định được.
- **Giai đoạn tiếp theo:** thêm bộ phận/khả năng, điều kiện/vòng lặp phức tạp hơn, nhiều đề thi, lưu tác phẩm và nâng cấp.
- **Giai đoạn nâng cao:** giải theo mùa, bài thi sáng tạo phong phú, đánh giá AI có kiểm soát, chia sẻ tác phẩm và thi đấu trực tuyến khi sản phẩm sẵn sàng.

Đây là cách chia phạm vi triển khai, không phải quyết định bỏ các tính năng khỏi tầm nhìn sản phẩm.

## 8. Chỉ dẫn bắt buộc cho OpenCode khi rà soát/viết lại tài liệu

1. Đọc tài liệu sản phẩm hiện tại và các nguồn ý tưởng gốc được cung cấp, bao gồm Master Prompt và README lịch sử liên quan.
2. Trước khi sửa, lập bảng đối chiếu từng tính năng theo trạng thái: **PRESERVED / WEAKENED / MISSING / CONFLICTING / DEFERRED**. Nêu rõ tính năng nằm ở tài liệu nào/mục nào.
3. Đặc biệt kiểm tra Arena nhiều bộ môn và đủ ba nhánh: đối kháng trực tiếp, tích lũy sản phẩm/bộ sưu tập sáng tạo, giải đồng đội; Creator Pro League; vẽ/lắp ghép; code điều khiển sản phẩm; mô phỏng; điểm/tiến độ realtime; chấm điểm; danh hiệu; điểm tuần/mùa; Main Quest miễn phí; Side Maps/Secret Isles và các mini-game đã có.
4. Không được chỉ chăm chăm vào kiến trúc, giao dịch dữ liệu, kiểm thử hoặc chi tiết kỹ thuật rồi bỏ qua gameplay tạo nên bản sắc sản phẩm.
5. Không tự ý xóa, giản lược hoặc đánh dấu “out of scope” cho ý tưởng sản phẩm đã có nguồn. Nếu có xung đột, ghi rõ và đề xuất lựa chọn; không tự quyết định loại bỏ.
6. Phân biệt **tầm nhìn sản phẩm**, **thiết kế gameplay**, **kiến trúc kỹ thuật** và **thứ tự roadmap**. Một tính năng được triển khai sau không có nghĩa là không tồn tại trong tầm nhìn.
7. Giữ lại các tính năng hiện hữu khác khi viết lại; tài liệu này chỉ bổ sung/định nghĩa rõ Arena và giải sáng tạo, không phải danh sách đầy đủ toàn bộ PyQuest.
8. Chỉ viết lại tài liệu sau khi hoàn thành bảng đối chiếu. Không sửa code ứng dụng trong nhiệm vụ rà soát tài liệu nếu chưa được yêu cầu.
9. Không tuyên bố đã bảo toàn toàn bộ ý tưởng nếu chưa đối chiếu với nguồn gốc. Nêu rõ những điểm chưa xác định để người dùng quyết định.
