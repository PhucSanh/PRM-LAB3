# Sửa các điểm còn thiếu sau rà soát — 06/11/2026

## Phần đã sửa

| Vấn đề | Hành vi hiện tại | Kiểm chứng |
| --- | --- | --- |
| Một lần → lặp | Cho phép đổi sang chuỗi lặp, xóa giới hạn endDate một lần; Undo trả về lịch cũ | `task_form_view_model_test.dart` |
| Sửa/xóa lần đã dời | Transaction đọc cả template và bản dời, tách đúng lần đang sửa, giữ các lần khác; snapshot Undo khôi phục bản dời | `moved_occurrence_edit_test.dart` |
| Dời trùng ngày | Chặn khi ngày đích đã có lần khác của cùng việc; thông báo chọn ngày khác hoặc đổi giờ lần đã có. Giữ khóa trạng thái hiện tại, không âm thầm gộp hai lần | `reschedule_collision_test.dart` |
| Dời/Undo đồng thời | Các transaction dời cùng ghi revision template để xung đột được retry; Undo kiểm tra bản dời hiện tại và không ghi đè lần dời mới | `reschedule_collision_test.dart`; code review transaction |
| Rung | Runtime theo dõi cài đặt của UID, đổi Android notification channel theo lựa chọn rung, lên lịch lại lời nhắc đang chờ | `reminder_preferences_test.dart` |
| Đọc to lời nhắc | Tự đọc khi Bác mở lời nhắc nếu đã bật; đọc/dừng thủ công vẫn có. Nhãn cài đặt nêu rõ đọc khi mở, không hứa TTS tự phát từ nền | `reminder_preferences_test.dart`, `device_access_flow_test.dart` |
| Thời điểm nhắc | UI ghi “Nhắc vào giờ làm”, khớp planner. Cài đặt giải thích chế độ tiết kiệm pin có thể giao thông báo muộn | LocalReminderService; widget regression |
| Deep link lời nhắc | Giữ ngày occurrence trong payload/route; chỉ nhận ngày hợp lệ | `reminder_preferences_test.dart` |
| Lỗi tải màn sửa | Có thông báo không tìm thấy/lỗi tải, Thử lại và Về lịch; giữ ngày đã chọn khi thử lại thành công, không giữ spinner vô hạn | `task_edit_load_error_test.dart`, gồm 360dp/200% |

Khi sửa lần đã dời, form sửa riêng lần đó; phần lặp khác được giữ. Muốn sửa chuỗi, mở một lần lịch bình thường. Đây là lựa chọn để tránh làm thay đổi nhầm toàn bộ chuỗi từ một ngoại lệ đã dời.

## Kết quả chốt local

- **832 test Flutter đạt**: `/tmp/readiness-accepted-tests.log`.
- **27 test Firebase Emulator đạt**: `/tmp/readiness-backend-regression.log`.
- `flutter analyze`: **No issues found**: `/tmp/readiness-accepted-analyze.log`.
- APK debug build từ entry production thành công: `/tmp/readiness-accepted-build.log`.
- Artifact: `build/app/outputs/flutter-apk/app-debug.apk`.
- `git diff --check` sạch. Test cũ kẹt vì đóng stream trước khi dispose container đã dừng; fixture mới kết thúc đúng vòng đời và bộ test cuối đã qua.

## Triển khai thật

**Firestore rules: đã deploy thành công** lên `prm393-145c9`; log `/tmp/readiness-firestore-deploy.log` ghi “released rules” và “Deploy complete”.

**Cloud Functions: chưa deploy được.** Đã thử lệnh deploy không tương tác cùng rules, nhưng Firebase chặn vì project cần gói Blaze để bật Cloud Build/Cloud Functions/Artifact Registry. Log `/tmp/readiness-firebase-deploy.log`. Không tự nâng gói hoặc thiết lập thanh toán.

Chủ project cần hoàn tất nâng gói tại Firebase Console trước; sau đó chạy lại:

```bash
firebase deploy --project prm393-145c9 --only functions --non-interactive
```

Các luồng phụ thuộc callable như ghép nối và gửi/nhận gợi ý chưa được nghiệm thu trên cloud production. Emulator đạt không thay cho bước triển khai này.

**Thiết bị thật: chưa nghiệm thu.** `adb devices` kiểm tra lại vẫn không có thiết bị kết nối. Cần thử Google login, hai tài khoản ghép nối, gửi/nhận/nhận tiếp, sửa/dời/xóa/Undo, thu hồi quyền, thông báo khi app đóng và khởi động lại, rung, giọng tiếng Việt, TTS và lưu PDF. Không đánh dấu app hoàn thiện end-to-end trên máy thật.

Các dữ liệu dời trùng ngày đã được tạo bởi phiên bản cũ không được tự di trú trong lượt này. Chính sách chặn áp dụng cho thao tác dời/Undo mới; nếu project có dữ liệu trùng từ trước, cần kiểm tra và giải quyết các ngoại lệ đó trước nghiệm thu.
