# Bước 06 · F2 · N04 → N05 → N18 → N19 Việc đầu tiên

Bạn là AI agent làm bước 06 của feature **F2 – Onboarding của Bác**. Bước 01–05 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Bác chọn một việc đầu tiên (theo thói quen Power 9), xem lại giờ, lưu. Xong thì đánh dấu đã onboarding, ghi `tutorial_complete`, về Hôm nay thấy việc vừa thêm (N19). Mở lại app không hỏi lại.

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

`CLAUDE.md`, `docs/design-traceability.md` mục F2 + F3 (dòng N19), `docs/architecture.md` mục 4, 7.1, 9 (dòng `TodayViewModel` – chủ là Khang), `lib/viewmodels/first_task_view_model.dart`, `onboarding_view_model.dart`, `lib/services/task_repository.dart`, `habit_repository.dart`, `profile_service.dart`, `lib/models/task_item.dart`, `habit.dart`, `lib/widgets/habit_widgets.dart`, `task_widgets.dart`, `time_field.dart`, `docs/analytics-plan.md` (`tutorial_complete`, `add_task` với `source: first_task`), `vocabulary.md`.

## Figma

| Khung | Node | Loại | Lấy gì |
| --- | --- | --- | --- |
| N04 Chọn việc đầu tiên | `38:2` | Màn | Danh sách việc gợi ý theo thói quen, chọn một |
| N05 Xem lại việc đầu tiên | `38:108` | Màn | Tên việc, thói quen, giờ (đổi được), nút lưu |
| N18 Đã lưu việc đầu tiên | `47:170` | State | Xác nhận đã lưu, nút về Hôm nay |
| N19 Hôm nay · việc đầu tiên | `47:225` | State của S03 | Hôm nay có đúng 1 việc vừa thêm |

N04 → N05 → N18 cùng route `/setup/first-task` (chuyển bằng state, Quay lại trong màn đưa về state trước). N19 là state của S03 (`/today`, `TodayViewModel` của Khang).

## Việc cần làm

1. `FirstTaskViewModel`: tải danh sách gợi ý (từ `HabitRepository.all()`, **không** hard-code 9 thói quen) → `UiState` Loading / Empty / Error + "Thử lại" / Data; `pick(habitKey hoặc việc mẫu)` → N05; `setTime(TimeOfDay)` (mặc định theo Figma / giờ thức dậy đã lưu); `Future<bool> save()` → `TaskRepository.save`, log `add_task` (`habit_key`, `repeat`, `source: "first_task"`, `duration_sec`), lỗi → state lỗi + `CrashService.recordError`, không mất lựa chọn; xong → N18.
2. `finish()` (từ N18): `ProfileService.markOnboarded()`, log `tutorial_complete` với `font_size` (`vua` / `lon` / `rat_lon`), `notifications_on` (bool, từ bước 04), `has_first_task` (bool). Nếu Bác bỏ qua việc đầu tiên (Figma có lối bỏ qua thì làm) vẫn `markOnboarded` với `has_first_task: false`. Thông tin font / quyền đọc từ `OnboardingViewModel` hoặc `SettingsService` – không dựng singleton toàn cục.
3. Tạo `lib/screens/onboarding/first_task_screen.dart` vẽ N04 / N05 / N18. N18 → `context.go('/today')`.
4. **N19 (S03 có việc đầu tiên)**: không sửa `lib/screens/today/` hay `today_view_model.dart` của Khang. Chạy thử: Hôm nay có tải lại và hiện việc vừa lưu không (cùng `TaskRepository`). Nếu cần thêm state / thẻ chào cho N19 thì **chỉ ghi lại** việc cần nhờ Khang (state gì, khung Figma nào) vào "Kết quả chạy".
5. **Mở lại app không hỏi lại**: kiểm tra khối `redirect` (Hiếu) có đọc `onboarded` chưa. Không sửa `redirect`; nếu chưa có thì ghi việc cần nhờ Hiếu. Test ở mức ViewModel: sau `finish()` thì Fake profile có `onboarded == true`.
6. Thay dòng placeholder `/setup/first-task` trong `app_router.dart`.
7. Test ViewModel: tải gợi ý Loading → Data / Empty / Error → Thử lại; lưu thành công gọi `save` đúng dữ liệu + event `add_task`; lưu lỗi giữ lựa chọn; `finish()` gọi `markOnboarded` + `tutorial_complete` đúng tham số và **không** chứa tên Bác / tên việc tự gõ. Test widget 360 / 412 dp × 1.3 / 2.0.
8. Đổi N04, N05, N18 sang `doing`; N19 giữ nguyên nếu chưa xong phần của Khang.

Được sửa: `lib/screens/onboarding/`, `lib/viewmodels/first_task_view_model.dart`, `onboarding_view_model.dart`, dòng `/setup/first-task` trong `app_router.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- Đi được S01 → S02 → S13 → N01 → N04 → N05 → N18 → Hôm nay bằng Fake.
- In cho người dùng: danh sách việc cần nhờ Khang (N19) và Hiếu (`redirect` theo `onboarded`, bản Firebase của service, trường Firestore).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy:
- File đã tạo / sửa:
- Lệch Figma (nếu có, lý do):
- `flutter analyze` / `flutter test`:
- Việc người dùng cần làm tay:
- Commit gợi ý:
