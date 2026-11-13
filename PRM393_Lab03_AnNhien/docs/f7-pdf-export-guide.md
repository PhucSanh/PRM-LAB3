# Hướng dẫn Kỹ thuật và Mẫu Thiết kế Xuất Lịch PDF (Feature F7)

## 1. Yêu cầu Thiết kế Bản in PDF
- **Khổ giấy tiêu chuẩn**: Khổ A4 nằm ngang (Landscape) để hiển thị trọn vẹn 7 cột tương ứng 7 ngày trong tuần.
- **Font chữ hỗ trợ Unicode Tiếng Việt**: Sử dụng nhúng font TTF `Roboto-Regular.ttf` và `Roboto-Bold.ttf` để tránh lỗi hiển thị dấu tiếng Việt.
- **Bố cục in**:
  - Phần đầu (Header): Tiêu đề "LỊCH SINH HOẠT VÀ UỐNG THUỐC TUẦN CỦA BÁC LAN", hiển thị khoảng ngày (Ví dụ: Từ 10/11/2026 đến 16/11/2026).
  - Số điện thoại liên lạc khẩn cấp của con cháu in đậm góc phải.
  - Bảng 7 ngày: Mỗi ngày chia thành 4 dòng (Sáng - Trưa - Chiều - Tối).
  - Ô vuông Checkbox in rỗng [  ] bên cạnh mỗi đầu việc để người lớn tuổi có thể lấy bút mực tích vào sau khi làm xong trên giấy in.

## 2. Gói Thư viện Flutter sử dụng
- `pdf: ^3.10.0`: Tạo tài liệu PDF theo widget tree.
- `printing: ^5.11.0`: Hiển thị PDF Preview, hỗ trợ gửi lệnh in trực tiếp đến máy in hệ điều hành hoặc chia sẻ qua share sheet.

## 3. Các Bước Xử lý Kỹ thuật
1. Lấy dữ liệu công việc trong tuần từ `WeeklyCalendarViewModel`.
2. Tạo cấu trúc `pw.Document` với `pw.PageTheme(pageFormat: PdfPageFormat.a4.landscape)`.
3. Render bảng lịch trình với `pw.Table` có viền kẻ rõ nét (border width: 1.0).
4. Lưu buffer dữ liệu thành tệp tạm thời trong thư mục ứng dụng hoặc mở `Printing.layoutPdf()`.\n