# Bước 01 · F2 · Service onboarding + khung ViewModel

Bạn là AI agent làm bước 01 của feature **F2 – Onboarding của Bác (Flow 1)** cho app An Nhiên (Flutter, MVVM + Riverpod, go_router). F0 đã merge vào `main`. Đọc hết file này rồi thực hiện.

## Mục tiêu

Có đủ service (interface + bản Fake) và khung 3 ViewModel để các bước 02–06 chỉ còn vẽ màn. Chạy được hoàn toàn bằng Fake, không cần mạng.

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

`CLAUDE.md`, `docs/architecture.md` mục 7.1 (điều kiện chặn `onboarded`), 8 (service), 9 (ViewModel ↔ service), 10 (`users/{uid}`), 15; `docs/analytics-plan.md`; `lib/services/*.dart` (đặc biệt `task_repository.dart`, `analytics_service.dart`, `providers.dart` – chỉ đọc); `lib/models/*.dart`; `lib/viewmodels/today_view_model.dart`, `ui_state.dart`; `test/today_view_model_test.dart`; `lib/theme/display_settings.dart` (`AppFontScale`, `fontScaleProvider`); `lib/utils/app_error.dart`.

Figma: không cần cho bước này.

## Việc cần làm

1. **Kiểm tra trùng trước**: tìm trong repo (và `git branch -a` + `git log --all -S "SettingsService"`) xem `SettingsService`, `ProfileService`, `ReminderService` đã có ở nhánh nào chưa (F8 – Sanh, F4 / F6 – Khang cũng dùng). Có rồi thì **dừng lại báo**, dùng bản đó, không viết bản thứ hai.
2. Tạo interface + Fake theo `architecture.md` mục 8.2 (mỗi service một file trong `lib/services/`, kiểu giống `task_repository.dart`):
   - `SettingsService`: `Stream<AppSettings> watch()`, `setFontScale(AppFontScale)`, `setHighContrast(bool)`, `setReadAloud(bool)`, `setVibrate(bool)`.
   - `ProfileService`: `Stream<UserProfile?> watch()`, `save(UserProfile)`, `setRole(String)`, `markOnboarded()`.
   - `ReminderService`: `Future<bool> requestPermission()`, `Future<bool> hasPermission()`, `schedule(TaskItem)`, `cancel(String id)`, `snooze(String id, int minutes)`, `Future<void> showTest()`. Không thêm package (`flutter_local_notifications` để Hiếu / Khang đề xuất sau).
   - Bản Fake: dữ liệu trong bộ nhớ, có độ trễ nhỏ như `FakeTaskRepository`; có cờ để test bật nhánh lỗi / từ chối, ví dụ `FakeReminderService(permissionGranted: false)`, `FakeProfileService(failOnSave: true)` ném `AppException` có `userMessage` tiếng Việt cho Bác.
3. Model cần cho `ProfileService` / `SettingsService` (`UserProfile`: `displayName`, `honorific` Ông / Bà / Bác, `wakeTime`, `onboarded`, `role`; `AppSettings`: `fontScale`, `highContrast`, `readAloud`, `vibrate`) – đúng các trường `users/{uid}` trong mục 10. `lib/models/` là của Hiếu: **hỏi người dùng** đặt ở `lib/models/` (đề xuất trong PR cho Hiếu chốt) hay tạm trong file service. Có `fromMap` / `toMap`.
4. Provider: đề xuất 3 dòng `settingsServiceProvider`, `profileServiceProvider`, `reminderServiceProvider` trỏ **bản Fake** (ghi `// TODO(Hiếu): bản Firebase`). `providers.dart` là của Hiếu → **hỏi người dùng trước khi sửa**; nếu không được sửa thì dừng và in đoạn code để người dùng gửi Hiếu.
5. Tạo khung 3 ViewModel trong `lib/viewmodels/` (Riverpod `Notifier`, chỉ state + hàm rỗng có `// TODO bước 0x`): `onboarding_view_model.dart` (S01, S02, DLG-WakeTime, S13, S13d), `try_reminder_view_model.dart` (N01–N03), `first_task_view_model.dart` (N04, N05, N18). Định nghĩa trước kiểu state của mỗi ViewModel (sealed class hoặc `UiState<…>` + trường bước) để các bước sau chỉ việc điền.
6. Test service Fake + test khung ViewModel trong `test/` (override bằng `overrideWithValue(Fake…)`): Fake lưu rồi `watch()` phát lại đúng; cờ lỗi ném `AppException`.
7. Cập nhật `docs/architecture.md` mục 8 (3 service chuyển lên "Đã có (Fake)"), mục 9 (cột "Có sẵn" cho 3 ViewModel = khung).

