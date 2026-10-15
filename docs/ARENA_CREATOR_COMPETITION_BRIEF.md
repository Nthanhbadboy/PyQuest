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

### 6.3. Năng lượng, quảng cáo theo từng hạng mục và quyền lợi nhỏ khi mua Side Map

#### Năng lượng là cơ chế giữ nhịp chơi và nhắc trẻ nghỉ
- PyQuest dùng hệ thống năng lượng để điều tiết thời lượng chơi; mục tiêu là giúp trẻ có nhịp học, chơi và nghỉ hợp lý, không khuyến khích chơi liên tục không giới hạn.
- Các hoạt động tiêu hao năng lượng theo mức được thiết kế phù hợp với độ dài và cường độ của hoạt động. Không mặc định mọi hành động đều tốn cùng một lượng.
- Năng lượng hồi lại theo thời gian. Khi năng lượng thấp hoặc hết, giao diện giải thích rõ và gợi ý nghỉ/ngừng chơi, quay lại sau; không dùng thông báo gây áp lực hoặc khiến trẻ sợ mất thành tích.
- Không để năng lượng làm mất tiến độ đang diễn ra: trẻ phải có thể kết thúc/lưu trạng thái ở điểm dừng hợp lý. Không cắt ngang một màn Main Quest hoặc làm mất tác phẩm chỉ vì hết năng lượng giữa chừng.
- Quảng cáo không được dùng để vô hiệu hóa hoàn toàn mục tiêu nghỉ ngơi. Nếu có lượt chơi thêm qua quảng cáo thì vẫn phải tuân thủ giới hạn và thiết kế nhịp nghỉ chung.

#### Quảng cáo có quy tắc và hạn mức riêng ở từng hạng mục
- Các hạng mục của PyQuest có thể tích hợp quảng cáo theo chính sách sản phẩm, nhưng mỗi hạng mục phải có hạn mức riêng, dễ hiểu: lượt miễn phí, số lượt có thể nhận thêm qua quảng cáo, khoảng thời gian áp dụng và thời điểm làm mới hạn mức.
- Quy tắc này áp dụng theo từng hạng mục, chẳng hạn Main Quest, Arena/thi đấu, sáng tạo, sưu tập, Side Maps và mini-game. Không mặc định tất cả phải có cùng số lượt hoặc cùng cách hiển thị quảng cáo; phải xác định hạn mức phù hợp với vai trò của từng hạng mục.
- Muốn chơi thêm sau khi dùng hết lượt miễn phí, người chơi có thể tự nguyện xem quảng cáo nếu hạng mục đó còn lượt thưởng quảng cáo; nếu hết hạn mức thì dừng và chờ lượt/năng lượng hồi lại hoặc quay sang hoạt động phù hợp khác.
- Quảng cáo phải xuất hiện ở điểm dừng tự nhiên, không ép xem giữa màn chơi, không chặn việc học kiến thức cốt lõi của Main Quest và không bắt trẻ xem quảng cáo để bảo vệ tiến độ đã đạt được.
- Năng lượng và lượt quảng cáo là hai giới hạn có liên quan nhưng không đồng nhất: xem quảng cáo không mặc nhiên xóa bỏ mọi giới hạn năng lượng hoặc cấp quyền chơi vô hạn. Luật kết hợp giữa chúng phải được công bố rõ.
- Không biến quảng cáo thành cách mua điểm, danh hiệu, thứ hạng hoặc bỏ qua điều kiện kiến thức. Điểm kiếm từ hoạt động có giới hạn phải được tính vào bảng xếp hạng theo quy tắc chống cày lặp đã nêu ở mục 6.2.

#### Mua Side Map chỉ cộng thêm một ít quyền chơi
- Khi người chơi mua/mở khóa một Side Map bằng tiền, có thể tặng kèm một lượng nhỏ năng lượng bổ sung hoặc một ít lượt chơi thêm như quyền lợi phụ.
- Phần cộng thêm phải có giới hạn rõ ràng, nhỏ và cân bằng; không được tạo năng lượng vô hạn, cho phép xem quảng cáo không giới hạn, hoặc biến người mua thành người có lợi thế xếp hạng không tương xứng.
- Quyền lợi phụ này không thay thế điều kiện kiến thức của hoạt động, không tự động trao danh hiệu thành tích và không mua trực tiếp điểm/thứ hạng.
- Mua map mở ra thế giới/nội dung mới là giá trị chính. Năng lượng hoặc lượt chơi cộng thêm chỉ là phần thưởng phụ, không được biến thành lý do duy nhất để mua.
- Cần tách bạch quyền lợi đi kèm giao dịch với năng lượng hồi tự nhiên, lượt miễn phí theo kỳ và lượt thưởng quảng cáo; hiển thị trước giao dịch để phụ huynh/trẻ hiểu rõ điều gì được nhận và giới hạn của nó.

#### Nguyên tắc an toàn với trẻ em
- Không dùng thông báo khẩn cấp giả, chuỗi ép xem quảng cáo, đồng hồ đếm ngược gây áp lực hoặc cơ chế khiến trẻ cảm thấy phải tiếp tục chơi để không mất thứ đã đạt được.
- Trước khi phát hành, phải rà soát cách triển khai quảng cáo, nội dung quảng cáo, sự đồng ý của phụ huynh, tần suất, mua hàng trong ứng dụng và quy định theo thị trường/nền tảng. Không giả định mọi định dạng quảng cáo thưởng đều phù hợp với mọi nhóm tuổi hoặc được phép ở mọi nơi.

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


## 9. Thế giới làng PyQuest — mỗi ngôi nhà là một tính năng độc lập

### 9.1. Nguyên tắc thế giới sống
- Màn hình chính nên là một ngôi làng/thế giới có thể khám phá, không chỉ là menu chứa các nút chức năng.
- Các ngôi nhà, công trình và cổng ma thuật là điểm vào những hệ thống gameplay khác nhau. Ví dụ: Thư viện Python/Tutor, tòa nhà Main Quest, Đấu trường, Xưởng sáng tạo, Bảo tàng/Bộ sưu tập và cổng tới Side Maps/Secret Isles.
- Tutor là các nhân vật có tính cách, lĩnh vực và vai trò riêng. Họ có thể đi lại trong làng, tương tác với người chơi, xuất hiện tại sự kiện hoặc trao danh hiệu. Chạm vào nhân vật có thể mở trò chuyện (và voice chat nếu sản phẩm hỗ trợ); chạm vào ngôi nhà mở tính năng tương ứng.
- Đây là tầm nhìn thế giới có thể mở rộng; không yêu cầu mọi nhân vật, hoạt ảnh hoặc công trình phải có ngay trong phiên bản đầu.

### 9.2. Mỗi ngôi nhà là một module sản phẩm
- Mỗi nhà đại diện cho một khả năng/tính năng được thiết kế riêng, có vòng lặp chơi, giao diện, luật, tiến trình, phần thưởng và nội dung mở rộng của chính nó.
- Ví dụ: Thư viện tập trung vào học và luyện Python; Arena tập trung vào thi đấu; Xưởng sáng tạo tập trung vào vẽ/lắp ghép/lập trình sản phẩm; Bảo tàng tập trung vào trưng bày và sưu tập; Nhà bạn bè tập trung vào giao lưu; cổng thế giới dẫn tới các Side Maps.
- Có thể bổ sung một ngôi nhà/tính năng mới mà không cần viết lại hoặc buộc mọi nhà hiện có phụ thuộc vào nó. Tính năng chưa triển khai vẫn thuộc tầm nhìn sản phẩm, không tự động bị coi là đã loại bỏ.
- Các nhà độc lập về gameplay nhưng dùng chung lớp dịch vụ nền cần thiết: hồ sơ người chơi, điểm, danh hiệu, bạn bè/quyền riêng tư và các quy tắc mở khóa kiến thức có liên quan.
- Không buộc người chơi phải đi qua mọi nhà. Người thích sáng tạo có thể tập trung sáng tạo; người thích thi đấu, khám phá, sưu tập hoặc giao lưu có thể theo đuổi nhánh mình yêu thích.

### 9.3. Điểm và danh hiệu là cầu nối thành tích chung
- Điểm và danh hiệu là lớp liên kết chung giữa các nhà, không phải dependency khiến cách chơi của nhà này phải phụ thuộc tiến trình nhà khác.
- Danh hiệu là một dạng thành tích có thể có giá trị điểm theo quy tắc được công bố. Không mặc định mọi danh hiệu đều cho cùng số điểm; điểm không bắt buộc đổi ngược thành danh hiệu.
- Cần phân biệt rõ: điểm phản ánh đóng góp theo công thức; danh hiệu ghi nhận thành tích/đặc trưng; vật phẩm/quà tặng thể hiện sở hữu hoặc quan hệ xã hội. Không đánh đồng ba loại này.
- Danh hiệu thành tích phải kiếm được bằng điều kiện tương ứng. Danh hiệu mang tính xã hội được tặng có thể hiển thị riêng, không giả làm chứng nhận người nhận đã hoàn thành thử thách mà họ chưa đạt.
- Mọi điểm cộng vào tổng sắp cần có luật chống cày lặp, giới hạn/hệ số phù hợp và không để một hoạt động duy nhất lấn át mọi chuyên môn.

## 10. Vòng lặp dài hạn — dễ bắt đầu, luôn có điều tiếp theo để khám phá

PyQuest học hỏi nguyên tắc sản phẩm từ các ứng dụng học tập có sức bền dài hạn: bắt đầu đơn giản, tạo mục tiêu ngắn dễ hiểu và mở ra con đường tiến bộ dài. Không sao chép máy móc cơ chế của sản phẩm khác; thiết kế vòng lặp phù hợp với game thế giới mở và trẻ em.

- **Mục tiêu ngắn:** mỗi lần vào game có thể làm một việc nhỏ, như hoàn thành một đoạn map, thử một ý tưởng, chăm/thu thập vật phẩm hoặc giúp đội.
- **Con đường dài:** Main Quest mở dần kiến thức; các nhà khác mở thêm thử thách, bộ sưu tập, sản phẩm, danh hiệu và thế giới mới.
- **Quay lại kiến thức trong ngữ cảnh mới:** khái niệm đã học có thể được áp dụng khi lập trình robot, giải mê cung, tạo trò chơi hoặc tham gia thử thách khác.
- **Nội dung định kỳ:** nhiệm vụ tuần/tháng, sự kiện theo mùa, thử thách cộng đồng và chủ đề sáng tạo mới có thể đem lại mục tiêu tiếp theo.
- **Phần thưởng nhiều tầng:** tiến bộ cá nhân, điểm theo kỳ, danh hiệu lâu dài, sản phẩm để trưng bày, kỷ niệm với bạn bè và thành tích đội.
- **Tôn trọng nghỉ ngơi:** năng lượng, lượt chơi và quảng cáo phải minh bạch, có giới hạn, không dùng nỗi sợ mất chuỗi hoặc phần thưởng để ép trẻ online liên tục.
- Không cần hàng nghìn tính năng ngay từ ngày đầu. Cần một vòng chơi cốt lõi đủ hấp dẫn, sau đó có thể bổ sung nhà, nội dung và hoạt động mà không phá vỡ trải nghiệm đơn giản cho người mới.

Nguyên tắc diễn đạt sản phẩm: **“Dễ bắt đầu như một hành trình học ngắn; càng đi sâu càng có nhiều thứ để sáng tạo, khám phá và chinh phục.”**

## 11. Nhà bạn bè và hệ thống cộng đồng

### 11.1. Kết bạn và khám phá thành tích
- Người chơi có thể gửi/nhận lời mời kết bạn, xem hồ sơ được chia sẻ, danh hiệu, tác phẩm trưng bày và bộ sưu tập mà chủ hồ sơ cho phép người khác xem.
- Có thể thăm không gian/trang trưng bày của bạn bè, xem sản phẩm sáng tạo, để lại phản hồi được kiểm soát như lời khen hoặc biểu tượng cảm xúc.
- Kết bạn là tùy chọn. Không được bắt buộc phải có bạn hoặc tham gia cộng đồng để hoàn thành Main Quest hay tiếp cận kiến thức cốt lõi.
- Quyền riêng tư cần cho phép người chơi/phụ huynh kiểm soát ai có thể tìm, kết bạn, xem tác phẩm, gửi quà hoặc tương tác.

### 11.2. Đội nhóm và hoạt động xã hội
- Người chơi có thể lập/tham gia đội để cùng giải mê cung, xây dựng sản phẩm, hoàn thành nhiệm vụ, dự thi và tích lũy thành tích chung.
- Hiển thị đóng góp cá nhân và kết quả đội theo luật rõ ràng; có thể có danh hiệu cá nhân lẫn danh hiệu tập thể.
- Tạo lý do tương tác thực chất: thử thách sản phẩm của bạn, giải mê cung do bạn tạo, cùng hoàn thành dự án, tham gia sự kiện cuối tuần hoặc xem triển lãm cộng đồng.
- Tác phẩm do người chơi tạo có thể trở thành nội dung cho người chơi khác khám phá, trong phạm vi quyền riêng tư, kiểm duyệt và an toàn cho trẻ em.

### 11.3. Quà tặng mua được và danh hiệu xã hội
- Người chơi có thể tự nguyện mua quà trong cửa hàng bằng loại tiền tệ được quy định rồi gửi tặng bạn: hoa, hộp quà, thú cưng mini, pháo hoa, phụ kiện, vật phẩm trang trí hoặc quà theo dịp.
- Có thể tặng danh hiệu xã hội độc đáo, khung hồ sơ, hiệu ứng, thiệp hoặc vật phẩm kỷ niệm. Ví dụ chủ đề: bạn đồng hành, ngôi sao của làng, người truyền cảm hứng, bạn sáng tạo tuyệt vời. Tên và cách thể hiện chỉ là ví dụ, cần được thiết kế sau.
- Quà theo dịp có thể gắn với sinh nhật, ngày kết bạn, chiến thắng, hoàn thành dự án chung hoặc sự kiện theo mùa. Không dùng thông báo giả hoặc đồng hồ đếm ngược gây áp lực mua.
- Quà/danh hiệu xã hội phải phân biệt trực quan với danh hiệu chứng minh kỹ năng hoặc thành tích thi đấu. Mua quà không mua được thứ hạng, điểm thi đấu hay chứng nhận kỹ năng.
- Người nhận có thể xem quà và lời nhắn, lưu vật phẩm nếu phù hợp, hoặc từ chối/giới hạn quà theo thiết lập. Cần có biện pháp chống spam, quấy rối, giao dịch gian lận và gây áp lực tặng quà.
- Không biến quà tặng thành nghĩa vụ: không phạt khi không tặng/không đáp lễ, không bắt mua quà để hoàn thành nhiệm vụ hoặc được công nhận là bạn bè.

