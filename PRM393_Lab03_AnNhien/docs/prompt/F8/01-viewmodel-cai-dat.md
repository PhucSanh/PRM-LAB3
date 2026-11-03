# Bước 01 · F8 · ViewModel cài đặt + hồ sơ, nạp cài đặt khi mở app

Bạn là AI agent làm bước 01 của feature **F8 – Cài đặt hiển thị & hồ sơ** cho app An Nhiên (Flutter, MVVM + Riverpod, go_router). F0 và F2 đã merge vào `main`. Đọc hết file này rồi thực hiện.

## Mục tiêu

Có khung `SettingsViewModel` (S10) và `ProfileViewModel` (N06) chạy bằng service Fake, và cài đặt đã lưu (cỡ chữ, tương phản cao) được áp dụng cho toàn app, kể cả khi mở lại app. Các bước 02–04 chỉ còn vẽ màn.

## Quy tắc chung (áp dụng cho mọi bước)

- Làm việc ở thư mục gốc repo `PRM393_Lab03_AnNhien`, nhánh F8 hiện tại (kiểm bằng `git branch --show-current`, dạng `feat/F8-…`). Đọc `CLAUDE.md` trước tiên và tuân theo.
- Figma file key `K3JczHkChbUWoDBkXZYMhR`. Nếu có Figma MCP: gọi `get_design_context` + `get_screenshot` cho từng node được liệt kê. Nếu không có: dùng Stitch / Codex HTML ở `../../prm393-lab2-an-nhien/stitch-runs/<mã màn>/` hoặc `codex-runs/<mã màn>/` (bản `v` số lớn nhất, xem cột Stitch trong `docs/design-traceability.md`). Figma lệch Stitch thì **Figma thắng**.
- Tài liệu Lab 2 (chỉ đọc) ở `../../prm393-lab2-an-nhien/`: `flutter-handoff.md` (S10 và bảng màn mới N06 / N08 / N20), `ux/user-flow.md` (Main flow), `rule.md`, `accessibility.md`, `assets/stitch/DESIGN.md`, `assets/stitch/AppStyleGuide.md`, `assets/stitch/vocabulary.md`.
- **Chỉ dùng widget trong `lib/widgets/`** (`AppButton`, `AppBackBar`, `ChoiceGroup` (có `previewScale`), `SwitchRow`, `AppTextField`, `TimeField` / `showTimeWheel`, `showConfirmDialog`, `showUndoSnackbar`, `ReadAloudButton`, `IconCircle`, `LoadingView` / `EmptyView` / `ErrorView`, `FirebaseDemoEntry`…). Icon chỉ lấy từ `AppIcons`. Thiếu widget / icon thì **dừng lại hỏi người dùng** (người dùng là Sanh, chủ `lib/widgets/` + `lib/theme/`, sẽ quyết định thêm vào F0 trong commit riêng), không tự làm bản riêng trong thư mục màn.
- **Không được sửa**: `android/`, `firebase/`, bản `Firebase…` của service, `lib/main.dart`, màn / ViewModel của người khác: `lib/screens/account/`, `lib/screens/firebase_demo/`, `lib/screens/onboarding/`, `lib/screens/today/`, `account_view_model.dart`, `onboarding_view_model.dart`, `today_view_model.dart`… `lib/services/providers.dart`, `lib/services/*` có sẵn và `lib/models/` là của Hiếu: muốn sửa thì **hỏi người dùng trước**. `lib/app.dart`, `lib/theme/`, `lib/widgets/`: chỉ sửa khi người dùng đồng ý. Không thêm package (kể cả `flutter_tts`, `shared_preferences`).
- Kiến trúc: View chỉ vẽ `UiState` bằng `switch` và gửi sự kiện; logic, validate, gọi service, log analytics nằm trong ViewModel (`Notifier`). Hành động một lần (lưu, đăng xuất…) trả kết quả về View để điều hướng / hiện Snackbar. Không gọi `FirebaseXxx.instance` trong widget.
- Không viết cứng màu / cỡ chữ / khoảng cách: chỉ dùng `lib/theme/` (màu qua `Theme.of(context).colorScheme` để tương phản cao có tác dụng). Chữ ≥ 20 sp, vùng chạm ≥ 72 dp, cách nhau `AppSpacing.betweenTargets`; kiểm tra 360 và 412 dp, `textScaler` 1.3 và 2.0 không tràn, cả chế độ tương phản cao.
- Mọi thay đổi có **Hoàn tác** (`showUndoSnackbar`, không tự tắt). Thao tác có hậu quả (đăng xuất, bỏ thay đổi chưa lưu) phải hỏi lại và nói rõ hậu quả.
- Câu chữ theo `AppStyleGuide.md` + `vocabulary.md` (gọi người dùng là "Bác", nút = động từ + việc, lỗi có "Ví dụ: …").
- Analytics chỉ gửi khoá / số / cờ (không gửi tên, số điện thoại). Tên event theo `docs/analytics-plan.md`; **không tự đặt event mới**.
- Gặp chỗ không chắc (thiếu file, Figma mâu thuẫn tài liệu, cần sửa file ngoài phạm vi) thì **dừng lại hỏi**, không đoán.
- Docs: màn đang làm thì đổi cột Trạng thái trong `docs/design-traceability.md` mục F8 từ `todo` → `doing` (bước 05 mới chốt `done` / `changed`). Lệch Figma thì thêm dòng `DT-xx` cuối file (số tiếp theo – hiện cuối là DT-27, kiểm lại trước khi thêm). Thêm / đổi service, ViewModel, route thì cập nhật `docs/architecture.md` (mục 7, 8, 9).
- Không tự `git commit` / `push`. Trước khi sửa, chạy `flutter test` một lần và ghi lại số lỗi **có sẵn** (lúc làm F2 là 68 lỗi ở `router_test`, `text_scale_overflow_test`, `auth_routing_test`, `theme_test`); chỉ chịu trách nhiệm lỗi mới. `dart format` **chỉ cho file F8 đã tạo / sửa** (chạy `dart format lib test` sẽ định dạng lại file của người khác). Chạy `flutter analyze` và `flutter test` tới khi không có lỗi mới rồi mới báo xong.
- Xong việc: điền mục **"Kết quả chạy"** ở cuối chính file này (thay các dòng trống), rồi in tóm tắt cho người dùng.

