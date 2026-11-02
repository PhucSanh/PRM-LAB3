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

- Ngày chạy:
- File đã tạo / sửa:
- Lệch Figma (nếu có, lý do):
- `flutter analyze` / `flutter test`:
- Việc người dùng cần làm tay:
- Commit gợi ý:
