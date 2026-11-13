# Tài liệu Đặc tả Tính năng Lịch tuần & Xuất PDF (Feature F7 - Flow 4)

## 1. Tổng quan
Tính năng Lịch tuần cung cấp cái nhìn tổng quan về lịch biểu sinh hoạt, uống thuốc, tập luyện và thăm khám bác sĩ của Bác Lan trong cả tuần. Đồng thời, tính năng cho phép xuất bản lịch biểu thành file PDF để in ấn hoặc gửi qua Zalo cho người thân.

## 2. Các Màn hình Chức năng (5 màn hình Figma)
1. `F7_01`: Màn hình Lịch tuần tổng thể (Weekly Overview Grid & Timeline).
2. `F7_02`: Chi tiết lịch trình theo từng ngày trong tuần (Thứ 2 đến Chủ nhật).
3. `F7_03`: Bộ lọc sự kiện theo phân loại: Uống thuốc, Tập thể dục, Dinh dưỡng, Nhắc hẹn.
4. `F7_04`: Màn hình xem trước bản in PDF (PDF Preview Screen).
5. `F7_05`: Hộp thoại chia sẻ hoặc lưu file PDF về bộ nhớ máy / in qua máy in không dây.

## 3. Luồng Dữ liệu (Data Flow)
```
[Firestore: users/{uid}/tasks]
         │
         ▼
[ScheduleService.getWeeklyTasks(weekRange)]
         │
         ▼
[WeeklyCalendarViewModel]
         ├── Cập nhật trạng thái hiển thị giao diện (StateNotifier)
         └── Gom nhóm công việc theo thứ và khung giờ (Sáng / Trưa / Chiều / Tối)
```

## 4. Quy tắc Nghiệp vụ
- Lịch tuần luôn hiển thị ngày hiện tại làm mốc mặc định.
- Mỗi sự kiện đều có mã màu trực quan:
  - Đỏ gạch / Cam: Uống thuốc, đo huyết áp (Ưu tiên cao).
  - Xanh lá cây: Thể dục, đi dạo, tưới cây.
  - Xanh dương: Lời nhắc từ con cháu, hẹn khám bác sĩ.\n