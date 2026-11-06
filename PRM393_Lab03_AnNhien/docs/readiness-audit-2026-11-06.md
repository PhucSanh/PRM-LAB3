# Rà soát độ sẵn sàng sau khi hoàn thiện bốn nhóm luồng

> Các mục code bên dưới đã được xử lý trong lượt tiếp theo: xem [kết quả sửa và triển khai](readiness-fixes-2026-11-06.md). Cloud Functions còn bị Firebase chặn bởi yêu cầu gói Blaze; chưa có thiết bị nghiệm thu.

Ngày: 06/11/2026. Revision kiểm tra: `129cac6`. Không sửa code sản phẩm trong lượt rà soát này.

Kết luận: chưa nên chốt hoàn thiện để dùng thực tế. Bộ 818 test trước đó đạt nhưng chưa phủ các ca lịch dưới đây. Ba ca đã tái hiện bằng kiểm thử chẩn đoán; các mục cài đặt và lỗi tải được xác nhận qua đường gọi trong code.

## P1 — Danh tính occurrence khi dời trùng ngày

Ví dụ: việc lặp mỗi ngày lúc 08:00; dời lần ngày 07 sang ngày 08 lúc 15:00. Ngày 08 có cả lần 08:00 và lần đã dời 15:00. `planReminders` chỉ định danh bằng UID + taskId + targetDate (`lib/services/local_reminder_service.dart:45`), nên loại mất một lời nhắc. Trạng thái completion và chi tiết cũng dùng taskId/ngày, chưa phân biệt đầy đủ sourceDate của hai lần việc.

Đã tái hiện: truyền hai occurrence cùng chuỗi/ngày, khác giờ/sourceDate; planner chỉ trả một kế hoạch. Cần thống nhất khóa occurrence xuyên suốt lịch, chi tiết, completion, notification payload và Undo; hoặc cấm trường hợp xung đột này với thông báo rõ, không âm thầm gộp.

## P1 — Chỉnh sửa các trường hợp lịch đặc biệt

- **Một lần → lặp:** `TaskFormViewModel.save` ép scope occurrence khi original là once (`lib/viewmodels/task_form_view_model.dart:229`). Planner occurrence lại ép replacement.repeat về once (`lib/services/caregiver_schedule_service.dart:59`). Vì thế chọn lặp mỗi ngày và lưu vẫn có thể thành việc một lần. Đã tái hiện ở planner với đúng nhánh VM đang gọi.
- **Sửa việc đã dời:** Firebase change đọc template gốc rồi gọi planner với ngày đang xem. `current.occursOn(day)` (`lib/services/caregiver_schedule_service.dart:34`) sai với việc một lần đã dời khỏi ngày gốc; planner từ chối dù occurrence thực sự xuất hiện trên lịch ngày mới. Đã tái hiện. Cần xử lý `taskReschedules` khi sửa/xóa, không chỉ dùng template.

## P2 — Cài đặt lời nhắc chưa tác động đầy đủ

`readAloud` và `vibrate` được lưu bởi SettingsService và vẽ trên SettingsScreen, nhưng không được ReminderRuntime/LocalReminderService sử dụng. Nút Đọc to thủ công đã hoạt động; công tắc “Điện thoại đọc lời nhắc” chưa nối với hành vi nhắc. Cấu hình rung Android vẫn dùng notification details cố định.

Ngoài ra, TaskSavedScreen ghi “Nhắc trước 10 phút” (`lib/screens/tasks/task_form_screens.dart:711`), trong khi planner đặt tại đúng giờ việc (`lib/services/local_reminder_service.dart:42`), không trừ 10 phút. Cần thống nhất hợp đồng thời điểm nhắc với nhãn UI. Các alarm hiện là inexact; cần đo việc giao thông báo khi máy tiết kiệm pin trên thiết bị thật trước khi cam kết độ chính xác.

## P2 — Màn sửa có thể quay loading vô hạn

`TaskConfigureScreen` chỉ thoát loading nếu `startEdit` trả true. Task không còn tồn tại trả false; lỗi đọc dữ liệu cũng không được bắt ở callback. Khi đó màn giữ spinner, không có lỗi/Thử lại/lối thoát rõ. Nguồn: `lib/screens/tasks/task_form_screens.dart:151` và `:200`.

Cần state loading/data/not-found/error và nút Thử lại/Quay về lịch; thêm test việc bị xóa trên máy khác và lỗi tải.

## Triển khai và nghiệm thu còn thiếu

- Chưa deploy Functions/rules mới lên Firebase production trong các lượt trước. Nhận tiếp gợi ý partial và cập nhật popupShown cần backend/rules tương ứng.
- `adb devices` kiểm tra lại vẫn không có thiết bị. Chưa nghiệm thu hai tài khoản trên hai máy: Google login, pairing, gửi/nhận/nhận tiếp, thu hồi quyền, notification khi app đóng, khởi động lại, đổi tài khoản, voice/TTS và lưu PDF.
- Nếu chuẩn bị phát hành thay vì nộp/demo: cấu hình release signing riêng. `android/app/build.gradle.kts:41` hiện ký release bằng debug key.

## Phạm vi không nên nhầm thành lỗi bắt buộc

Thư viện lưu hoạt động/bookmark và gửi tin nhắn trong app chưa hỗ trợ; UI đang nói rõ. Chỉ cần triển khai nếu nằm trong phạm vi sản phẩm chốt, không phải điều kiện để dùng lịch sinh hoạt.

## Bằng chứng và giả thuyết đã loại

Đã chạy bốn phép chẩn đoán, log `/tmp/readiness-audit-repro.log`. Ba phép xác nhận hành vi lỗi lịch nêu trên. Một phép tiêm AnalyticsService ném lỗi khiến VM báo lưu lỗi sau khi repository đã lưu; đối chiếu adapter production `FirebaseAnalyticsService.logEvent` cho thấy đã bắt lỗi SDK. Vì thế **không coi giả thuyết Analytics này là lỗi production đã xác nhận**. Có thể tăng phòng vệ ở ViewModel sau, nhưng không xếp trước các lỗi lịch.

File test chẩn đoán tạm đã được xóa sau khi kiểm tra; không sửa golden hoặc đưa các assertion xác nhận hành vi sai vào bộ test chuẩn.

Thứ tự đề xuất: sửa danh tính occurrence và hai nhánh chỉnh sửa → nối cài đặt/thời điểm nhắc → xử lý lỗi tải form → chạy hồi quy → deploy backend → nghiệm thu hai thiết bị. Chưa thể dùng số test đạt để thay cho các bước này.
