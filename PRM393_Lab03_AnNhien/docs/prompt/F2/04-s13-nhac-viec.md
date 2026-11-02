# Bước 04 · F2 · S13 Cho phép nhắc việc (Bước 2/2) + S13d

Bạn là AI agent làm bước 04 của feature **F2 – Onboarding của Bác**. Bước 01–03 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Giải thích vì sao cần thông báo, xin quyền. Cho phép → sang thử lời nhắc (N01). Từ chối → hiện S13d, Bác vẫn đi tiếp được, biết cách bật lại sau.

## Quy tắc chung (áp dụng cho mọi bước)

- Làm việc ở thư mục gốc repo `PRM393_Lab03_AnNhien`, nhánh `feat/F2-onboarding`. Đọc `CLAUDE.md` trước tiên và tuân theo.
- Figma file key `K3JczHkChbUWoDBkXZYMhR`. Nếu có Figma MCP: gọi `get_design_context` + `get_screenshot` cho từng node được liệt kê. Nếu không có: dùng Stitch / Codex HTML ở `../../prm393-lab2-an-nhien/stitch-runs/<mã màn>/` hoặc `codex-runs/<mã màn>/` (bản `v` số lớn nhất, xem cột Stitch trong `docs/design-traceability.md`). Figma lệch Stitch thì **Figma thắng**.
- Tài liệu Lab 2 (chỉ đọc) ở `../../prm393-lab2-an-nhien/`: `flutter-handoff.md`, `ux/user-flow.md` (Flow 1), `rule.md`, `accessibility.md`, `assets/stitch/DESIGN.md`, `assets/stitch/AppStyleGuide.md`, `assets/stitch/vocabulary.md`.
- **Chỉ dùng widget trong `lib/widgets/`** (`AppButton`, `AppBackBar`, `AppTextField`, `TimeField` / `showTimeWheel`, `ChoiceGroup`, `SwitchRow`, `HabitTile`, `TaskRow`, `showConfirmDialog`, `showUndoSnackbar`, `LoadingView` / `EmptyView` / `ErrorView`, `IconCircle`…). Thiếu widget thì **dừng lại báo**, không tự làm bản riêng trong thư mục màn.
- **Không được sửa**: `android/`, `firebase/`, `lib/theme/`, `lib/widgets/`, bản `Firebase…` của service, `lib/main.dart`, màn / ViewModel của người khác (nhất là `lib/screens/today/`, `today_view_model.dart` của Khang). `lib/services/providers.dart` và `lib/models/` là của Hiếu: muốn sửa thì **hỏi người dùng trước**. Không thêm package.
- Kiến trúc: View chỉ vẽ `UiState` bằng `switch` và gửi sự kiện; logic, validate, gọi service, log analytics nằm trong ViewModel (`Notifier`). Hành động một lần (lưu, xin quyền…) trả kết quả về View để điều hướng / hiện Snackbar. Không gọi `FirebaseXxx.instance` trong widget.
- Không viết cứng màu / cỡ chữ / khoảng cách: chỉ dùng `lib/theme/` (màu qua `Theme.of(context).colorScheme` để tương phản cao có tác dụng). Chữ ≥ 20 sp, vùng chạm ≥ 72 dp, cách nhau `AppSpacing.betweenTargets`; kiểm tra 360 và 412 dp, `textScaler` 1.3 và 2.0 không tràn.
- Câu chữ theo `AppStyleGuide.md` + `vocabulary.md` (gọi người dùng là "Bác", nút = động từ + việc, lỗi có "Ví dụ: …").
- Analytics chỉ gửi khoá / số / cờ (không gửi tên, số điện thoại, tên việc tự gõ). Tên event theo `docs/analytics-plan.md`.
- Gặp chỗ không chắc (thiếu file, Figma mâu thuẫn tài liệu, cần sửa file ngoài phạm vi) thì **dừng lại hỏi**, không đoán.
- Docs: màn đang làm thì đổi cột Trạng thái trong `docs/design-traceability.md` mục F2 từ `todo` → `doing` (bước 07 mới chốt `done` / `changed`). Lệch Figma thì thêm dòng `DT-xx` (số tiếp theo) cuối file. Thêm / đổi service, ViewModel, route thì cập nhật `docs/architecture.md` (mục 7, 8, 9).
- Không tự `git commit` / `push`. Chạy `dart format lib test`, `flutter analyze` và `flutter test` tới khi sạch rồi mới báo xong (`auth_routing_test` có thể lỗi sẵn nếu khối `redirect` đang comment – ghi lại, không sửa).
- Xong việc: điền mục **"Kết quả chạy"** ở cuối chính file này (thay các dòng trống), rồi in tóm tắt cho người dùng.

## Đọc trước

`CLAUDE.md`, `docs/design-traceability.md` mục F2, `lib/viewmodels/onboarding_view_model.dart`, `lib/services/reminder_service.dart`, `lib/services/messaging_service.dart` (chỉ đọc – FCM của Hiếu, **không** gộp với quyền nhắc việc cục bộ nếu chưa hỏi), `lib/widgets/icon_circle.dart`, `app_button.dart`, `app_back_bar.dart`, `docs/analytics-plan.md` (`notifications_on`), `AppStyleGuide.md`.

## Figma

| Khung | Node | Loại | Lấy gì |
| --- | --- | --- | --- |
| S13 Cho phép nhắc việc (Bước 2/2) | `1:217` | Màn | Icon chuông, tiêu đề, lý do, nút cho phép + nút phụ |
| S13d Nhắc việc đang tắt | `14:284` | State | Báo đang tắt, cách bật lại, nút đi tiếp |

## Việc cần làm

1. `OnboardingViewModel` cho S13: khi vào màn gọi `ReminderService.hasPermission()` (đã có quyền thì đi thẳng tiếp); `Future<PermissionResult> allowReminders()` gọi `requestPermission()` → `granted` / `denied`; `skipReminders()`. Lưu cờ `notificationsOn` để bước 06 gửi trong `tutorial_complete`.
2. Tạo `lib/screens/onboarding/notifications_screen.dart`: vẽ S13 và S13d (cùng route `/setup/notifications`, chọn theo state). Cho phép → `context.go('/setup/try-reminder')`. Từ chối hoặc "Để sau" → S13d; từ S13d nút đi tiếp → `context.go('/setup/first-task')` (bỏ qua thử lời nhắc vì không có quyền). Câu chữ đúng Figma / style guide; không trách Bác.
3. Nút mở cài đặt hệ thống (nếu Figma có): cần package `app_settings` / `permission_handler` → **không thêm**, dừng hỏi người dùng; tạm làm hướng dẫn bằng chữ và ghi DT-xx.
4. Thay dòng placeholder `/setup/notifications` trong `app_router.dart`.
5. Test ViewModel: Fake cho phép → `granted`; Fake từ chối → state S13d; đã có quyền sẵn → bỏ qua S13. Test widget 360 / 412 dp × 1.3 / 2.0.
6. Đổi S13, S13d sang `doing`.

