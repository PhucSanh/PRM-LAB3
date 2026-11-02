# Bước 03 · F2 · S02 Thiết lập hồ sơ (Bước 1/2) + DLG-WakeTime

Bạn là AI agent làm bước 03 của feature **F2 – Onboarding của Bác**. Bước 01–02 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Bác xác nhận / nhập tên gọi và giờ thức dậy, lưu hồ sơ, sang S13. Tên trống thì báo lỗi ngay dưới ô (icon + câu + ví dụ).

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

`CLAUDE.md`, `docs/design-traceability.md` mục F2, `lib/viewmodels/onboarding_view_model.dart`, `lib/services/profile_service.dart`, `lib/services/auth_service.dart` (lấy `displayName` Google để gợi ý tên – chỉ qua service / provider có sẵn), `lib/widgets/app_text_field.dart`, `time_field.dart`, `choice_group.dart`, `app_back_bar.dart`, `flutter-handoff.md` mục S02, `ux/user-flow.md` Flow 1 (nhánh lỗi tên), `AppStyleGuide.md` (câu báo lỗi có ví dụ).

## Figma

| Khung | Node | Loại | Lấy gì |
| --- | --- | --- | --- |
| S02 Xác nhận tên (trước S02) | `1:58` | State | Hỏi lại tên lấy từ tài khoản, 2 lựa chọn đúng / đổi tên |
| S02 Thiết lập hồ sơ (Bước 1/2) | `1:103` | Màn | Thanh "Quay lại · Bước 1/2", ô tên, cách gọi (nếu có), giờ thức dậy, nút "Tiếp tục" |
| S02 Nhập lại tên | `1:176` | State | Lỗi tên trống: icon + câu + "Ví dụ: …" |
| DLG-WakeTime Chọn giờ thức dậy | `31:2` | Dialog | Hộp chọn giờ (dùng `showTimeWheel`) |

Ba khung S02 là **state** của cùng route `/setup`, không tạo route mới. Ô số điện thoại người thân trong `flutter-handoff.md` S02: làm theo Figma; Figma không có thì không làm, ghi DT-xx.

## Việc cần làm

1. `OnboardingViewModel` cho S02: `UiState` khi tải tên gợi ý (Loading → Data; lỗi → Error + "Thử lại"); `confirmName()`, `editName()`, `setName(String)`, `setWakeTime(TimeOfDay)` (mặc định theo Figma), `Future<bool> submitProfile()` – validate tên (bỏ khoảng trắng, không rỗng, giới hạn độ dài theo Figma / style guide), gọi `ProfileService.save`, trả kết quả để View điều hướng. Lỗi lưu → `AppException.userMessage` + `CrashService.recordError`.
2. Tạo `lib/screens/onboarding/setup_profile_screen.dart`: vẽ 3 state theo Figma; giờ thức dậy dùng `TimeField` mở `showTimeWheel` (DLG-WakeTime); nút "Tiếp tục" không bị bàn phím che; Quay lại → `/welcome`; lưu được → `context.go('/setup/notifications')`; lưu lỗi → hiện lỗi + "Thử lại", không mất dữ liệu đã nhập.
3. Thay dòng placeholder `/setup` trong `app_router.dart`.
4. Test ViewModel (Fake): tên trống → lỗi, tên hợp lệ → `save` được gọi đúng dữ liệu, Fake lỗi → state lỗi có `userMessage`, tải tên gợi ý lỗi → `UiError` rồi "Thử lại" → `UiData`. Test widget: 360 / 412 dp × 1.3 / 2.0 không tràn, lỗi tên có `liveRegion`.
5. Đổi 4 dòng S02 / DLG-WakeTime sang `doing` trong traceability.

Được sửa: `lib/screens/onboarding/`, `lib/viewmodels/onboarding_view_model.dart`, dòng `/setup` trong `app_router.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- `/setup` chạy đủ 3 state + hộp chọn giờ, đúng Figma.
- In cho người dùng: bảng khung Figma | state trong ViewModel | lệch (nếu có).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy:
- File đã tạo / sửa:
- Lệch Figma (nếu có, lý do):
- `flutter analyze` / `flutter test`:
- Việc người dùng cần làm tay:
- Commit gợi ý:
