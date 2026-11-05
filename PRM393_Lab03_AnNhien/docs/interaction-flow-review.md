# Rà soát và tối ưu luồng tương tác — 05/11/2026

## Phạm vi và phương pháp

Đọc router, screen, ViewModel và service của các luồng hiện có; đối chiếu với widget test.
Ưu tiên: tác vụ thường dùng ít bước, người dùng biết mình đang ở đâu, quay lại không mất
thông tin, thông báo đúng dữ liệu, giữ bước xem lại trước khi ghi/gửi lịch.
Đây là đánh giá từ code và test, chưa phải nghiên cứu người dùng hoặc kiểm tra tay Android.

UI/icon của đợt trước đã commit riêng: `ecb5211`.

## Những điểm đã sửa

| Luồng | Trước | Sau |
| --- | --- | --- |
| Tạo lịch cho mẹ | Bắt buộc Thông tin → Lặp lại → Xem lại | Thông tin → Xem lại; lịch lặp/ngày là nhánh tùy chọn, có tóm tắt ngay trên form |
| Chỉnh lại trước gửi | Quay qua màn lặp dù chỉ muốn sửa giờ/tên | Nút “Sửa thông tin lịch” đưa thẳng về form, dữ liệu vẫn còn |
| Tùy chỉnh lịch lặp | Phải có tên việc mới qua được toàn bộ validation | Có thể chọn lịch trước tên; kiểm tra đầy đủ khi bấm Xem lại và trước gửi |
| Chuyển bước | Có thể giữ offset cuộn của màn trước, mở vào giữa nội dung | Mỗi bước mở từ đầu nội dung, giữ dữ liệu đang soạn |
| Form thiếu dữ liệu | Lỗi ở đầu có thể nằm ngoài vùng đang nhìn | Cuộn về đầu để đọc lỗi; không gửi dữ liệu chưa hợp lệ |
| Rời form mới mở | Chưa sửa gì vẫn bị hỏi bỏ thay đổi | Chỉ hỏi sau khi có tương tác chỉnh dữ liệu |
| Bỏ thay đổi | Quay về lịch nhưng ViewModel còn giữ dữ liệu cũ | Xóa trạng thái form khi người dùng chọn “Bỏ thay đổi” |
| Trùng giờ | Chọn Đổi giờ khác vẫn ở màn xem lại | Đưa về form để sửa trực tiếp; “Vẫn gửi” vẫn cần lựa chọn rõ |
| Ngày kết thúc | Chưa đặt ngày nhưng UI hiện ngày bắt đầu như là ngày kết thúc | Hiện rõ không giới hạn; chỉ có ngày kết thúc khi người dùng đặt; việc một lần không hỏi ngày kết thúc |
| Lịch của mẹ | Quay về có thể reset về chế độ Ngày | Giữ ngày và chế độ đang xem nếu route không yêu cầu chế độ cụ thể |
| Di chuyển lịch | Chỉ Trước/Sau, thiếu đường về hiện tại | Thêm “Về hôm nay” một chạm; vuốt trên phần chọn ngày, vẫn có nút thay thế |
| Đổi chế độ/ngày hiện tại | Gọi tải lại kể cả không thay đổi | Không tải lại nếu giá trị đang chọn không thay đổi |
| Tìm ghép nối | Hướng dẫn yêu cầu vào Tài khoản, Cài đặt chưa có lối vào | Cài đặt → Tài khoản và ghép nối; Tài khoản có Quay lại và đích chính theo vai trò |
| Quay lại từ ghép nối | Luôn đưa về Tài khoản dù mở từ lịch | Về đúng màn trước nếu có lịch sử điều hướng |
| Đăng xuất từ Tài khoản | Demo tắt guard có thể ở lại màn cũ sau đăng xuất | Về đăng nhập khi đăng xuất thành công; lỗi vẫn ở lại |
| Nhập mã ghép nối | Cho ký tự không phù hợp, có thể gửi khi thiếu số | Bàn phím số, lọc số khi gõ/dán, bật nút khi đủ 6 số, Xong trên bàn phím cũng gửi |
| Form khi dùng bàn phím | Cần tự đóng bàn phím để cuộn | Kéo danh sách đóng bàn phím; xem lại/gửi mã chủ động đóng bàn phím |

