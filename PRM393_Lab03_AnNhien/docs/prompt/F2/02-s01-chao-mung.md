# Bước 02 · F2 · S01 Chào mừng – chọn cỡ chữ

Bạn là AI agent làm bước 02 của feature **F2 – Onboarding của Bác**. Bước 01 (service + khung ViewModel) đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Màn đầu tiên Bác thấy: chọn cỡ chữ Vừa / Lớn / Rất lớn, chữ toàn app đổi **ngay khi chạm**, bấm "Bắt đầu" sang S02.

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

`CLAUDE.md`, `docs/design-traceability.md` mục F2, `lib/viewmodels/onboarding_view_model.dart`, `lib/services/settings_service.dart`, `lib/theme/display_settings.dart`, `lib/widgets/choice_group.dart` (`previewScale`), `lib/widgets/app_button.dart`, `lib/router/app_router.dart` (dòng `/welcome`), `lib/screens/today/` (màn mẫu), `flutter-handoff.md` mục S01, `ux/user-flow.md` Flow 1, `docs/analytics-plan.md` (`font_size`).

## Figma

| Khung | Node | Lấy gì |
| --- | --- | --- |
| S01 Chào mừng – chọn cỡ chữ | `1:2` | Logo, tiêu đề "An Nhiên", câu mô tả, 3 lựa chọn cỡ chữ có chữ mẫu, nút "Bắt đầu" |

## Việc cần làm

1. `OnboardingViewModel`: `selectFontScale(AppFontScale)` → cập nhật `fontScaleProvider` (để toàn app đổi ngay) **và** gọi `SettingsService.setFontScale`. Mặc định "Lớn" (theo F0 / Figma). Lưu lỗi thì giữ lựa chọn trên máy, không chặn Bác (ghi `CrashService.recordError` non-fatal).
2. Tạo `lib/screens/onboarding/welcome_screen.dart` (S01): `ChoiceGroup<AppFontScale>` 3 lựa chọn, mỗi lựa chọn hiện chữ mẫu đúng cỡ; nút chính "Bắt đầu" → `context.go('/setup')`. Không có nút Quay lại (màn gốc). Nội dung cuộn được khi chữ ×2.0, nút "Bắt đầu" luôn thấy.
3. Màn này không tải dữ liệu nên không cần Loading / Empty / Error; ghi rõ lý do trong comment đầu file.
4. Thay đúng dòng placeholder `/welcome` trong `app_router.dart` bằng `WelcomeScreen` (chỉ dòng đó).
5. Test ViewModel: chọn cỡ → `fontScaleProvider` đổi + Fake nhận đúng giá trị; Fake lỗi → không ném ra View. Test widget: 360 / 412 dp × `textScaler` 1.3 / 2.0 không tràn.
6. Đổi S01 sang `doing` trong `docs/design-traceability.md`.

Được sửa: `lib/screens/onboarding/`, `lib/viewmodels/onboarding_view_model.dart`, dòng `/welcome` trong `app_router.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- `/welcome` hiện S01 đúng Figma, chạm lựa chọn thì chữ đổi ngay, "Bắt đầu" sang `/setup`.
- In cho người dùng: ảnh chụp cần chụp (360 dp, 3 mức cỡ chữ), lệch Figma nếu có.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 02/11/2026
- File đã tạo / sửa:
  - Tạo: `lib/screens/onboarding/welcome_screen.dart` (S01), `test/welcome_screen_test.dart`.
  - Sửa: `lib/viewmodels/onboarding_view_model.dart` (`selectFontScale` đổi `fontScaleProvider` ngay rồi gọi `SettingsService.setFontScale`, lỗi → `CrashService.recordError` reason `save_font_scale`, không ném ra View; `load()` áp cỡ đã lưu cho toàn app nhưng không ghi đè nếu Bác đã chạm chọn), `lib/router/app_router.dart` (chỉ dòng `/welcome` + 1 import), `test/f2_view_models_test.dart` (+4 test S01), `docs/design-traceability.md` (S01 → `doing`, thêm DT-23), `docs/architecture.md` mục 7.2.
  - Figma: đã lấy `get_design_context` + ảnh node `1:2` qua Figma MCP. Không tải asset SVG: icon theo `AppIcons` / Material (DT-09).
  - Analytics: S01 không có event riêng; `font_size` gửi trong `tutorial_complete` ở bước 06.
- Lệch Figma (nếu có, lý do): DT-23 – logo `IconCircle` 112 / 64 (Figma 72 / 40); icon "Cỡ chữ" là Material `text_fields`; icon mũi tên của "Bắt đầu" bên trái chữ (`AppButton`); "Xem thử" là nhãn; câu mẫu xuống 2 dòng do cả app phóng ×1.15; ở 360 × 800 cỡ "Lớn" ô "Rất lớn" bị thanh nút che một phần, cần cuộn. Lý do: chỉ dùng widget trong `lib/widgets/`. Ngoài ra "Đang chọn" + dấu tích đã có ở DT-15.
- `flutter analyze` / `flutter test`:
  - `flutter analyze`: 1 warning có sẵn (`pendingNotification` không dùng, `lib/router/app_router.dart:33`), không do bước này.
  - Test F2 (`f2_services_test`, `f2_view_models_test`, `welcome_screen_test`): 28/28 qua – gồm 360 / 412 dp × `textScaler` 1.3 / 2.0 không tràn và nút "Bắt đầu" luôn trong màn.
  - `flutter test` toàn bộ: +161 −68. 68 lỗi giống hệt trước bước này (auth_routing, router, text_scale_overflow, theme – xem bước 01).
  - Đã render thử 3 cỡ chữ ở 360 dp bằng font Be Vietnam Pro thật (ảnh tạm, không commit) và so với ảnh Figma.
- Việc người dùng cần làm tay:
  - Chụp ảnh trên máy ảo 360 dp ở 3 mức Vừa / Lớn / Rất lớn (`flutter run`, vào `/welcome` – khối `redirect` đang comment nên vào thẳng được).
  - Báo Sanh (F0): thêm tham số cỡ cho `IconCircle` (logo 72 / icon 40) và icon `type` vào `AppIcons` để bỏ được một phần DT-23; sửa Figma hoặc nhóm chốt các điểm còn lại của DT-23.
- Commit gợi ý: `feat(F2): màn S01 Chào mừng – chọn cỡ chữ, đổi chữ toàn app ngay khi chạm`