### 11.4. Người chơi tự tạo tranh, thiệp và quà
- Xưởng sáng tạo có thể cung cấp công cụ vẽ tranh, thiết kế thiệp, chọn màu/nền, dùng nhãn dán, viết lời chúc và tạo vật phẩm đơn giản để tặng người khác.
- Có thể mở rộng sang nhân vật, biểu tượng, huy hiệu, phụ kiện hoặc món quà tương tác do người chơi tự thiết kế; tùy khả năng sản phẩm, tác phẩm có thể được lưu vào bộ sưu tập của người nhận.
- Có thể có album kỷ niệm, lịch sử quà đã trao, thiệp sinh nhật, lời chúc chiến thắng, cảm ơn, động viên hoặc tác phẩm kỷ niệm của đội.
- Tác phẩm tự làm có thể miễn phí; quà mua sẵn là lựa chọn bổ sung, không thay thế ý nghĩa của món quà cá nhân.
- Về sau, người chơi có thể học cách làm thiệp chuyển động, thêm hiệu ứng, tạo nhân vật biết vẫy tay hoặc lập trình món quà tương tác. Đây là cơ hội nối sáng tạo xã hội với kiến thức lập trình, không bắt mọi hoạt động tặng quà trở thành bài học hay bài kiểm tra.

### 11.5. An toàn cộng đồng cho trẻ em
- Thiết kế theo độ tuổi và rà soát các yêu cầu pháp lý/nền tảng trước khi phát hành: quyền riêng tư, sự đồng ý của phụ huynh khi cần, giới hạn tin nhắn, kiểm soát nội dung do người dùng tạo, chặn/báo cáo, chống giả mạo và bảo vệ giao dịch.
- Không mặc định cho phép giao dịch điểm, danh hiệu thành tích hoặc tài khoản giữa người chơi. Mọi loại trao đổi phải có danh sách vật phẩm được phép, quy tắc rõ và biện pháp chống lừa đảo.
- Nội dung do người chơi tạo và lời nhắn phải có cơ chế báo cáo/kiểm duyệt phù hợp. Cần tránh để thông tin cá nhân hoặc nội dung không phù hợp xuất hiện công khai.
- Mọi mua hàng/quà tặng trả phí phải hiển thị rõ giá, vật phẩm nhận được và xác nhận trước giao dịch; cân nhắc kiểm soát của phụ huynh phù hợp với nhóm tuổi và thị trường.
- Những cơ chế cộng đồng này là tầm nhìn sản phẩm cần bảo toàn; thứ tự triển khai có thể chia giai đoạn, không được lặng lẽ xóa khỏi tầm nhìn chỉ vì phiên bản đầu chưa có.

## 12. Nguyên tắc tổng hợp không được làm mất khi cập nhật tài liệu
1. **Mỗi nhà là một tính năng độc lập; điểm và danh hiệu là cầu nối thành tích chung.**
2. **Người chơi có thể chơi theo sở thích và tiến bộ một mình; cộng đồng mở thêm lựa chọn chứ không phải điều kiện bắt buộc.**
3. **Điểm, danh hiệu thành tích, danh hiệu xã hội và quà tặng là những khái niệm khác nhau, dù có thể cùng xuất hiện trong hồ sơ.**
4. **Tặng quà là tự nguyện; tự vẽ tranh/thiệp và tự tạo quà phải được giữ như một phần của tầm nhìn sáng tạo.**
5. **Vòng lặp dài hạn phải kết hợp mục tiêu ngắn, tiến trình lâu dài, nội dung mới và sự tôn trọng thời gian nghỉ.**
6. **Tầm nhìn sản phẩm không đồng nghĩa roadmap phiên bản đầu.** Có thể triển khai từng phần, nhưng phải ghi rõ phần nào được giữ cho giai đoạn sau thay vì làm biến mất khỏi tài liệu.
7. Khi rà soát hoặc viết lại tài liệu PyQuest, phải đối chiếu cả các mục mới 9–12, không chỉ Arena/Creator League. Không tự ý loại bỏ các tính năng xã hội, sáng tạo, quà tặng hoặc vòng lặp dài hạn vì lý do thu gọn phạm vi kỹ thuật.
