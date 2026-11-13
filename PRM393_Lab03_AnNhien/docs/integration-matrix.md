# Ma trận Tích hợp Tính năng & Kế hoạch Phối hợp Nhóm (PRM393 - Lab 3)

## 1. Phân chia Trách nhiệm & Ranh giới Module
| Module | Thành viên phụ trách | Giao tiếp với Module khác | Trạng thái tích hợp |
|---|---|---|---|
| F0 (Foundation, Theme, Route) | Sanh | Nền tảng dùng chung cho tất cả các màn hình | Hoàn thành |
| F1 (Auth, Chọn vai trò) | Hiếu | Chuyển hướng tới F2 (Bác) hoặc F13 (Con cháu) | Hoàn thành |
| F2 (Onboarding Bác) | Hương | Sử dụng Theme F0, chuyển dữ liệu sang F3 Hôm nay | Hoàn thành |
| F3, F4, F5, F6 (Task & Voice) | Khang | Đồng bộ task với F7 Lịch tuần và F14 Con lập lịch | Hoàn thành |
| F7 (Lịch tuần & PDF) | Hương | Đọc dữ liệu task từ TaskService (Khang/Hiếu) | Hoàn thành |
| F8 (Cài đặt hiển thị & Hồ sơ) | Sanh | Đồng bộ cỡ chữ với F2 Onboarding | Hoàn thành |
| F9 (Power 9 Habits) | Hương | Tích hợp thành các task thói quen trong ngày (F3) | Hoàn thành |
| F10 (Firebase Infrastructure) | Hiếu | Cung cấp backend Firestore, Auth, FCM cho toàn app | Hoàn thành |
| F11 (Gia đình & Tin nhắn) | Hương | Đồng bộ trạng thái kết nối với F13 Ghép nối (Hiếu) | Hoàn thành |
| F12 (Gợi ý lịch con gửi) | Sanh | Hiển thị trong trang Hôm nay của Bác Lan | Hoàn thành |
| F13, F14 (Chế độ Con cháu) | Hiếu | Quản lý lịch cho cha mẹ, nhận tin từ F11 | Hoàn thành |

## 2. Kế hoạch Kiểm tra Tương thích Chéo (Cross-check Plan)
1. **Kiểm tra cỡ chữ toàn cục**: Thay đổi cỡ chữ tại F8/F2, kiểm tra hiển thị đồng loạt trên F3, F7, F9, F11.
2. **Kiểm tra tạo việc từ xa**: Máy Con cháu (F14) tạo lịch uống thuốc, máy Bác Lan (F3 & F7) nhận thông báo và hiển thị ngay trên danh sách.
3. **Kiểm tra offline-first**: Ngắt kết nối mạng WiFi/4G, các tác vụ xem lịch tuần và hoàn thành thói quen Power 9 vẫn hoạt động trơn tru nhờ Firestore Cache.\n