Được sửa: `lib/services/` (file mới: interface + Fake), `lib/viewmodels/` (3 file mới), `test/`, `docs/architecture.md`; `lib/models/` và `providers.dart` chỉ khi người dùng đồng ý.

## Đầu ra mong đợi

- 3 service có interface + Fake, test qua; 3 ViewModel khung build được.
- In cho người dùng: bảng service | hàm | Fake có cờ gì; danh sách việc cần Hiếu làm (bản Firebase, trường Firestore mới nếu có).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 02/11/2026
- File đã tạo / sửa:
  - Kiểm tra trùng: `ProfileService` **đã có** (Hiếu, commit 8167e6b, có cả bản Firebase) → dùng lại, không viết bản thứ hai. Hàm hiện có: `ensureProfile`, `watch(uid)`, `setRole`, `markOnboarded(uid)`; **chưa có** hàm lưu hồ sơ S02. `SettingsService`, `ReminderService` chưa có ở nhánh nào (chỉ có trong docs) → đã tạo.
  - Tạo: `lib/models/app_settings.dart` (người dùng đồng ý đặt ở `lib/models/`, Hiếu chốt trong PR), `lib/services/settings_service.dart`, `lib/services/reminder_service.dart`, `lib/viewmodels/onboarding_view_model.dart`, `lib/viewmodels/try_reminder_view_model.dart`, `lib/viewmodels/first_task_view_model.dart`, `test/f2_services_test.dart`, `test/f2_view_models_test.dart`.
  - Sửa: `lib/services/providers.dart` (người dùng đồng ý; chỉ thêm 2 import + `settingsServiceProvider`, `reminderServiceProvider` trỏ Fake, có `TODO(Hiếu)`), `docs/architecture.md` mục 8.1 / 8.2 / 9.
  - Không sửa `profile_service.dart`, `firebase_profile_service.dart`, `user_profile.dart` (người dùng chọn gửi đề xuất cho Hiếu).
- Lệch Figma (nếu có, lý do): không (bước này không vẽ màn). Giờ mặc định (thức dậy 6:00, việc đầu tiên 7:00) là tạm, có TODO đối chiếu Figma ở bước 03 / 06.
- `flutter analyze` / `flutter test`:
  - `flutter analyze`: 1 warning **có sẵn**, không do bước này – `unused_local_variable 'pendingNotification'` ở `lib/router/app_router.dart:32` (từ commit 8f29e6f). File mới sạch.
  - `flutter test test/f2_services_test.dart test/f2_view_models_test.dart`: 17/17 qua.
  - `flutter test` toàn bộ: 68 lỗi **có sẵn** ở `auth_routing_test` (9), `router_test` (44), `text_scale_overflow_test` (14), `theme_test` (1) – đã kiểm tra bằng cách tạm bỏ thay đổi `providers.dart`: vẫn đúng 68 lỗi (+5 / −68) ở 4 file này. Nguyên nhân thấy được: `router_test` tìm chữ placeholder ("C01 · F1"…) nhưng `app_router.dart` đã bị viết lại; timer chờ 0.8 s còn treo. Không sửa (ngoài phạm vi).
  - `dart format`: chỉ chạy cho các file của bước này để không đổi định dạng file người khác.
- Việc người dùng cần làm tay:
  - Gửi Hiếu: (1) thêm hàm lưu hồ sơ S02 vào `ProfileService` + Fake + Firebase, ví dụ `Future<void> saveSetup(String uid, {required String displayName, required String honorific, required int wakeHour, required int wakeMinute})`, ghi `users/{uid}.displayName / honorific / wakeTime`; (2) thêm `honorific`, `wakeTime` vào `UserProfile` (`fromMap` / `copyWith`), chốt định dạng `wakeTime` (đề xuất chuỗi `"HH:mm"`); (3) chốt `lib/models/app_settings.dart` + viết `FirebaseSettingsService` (`fontScale` lưu số 1.0 / 1.15 / 1.3); (4) bản thật `ReminderService` (cần package `flutter_local_notifications` – Hiếu / Khang đề xuất); (5) xem 68 test lỗi sẵn ở router / auth.
  - Bước 03 (S02) bị chặn ở `submitProfile()` cho tới khi có (1) + (2).
- Commit gợi ý: `feat(F2): thêm SettingsService, ReminderService (Fake) và khung ViewModel onboarding`
