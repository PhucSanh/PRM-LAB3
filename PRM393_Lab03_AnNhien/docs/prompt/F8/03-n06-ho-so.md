# Bước 03 · F8 · N06 Thông tin của Bác (Sửa hồ sơ)

Bạn là AI agent làm bước 03 của feature **F8 – Cài đặt hiển thị & hồ sơ**. Bước 01–02 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Màn N06: Bác sửa tên, cách gọi (Ông / Bà), giờ thức dậy; "Lưu hồ sơ" có Hoàn tác; rời màn khi chưa lưu thì hỏi lại. Cuối màn giữ lối vào **khu demo Firebase** của Hiếu (F10).

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

## Trước khi làm

- N06 dùng chung route `/settings/profile` với khu demo F10 của Hiếu, và file chia task ghi flow "Đăng nhập + Hồ sơ" là của Hiếu. **Hỏi người dùng đã chốt với Hiếu chưa** (Sanh làm form sửa hồ sơ, Hiếu giữ khu demo). Chưa chốt thì dừng.
- Đọc mục "Kết quả chạy" của bước 01: người dùng đã chọn (a) hay (b) cho nguồn `honorific` / `wakeTime`. Chọn (b) thì bước này chỉ làm phần sửa tên, ô cách gọi / giờ thức dậy để lại `// TODO` và ghi rõ trong kết quả.

## Đọc trước

`CLAUDE.md`, `docs/design-traceability.md` mục F8 + DT-24 (S02), `docs/prompt/F8/01-viewmodel-cai-dat.md` (Kết quả chạy), `lib/viewmodels/profile_view_model.dart`, `lib/services/profile_service.dart`, `lib/services/profile_setup_service.dart`, `lib/screens/onboarding/setup_profile_screen.dart` + phần S02 trong `onboarding_view_model.dart` (cách F2 validate tên, câu lỗi, `TimeField` – chỉ đọc, chép **logic** sang `ProfileViewModel`, không import ViewModel của Hương), `lib/screens/firebase_demo/profile_demo_entry_screen.dart` + `lib/widgets/firebase_demo_entry.dart` (khu demo F10 – chỉ đọc), `lib/widgets/app_text_field.dart`, `lib/widgets/time_field.dart`, `lib/widgets/choice_group.dart`, `lib/widgets/confirm_dialog.dart`, `lib/widgets/undo_snackbar.dart`, `lib/router/app_router.dart` (dòng `/settings/profile`).

## Figma

| Khung | Node | Lấy gì |
| --- | --- | --- |
| N06 Thông tin của Bác (Sửa hồ sơ) | `38:187` | Ô tên, cách gọi, giờ thức dậy, câu lưu ý, nút "Lưu hồ sơ" / "Hủy" |

Đặc tả Lab 2 (`flutter-handoff.md`, bảng màn mới): N06 "Như S02 + lưu ý **'Đổi giờ thức dậy không tự đổi giờ những việc đã lưu.'**"; nút "Lưu hồ sơ" / "Hủy" (đã sửa mà rời → hỏi như N14). Stitch: `stitch-runs/N06/v2.html`.

## Việc cần làm

1. Điền `ProfileViewModel`:
   - `load()`: lấy `uid` như F2 lấy, nạp tên + cách gọi + giờ thức dậy → `UiData(ProfileForm)`; lỗi → `UiError` + `retry()`.
   - `changeName` / `changeHonorific` / `changeWakeTime` cập nhật form, bật `dirty`.
   - `save()`: validate tên giống S02 (trống, quá dài – câu lỗi có "Ví dụ: …"); hợp lệ thì lưu qua `ProfileSetupService.saveSetup`; trả kết quả (thành công / lỗi `userMessage`) về View; lỗi thật → `CrashService.recordError` non-fatal. Giữ bản cũ để `undo()` lưu lại bản cũ.
   - `discard()`: bỏ thay đổi.
   - Analytics: `docs/analytics-plan.md` **không có** event cho N06 → không log, không tự đặt event (ghi trong kết quả).
2. Tạo `lib/screens/settings/profile_screen.dart` (N06):
   - `AppBackBar`, tiêu đề như Figma; `AppTextField` tên (`hint` "Ví dụ: …", lỗi có icon); `ChoiceGroup` Ông / Bà; `TimeField` giờ thức dậy; câu lưu ý về giờ thức dậy (dùng widget thông báo có sẵn trong `lib/widgets/form_parts.dart` nếu có).
   - Nút chính "Lưu hồ sơ" (60 dp) + "Hủy". Lưu xong: `showUndoSnackbar` ("Đã lưu hồ sơ.") → "Hoàn tác" gọi `undo()`.
   - Rời màn khi `dirty` (bấm Hủy, Quay lại, cử chỉ back – `PopScope`) → `showConfirmDialog` kiểu N14: nói rõ thay đổi sẽ mất, "Ở lại sửa" / "Bỏ thay đổi".
   - **Cuối màn** đặt `FirebaseDemoEntry(onOpen: () => context.push('/settings/firebase-demo'))` để giữ khu demo F10.
   - Vẽ đủ Loading / Error + Thử lại / Data (Empty không áp dụng: hồ sơ luôn có sau onboarding – ghi lý do).
3. Route: thay `ProfileDemoEntryScreen` ở dòng `/settings/profile` bằng `ProfileScreen` (chỉ dòng đó + import). **Không xoá** `profile_demo_entry_screen.dart` (file của Hiếu) – ghi vào việc nhờ Hiếu dọn. Giữ nguyên route `/settings/firebase-demo`.
4. Test:
   - `test/profile_view_model_test.dart`: load → Data; Fake lỗi → Error → retry; tên trống / quá dài → lỗi có "Ví dụ"; lưu đúng giá trị vào Fake; `failOnSave` → trả lỗi, không mất dữ liệu đã gõ; `undo` lưu lại bản cũ.
   - `test/profile_screen_test.dart`: sửa tên rồi bấm Quay lại → hộp thoại hỏi; "Bỏ thay đổi" rời màn; có nút "Khu thử tính năng"; 360 / 412 dp × 1.3 / 2.0 (có bàn phím mở) không tràn, nút Lưu không bị che.
5. Đổi N06 sang `doing` trong `docs/design-traceability.md`; lệch Figma thì thêm `DT-xx`; `docs/architecture.md` mục 7.2 (`/settings/profile` = N06 + lối vào khu demo F10).