Được sửa: `lib/screens/onboarding/`, `lib/viewmodels/onboarding_view_model.dart`, dòng `/setup/notifications` trong `app_router.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- Cả hai nhánh cho phép / từ chối chạy được bằng Fake (đổi cờ Fake để thử).
- In cho người dùng: cách thử từng nhánh, lệch Figma nếu có, việc cần Hiếu / Khang (bản thật của `ReminderService`).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 02/11/2026
- File đã tạo / sửa:
  - Tạo: `lib/screens/onboarding/notifications_screen.dart` (S13 + S13d theo `OnboardingData.step`), `test/notifications_screen_test.dart`.
  - Sửa: `lib/viewmodels/onboarding_view_model.dart` – `checkPermission()` (có quyền sẵn → `true`, chỉ tự đi tiếp ở **lần vào đầu** để "Quay lại" từ N01 không bị đẩy đi lại), `allowReminders()` → `granted` / `denied` (từ chối → `notificationsDenied`; lỗi service → coi như từ chối + `CrashService.recordError`), `skipReminders()` → S13d, `showReminderPrompt()` (Quay lại ở S13d → S13); cờ `notificationsOn` lưu sẵn cho `tutorial_complete` ở bước 06. Dòng `/setup/notifications` + import trong `app_router.dart`; `test/f2_view_models_test.dart` (+5 test S13); `docs/design-traceability.md` (S13, S13d → `doing`, DT-25); `docs/architecture.md` (mục 7.2, 9).
  - Hỏi người dùng 2 lần: (1) nút "Bật nhắc việc" ở S13d → **hỏi lại quyền**, không thêm package mở cài đặt hệ thống; (2) hộp gợi ý vàng (chưa có `InlineHint`) → dùng `FieldMessage.hint` có sẵn.
  - Không gộp với `MessagingService.requestPermission()` (FCM của Hiếu) – S13 chỉ dùng `ReminderService`.
  - Figma: `get_design_context` + ảnh cho `1:217`, `14:284`.
- Lệch Figma (nếu có, lý do): DT-25 – hộp gợi ý dùng `FieldMessage.hint` (không nền vàng); câu dặn "Bác bấm Cho phép" đưa lên trước thẻ ví dụ để luôn thấy trước khi điện thoại hỏi; vòng icon 112 / 64; S13d vòng nền `errorContainer` (theo handoff); thẻ ví dụ bằng `HabitAccentCard` + `HabitBadge`; icon nút theo `AppIcons`, nút cao 72; "Bật nhắc việc" ở S13d chỉ hỏi lại quyền.
- `flutter analyze` / `flutter test`:
  - `flutter analyze`: 1 warning có sẵn (`pendingNotification`, `app_router.dart`).
  - Test F2 (5 file): 60/60 qua – gồm S13 + S13d × 360 / 412 dp × `textScaler` 1.3 / 2.0 không tràn, nút đáy luôn thấy; cho phép → `/setup/try-reminder`; từ chối → S13d → "Vẫn để sau" → `/setup/first-task`; có quyền sẵn → đi thẳng, không hỏi.
  - `flutter test` toàn bộ: +193 −68 (68 lỗi có sẵn như các bước trước).
  - Chỉ `dart format` file của F2. Đã render S13 / S13d ở 360 dp bằng font thật để so với Figma (ảnh tạm, không commit).
- Việc người dùng cần làm tay:
  - Thử từng nhánh bằng cách đổi Fake trong `providers.dart` (`reminderServiceProvider`): mặc định `FakeReminderService()` = cho phép; `FakeReminderService(permissionGranted: false)` = từ chối → S13d; `FakeReminderService(alreadyGranted: true)` = có quyền sẵn → bỏ qua S13. Đổi xong hot restart, đi `/welcome` → `/setup` → `/setup/notifications`. Nhớ trả về mặc định trước khi commit.
  - Nhờ Hiếu / Khang: bản thật `ReminderService` (flutter_local_notifications; Android 13+ quyền `POST_NOTIFICATIONS`, 14+ `USE_FULL_SCREEN_INTENT`, `SCHEDULE_EXACT_ALARM`), thêm cách mở cài đặt hệ thống khi đã bị từ chối hẳn (đề xuất `openSystemSettings()` + package trong PR). Chốt với Hiếu có gộp quyền FCM vào S13 hay không.
  - Nhờ Sanh (F0): thêm widget `InlineHint` (nền `warning-container`) + vai trò màu warning cho tương phản cao, rồi thay `FieldMessage.hint` ở S13 / S13d.
- Commit gợi ý: `feat(F2): màn S13 cho phép nhắc việc và S13d nhắc việc đang tắt`
