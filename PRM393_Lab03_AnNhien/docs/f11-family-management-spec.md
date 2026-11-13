# Đặc tả Tính năng Quản lý Người thân & Gia đình (Feature F11 - Flow 5 & Flow 9)

## 1. Mục đích
Cho phép người cao tuổi dễ dàng kết nối với con cháu trong gia đình. Người thân có thể kết nối thông qua quét mã QR hoặc nhập mã kết nối 6 chữ số ngắn gọn.

## 2. Các Vai trò trong Nhóm Gia đình
- **Người cao tuổi (Chủ tài khoản chính)**: Nhận lời nhắc, xem danh sách con cháu, nhận tin nhắn và lời hỏi thăm.
- **Người chăm sóc chính (Con trai / Con gái trưởng)**: Có quyền thêm lịch uống thuốc, theo dõi trạng thái hoàn thành công việc của mẹ/bố.
- **Thành viên gia đình thân thiết (Cháu, dâu, rể)**: Gửi lời chúc, tin nhắn ảnh và sticker động viên.

## 3. Danh sách Màn hình (13 màn hình Figma)
- `Màn hình F11_01`: Cây gia đình / Danh sách thành viên thân yêu.
- `Màn hình F11_02`: Thẻ hồ sơ thành viên (Ảnh đại diện, tên gọi thân mật, số điện thoại).
- `Màn hình F11_03`: Màn hình tạo mã kết nối (Hiển thị mã PIN 6 số cỡ to và mã QR).
- `Màn hình F11_04`: Hướng dẫn con cháu cách quét mã để ghép nối.
- `Màn hình F11_05`: Danh sách yêu cầu kết nối đang chờ xác nhận.
- `Màn hình F11_06 - F11_13`: Các trạng thái chi tiết, sửa thông tin người thân, cài đặt quyền chia sẻ.

## 4. Bảo mật và Quyền riêng tư
- Dữ liệu kết nối gia đình được lưu trữ an toàn tại `families/{familyId}/members`.
- Chỉ các thành viên được người cao tuổi hoặc người chăm sóc chính chấp thuận mới có quyền xem thông tin sức khỏe.\n