Được sửa: `lib/screens/settings/`, `lib/viewmodels/profile_view_model.dart`, dòng `/settings/profile` trong `app_router.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- `/settings/profile` hiện N06 đúng Figma, lưu được, có Hoàn tác, rời màn chưa lưu thì hỏi; khu demo F10 vẫn mở được.
- In cho người dùng: ảnh cần chụp (360 dp × 1.3; lỗi tên; hộp thoại bỏ thay đổi), lệch Figma, việc nhờ Hiếu.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 04/11/2026, nhánh `feat/F8-setting`. Figma MCP: `get_design_context` (kèm ảnh) cho `38:187`.
- Trước khi làm: người dùng xác nhận **đã chốt với Hiếu** (Sanh làm form N06, Hiếu giữ khu demo F10). Bước 01 đã chọn **(a)** nên N06 có đủ tên, cách gọi và giờ thức dậy.
- Người dùng chọn (04/11): giữ cách gọi **Ông / Bà** (Figma có thêm "Bác"); nhãn nút theo Figma **"Lưu thông tin"**; ô lưu ý dùng `FieldMessage.hint`; thêm icon `AppIcons.smile`, `AppIcons.sunrise` (F0).
- File đã tạo / sửa:
  - Tạo: `lib/screens/settings/profile_screen.dart` (N06), `test/profile_screen_test.dart` (17 test).
  - Sửa: `lib/viewmodels/profile_view_model.dart` (điền `load` / `retry` / `changeName` / `changeHonorific` / `changeWakeTime` / `save` → `ProfileSaved` / `undo` / `discard`; kiểm tra tên chép logic S02, không import ViewModel của Hương), `lib/services/profile_setup_service.dart` (bản Fake `watchSetup` đổi sang `Stream.multi`, `onCancel` không trả Future – xem dưới), `lib/theme/app_icons.dart` (+`smile`, `sunrise`), `lib/router/app_router.dart` (chỉ dòng `/settings/profile` + import; bỏ import `ProfileDemoEntryScreen`), `test/profile_view_model_test.dart` (13 test), `test/router_test.dart` (bỏ `/settings/profile` khỏi danh sách placeholder), `docs/design-traceability.md` (DT-29; N06 đã `doing` từ bước 01), `docs/architecture.md` (mục 7.2, 9, 12).
  - **Không xoá** `lib/screens/firebase_demo/profile_demo_entry_screen.dart` (của Hiếu) – giờ không route nào dùng.
- Analytics: `docs/analytics-plan.md` không có event cho N06 nên **không log**, không tự đặt event.
- Lệch Figma (nếu có, lý do): **DT-29**. Gồm: chỉ Ông / Bà; ô lưu ý nền xanh + dòng có icon chuông vẽ bằng `FieldMessage.hint` (ⓘ, không nền); ô giờ hiện "5:30 sáng · Đổi giờ ⌄"; nút cao 72 (Figma 60); "Khu thử tính năng" ở cuối phần cuộn, không nằm dưới thanh nút đáy; thêm hộp hỏi "Bác chưa lưu thay đổi" và câu lỗi lưu (Figma chưa vẽ).
- `flutter analyze` / `flutter test`: analyze còn 1 warning có sẵn (`app_router.dart:38`, không phải F8). Test: trước 273 qua / 65 lỗi → sau **298 qua / 64 lỗi**. Lỗi có sẵn ở cùng 4 file: `router_test` 42 (bớt 1 vì bỏ dòng `/settings/profile`), `text_scale_overflow_test` 12, `auth_routing_test` 9, `theme_test` 1. Không có lỗi mới. Test F2 dùng chung `ProfileSetupService` (`f2_view_models_test`, `setup_profile_screen_test`, `onboarding_flow_test`) vẫn qua.
- Phát hiện khi test: `.first` trên stream Fake dựng bằng `Stream.multi` với `sink.onCancel = subscription.cancel` bị **treo trong `testWidgets`**. Lý do: Future huỷ của broadcast stream nằm ở root zone, thời gian giả không chạy tới. Đã sửa bản Fake `watchSetup` của F8. `FakeProfileService.watch` (của Hiếu) cũng bị như vậy: `test/profile_screen_test.dart` tạm dùng lớp con `_StaticProfileService` (`watch` = `Stream.value`).
- Việc người dùng cần làm tay:
  - Chụp ảnh 360 dp × 1.3: N06 có dữ liệu; N06 khi lỗi tên trống ("Bác chưa nhập tên gọi." + "Ví dụ: Lan"); hộp hỏi "Bác chưa lưu thay đổi".
  - Sửa Figma theo DT-29 (vẽ hộp hỏi bỏ thay đổi, trạng thái lỗi lưu; bỏ "Bác" hoặc ghi chú) rồi đánh ☑.
  - Nhờ Hiếu: (1) bản Firebase `ProfileSetupService.watchSetup` + `saveSetup` (đọc / ghi `users/{uid}`: `displayName`, `honorific`, `wakeTime`); (2) dọn `profile_demo_entry_screen.dart` (không còn route dùng); (3) sửa `FakeProfileService.watch`: `sink.onCancel = () { subscription.cancel(); }` để `.first` không treo trong widget test; (4) nếu muốn cách gọi "Bác" như Figma: thêm vào `Honorific` + rules, báo Hương (S02 tự hiện thêm lựa chọn).
  - Gộp `smile`, `sunrise` vào commit F0 cùng 8 icon của bước 02.
- Commit gợi ý:
  1. `feat(F0): thêm icon smile, sunrise cho hồ sơ` (hoặc gộp vào commit F0 bước 02)
  2. `feat(F8): N06 Thông tin của Bác – sửa tên, cách gọi, giờ thức dậy, Hoàn tác, hỏi khi bỏ thay đổi`
