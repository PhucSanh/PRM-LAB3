# Sổ tay Xử lý Sự cố & Vận hành Ứng dụng (Troubleshooting & Runbook)

## 1. Vấn đề Thông báo & Lời nhắc Không Rung/Chuông
- **Nguyên nhân**: Hệ điều hành Android đưa ứng dụng vào chế độ tiết kiệm pin ngầm (Battery Optimization) hoặc quyền thông báo chưa được cấp đầy đủ.
- **Cách khắc phục**:
  1. Vào *Cài đặt hệ thống* -> *Ứng dụng* -> *An Nhiên*.
  2. Chọn mục *Pin* -> chuyển sang chế độ **Không hạn chế (Unrestricted)**.
  3. Kiểm tra mục *Thông báo* -> Bật toàn bộ các kênh âm thanh và biểu ngữ ưu tiên cao.

## 2. Mã Ghép nối Gia đình Báo Lỗi Hết hạn
- **Nguyên nhân**: Vì lý do an toàn bảo mật, mã kết nối 6 chữ số có hiệu lực trong vòng 15 phút kể từ lúc tạo.
- **Cách khắc phục**:
  - Trên máy Bác Lan: Nhấn nút **"Tạo mã mới"** để sinh mã PIN mới.
  - Nhập ngay mã mới trên thiết bị con cháu.

## 3. Sự cố Đồng bộ Dữ liệu khi Mất Kết nối Mạng
- **Cơ chế hoạt động**: An Nhiên hỗ trợ lưu trữ cục bộ (Local Persistence) với Firestore Cache.
- Khi mất mạng: Ứng dụng vẫn cho phép xem lịch, đánh dấu hoàn thành công việc và tích điểm thói quen bình thường.
- Khi có mạng trở lại: Dữ liệu tự động đồng bộ lên máy chủ đám mây trong vòng 5 giây mà không làm mất bất kỳ thông tin nào.

## 4. Lỗi Font Chữ khi Xuất PDF trên Một số Dòng Máy Cũ
- Bản vá mới nhất đã đóng gói trực tiếp tệp font `BeVietnamPro-Regular.ttf` vào thư mục assets của bundle ứng dụng, loại bỏ hoàn toàn sự phụ thuộc vào font chữ có sẵn của thiết bị.\n