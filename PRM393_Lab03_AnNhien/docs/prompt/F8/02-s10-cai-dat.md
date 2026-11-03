# Bước 02 · F8 · S10 Cài đặt hiển thị

Bạn là AI agent làm bước 02 của feature **F8 – Cài đặt hiển thị & hồ sơ**. Bước 01 (`SettingsViewModel`, nạp cài đặt khi mở app) đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Màn S10: Bác đổi cỡ chữ (cả app đổi **ngay khi chạm**), bật / tắt tương phản cao, đọc to, rung; xem thử lời nhắc; đi tới Cách dùng / Sửa hồ sơ / Nhắc việc / Dữ liệu; đăng xuất có hỏi lại. Mọi thay đổi có Hoàn tác.

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

`CLAUDE.md`, `docs/design-traceability.md` mục F8, `docs/prompt/F8/01-viewmodel-cai-dat.md` (mục "Kết quả chạy"), `lib/viewmodels/settings_view_model.dart`, `lib/viewmodels/account_view_model.dart` (`signOutViewModelProvider`), `lib/screens/account/account_screen.dart` (cách Hiếu hỏi lại trước khi đăng xuất – chỉ đọc), `lib/widgets/choice_group.dart` (`previewScale`), `lib/widgets/switch_row.dart`, `lib/widgets/confirm_dialog.dart`, `lib/widgets/undo_snackbar.dart`, `lib/widgets/state_views.dart`, `lib/screens/onboarding/welcome_screen.dart` (S01 – cùng kiểu chọn cỡ chữ, chỉ đọc), `lib/router/app_router.dart` (dòng `/settings`), `docs/architecture.md` mục 7.2 (`/reminder/:taskId?preview=true` từ S10), `flutter-handoff.md` mục S10.

## Figma

| Khung | Node | Lấy gì |
| --- | --- | --- |
| S10 Cài đặt hiển thị | `1:2325` | Thanh Quay lại, tiêu đề, thẻ cỡ chữ Vừa / Lớn / Rất lớn + "Xem thử: …", thẻ 3 công tắc |
| S10 Cài đặt hiển thị (cuộn xuống) | `1:2474` | Nút "Xem thử lời nhắc", 4 hàng: Cách dùng đơn giản, Sửa hồ sơ, Nhắc việc, Dữ liệu trên điện thoại; nút Đăng xuất (nếu có) |

Đặc tả Lab 2 (`flutter-handoff.md` S10): Card cỡ chữ (Vừa / Lớn / Rất lớn + "Xem thử: Đi bộ 20 phút lúc 9:30 sáng") → Card 3 công tắc (Tương phản cao, Đọc to nội dung, Rung khi nhắc việc) → nút viền "Xem thử lời nhắc" → 4 hàng tới N08 / N06 / N07 / N20. Tương phản cao bật → đổi `ColorScheme`. Không có thiết lập nào cần nhập chữ.

## Việc cần làm

1. Tạo `lib/screens/settings/settings_screen.dart` (S10):
   - `AppBackBar` ("Quay lại"), tiêu đề "Cài đặt hiển thị".
   - `ChoiceGroup<AppFontScale>` 3 lựa chọn có `previewScale` + câu "Xem thử" như Figma.
   - 3 `SwitchRow`: Tương phản cao, Đọc to nội dung, Rung khi nhắc việc.
   - Nút phụ "Xem thử lời nhắc" → `context.push('/reminder/preview?preview=true')` theo architecture mục 7.2. **S14 là màn của Khang (F6)**, đang placeholder: không làm S14, chỉ điều hướng; ghi lại trong "Kết quả chạy".
   - 4 hàng điều hướng (cả hàng bấm được, ≥ 72 dp): Cách dùng đơn giản → `/settings/help`, Sửa hồ sơ → `/settings/profile`, Nhắc việc → `/settings/reminders` (N07 của Khang), Dữ liệu trên điện thoại → `/settings/data`.
   - Nút **Đăng xuất** (đề bắt buộc). Figma không vẽ thì vẫn thêm ở cuối màn và ghi `DT-xx`. Bấm → `showConfirmDialog` nói rõ hậu quả (vd. "Bác sẽ cần đăng nhập lại. Lịch đã lưu vẫn còn.") → gọi `signOutViewModelProvider`; lỗi hiện `userMessage`. Điều hướng sau đăng xuất để router lo (không tự `go('/sign-in')` nếu router đã redirect – kiểm `app_router.dart`).
2. Vẽ đủ `UiLoading` → `LoadingView`, `UiError` → `ErrorView` + "Thử lại", `UiData` → nội dung. Empty không áp dụng: ghi lý do trong comment đầu file.
3. Mỗi lần đổi cỡ chữ / công tắc: gọi ViewModel, rồi hiện `showUndoSnackbar` (câu ngắn theo style guide, vd. "Đã đổi cỡ chữ sang Lớn.") → "Hoàn tác" gọi `undo`. Lưu lỗi thì hiện câu `userMessage` nhẹ nhàng, không chặn Bác.
4. Nội dung cuộn được ở `textScaler` 2.0; không tràn ở 360 / 412 dp.
5. Kiểm tra đường vào S10: nút / hàng nào trên S03 hoặc `AppShell` đang trỏ `/settings`. Nếu chưa có đường vào thì **báo người dùng** (S03 của Khang, `AppShell` của F0), không tự sửa.
6. Thay đúng dòng placeholder `/settings` trong `app_router.dart` bằng `SettingsScreen` (chỉ dòng đó + import).
7. Test widget `test/settings_screen_test.dart` (override bằng Fake): chạm "Rất lớn" → `textScaler` của app đổi; bật tương phản cao → theme đổi; Hoàn tác trả lại; Fake lỗi → `ErrorView` + "Thử lại"; Đăng xuất hỏi lại, "Hủy" không gọi `signOut`; 360 / 412 dp × `textScaler` 1.3 / 2.0 × thường / tương phản cao không tràn.
8. Đổi 2 dòng S10 sang `doing` trong `docs/design-traceability.md`; lệch Figma thì thêm `DT-xx`.

