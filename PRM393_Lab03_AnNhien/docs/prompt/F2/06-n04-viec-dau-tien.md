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

- Ngày chạy: 02/11/2026
- File đã tạo / sửa:
  - Hỏi người dùng 2 lần: (1) N04 dùng **9 thói quen** từ `HabitRepository` (model `Habit` chưa có `suggestions[]`, không hard-code); (2) N05 **chỉ đổi giờ**, ngày = hôm nay, nhịp = mỗi ngày (chỉ xem), không làm "Tự đặt tên việc".
  - Tạo: `lib/screens/onboarding/first_task_screen.dart` (N04 / N05 / N18 theo `FirstTaskData.step`; Loading / Empty / Error + Thử lại khi nạp gợi ý), `test/first_task_screen_test.dart`.
  - Sửa: `lib/viewmodels/first_task_view_model.dart` – `pick`, `confirmPick`, `backToPick`, `setTime` (mặc định 9:00 sáng theo Figma N05), `save()` (`TaskRepository.save` việc lặp mỗi ngày → N18; lỗi → `saveError` + `CrashService.recordError`, giữ lựa chọn; log `add_task` `{habit_key, repeat, source: first_task, duration_sec}`; đã cho phép nhắc việc thì `ReminderService.schedule`), `finish()` (`ProfileService.markOnboarded(uid)` + log `tutorial_complete` `{font_size: vua/lon/rat_lon, notifications_on, has_first_task}`; dùng cho "Xem lịch", "Thêm việc khác" và "Để sau" ở N04; lỗi → `saveError`, không log). `notifications_on` = cờ S13 hoặc quyền thật của máy. Dòng `/setup/first-task` + import trong `app_router.dart`. `test/f2_view_models_test.dart` (+6 test, `RecordingAnalytics` ghi cả tham số, `FlakyTaskRepository`). `docs/design-traceability.md` (N04, N05, N18 → `doing`, DT-27; N19 giữ `todo`), `docs/architecture.md` (mục 7.2, 9).
  - Figma: `get_design_context` + ảnh cho `38:2`, `38:108`, `47:170`; ảnh `47:225` (N19) để đối chiếu.
- Lệch Figma (nếu có, lý do): DT-27 – N04 là 9 thói quen (tên + mô tả), không có thẻ "Tự đặt tên việc", không có thanh tab; N05 chỉ đổi giờ, "Ngày bắt đầu: Hôm nay" / "Nhịp nhắc: Mỗi ngày" chỉ xem (Figma N05 "Một lần" ≠ N18 "Mỗi ngày"); N18 không có "Nhắc trước 10 phút" (`TaskItem` chưa có trường), vòng icon 112; lỗi lưu → câu lỗi + "Thử lại".
- `flutter analyze` / `flutter test`:
  - `flutter analyze`: 1 warning có sẵn (`pendingNotification`, `app_router.dart`).
  - Test F2: `f2_view_models_test` + `first_task_screen_test` 46/46 qua – gồm N04 / N05 / N18 × 360 / 412 dp × `textScaler` 1.3 / 2.0 không tràn; lưu đúng dữ liệu + `add_task` chỉ khoá / số; lưu lỗi giữ lựa chọn; `finish()` → `onboarded == true` + `tutorial_complete` đúng tham số, không chứa tên Bác / tên việc; "Để sau" → `has_first_task: false`; `markOnboarded` lỗi → không log.
  - `flutter test` toàn bộ: +223 −68 (68 lỗi có sẵn như các bước trước). Lần chạy đầu ra −72: 4 lỗi do chính test N04 (chữ "Mỗi ngày" xuất hiện 2 lần sau khi đổi dòng phụ của `TaskRow`) – đã sửa.
  - Chỉ `dart format` file của F2. Đã render N04 / N05 / N18 ở 360 dp bằng font thật để so với Figma (ảnh tạm, không commit).
- Việc người dùng cần làm tay:
  - **Nhờ Hiếu**: (1) `FirebaseTaskRepository.save()` / `tasksForDay()` hiện **luôn ném** "Lịch đang chờ thống nhất dữ liệu ngày và lặp lại." → trên máy thật N05 luôn báo lỗi và Hôm nay không tải được cho tới khi chốt schema `TaskItem` (ngày bắt đầu, lặp, `remindBeforeMin`). (2) Bỏ comment khối `redirect` và thêm điều kiện mục 7.1: `role == null` → `/role`; Bác chưa `onboarded` → `/welcome`; đã `onboarded` thì không vào lại `/welcome` – hiện "mở lại app không hỏi lại" mới đúng ở mức ViewModel (`markOnboarded`), chưa ở router. (3) Gộp `ProfileSetupService` vào `ProfileService` (bước 03). (4) Thêm `Habit.suggestions` (Firestore `habits/{key}.suggestions[]`) để N04 khớp Figma. (5) Bản thật `ReminderService` (cùng Khang).
  - **Nhờ Khang (N19)**: S03 khi chỉ có đúng 1 việc vừa thêm (Figma `47:225`): lời chào "Chào buổi sáng, Bác {tên}", thẻ "Việc tiếp theo" + "Dời lại", danh sách "Việc hôm nay" 1 dòng, nút "Thêm việc khác" và nút đáy "Đã xong". `TodayViewModel` đọc cùng `TaskRepository` nên việc vừa lưu sẽ hiện khi S03 tải lần đầu; nếu S03 đã được tạo trước đó thì cần gọi lại `load()` khi quay về (F2 không sửa `today_view_model.dart`). `/today/add` (S05) vẫn là placeholder.
  - Thử cả luồng bằng Fake: `/welcome` → `/setup` → `/setup/notifications` → `/setup/try-reminder` → `/setup/first-task` → "Lưu việc" → "Xem lịch". Muốn lưu được trên máy cần tạm đổi `taskRepositoryProvider` sang `FakeTaskRepository()` (nhớ trả lại trước khi commit).
- Commit gợi ý: `feat(F2): màn N04–N18 chọn và lưu việc đầu tiên, markOnboarded + tutorial_complete`