Không rút bỏ bước kiểm tra phạm vi sửa lịch, chấp thuận của mẹ, xác nhận trùng giờ,
ngưng lặp lại hoặc bỏ dữ liệu đang soạn. Mặc định lịch lặp hiện có được giữ lại và
hiển thị rõ; không tự đổi lịch thực tế của người dùng.

## Vấn đề còn lại, theo ưu tiên

### P1 — luồng chính của Bác còn điểm cụt

`/today/add`, `/today/task/:id`, sửa việc, `/week`, `/habits`, `/family` vẫn có route
placeholder. Nút bấm được nhưng tác vụ chưa hoàn tất. Đây là phần thiếu chức năng,
không thể xử lý chỉ bằng đổi nhãn hoặc giao diện. Cần triển khai F3/F4/F7/F9/F11 với
repository, quyền truy cập và test tương ứng; không thay bằng dữ liệu hoặc thành công giả.

### P2 — cần phát triển riêng

- Lưu nháp bền qua đóng app và khôi phục rõ ràng. Hiện dữ liệu giữ khi qua lại các
  bước; chọn bỏ thay đổi thì xóa, không hứa khôi phục sau tắt app.
- Tuần/tháng hiện vẫn là danh sách ngày, chưa phải lịch tháng trực quan. Cần thiết kế
  lịch có số lượng việc, chọn ngày rõ, tránh danh sách 31 nút dài.
- Phân biệt quá giờ/sắp tới ở Hôm nay; thống nhất nghiệp vụ postponed và nhắc sau
  trước khi thêm thao tác lên thông báo.
- Tách khu thử nghiệm khỏi đường dùng hằng ngày khi chuyển từ demo sang production.
- Cần đo thực tế các tác vụ với người dùng lớn tuổi; đặc biệt khả năng phát hiện vuốt,
  hiểu lịch lặp và khoảng cách vùng chạm.

## Kiểm tra tay đề nghị

1. Từ lịch → Tạo lịch → mẫu Uống trà → giờ nhanh → Xem lại → gửi.
2. Mở lịch lặp trước khi điền tên → chọn Mỗi ngày → Dùng lịch này → tiếp tục nhập.
3. Từ Xem lại sửa tên/giờ, quay lại kiểm tra không mất ngày/lặp/lời nhắn.
4. Form trống: Quay lại không hỏi; form đã sửa: hủy ở lại, bỏ thay đổi thì xóa.
5. Lịch Tuần ở ngày khác: vào chi tiết/tài khoản rồi về, kiểm tra giữ chế độ/ngày;
   bấm Về hôm nay, vuốt trên ngày, thử nút Trước/Sau.
6. Cài đặt → Tài khoản và ghép nối → nhập/dán mã có khoảng trắng; mã sai không mất
   nội dung, đủ 6 số mới bật nút; thử Xong trên bàn phím.
7. Chữ ×2.0, màn 360px, bàn phím mở, lỗi mạng, bấm gửi lặp, hủy dialog trùng giờ.

## Kết quả tự động

- Toàn bộ suite: **611/611 test qua**.
- Nhóm kiểm tra cuối caregiver/auth: **21/21 qua**, bao gồm các chỉnh sửa đăng xuất/quay lại cuối phiên.
- Bổ sung 5 regression test: rời form chưa sửa; xác nhận bỏ dữ liệu; đổi lịch lặp trước tên và quay từ review; giữ ngày/chế độ lịch + Về hôm nay; lọc mã và trạng thái nút ghép nối.
- Analyzer: chỉ còn 2 info có sẵn ở `main_emulator.dart:29,52`, không lỗi/warning mới.
- `git diff --check`: qua.
- Đã xuất/xem widget render form mới; chưa kiểm tra tay Android/TalkBack thật.