## Đọc trước

`CLAUDE.md`; `../An-Nhien_Chia-task_Lab3.md` mục F8 (nếu không có thì đọc `docs/design-traceability.md` mục F8); `docs/architecture.md` mục 7.2, 8, 9 (dòng `SettingsViewModel`, `ProfileViewModel`), 10 (`users/{uid}`), 13, 15; `docs/analytics-plan.md` (User property `font_size`, `high_contrast`; event `change_font_size`, `logout`).

Code (chỉ đọc, trừ file được phép sửa ở dưới): `lib/services/settings_service.dart`, `lib/models/app_settings.dart`, `lib/theme/display_settings.dart` (`fontScaleProvider`, `highContrastProvider`), `lib/app.dart`, `lib/viewmodels/account_view_model.dart` (`signOutViewModelProvider` – Hiếu, đã log `logout` và xoá dữ liệu trên máy), `lib/services/profile_service.dart`, `lib/services/profile_setup_service.dart`, `lib/models/user_profile.dart`, `lib/viewmodels/onboarding_view_model.dart` (cách F2 dùng `SettingsService` / `ProfileSetupService`, khoá `vua` / `lon` / `rat_lon`), `lib/services/analytics_service.dart`, `lib/services/crash_service.dart`, `lib/services/providers.dart`, `lib/viewmodels/ui_state.dart`, `lib/utils/app_error.dart`, `test/f2_view_models_test.dart` (mẫu test).

Figma: không cần cho bước này.

## Việc cần làm

