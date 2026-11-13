# Bảng Thuật ngữ Dự án An Nhiên

Giải thích nhanh các thuật ngữ và viết tắt dùng trong tài liệu và mã nguồn.

## Người dùng & vai trò

| Thuật ngữ | Ý nghĩa |
| --- | --- |
| **Bác** | Người dùng chính, 65 tuổi trở lên. Giao diện chữ lớn, vùng chạm rộng. |
| **Con cháu** | Vai trò thứ hai: người thân theo dõi, lập lịch và gửi lời nhắn cho Bác. |
| **Ghép nối (Pairing)** | Liên kết tài khoản Con cháu với tài khoản Bác bằng mã `pairings/{code}`. |

## Tính năng

| Mã | Tên |
| --- | --- |
| F0 | Nền tảng (theme, widget dùng chung, router) |
| F1 | Tài khoản + chọn vai trò |
| F2 | Onboarding |
| F3 | Hôm nay |
| F4 | Thêm / sửa / xoá việc |
| F5 | Nhập bằng giọng nói |
| F6 | Lời nhắc |
| F7 | Lịch tuần + xuất PDF |
| F8 | Cài đặt & hồ sơ |
| F9 | Thói quen Power 9 |
| F10 | Firebase |
| F11 | Gia đình |
| F12 | Gợi ý lịch |
| F13 | Ghép nối |
| F14 | Con cháu lập lịch |

## Khái niệm sản phẩm

| Thuật ngữ | Ý nghĩa |
| --- | --- |
| **Power 9** | 9 thói quen sống thọ rút ra từ nghiên cứu Blue Zones. Khoá: `move`, `purpose`, `downshift`, `eighty`, `plant`, `tea`, `belong`, `family`, `tribe`. |
| **Blue Zones** | Các vùng trên thế giới có tỉ lệ người sống trên 100 tuổi cao. |
| **Hoàn tác** | Thao tác đảo ngược thay đổi vừa làm, hiện qua `UndoSnackbar` (không tự tắt). |
| **Remote Config** | Cấu hình từ xa: `snooze_minutes`, `voice_input_enabled`, `home_max_upcoming`. |

## Kỹ thuật

| Thuật ngữ | Ý nghĩa |
| --- | --- |
| **MVVM** | Model – View – ViewModel. View chỉ vẽ, ViewModel giữ trạng thái và gọi service. |
| **Riverpod** | Thư viện quản lý trạng thái và tiêm phụ thuộc; mọi service đăng ký trong `lib/services/providers.dart`. |
| **UiState** | Trạng thái màn: `UiLoading`, `UiEmpty`, `UiError`, `UiData`. |
| **Fake service** | Bản service giả, chạy không cần mạng, dùng cho test ViewModel. |
| **AppException** | Lỗi đã chuẩn hoá; `userMessage` là câu thông báo thân thiện cho Bác. |
| **ARTEMIS** | Bộ kiểm thử end-to-end bằng pytest trong `e2e_test/`. |
| **DT-xx** | Mã ghi nhận một điểm lệch thiết kế so với Figma, ghi cuối `design-traceability.md`. |
| **CR-xx** | Mã một phát hiện từ AI code review, ghi trong `code-review.md`. |
| **textScaler** | Hệ số phóng chữ toàn app: 1.0 / 1.15 / 1.3; layout phải chịu được 2.0. |