Được sửa: `lib/screens/settings/`, `lib/viewmodels/settings_view_model.dart`, dòng `/settings` trong `app_router.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- `/settings` hiện S10 đúng Figma, đổi cỡ chữ / tương phản cao thấy ngay toàn app, có Hoàn tác, đăng xuất có hỏi lại.
- In cho người dùng: ảnh cần chụp (360 dp × 3 cỡ chữ; tương phản cao bật; hộp thoại đăng xuất), lệch Figma, đường vào S10 có chưa.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 03/11/2026, nhánh `feat/F8-setting`. Figma MCP: đã gọi `get_design_context` (kèm ảnh) cho `1:2325` và `1:2474`.
- Người dùng chọn (03/11): thêm widget `NavRow` + `SectionCard` vào `lib/widgets/` (F0, commit riêng); thêm 8 icon vào `AppIcons`; thanh trên theo prompt ("Quay lại" + tiêu đề "Cài đặt hiển thị"); đăng xuất xong thì tự `go('/sign-in')` (vì `redirect` đang tạm tắt).
- File đã tạo / sửa:
  - Tạo: `lib/screens/settings/settings_screen.dart` (S10), `lib/widgets/nav_row.dart`, `lib/widgets/section_card.dart`, `test/settings_screen_test.dart` (16 test).
  - Sửa: `lib/theme/app_icons.dart` (+8 icon: `settings`, `textSize`, `contrast`, `vibrate`, `bellRing`, `bookOpen`, `smartphone`, `logout`), `lib/router/app_router.dart` (chỉ dòng `/settings` + import), `test/router_test.dart` (bỏ `/settings` khỏi danh sách placeholder), `docs/design-traceability.md` (DT-28; 2 dòng S10 đã `doing` từ bước 01), `docs/architecture.md` (mục 7.2, 9, 12, 13).
  - `SettingsViewModel` không phải sửa.
- Đường vào S10: **đã có**. Nút "Cài đặt" trên S03 (`lib/screens/today/today_screen.dart:50`, của Khang) đi `context.push('/settings')`. `AppShell` không có đường vào (đúng Figma).
- S14: "Xem thử lời nhắc" chỉ điều hướng `/reminder/preview?preview=true`. S14 là màn của Khang (F6), hiện vẫn là placeholder; Khang cần đọc `preview=true` để không ghi gì.
- Lệch Figma (nếu có, lý do): **DT-28**. Gồm: "Quay lại" thay "Hôm nay"; tiêu đề "Cài đặt hiển thị" ở đầu nội dung (Figma "Cài đặt" bên phải thanh trên); khung Xem thử viền liền (Figma viền đứt); thêm nút Đăng xuất + hộp hỏi lại (Figma không vẽ); thẻ / hàng dùng widget F0 mới. Chọn cỡ chữ theo DT-15, công tắc theo DT-14.
- `flutter analyze` / `flutter test`: analyze còn 1 warning có sẵn (`app_router.dart:38` `pendingNotification`, không phải F8). Test: trước 257 qua / 66 lỗi → sau **273 qua / 65 lỗi**. Lỗi có sẵn còn ở cùng 4 file: `router_test` 43 (bớt 1 vì đã bỏ dòng `/settings`), `text_scale_overflow_test` 12, `auth_routing_test` 9, `theme_test` 1. Không có lỗi mới. Lần chạy đầu có dòng "did not complete" ở `widgets/app_button_test.dart` nhưng không tính vào số lỗi; chạy riêng thì 11/11 qua, chạy lại toàn bộ thì cũng qua.
- Việc người dùng cần làm tay:
  - Chụp ảnh trên máy / emulator 360 dp: S10 ở 3 cỡ chữ (Vừa / Lớn / Rất lớn); S10 khi bật "Chữ và nền rõ hơn"; hộp hỏi đăng xuất (xem 2 nút có nằm trong màn ở cỡ "Lớn" không – font test vẽ chữ rộng hơn thật nên test không đo được).
  - Sửa Figma theo DT-28 (thêm nút Đăng xuất + khung hộp hỏi lại) rồi đánh ☑.
  - Commit riêng phần F0 (`lib/widgets/nav_row.dart`, `lib/widgets/section_card.dart`, `lib/theme/app_icons.dart`, mục 13 trong `docs/architecture.md`) trước commit S10. Có thể thêm 2 widget mới vào `WidgetGallery`.
  - Báo Khang: S14 nhận `/reminder/preview?preview=true`; hàng "Lời nhắc" đi `/settings/reminders` (N07).
  - Khi bật lại `redirect` trong router: dòng `go('/sign-in')` sau đăng xuất vẫn an toàn (redirect cho phép `/sign-in` khi chưa đăng nhập).
- Commit gợi ý:
  1. `feat(F0): thêm NavRow, SectionCard và icon cài đặt vào AppIcons`
  2. `feat(F8): S10 Cài đặt hiển thị – cỡ chữ, tương phản cao, công tắc, Hoàn tác, đăng xuất có hỏi lại`
