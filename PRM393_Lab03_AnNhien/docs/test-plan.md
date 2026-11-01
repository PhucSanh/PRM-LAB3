# Test plan – Google ARTEMIS

Chủ file: Hương. Mỗi test chạy ≥ 3 lần, ghi pass rate. Tài khoản Google test và API key để trong biến môi trường, không commit.

## Flow quan trọng → màn

| Flow | Màn |
| --- | --- |
| Đăng nhập / đăng xuất | A01 (Google), S10 |
| Onboarding | S01, S02, S13, N01–N05 |
| Thêm việc (có lỗi + phục hồi) | S05, S06, S06e, ST-Saved, ST-Error |
| Làm xong / dời / bỏ qua | S03, S04, DLG-* |
| Thêm việc bằng giọng nói | V00–V05 |
| Lịch tuần + xuất PDF | S07, S11 |
| Thói quen | S08, S16 |
| Gia đình | S09, S12, S17 |

## Ca test

| ID | Flow | Điều kiện đầu | Bước | Kết quả mong đợi (giá trị agent phải báo lại) | Loại | Người | Kết quả |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TC-01 | Đăng nhập | Cài app, chưa đăng nhập | Mở app → "Tiếp tục với Google" → chọn tài khoản test | Thấy Hôm nay + 4 tab; báo dòng "Đã xong x/y việc" | Native | Hương | |
| TC-02 | Đăng nhập | Chưa đăng nhập | Bấm Google → huỷ | Thấy câu "Bác chưa đăng nhập…" | Lỗi | Hương | |
| TC-03 | Thêm việc | Đã đăng nhập | Thêm "Đi bộ" 6:00 mỗi ngày | Việc có trong Hôm nay; báo tổng số việc | Chính | Khang | |
| TC-04 | Thêm việc | Đã đăng nhập | Lưu khi chưa chọn giờ → chọn giờ → lưu | Thấy lỗi có ví dụ, sau đó lưu được | Lỗi | Khang | |
| TC-05 | Làm xong | Có việc chưa làm | Bấm Đã xong → Hoàn tác | Trạng thái quay về "Chưa làm"; báo số việc xong | Chính | Khang | |
| TC-06 | Giọng nói | Quyền micro đã cho | V01 → nói → V03 → Lưu | V05 hiện tên việc + giờ | Chính | Khang | |
| TC-07 | Điều hướng | Đã đăng nhập | Mở lần lượt 4 tab + 1 màn chi tiết mỗi tab | Báo tiêu đề từng màn | Chính | Hương | |
| TC-08 | Gia đình | Đã đăng nhập | Thêm người thân số sai → sửa → lưu | Thấy lỗi, rồi người thân có trong danh sách | Lỗi | Hương | |
| TC-09 | Xuất PDF | Có việc trong tuần | S07 → Xuất PDF | Thấy tiến độ 100 % và link tải | Export | Hương | |
| TC-10 | Remote Config | `snooze_minutes` = 15 trên console | Mở S14 | Báo số phút trên nút = 15 | RC | Hương | |
| TC-11 | Thông báo | App đã tắt | Gửi FCM từ console → bấm ở khay thông báo | Mở đúng màn lời nhắc | Native | Hương | |
| TC-12 | Mất mạng | Tắt Wi-Fi + dữ liệu | Lưu việc | Thấy màn lỗi có "Thử lại" | Lỗi | Khang | |
| TC-13 | Đăng xuất | Đã đăng nhập | Cài đặt → Đăng xuất | Về màn đăng nhập, không thấy dữ liệu cũ | Chính | Hương | |
| TC-14 | Analytics | Debug mode bật | Làm TC-03 | Logcat có `add_task` | Analytics | Hương | |
| EX-01 | Khám phá | Profile Pro, 15–30 phút | Không kịch bản | Danh sách lỗi tìm được | Exploratory | Hương | |

## Kết quả chạy

| ID | Lần 1 | Lần 2 | Lần 3 | Pass rate | Thời gian TB | Ghi chú (flaky vì sao) |
| --- | --- | --- | --- | --- | --- | --- |
