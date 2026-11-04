# Bước 05 · F8 · Kiểm tra cả feature, chốt docs, soạn PR

Bạn là AI agent làm bước 05 (cuối) của feature **F8 – Cài đặt hiển thị & hồ sơ**. Bước 01–04 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Chắc chắn F8 đạt mục "Xong khi", không vi phạm luật bị chấm, docs khớp code, có sẵn mô tả PR.

**Xong khi (file chia task):** Đổi cỡ chữ áp dụng toàn app; đúng ở 360 và 412 dp, không tràn chữ.

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

`CLAUDE.md` (mục "Luật bị chấm", "Checklist trước khi mở PR"), `../An-Nhien_Chia-task_Lab3.md` mục F8, `docs/design-traceability.md` mục F8, `docs/architecture.md` mục 7–9, 15, `docs/analytics-plan.md`, `rule.md` (11 nhóm luật), `docs/prompt/F8/0*.md` (mục "Kết quả chạy" các bước trước), `docs/prompt/F2/PR-F2.md` (mẫu PR gần nhất), `docs/prompt/F2/07-kiem-tra-pr.md` (cách F2 kiểm tra).

## Việc cần làm

1. **Test cả luồng**: tạo `test/settings_flow_test.dart` – `ProviderScope` override toàn bộ service bằng Fake, mở `/settings`:
   - chọn "Rất lớn" → quay về `/today` thấy `textScaler` vẫn ×1.3; dựng lại app với cùng Fake (giả lập mở lại app) → vẫn ×1.3 (đúng "Xong khi");
   - bật tương phản cao → Hoàn tác → tắt lại;
   - đi S10 → N06 (sửa tên, lưu, Hoàn tác) → về S10 → N08 → về → N20 → về;
   - Đăng xuất → "Hủy" không đăng xuất; xác nhận → `FakeAuthService` đã `signOut`, event `logout` đúng 1 lần (từ `SignOutViewModel`);
   - event `change_font_size` đúng `from` / `to`, không chứa tên Bác.
2. **Quét luật bị chấm** trong `lib/screens/settings/` + `settings_view_model.dart`, `profile_view_model.dart` (và file sync cài đặt nếu có): không `FirebaseXxx.instance` / `http` trong widget; không logic trong `build()`; màn tải dữ liệu đủ Loading / Error + Thử lại / Data; không `Color(0x…)`, `Colors.*`, `fontSize:`, `EdgeInsets` / `SizedBox` số cứng, `Icons.*` ngoài `AppIcons`; không widget tự chế lặp lại widget F0. Sửa chỗ sai trong phạm vi F8; thiếu widget / icon thì liệt kê (Sanh tự thêm vào F0 ở commit riêng).
3. **Kiểm tra giao diện**: test tràn chữ cho mọi màn / state F8 (S10 Data / Loading / Error, hộp thoại đăng xuất, N06 Data / lỗi tên / hộp thoại bỏ thay đổi, N08, N20) ở 360×800 và 412×915, `textScaler` 1.0 / 1.3 / 2.0, thường và tương phản cao.
4. **Tự chấm `rule.md`** (11 nhóm): bảng nhóm luật | đạt / chưa | chỗ chưa đạt, cho phạm vi F8.
5. **Docs**:
   - `docs/design-traceability.md` mục F8: 5 dòng → `done` (khớp Figma) hoặc `changed` + `DT-xx` cuối file (cột "Đã sửa Figma?" để ☐).
   - `docs/architecture.md`: mục 7.2 (4 route F8 không còn "placeholder"; `/settings/profile` = N06 + lối vào khu demo F10), mục 8 (nếu thêm hàm service), mục 9 (cột "Có sẵn" của `SettingsViewModel`, `ProfileViewModel`).
   - `docs/analytics-plan.md`: chỉ thêm "Cách lấy bằng chứng event F8" trong mục Bằng chứng (DebugView), **không** sửa phần khác (file của Hiếu).
6. **Soạn `docs/prompt/F8/PR-F8.md`** (tiếng Việt, theo mẫu `PR-F2.md`): tiêu đề `feat(F8): …`, làm gì, màn + route, ViewModel / service mới, event analytics, lệch Figma (DT-xx), sửa ngoài phạm vi (nếu có, đã hỏi), việc nhờ Hiếu / Khang (vd. `setUserProperty`, Firebase `SettingsService`, đọc `honorific` / `wakeTime`, dọn `profile_demo_entry_screen.dart`, S14 chế độ `preview`, đường vào S10 từ S03), ảnh cần chụp, checklist "trước khi mở PR" trong `CLAUDE.md` đã tick.
7. Chạy `dart format` cho file F8, `flutter analyze`, `flutter test`; so số lỗi với mức có sẵn ghi ở bước 01.

Được sửa: `lib/screens/settings/`, 2 ViewModel F8 (+ file sync cài đặt nếu có), `test/`, `docs/design-traceability.md`, `docs/architecture.md`, `docs/analytics-plan.md` (mục Bằng chứng), `docs/prompt/F8/`.

## Đầu ra mong đợi

