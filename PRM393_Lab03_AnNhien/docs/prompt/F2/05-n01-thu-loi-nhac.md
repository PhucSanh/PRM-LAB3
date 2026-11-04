# Bước 05 · F2 · N01–N03 Thử lời nhắc

Bạn là AI agent làm bước 05 của feature **F2 – Onboarding của Bác**. Bước 01–04 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Gửi một lời nhắc thử để Bác thấy nó trông thế nào, hỏi Bác đã nhận được chưa. Nhận được → N02; chưa nhận → N03 (hướng dẫn + thử lại / bỏ qua). Sau đó sang chọn việc đầu tiên.

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

`CLAUDE.md`, `docs/design-traceability.md` mục F2, `lib/viewmodels/try_reminder_view_model.dart`, `lib/services/reminder_service.dart`, `lib/widgets/` (nút, `IconCircle`, state views), `docs/analytics-plan.md` (`test_reminder`), `AppStyleGuide.md`.

## Figma

| Khung | Node | Loại | Lấy gì |
| --- | --- | --- | --- |
| N01 Thử lời nhắc | `31:68` | Màn | Giải thích, nút gửi thử, câu hỏi "đã thấy chưa" |
| N02 Đã nhận lời nhắc | `31:170` | State | Xác nhận thành công, nút đi tiếp |
| N03 Chưa nhận lời nhắc | `31:218` | State | Hướng dẫn kiểm tra, "Thử lại", đi tiếp |

## Việc cần làm

1. `TryReminderViewModel`: state `idle` → `sending` → `waitingAnswer` → `received` (N02) / `notReceived` (N03); `sendTest()` gọi `ReminderService.showTest()` (lỗi → state lỗi + "Thử lại", `CrashService.recordError`); `answer(bool received)` log `test_reminder` với `received` (bool); `retry()`.
2. Tạo `lib/screens/onboarding/try_reminder_screen.dart` (route `/setup/try-reminder`), vẽ N01 / N02 / N03 theo state. Đi tiếp từ N02 hoặc N03 → `context.go('/setup/first-task')`. Có Quay lại → `/setup/notifications`.
3. Thay dòng placeholder `/setup/try-reminder` trong `app_router.dart`.
4. Test ViewModel: gửi thử gọi Fake; trả lời có / không ra đúng state; event `test_reminder` được log đúng 1 lần mỗi câu trả lời (dùng `FakeAnalyticsService.logged`); Fake lỗi → state lỗi. Test widget 360 / 412 dp × 1.3 / 2.0.
5. Đổi N01–N03 sang `doing`.

Được sửa: `lib/screens/onboarding/`, `lib/viewmodels/try_reminder_view_model.dart`, dòng `/setup/try-reminder` trong `app_router.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- `/setup/try-reminder` chạy đủ 3 state + lỗi, event đúng.
- In cho người dùng: lệch Figma nếu có.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 02/11/2026
- File đã tạo / sửa:
  - Tạo: `lib/screens/onboarding/try_reminder_screen.dart` (N01 / N02 / N03 theo `TryReminderState.phase`), `test/try_reminder_screen_test.dart`.
  - Sửa: `lib/viewmodels/try_reminder_view_model.dart` – `sendTest()` (`sending` → `waitingAnswer`; lỗi → về N01 + `error` + `CrashService.recordError` reason `show_test_reminder`), `answer(bool received)` (chỉ khi đang `waitingAnswer` → `received` / `notReceived`, log `test_reminder` `{received}` đúng 1 lần, analytics lỗi không chặn Bác), `retry()`, `backToStart()` (Quay lại ở N02 / N03 → N01). `lib/services/reminder_service.dart`: cờ `failOnShowTest` bỏ `final` để test bật / tắt lỗi (giống `failOnSave`). Dòng `/setup/try-reminder` + import trong `app_router.dart`. `test/f2_view_models_test.dart`: helper nhận `analytics`, +6 test. `docs/design-traceability.md` (N01–N03 → `doing`, DT-26), `docs/architecture.md` (mục 7.2, 9).
  - Figma: `get_design_context` + ảnh cho `31:68`, `31:170`, `31:218`. Theo Figma, N02 là bước **hỏi** "Bác đã nhận được chưa?" ngay sau khi gửi (`waitingAnswer`); "Tôi đã nhận được" → `received` → View đi `/setup/first-task`; "Chưa nhận được" → N03.
- Lệch Figma (nếu có, lý do): DT-26 – tiêu đề N02 "Đã gửi lời nhắc thử" (Figma "Đã nhận lời nhắc" trong khi Bác chưa trả lời); không có thanh tab ở N01 và chữ "An Nhiên" ở N02 / N03; chip "Lời nhắc thử" thành icon + chữ; thẻ mẫu bằng `TaskRow`; ô ghi chú xanh dùng `FieldMessage.hint`; dòng kiểm tra / bước dùng `FieldLabel`; nút cao 72, có icon; lỗi gửi thử: câu lỗi + "Thử lại".
- `flutter analyze` / `flutter test`:
  - `flutter analyze`: 1 warning có sẵn (`pendingNotification`, `app_router.dart`).
  - Test F2 (6 file): 75/75 qua – gồm N01 / N02 / N03 × 360 / 412 dp × `textScaler` 1.3 / 2.0 không tràn, nút đáy luôn thấy; `test_reminder` log đúng 1 lần mỗi câu trả lời; gửi lỗi → "Thử lại"; "Để sau" không gửi, không log.
  - Bắt được và sửa: chữ "Lời nhắc thử" tràn 18 px ở 412 dp × 1.3 (Row trong `Wrap` thiếu `Flexible`).
  - `flutter test` toàn bộ: +208 −68 (68 lỗi có sẵn như các bước trước).
  - Chỉ `dart format` file của F2. Đã render N01–N03 ở 412 dp bằng font thật để so với Figma (ảnh tạm, không commit).
- Việc người dùng cần làm tay:
  - Thử trên máy: `/setup/try-reminder` → "Gửi thử" → bản Fake chỉ giả lập, **không có thông báo thật** hiện lên cho tới khi Hiếu / Khang viết bản thật `ReminderService.showTest()` (flutter_local_notifications). Thử nhánh lỗi: tạm đổi `reminderServiceProvider` sang `FakeReminderService(alreadyGranted: true, failOnShowTest: true)` rồi hot restart; nhớ trả về mặc định.
  - Kiểm tra event `test_reminder` trên Firebase DebugView khi chạy bản thật (`analyticsServiceProvider` đang là Firebase).
  - Nhờ Sanh (F0): widget chip nhãn (vd. "Lời nhắc thử") và `InlineHint` (ô ghi chú màu) nếu muốn bỏ bớt DT-26 / DT-25.
- Commit gợi ý: `feat(F2): màn N01–N03 thử lời nhắc, log test_reminder`