1. **Kiểm tra trùng trước**: `git branch -a` + `git log --all -S "SettingsViewModel"` / `-S "ProfileViewModel"`. Đã có ở nhánh nào thì **dừng lại báo**. `SettingsService` và `ProfileSetupService` đã có từ F2: **dùng lại, không viết service cài đặt / hồ sơ mới**.
2. **Đăng xuất**: dùng lại `signOutViewModelProvider` của Hiếu. Không viết hàm đăng xuất thứ hai, không log `logout` lần nữa.
3. **Cài đặt có được nạp khi mở app không?** Đọc `app.dart`, `display_settings.dart`, `OnboardingViewModel.load()` rồi trả lời: mở lại app (đã onboard, không qua S01) thì cỡ chữ / tương phản cao đã lưu có được áp dụng không. Nếu không:
   - Đề xuất cách nối, ưu tiên cách không sửa file người khác, ví dụ một provider trong `lib/viewmodels/` (vd. `display_settings_sync.dart`) lắng `SettingsService.watch()` và cập nhật `fontScaleProvider` / `highContrastProvider`; nói rõ nó được kích hoạt ở đâu.
   - Nếu buộc phải sửa `lib/app.dart`, `lib/theme/display_settings.dart` hoặc phần ngoài dòng route của `app_router.dart` thì **hỏi người dùng trước**, chỉ sửa đúng chỗ tối thiểu.
4. **`lib/viewmodels/settings_view_model.dart`** (S10), Riverpod `Notifier`:
   - State: `UiState<AppSettings>` – `UiLoading` khi `watch()` chưa phát, `UiError` + `retry()`, `UiData`. (Empty không áp dụng – ghi lý do trong comment.)
   - `setFontScale(AppFontScale)`: đổi `fontScaleProvider` **ngay**, rồi lưu qua `SettingsService.setFontScale`; log `change_font_size` với `from` / `to` là khoá `vua` / `lon` / `rat_lon` (giống F2); không log khi chọn lại đúng cỡ đang dùng.
   - `setHighContrast(bool)`: đổi `highContrastProvider` ngay rồi lưu. `setReadAloud(bool)`, `setVibrate(bool)`: lưu.
   - Lưu lỗi: giữ giá trị trên máy, `CrashService.recordError` (non-fatal, có `reason`), trả kết quả để View báo nhẹ bằng `userMessage`; không ném ra View.
   - Mỗi hàm đổi trả về giá trị cũ (hoặc một `SettingChange`) để View hiện `showUndoSnackbar` → `undo(change)` khôi phục và lưu lại.
5. **`lib/viewmodels/profile_view_model.dart`** (N06) – chỉ khung:
   - State: `UiState<ProfileForm>` (`displayName`, `honorific` Ông / Bà, `wakeTime`) + cờ `dirty` + lỗi tên (`nameError`) + cờ đang lưu.
   - Nguồn dữ liệu: `displayName` từ `ProfileService.watch(uid)`. **`UserProfile` hiện chưa có `honorific`, `wakeTime` và `ProfileSetupService` chỉ có `saveSetup`.** Kiểm lại; nếu vẫn vậy thì **dừng lại hỏi người dùng** chọn:
     - (a) thêm `Stream<ProfileSetup?> watchSetup(String uid)` vào interface + bản Fake của `ProfileSetupService` (người làm feature viết interface + Fake theo `CLAUDE.md`), ghi việc nhờ Hiếu viết bản Firebase; hoặc
     - (b) chờ Hiếu thêm trường vào `UserProfile` / `ProfileService`, bước 03 tạm chỉ sửa tên.
   - Hàm để trống có `// TODO bước 03`: `load()`, `changeName`, `changeHonorific`, `changeWakeTime`, `save()`, `discard()`.
6. **Test** (override bằng `overrideWithValue(Fake…)`, không mạng):
   - `test/settings_view_model_test.dart`: Fake phát giá trị → `UiData`; stream lỗi → `UiError`, `retry()` → `UiData`; `setFontScale` đổi `fontScaleProvider` + Fake nhận đúng + event `change_font_size` đúng `from` / `to`; chọn lại cỡ cũ không log; `FakeSettingsService(failOnSave: true)` → không ném, có `recordError`; `undo` trả lại giá trị cũ.
   - `test/profile_view_model_test.dart`: khung build được, `load()` ra `UiData` với Fake.
   - Nếu làm mục 3: test mở app với Fake đã lưu `ratLon` + tương phản cao → hai provider đổi theo.
7. **Docs**: `docs/architecture.md` mục 9 – cột "Có sẵn" của `SettingsViewModel` (ghi dùng `SignOutViewModel` cho Đăng xuất thay vì gọi `AuthService` trực tiếp) và `ProfileViewModel` = khung; mục 8 nếu thêm hàm vào `ProfileSetupService`.

