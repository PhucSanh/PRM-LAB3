# F1 — tài khoản và chọn vai trò

Ngày: 02/11/2026. Chủ: Hiếu. Trạng thái: đã triển khai code; còn nghiệm thu Firebase/Android thật và đối chiếu Figma.

## Hành vi đã triển khai

- Giữ Google Sign-In; chặn bấm lặp, thông báo huỷ/mất mạng. Nếu Firebase trả `operation-not-allowed`, báo đăng nhập Google đang tạm tắt. Không thay đổi cấu hình provider trên Console.
- `users/{uid}` được tạo lần đầu bằng transaction. Không ghi đè role/onboarded đã có; đọc profile stream theo UID và có màn chờ/lỗi/thử lại.
- C01 chọn Bác hoặc Con cháu, lưu role trước khi đi tiếp. Bác mới tới `/welcome`; Bác onboarded tới `/today`; Con cháu chưa ghép nối tới `/caregiver/pair`, đã có pairedMomUid tới `/caregiver/schedule`.
- Chưa đăng nhập không vào được route dữ liệu; không bỏ qua màn role/onboarding qua deep link. Account hỗ trợ xem tên/vai trò và đăng xuất có xác nhận.
- Đăng xuất xoá Firestore cache/pending writes, kết thúc Firebase/Google và reset các state theo UID. Nếu xoá cache thất bại vẫn kết thúc auth và báo lỗi; lần đăng nhập tiếp theo phải xoá cache thành công trước khi xác thực tài khoản khác. Thông báo rõ dữ liệu chưa đồng bộ có thể bị xoá.
- Analytics login/logout/select_role; lỗi telemetry không làm mất kết quả xác thực hoặc chặn đăng xuất.

## Phạm vi và tích hợp

`AppUser`/`AuthService` giữ nguyên contract. `UserProfile` và `ProfileService` mới tách riêng.
F2 gọi `profileServiceProvider.markOnboarded(uid)` qua service sau khi hoàn tất onboarding;
F2/F8 cần bổ sung contract lưu các trường hồ sơ theo công việc của nhóm.
F13/F14 chỉ có điểm vào placeholder, không có ghép nối/lịch mẹ thật trong F1.
Role và pairedMomUid chỉ điều hướng UI; quyền dữ liệu UID khác phải do Firestore rules/grants kiểm tra.

Chỉnh widget dùng chung tối thiểu để có lối vào Account. TodayViewModel chỉ thêm guard
`ref.mounted` để kết quả tải bất đồng bộ không ghi state sau khi đổi phiên/dispose.
Không sửa schema TaskItem hoặc triển khai thay các feature của thành viên khác.
A02–A04 hoãn theo phân công: giữ phương thức Google bắt buộc, không giả lập OTP/sinh trắc học.
Chưa sửa hoặc đối chiếu Figma; traceability vẫn ghi rõ phần này.

## Kiểm tra tự động

- `flutter analyze`: PASS, không có issues.
- `flutter test`: PASS 16 tests (gồm 2 Today tests có sẵn). Kiểm tra 5 nhánh khôi phục profile, signed-out/deep-link guards, chọn cả hai role, xác nhận/hủy đăng xuất và cache clear, profile lỗi/thử lại, chữ 200% ở màn session/role/account, role save lỗi/bấm lặp, cache/telemetry lỗi, huỷ/mất mạng khi đăng nhập, bootstrap không reset profile.
- `npm test --prefix firebase/tests`: PASS 7 nhóm Emulator tests, gồm profile owner được tạo/cập nhật và stranger/anonymous bị từ chối. Không sửa/deploy rules production.
- `flutter build apk --debug`: PASS; artifact `build/app/outputs/flutter-apk/app-debug.apk`.

Các test Flutter dùng Fake service; không phải bằng chứng Firebase SDK/Google native đã chạy trên thiết bị.
Emulator rules test xác minh quyền, không thay cho integration test của adapter.

## Còn cần nghiệm thu trên thiết bị

Google provider đang được chủ dự án tắt tạm thời. Máy hiện không có Android device/emulator.
Sau khi bật lại provider, dùng máy có debug SHA-1 được phép và kiểm tra:

1. Google đăng nhập mới, huỷ, mất mạng; hồ sơ được tạo đúng UID.
2. Chọn role và mở lại app giữ đúng nhánh; hai máy cùng tài khoản không reset role/onboarded.
3. Đăng xuất rồi đổi tài khoản: không thấy profile/task của tài khoản trước; xác minh Firestore native cache được xoá.
4. Khởi động lại, offline với profile cache, mất mạng khi lưu role và thử lại.
5. Chụp evidence Auth/Firestore/Analytics; chạy ARTEMIS theo yêu cầu bài. Chưa có bằng chứng ARTEMIS hoặc ảnh DebugView trong lần này.