- Test cả luồng qua; analyze không có lỗi mới; docs khớp code; `PR-F8.md` sẵn sàng.
- In cho người dùng: bảng đối chiếu "Xong khi" (đạt / chưa), bảng tự chấm `rule.md`, danh sách việc nhờ người khác, danh sách ảnh cần chụp, thứ tự commit gợi ý (mỗi bước 01–05 một commit).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 04/11/2026, nhánh `feat/F8-setting`. Trước đó đã chốt "Kết quả chạy" bước 04.
- File đã tạo / sửa:
  - Tạo: `test/settings_flow_test.dart` (4 test cả luồng trên `AnNhienApp` thật – override `routerProvider`, `messagingServiceProvider` và mọi service bằng Fake), `test/settings_overflow_test.dart` (60 test: S10 Data / Loading / Error + hộp đăng xuất, N06 Data / lỗi tên / hộp bỏ thay đổi / Loading / Error, N08, N20 × 360×800 / 412×915 × 1.0 / 1.3 / 2.0 × thường / tương phản cao), `docs/prompt/F8/PR-F8.md`.
  - Sửa: `lib/screens/settings/settings_screen.dart` (vạch ngăn `Divider(height: 1, thickness: 1)` → `Divider(height: AppSpacing.xl)`, bỏ số cứng); `lib/screens/settings/help_screen.dart` (nút "Thử lời nhắc" dùng `AppIcons.bellRing` giống S10 – R-ICON-03); `docs/design-traceability.md` (5 dòng F8 → `changed (DT-xx)`, cột service khớp code, dòng N06 ở bảng F10); `docs/analytics-plan.md` (chỉ thêm "Cách lấy bằng chứng event F8" trong mục Bằng chứng).
  - `docs/architecture.md` mục 7.2, 8, 9 đã khớp code từ bước 01–04, không phải sửa thêm.
- Quét luật bị chấm (`lib/screens/settings/`, 2 ViewModel, `display_settings_sync.dart`): không `FirebaseXxx.instance` / `http`; không gọi service hay `logEvent` trong widget; S10, N06 vẽ đủ Loading / Error + Thử lại / Data; không `Color(0x…)`, `Colors.*`, `fontSize:`, `Icons.*` ngoài `AppIcons`. Số cứng duy nhất (vạch ngăn S10) đã sửa. Còn ghép tay trong màn (không lặp widget F0 nào): `_FontPreview` (S10), `_StepCard` (N08), thanh nút ghim đáy (N06, N08, N20 – cùng khung với `OnboardingLayout` của F2) → đề xuất Sanh đưa khung này vào F0.
- Lệch Figma (nếu có, lý do): không thêm DT mới ở bước này. F8 dùng DT-28 (S10), DT-29 (N06), DT-30 (N20 câu chữ), DT-31 (N08); cả 5 dòng F8 `changed`, cột "Đã sửa Figma?" còn ☐.
- Đối chiếu "Xong khi":
  - Đổi cỡ chữ áp dụng toàn app: **đạt** (`settings_flow_test`: "Rất lớn" → về Hôm nay ×1.3; mở lại app với cùng Fake → vẫn ×1.3).
  - Đúng ở 360 và 412 dp, không tràn chữ: **đạt** (`settings_overflow_test`, 60 test).
  - Máy thật giữ cài đặt sau khi tắt app: **chưa** – chờ Hiếu viết bản Firebase `SettingsService`.
- Tự chấm `rule.md`: 9 nhóm đạt, nhóm 6 không áp dụng, nhóm 9 (giọng đọc) chưa đạt một phần (ô tên N06 chưa có "🎤 Nói…", "Đọc to nội dung" mới lưu cờ) – bảng đầy đủ trong `PR-F8.md`.
- `flutter analyze` / `flutter test`: analyze còn 1 warning có sẵn (`app_router.dart:40`, không phải F8). Test: trước 319 qua / 62 lỗi → sau **383 qua / 62 lỗi**. Lỗi có sẵn ở cùng 4 file: `router_test` 40, `text_scale_overflow_test` 12, `auth_routing_test` 9, `theme_test` 1. Không có lỗi mới. So với bước 01 (241 qua / 66 lỗi): F8 thêm 142 test, và giảm 4 lỗi `router_test` vì đã bỏ 4 route F8 khỏi danh sách placeholder.
- Việc người dùng cần làm tay:
  - Chụp ảnh (máy ảo 360 dp): S10 ở Vừa / Lớn / Rất lớn; S10 tương phản cao; Snackbar đổi cỡ chữ; hộp hỏi đăng xuất; N06 (×1.3); N06 lỗi tên trống; hộp "Bác chưa lưu thay đổi"; N08; N20; Hôm nay sau khi chọn "Rất lớn".
  - Sửa Figma theo DT-28 → DT-31 rồi đánh ☑.
  - Gửi việc cho Hiếu, Khang và tự làm phần F0 theo mục "Việc nhờ người khác" trong `PR-F8.md`.
  - Mở PR bằng nội dung `docs/prompt/F8/PR-F8.md`.
- Commit gợi ý (theo thứ tự, mỗi bước một commit):
  1. `feat(F0): thêm SectionCard, NavRow và icon cài đặt / hồ sơ vào AppIcons`
  2. `feat(F8): SettingsViewModel + ProfileViewModel, nạp cài đặt hiển thị khi mở app`
  3. `feat(F8): S10 Cài đặt hiển thị – cỡ chữ, tương phản cao, công tắc, Hoàn tác, đăng xuất có hỏi lại`
  4. `feat(F8): N06 Thông tin của Bác – sửa tên, cách gọi, giờ thức dậy, Hoàn tác, hỏi khi bỏ thay đổi`
  5. `feat(F8): N08 Cách dùng đơn giản + N20 Dữ liệu trên điện thoại (câu chữ đúng Lab 3)`
  6. `test(F8): test cả luồng + tràn chữ, chốt docs, PR-F8`