Được sửa: `lib/viewmodels/` (file mới), `test/` (file mới), `docs/architecture.md`; `lib/services/profile_setup_service.dart` chỉ khi người dùng chọn (a); `lib/app.dart` / `lib/theme/display_settings.dart` chỉ khi người dùng đồng ý ở mục 3.

## Đầu ra mong đợi

- 2 ViewModel build được, test qua; cài đặt đã lưu áp dụng khi mở app (hoặc có đề xuất chờ người dùng duyệt).
- In cho người dùng: bảng ViewModel | state | hàm | service; trả lời mục 3; danh sách việc nhờ Hiếu – ít nhất: (1) `AnalyticsService` chưa có `setUserProperty` nên user property `font_size` / `high_contrast` chưa đặt được; (2) bản Firebase `SettingsService`; (3) đọc `honorific` / `wakeTime` cho N06 (nếu chọn (a): bản Firebase của `watchSetup`).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 03/11/2026, nhánh `feat/F8-setting`. Kiểm trùng: không nhánh nào có `SettingsViewModel` / `ProfileViewModel` (commit `6301bfb` chỉ là docs).
- Người dùng chọn: (mục 3) đồng ý sửa `lib/app.dart` 1 dòng + 1 import; (mục 5) phương án **(a)** thêm `watchSetup` vào `ProfileSetupService`.
- Trả lời mục 3: **trước bước này, mở lại app KHÔNG áp cài đặt đã lưu.** Chỉ `OnboardingViewModel.load()` (S01) đọc `SettingsService` và chỉ đặt cỡ chữ; tương phản cao không ai nạp. Đã nối bằng `displaySettingsSyncProvider` (lắng `SettingsService.watch()` → `fontScaleProvider` / `highContrastProvider`), kích hoạt bằng `ref.watch` trong `AnNhienApp.build()`.
- File đã tạo / sửa:
  - Tạo: `lib/viewmodels/settings_view_model.dart`, `lib/viewmodels/profile_view_model.dart`, `lib/viewmodels/display_settings_sync.dart`, `test/settings_view_model_test.dart` (11 test), `test/profile_view_model_test.dart` (5 test).
  - Sửa: `lib/app.dart` (import + `ref.watch(displaySettingsSyncProvider)`), `lib/services/profile_setup_service.dart` (`watchSetup` trong interface + Fake, Fake có `seed:` và `dispose()`), `docs/architecture.md` (mục 8.1, 9, 12), `docs/design-traceability.md` (S10 ×2, N06: `todo` → `doing`).
- Lệch Figma (nếu có, lý do): không (bước này không vẽ màn).
- `flutter analyze` / `flutter test`: analyze còn 1 warning có sẵn (`lib/router/app_router.dart:37` `pendingNotification` không dùng, không phải F8). Test: trước 241 qua / 66 lỗi → sau **257 qua / 66 lỗi**; 66 lỗi có sẵn, cùng 4 file (`router_test` 44, `text_scale_overflow_test` 12, `auth_routing_test` 9, `theme_test` 1). Không có lỗi mới.
- Việc người dùng cần làm tay:
  - Nhờ Hiếu: (1) `AnalyticsService` chưa có `setUserProperty` → chưa đặt được user property `font_size` / `high_contrast` (đã để `TODO(Hiếu)` trong `SettingsViewModel`); (2) bản Firebase `SettingsService` (Firestore `users/{uid}` + cache máy); (3) bản Firebase `ProfileSetupService.watchSetup` (đọc `displayName`, `honorific`, `wakeTime` từ `users/{uid}`), về sau gộp vào `ProfileService` / `UserProfile`.
  - Lưu ý cho bước 02: Hoàn tác cỡ chữ cũng log `change_font_size` (chiều ngược lại) để số liệu khớp cỡ cuối cùng. Nếu một lần lưu lỗi rồi lần lưu sau (trường khác) thành công, `watch()` phát giá trị đã lưu nên trường lỗi trên máy trở về giá trị cũ. Đây là hành vi của Fake, cần chốt với bản Firebase + cache.
  - Đăng xuất ở S10: View gọi `ref.read(signOutViewModelProvider.notifier).signOut()`, không gọi qua `SettingsViewModel`.
- Commit gợi ý: `feat(F8): SettingsViewModel + ProfileViewModel khung, nạp cài đặt hiển thị khi mở app`
