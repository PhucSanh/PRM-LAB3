# Hoàn thiện bốn nhóm luồng — 06/11/2026

Trạng thái: đã triển khai trong code và kiểm tra local. Không dùng kết quả test Fake làm bằng chứng đã nghiệm thu Firebase production hoặc Android thật.

## 1. Gợi ý gia đình dùng Firebase

- `/caregiver/suggest`, tab Gia đình của Bác và `/inbox/suggestions/:id` cùng dùng adapter `FirebaseFamilySuggestionService` và schema `tasks`/`acceptedIds` của backend hiện có.
- Gửi có request ID ổn định để retry không sinh hai thông báo. Tên người gửi lấy từ hồ sơ trên server.
- Nhận việc qua `resolveSuggestion` trong transaction; ViewModel không lưu thêm các việc `sg-*` khi service đã tạo việc nguyên tử.
- Nhận một phần, quay lại nhận phần còn lại; bỏ qua phần còn lại rồi hoàn tác vẫn giữ các việc đã nhận.
- Con cháu không đọc được trạng thái nhận/bỏ qua. Rules chỉ cho chủ tài khoản đánh dấu `popupShown: true`, không cho client tự sửa trạng thái.
- Các service Fake chỉ còn trong fixture/preview; provider production không dùng Fake cho tab gợi ý.

## 2. Thao tác trên chi tiết lịch mới

- `/calendar/task/:id` có Dời lại và Bỏ qua hôm nay, tái sử dụng xác nhận và Hoàn tác của luồng hiện có.
- Chỉnh sửa được việc hôm nay/tương lai, truyền đúng ngày vào form thay vì luôn đọc hôm nay. Thay đổi trạng thái vẫn chỉ cho hôm nay.
- Form production dùng transaction theo phạm vi một lần hoặc lần này và các lần sau; giữ lịch sử và hỗ trợ Undo. Lưu mới giữ ngày và các ngày lặp đã chọn.
- Ngày của occurrence đang sửa được giữ cố định trong form; thao tác đổi ngày hôm nay đi qua Dời lại.
- Runtime nhắc việc theo dõi cả `taskReschedules`; planner hỗ trợ việc một lần đã được dời ra ngoài ngày gốc. Việc đã dời tới hôm nay vẫn đánh dấu hoàn thành được.
- Bản nháp form được xóa khi phiên đăng nhập đổi UID.

## 3. Nhập giọng nói và cài đặt nhắc việc

- `/today/voice` mở bộ nhận giọng nói Android với tiếng Việt. Nội dung nhận được có thể sửa, đọc lại, nói lại và xác nhận trước khi sang bước đặt giờ. Chưa xác nhận/lưu form thì không ghi việc vào lịch.
- Android không có dịch vụ nhận giọng nói sẽ trả lỗi rõ; Bác vẫn có ô gõ tên việc. Hủy nhận giữ nguyên nội dung cũ.
- Nút Nói việc theo `voice_input_enabled` của Remote Config; ViewModel cũng kiểm tra cờ khi bắt đầu nhận.
- `/settings/reminders` đọc quyền thông báo thật, xin quyền, gửi lời nhắc thử và mở cài đặt thông báo Android. Trạng thái quyền được đọc lại khi quay về app.
- Bật/tắt nhắc riêng cho từng việc tại Chỉnh sửa; tắt toàn bộ thông báo tại cài đặt Android. Màn mới không trình bày một công tắc giả.

## 4. Đọc to và PDF lịch thật

- Nút Đọc to trong các trạng thái duyệt gợi ý đã nối TTS Android `vi-VN`, có Dừng đọc, lỗi thiếu giọng tiếng Việt và dừng khi app ra nền/đóng màn.
- Nhập giọng nói cũng có đọc lại tên việc trước khi xác nhận.
- Trang chủ → Lưu lịch tuần PDF → Tạo và lưu PDF. `WeeklyReportService` nạp đủ bảy ngày của tuần đang xem từ `TaskRepository`, gồm ngày/giờ, thời lượng và trạng thái thật.
- Tệp dùng font Be Vietnam Pro nhúng, phân trang A4, có số trang; tiêu đề ngày đi cùng việc đầu tiên. Kiểm tra trực quan bản stress 84 việc/tên dài qua 11 trang.
- Lưu bằng Android document picker; hủy không báo thành công. Đổi UID giữa lúc xuất sẽ dừng trước khi tiếp tục. Không phụ thuộc Firebase Storage hoặc PDF mẫu của khu demo.

## Kiểm chứng

- Full Flutter suite: xem kết quả chốt bên dưới.
- Firebase Emulator: **27 test đạt**, gồm rules, transaction, nhận tiếp, hoàn tác bỏ qua và bảo vệ quyền riêng tư.
- PDF: render bằng Poppler, kiểm tra dấu tiếng Việt và phân trang; test dữ liệu thực, hủy lưu và đổi tài khoản.
- Các màn mới kiểm tra ở 360dp, text scale 1.0 và 2.0. Golden cố định clock tại 05/11/2026 để không đổi theo ngày chạy.
- APK debug build từ entry production `lib/main.dart`; không bật `UI_PREVIEW` hay tắt auth guard.

## Cần nghiệm thu khi triển khai

Chưa triển khai Cloud Functions/rules lên project thật trong phiên này. Để bật đầy đủ hành vi nhận tiếp và lưu cờ popup trên cloud, triển khai cả hai cùng bản app:

```bash
firebase deploy --project prm393-145c9 --only functions,firestore:rules
```

Chưa chạy Google login, nhận giọng nói/TTS, document picker và thông báo trên điện thoại thật: `adb devices` không có thiết bị, SDK hiện tại không có binary emulator để tự khởi động máy ảo. Cần kiểm thử hai tài khoản/thiết bị độc lập sau deploy, gồm gửi/nhận gợi ý, sửa lịch, notification, khởi động lại và đổi tài khoản. Máy cần có dịch vụ nhận giọng nói và giọng TTS tiếng Việt; app có lỗi/fallback rõ khi thiếu.

## Kết quả chốt

- `flutter test`: **818 tests passed**, `/tmp/flow-delivery-accepted-tests.log`.
- `flutter analyze`: **No issues found**, `/tmp/flow-delivery-accepted-analyze.log`.
- Firebase Emulator: **27 tests passed**, `/tmp/flow-final-backend.log`.
- `flutter build apk --debug`: thành công, `/tmp/flow-delivery-accepted-build.log`; APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- `git diff --check`: sạch. Không cập nhật/deploy dịch vụ production trong phiên này.
