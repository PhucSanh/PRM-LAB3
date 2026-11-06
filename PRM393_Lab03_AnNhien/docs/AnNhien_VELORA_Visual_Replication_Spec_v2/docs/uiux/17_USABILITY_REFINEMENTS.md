# 17 — Điều chỉnh khả dụng sau rà soát 2026-11-06

Áp dụng cùng 15 và 16. Giữ màu, minh họa và typography hiện tại; các quy tắc dưới đây bổ sung hành vi để người lớn tuổi thao tác thuận tiện. Nếu mô tả màn cũ mâu thuẫn với các hành vi này, dùng file này.

- **Trang chủ:** nút “Thêm hoạt động” cố định phía trên vùng điều hướng. Chọn ngày, ngày trước/sau và “Về hôm nay” nằm trước danh sách việc. Khi thêm việc, giữ ngày đang xem; ngày quá khứ dùng thời điểm kế tiếp hợp lệ và hiển thị ngày thực tế trong form.
- **Chi tiết thói quen:** “Thêm vào lịch” mở thẳng bước đặt giờ, giữ tên và nhóm vừa chọn. Không bắt chọn lại hoạt động. Nhóm ngoài các lựa chọn nhanh vẫn phải hiển thị đúng tên/icon trong form và màn kết quả.
- **Chữ rất lớn:** dưới 600dp và text scaler hiệu dụng > 1.6, điều hướng của Bác dùng nút “Menu: [mục hiện tại]” mở danh sách cuộn được, đủ 5 mục và có nút đóng. Cỡ thường giữ 5 mục dưới màn hình, màn rộng giữ rail. Không giảm cỡ chữ hoặc bẻ từng ký tự để ép 5 nhãn vào hàng hẹp.
- **TalkBack:** node nút có `excludeSemantics` phải tự khai báo `onTap`; gồm AppButton, thanh điều hướng và ô nhóm hoạt động. Ô nhập phải gắn nhãn với node editable và giữ hành động chỉnh sửa. Nút đang xử lý giữ nhãn, báo trạng thái, không kích hoạt được.
- **Form:** tối đa 80 ký tự tên việc; lỗi tên và lỗi giờ độc lập. Khi tên sai, đưa tiêu điểm về ô tên; khi chỉ giờ sai, cuộn tới phần giờ. Không hiển thị lỗi thiếu tên cho tên hợp lệ. Không ghi hai lần khi bấm lưu liên tiếp. Lưu thất bại giữ bản nháp, báo chưa lưu và cho thử lại.
- **Tài khoản:** Bác thấy mã ghép nối của Bác; con cháu thấy ghép nối/lịch của mẹ. Công cụ thử nghiệm chỉ xuất hiện trong debug build.
- **Chức năng chưa có:** không quảng bá tab “Đã lưu” khi chưa có bookmark. Link cũ vẫn hiển thị giải thích trung thực và đường sang Thói quen.

## Kiểm chứng

Test tự động kiểm tra action semantics thực sự đổi route, giữ ngày khi thêm việc ở 100%/200%, giữ nhóm thói quen, chống lưu trùng và bảo toàn bản nháp khi lỗi. Golden dùng font thật, kiểm tra bố cục 360/390dp và chữ đến 200%; kiểm tra overflow thêm các bề rộng 320/800dp.

Các kiểm tra này chưa thay thế thử TalkBack trên Android thật hoặc thử với người cao tuổi. Không suy ra Firebase Functions đã triển khai từ việc widget test thành công; xem `docs/uiux-audit-2026-11-06.md` ở project để biết giới hạn nghiệm thu.
