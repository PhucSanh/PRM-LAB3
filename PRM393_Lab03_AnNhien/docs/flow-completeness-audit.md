# Kiểm tra độ hoàn chỉnh luồng — 06/11/2026

Kết luận: chưa hoàn chỉnh end-to-end. Các luồng chính có route, ViewModel và test, nhưng còn điểm đứt tích hợp trong giao diện đang dùng. Đây là kiểm tra code và kiểm thử tự động, chưa phải nghiệm thu trên thiết bị với Firebase production.

## Các điểm cần xử lý

1. **Ưu tiên cao — Gợi ý gia đình dùng hai hệ dữ liệu.** Tab `/caregiver/suggest` gọi `SuggestionComposeViewModel.send` → `suggestionServiceProvider`, đang là `FakeSuggestionService` trong bộ nhớ (`lib/services/providers.dart:112`). Tab Gia đình của Bác cũng đọc provider giả qua `SuggestionInboxViewModel`. Trong khi đó hộp thông báo `/inbox/suggestions/:id` đọc Firebase qua `caregiverSuggestionServiceProvider` và `pendingSuggestionsProvider`. Gửi từ tab chính có thể báo thành công mà không ghi Firebase, không tới máy Bác, không tồn tại sau khi khởi động lại. Cần nối cả soạn, danh sách và duyệt gợi ý vào cùng backend thật; kiểm chứng bằng hai tài khoản trên hai phiên độc lập.
2. **Thiếu thao tác ở luồng mới.** `/calendar/task/:id` chỉ có Hoàn thành và Chỉnh sửa trong hôm nay. Dời lại và Bỏ qua hôm nay vẫn chỉ nằm ở `lib/screens/today/task_detail_screen.dart`. Người đi từ Trang chủ mới không có các thao tác này. Chỉnh sửa còn bị ẩn cho cả ngày tương lai; cần phân biệt giới hạn cập nhật trạng thái hôm nay với nhu cầu sửa lịch tương lai.
3. **Nút đang hoạt động dẫn tới placeholder.** “Nói việc” trong chọn hoạt động mở `/today/voice`; “Lời nhắc” trong Cài đặt mở `/settings/reminders`. Cả hai vẫn là `FeaturePlaceholder` trong router. Nhắc lịch local đã có service/runtime riêng; placeholder này không có nghĩa toàn bộ nhắc lịch chưa được làm.
4. **Các chức năng chưa tích hợp.** Đọc to trong màn duyệt gợi ý bị tắt (`ReadAloudButton(onPressed: null)`). `reportServiceProvider` tạo `FirebaseReportService` không truyền renderer, nên `exportWeek` báo đang chờ tích hợp F7; chưa có luồng xuất PDF thật từ lịch mới. Không đánh đồng PDF mẫu ở khu demo với báo cáo lịch thật.
5. **Kiểm thử phụ thuộc ngày thực.** 8 lỗi hiện tại đều ở `test/calm_migration_test.dart`: một assertion coi 2026-11-06 là ngày khác nhưng hôm nay chính là ngày đó; bảy golden (caregiver_calendar và sáu task_detail) có nội dung dựa trên ngày thực. Cần cố định clock trong fixture và giữ một test riêng kiểm tra chuyển ngày; không cập nhật ảnh chuẩn chỉ để che lỗi phụ thuộc ngày.

## Phần đã có đường đi và kiểm thử

| Luồng | Bằng chứng hiện có | Giới hạn |
| --- | --- | --- |
| Intro → đăng nhập → vai trò → onboarding → Trang chủ | Router bật auth mặc định; auth_routing/onboarding_flow tests | Chưa chạy Google login thật lần kiểm tra này |
| Chọn hoạt động → cấu hình giờ/ngày/lặp → lưu → lịch | Task form/repository/ViewModel và test | Nhánh giọng nói chưa làm |
| Chi tiết hôm nay → hoàn thành → hoàn tác; sửa/xóa qua form | calm_migration, task_form, today tests | Thiếu dời/bỏ qua trên chi tiết mới; giới hạn sửa tương lai |
| Ghép nối → Con cháu xem/tạo/sửa lịch | Firebase pairing/schedule services, caregiver tests | Chưa nghiệm thu liên thiết bị; tab Gợi ý riêng vẫn dùng Fake |
| Hồ sơ/cỡ chữ/tương phản/đăng xuất | Settings/account tests | Chưa kiểm tra persistence production trên thiết bị lần này |
| Nhắc việc local, mở thông báo, inbox | Runtime/plugin adapter và unit/widget tests; có integration tests | Chưa chạy integration Android lần này |

## Kết quả chạy lại

- `flutter test --reporter compact`: **791 đạt, 8 lỗi**, log `/tmp/flow-audit-tests.log`.
- `flutter analyze`: **No issues found**, log `/tmp/flow-audit-analyze.log`.
- `adb devices`: không có thiết bị kết nối. Không chạy được integration tests Android hoặc kiểm chứng hai máy thật trong lượt này.
- Test Cloud Functions chưa chạy được: môi trường lệnh hiện tại không có `node`.
- Không thay đổi code sản phẩm hoặc cập nhật golden trong lượt kiểm tra này. Ảnh diff do test sinh ở `test/failures/` dùng để chẩn đoán.

Thứ tự hoàn thiện: thống nhất backend gợi ý → khôi phục thao tác chi tiết ở UI mới → xử lý hai route placeholder → cố định clock của test → nghiệm thu hai tài khoản/thiết bị, bao gồm notification, offline, khởi động lại và đăng xuất/đăng nhập lại.
