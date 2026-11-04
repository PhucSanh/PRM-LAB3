# Bước 04 · F12 · G06 / G07 / G07b chọn từng việc + G09 bỏ qua có Hoàn tác

Bạn là AI agent làm bước 04 của feature **F12 – Gợi ý lịch**. Bước 01–03 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Trên G03: "Chọn từng việc" → G06 Bác chọn việc muốn nhận → G07 / G07b đã nhận một phần. "Bỏ qua gợi ý" → G09 đã bỏ qua, có **Hoàn tác** quay lại G03; **không báo lại** cho người gửi (FR08).

## Quy tắc chung (áp dụng cho mọi bước)

- Làm việc ở thư mục gốc repo `PRM393_Lab03_AnNhien`, nhánh F12 hiện tại (kiểm bằng `git branch --show-current`, dạng `feat/F12-…`). Đọc `CLAUDE.md` trước tiên và tuân theo.
- **Figma là nguồn đúng duy nhất cho giao diện và câu chữ.** File key `K3JczHkChbUWoDBkXZYMhR`. Trước khi viết code một màn / state: gọi `get_design_context` **và** `get_screenshot` cho **từng** node được liệt kê (không bỏ node nào, kể cả state). Chép **nguyên văn** mọi chữ trong Figma (tiêu đề, câu mô tả, nhãn nút, chip, nhãn nút Quay lại) – tên layer trong `get_metadata` bị cắt ở 40 ký tự, phải lấy câu đầy đủ từ `get_design_context`. Giữ đúng thứ tự khối, nút nào là nút chính / phụ / chữ, có hay không có bottom nav, icon nào ở đâu. **Không tự thêm** khối, nút, câu chữ, hộp thoại mà Figma không có; **không bỏ** thứ Figma có. Bảng "Figma" trong file này là bản tóm tắt đã đối chiếu ngày 04/11/2026 – vẫn phải gọi Figma MCP; Figma khác bảng thì **theo Figma**.
- Figma không vẽ (đang tải / lỗi / trống / chưa ghép nối) thì dùng `LoadingView` / `ErrorView` / `EmptyView` có sẵn và ghi `DT-xx`. Figma mâu thuẫn với chính nó, với luật đề / `rule.md` / `CLAUDE.md`, hoặc không vẽ được bằng widget F0 → **dừng lại hỏi người dùng** (mỗi file có mục "Điểm Figma cần hỏi"), không tự chọn. Chỉ lệch Figma khi người dùng đồng ý, và mọi chỗ lệch phải có dòng `DT-xx`.
- Làm xong mỗi màn: dựng màn Flutter đúng bề rộng khung Figma (412 hoặc 360 dp, `textScaler` 1.0), chụp ảnh tạm (không commit) và **so từng khối với ảnh `get_screenshot`**; liệt kê mọi chỗ khác trong "Kết quả chạy".
- Không có Figma MCP thì **dừng lại báo người dùng**, không tự làm theo Stitch. Stitch / Codex HTML (`../../prm393-lab2-an-nhien/stitch-runs/` hoặc `codex-runs/`) chỉ để tham khảo; lệch thì **Figma thắng**.
- Tài liệu Lab 2 (chỉ đọc) ở `../../prm393-lab2-an-nhien/`: `flutter-handoff.md` mục "G01 – G12 · Gợi ý lịch từ người thân", `ux/user-flow.md` mục 14 (flow G), `rule.md`, `accessibility.md`, `assets/stitch/DESIGN.md`, `assets/stitch/AppStyleGuide.md`, `assets/stitch/vocabulary.md`.
- **Luật riêng của gợi ý lịch (đề + Lab 2, bị chấm):** lịch của Bác **chỉ đổi sau khi Bác bấm nhận**; bỏ qua **không báo lại** cho người gửi (không FCM, không ghi gì người gửi đọc được ngoài `status` do rules quyết định – FR08); popup gợi ý mới hiện **một lần** (`popupShown`), không tự đóng, đóng bằng "Để sau"; bỏ qua có **Hoàn tác**; Bác nhận gợi ý **≤ 2 lần chạm** tính từ popup / thẻ (chỉ số M6).
- **Chỉ dùng widget trong `lib/widgets/`** (`AppButton`, `AppBackBar`, `ChoiceGroup`, `TimeField` / `showTimeWheel` / `formatTimeOfDay`, `TaskRow`, `SuggestionCard`, `AppTextField`, `showConfirmDialog`, `showUndoSnackbar`, `IconCircle`, `LoadingView` / `EmptyView` / `ErrorView`…). Icon chỉ lấy từ `AppIcons` (`AppIcons.suggestion` cho thư gợi ý). Thiếu widget / icon thì **dừng lại hỏi người dùng** (người dùng là Sanh, chủ `lib/widgets/` + `lib/theme/`, sẽ quyết định thêm vào F0 trong commit riêng), không tự làm bản riêng trong thư mục màn.
- **Không được sửa**: `android/`, `firebase/`, bản `Firebase…` của service, `lib/main.dart`, màn / ViewModel của người khác: `lib/screens/today/` + `today_view_model.dart` (Khang – thẻ G12 Khang tự đặt theo comment trong `suggestion_card.dart`), S11 / `DayDetailViewModel` (Hương), màn Gia đình S09 (Hương), màn `/caregiver/*` của F13 / F14 (Hiếu), `lib/screens/onboarding/`, `lib/screens/account/`. `lib/services/providers.dart`, service có sẵn và `lib/models/` là của Hiếu: muốn sửa thì **hỏi người dùng trước**. `lib/app.dart`, `lib/widgets/app_shell.dart`, `lib/theme/`: chỉ sửa khi người dùng đồng ý. Không thêm package.
- Kiến trúc: View chỉ vẽ `UiState` bằng `switch` và gửi sự kiện; logic, validate, gọi service, log analytics nằm trong ViewModel (`Notifier`). Hành động một lần (gửi, nhận, bỏ qua…) trả kết quả về View để điều hướng / hiện Snackbar. Không gọi `FirebaseXxx.instance` trong widget.
- Không viết cứng màu / cỡ chữ / khoảng cách: chỉ dùng `lib/theme/` (màu qua `Theme.of(context).colorScheme` để tương phản cao có tác dụng). Chữ ≥ 20 sp, vùng chạm ≥ 72 dp, cách nhau `AppSpacing.betweenTargets`; kiểm tra 360 và 412 dp, `textScaler` 1.3 và 2.0 không tràn, cả chế độ tương phản cao.
- Câu chữ theo `AppStyleGuide.md` + `vocabulary.md` (gọi người dùng là "Bác", tên người gửi giữ nguyên – SG-05, nút = động từ + việc, lỗi có "Ví dụ: …"). Màn của con cháu (G01, G02) gọi người lớn tuổi là "mẹ" / theo `honorific` như Figma.
- Analytics chỉ gửi khoá / số / cờ (không gửi tên người gửi, lời nhắn, tên việc). Tên event theo `docs/analytics-plan.md` (`send_suggestion`, `accept_suggestion`, `dismiss_suggestion`, `undo_action` với `action: dismiss_suggestion`); **không tự đặt event mới**.
- Gặp chỗ không chắc (thiếu file, Figma mâu thuẫn tài liệu, cần sửa file ngoài phạm vi) thì **dừng lại hỏi**, không đoán.
- Docs: màn đang làm thì đổi cột Trạng thái trong `docs/design-traceability.md` mục F12 từ `todo` → `doing` (bước 06 mới chốt `done` / `changed`). Lệch Figma thì thêm dòng `DT-xx` cuối file (lấy số tiếp theo sau dòng `DT-` lớn nhất hiện có). Thêm / đổi service, ViewModel, route thì cập nhật `docs/architecture.md` (mục 7, 8, 9).
- Không tự `git commit` / `push`. Trước khi sửa, chạy `flutter test` một lần và ghi lại số lỗi **có sẵn**; chỉ chịu trách nhiệm lỗi mới. `dart format` **chỉ cho file F12 đã tạo / sửa** (chạy `dart format lib test` sẽ định dạng lại file của người khác). Chạy `flutter analyze` và `flutter test` tới khi không có lỗi mới rồi mới báo xong.
- Xong việc: điền mục **"Kết quả chạy"** ở cuối chính file này (thay các dòng trống), rồi in tóm tắt cho người dùng.

## Đọc trước

`CLAUDE.md`, `docs/design-traceability.md` mục F12, `docs/prompt/F12/03-g03-nhan-goi-y.md` (Kết quả chạy), `lib/viewmodels/suggestion_review_view_model.dart`, `lib/screens/suggestion/suggestion_review_screen.dart`, `lib/services/suggestion_service.dart`, `lib/widgets/undo_snackbar.dart`, `lib/widgets/choice_group.dart`, `lib/widgets/confirm_dialog.dart`, `docs/analytics-plan.md` (`accept_suggestion` `partial`, `dismiss_suggestion`, `undo_action`), `docs/test-plan.md` TC-27.

## Figma (đã đối chiếu 04/11/2026 – vẫn phải gọi `get_design_context` lấy câu đầy đủ)

| Khung | Node | Nội dung trong Figma |
| --- | --- | --- |
| G06 Chọn từng việc | `58:117` | Back "Gia đình"; tiêu đề **"Chọn từng việc"**; thẻ trích dẫn + "Đọc to"; câu **"Bác muốn nhận việc nào?"**; 2 thẻ việc (ô icon, tên, icon đồng hồ + giờ) có **icon chọn ở bên phải thẻ**; thẻ trạng thái có icon: **"Chưa thêm vào lịch của Bác."** + "Lịch chỉ thay đổi sau khi Bác xác nhận ở…"; nút chữ **"Quay lại"**; nút chính **"Tiếp tục"**; bottom nav. |
| G07 Đã nhận một việc | `61:2` | Back "Quay lại Gia đình"; **"Đã thêm vào lịch"**; "1 việc của Mai đã vào lịch ngày mai."; "Đọc to"; **"1 việc đã nhận"**; thẻ việc đã nhận (đi bộ: tên, "Vận động tự nhiên", chip "Chưa làm", "8:00 sáng · 20 phút"); thẻ việc chưa nhận (thư giãn: chip **"Gợi ý của Mai"**, "9:00 sáng · 15 phút", câu **"Chưa thêm vào lịch. Bác có thể thêm sau…"**); khối "Bác có thể đổi giờ hoặc ngưng nhắc."; nút chính "Xem lịch ngày mai", nút "Về Gia đình"; bottom nav. |
| G07b Đã nhận một việc · nhánh B | `61:118` | Như G07 nhưng nhận **thư giãn**; thẻ đi bộ còn chip "Gợi ý của Mai" + giờ, dưới thẻ có dòng "Chưa thêm vào lịch."; khối "Bác có thể đổi giờ hoặc ngưng nhắc."; 2 nút như G07; bottom nav. |
| G09 Đã bỏ qua gợi ý | `66:2` | **Màn kết quả toàn trang**: back "Quay lại Gia đình"; **"Đã bỏ qua gợi ý"**; "Chưa việc nào của Mai vào lịch ngày mai."; "Đọc to"; **"2 việc đã bỏ qua"**; 2 thẻ có chip **"Bỏ qua"** + giờ; khối có icon "Bác có thể xem lại gợi ý bất cứ lúc nào…"; nút chính **"Hoàn tác"**, nút "Về Gia đình"; bottom nav. |

Codex (chỉ tham khảo): `codex-runs/G06/v5.html`, `G07/v1.html`, `G07b/v1.html`, `G09/v2.html`.

**Điểm Figma cần hỏi người dùng (dừng lại hỏi trước khi code):**
1. G06: icon bên phải thẻ là ô tích (chọn nhiều) hay radio (chọn một)? Đọc `get_design_context`. Figma chỉ có kết quả nhận **1 việc** (G07 / G07b). Nếu chọn được cả 2 thì coi như nhận hết → G05?
2. G06 "Tiếp tục" lưu luôn rồi sang G07, hay còn bước xác nhận? Câu "Lịch chỉ thay đổi sau khi Bác xác nhận ở…" – đọc đủ câu để biết; Figma không vẽ bước xác nhận thì **không tự thêm**.
3. G07 / G07b: việc chưa nhận "Bác có thể thêm sau" → nhận tiếp ở đâu (mở lại G03 từ thẻ G12 / S09?) và gợi ý `partial` còn hiện thẻ G12 không? Cần hàm nhận tiếp (theo câu trả lời ở bước 01).
4. G09: Figma đặt **"Hoàn tác" là nút chính trên màn**, còn `CLAUDE.md` nói Hoàn tác dùng `UndoSnackbar`. Theo Figma (nút trên màn) hay cả nút + snackbar? "Bác có thể xem lại gợi ý bất cứ lúc nào" → xem lại ở đâu (S09 của Hương?).
5. Nút "Bỏ qua gợi ý" ở G03b có tên layer `open-skip-modal-btn` nhưng Figma **không vẽ** hộp thoại xác nhận. Đề xuất: không thêm hộp thoại (đã có "Hoàn tác" trên G09) – đồng ý không?

## Việc cần làm

1. `SuggestionReviewViewModel`:
   - `startChoosing()` ("Chọn từng việc") → state G06; chọn việc theo câu trả lời điểm 1; `backToReview()` ("Quay lại") → G03.
   - `continueChoosing()` ("Tiếp tục"): chặn khi chưa chọn việc nào (Figma không vẽ câu nhắc → hỏi người dùng câu chữ, ghi `DT-xx`); tạo việc đã chọn qua `TaskRepository.save`; `SuggestionService.accept(..., items)` → `partial` → state G07 / G07b (việc nào đã nhận, việc nào còn "Gợi ý của Mai"); log `accept_suggestion { count, changed_time, partial: true, taps }`.
   - `dismiss()` ("Bỏ qua gợi ý"): `SuggestionService.dismiss` → state G09; log `dismiss_suggestion { items }`. **Không** gọi bất kỳ thứ gì báo cho người gửi.
   - `undoDismiss()` (nút "Hoàn tác" trên G09): `SuggestionService.undoDismiss` → về G03 nguyên trạng; log `undo_action { action: 'dismiss_suggestion' }`.
2. Màn: G06, G07, G07b, G09 là **state của `suggestion_review_screen.dart`**, vẽ **đúng bảng Figma** – từng khối, từng chữ, đúng thứ tự. G06: mỗi thẻ là vùng chạm ≥ 72 dp, trạng thái chọn có icon + chữ cho TalkBack (không chỉ màu). G09: nút "Hoàn tác" đúng vị trí Figma (+ snackbar nếu người dùng chọn ở điểm 4). "Xem lịch ngày mai" → `/week/<ngày mai>`; "Về Gia đình" → `/family`.
3. Test: chọn 1 việc → đúng 1 việc trong `FakeTaskRepository`, status `partial`, state G07 / G07b đúng việc; chưa chọn → không lưu; bỏ qua → không còn trong `watchPending`, lịch không đổi, **số lần báo người gửi = 0**; "Hoàn tác" → lại `pending`, về G03; event đúng; widget G03 → "Chọn từng việc" → G06 → chọn → "Tiếp tục" → G07, G03 → "Bỏ qua gợi ý" → G09 → "Hoàn tác" → G03; **mọi chữ trong bảng Figma** có trên màn (`find.text`); 360 / 412 dp × 1.3 / 2.0 không tràn.
4. Đổi G06, G07, G07b, G09 sang `doing` trong `docs/design-traceability.md`; mỗi chỗ lệch Figma (đã được đồng ý) thêm `DT-xx`.

Được sửa: `lib/screens/suggestion/`, `lib/viewmodels/suggestion_review_view_model.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- Chọn từng việc và bỏ qua chạy đúng, có Hoàn tác, không báo người gửi (có test).
- In cho người dùng: ảnh cần chụp (G06, G07, G07b, G09 + snackbar ở 360 dp × 1.3), lệch Figma.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 04/11/2026, nhánh `feat/F12-suggest-schedule`. Figma MCP chập chờn: `get_design_context` lấy được G06 `58:117`, G07 `61:2`, G09 `66:2` (kèm ảnh) và G07b `61:118` (chỉ code, không ảnh – thử 3 lần); `get_screenshot` riêng cho 4 node đều mất kết nối, dùng ảnh trong `get_design_context`. Khung G07 trong Figma tự cắt cụt 2 thẻ (cao 42 dp) – lấy chữ từ code.
- Figma khác bảng tóm tắt (theo Figma): G06 "…sau khi Bác xác nhận ở bước tiếp theo."; G07 "Chưa thêm vào lịch. Bác có thể thêm sau trong Gia đình."; G09 "Bác có thể xem lại gợi ý bất cứ lúc nào trong Gia đình."; G06 dấu chọn là chấm tròn và **cả 2 thẻ đang chọn**.
- Người dùng trả lời: chọn nhiều, mặc định chọn hết (chọn hết → G05); "Tiếp tục" lưu luôn, đổi câu phụ; chưa chọn → câu lỗi + "Ví dụ: …" trên nút; G09 chỉ nút "Hoàn tác" trên màn (không snackbar); nhận tiếp việc còn lại từ Gia đình (nhờ Hương); ghép widget F0 + DT; "Bỏ qua gợi ý" không hỏi lại.
- Baseline: lần chạy cuối của bước 03 (305 qua / 66 lỗi có sẵn), chưa sửa gì từ đó.
- File đã tạo / sửa:
  - Mới: `test/f12_choose_dismiss_test.dart` (8 test ViewModel + 13 test widget, dùng lại `Harness` của `f12_review_test.dart`).
  - Sửa: `lib/viewmodels/suggestion_review_view_model.dart` (tách `_accept` dùng chung cho "Thêm vào lịch" và "Tiếp tục"; `startChoosing`, `toggle`, `backToReview`, `continueChoosing`, `dismiss`, `undoDismiss`; trường `needSelection`; bỏ `acceptSelected` trống), `lib/screens/suggestion/suggestion_review_screen.dart` (state G06 `_Choose`, G07 / G07b trong `_Accepted`, G09 `_Dismissed`; nhãn back cho màn kết quả).
  - Docs: `docs/design-traceability.md` (G06, G07, G07b, G09 → `doing`; DT-32), `docs/architecture.md` mục 7, 9.
- Lệch Figma (nếu có, lý do): DT-32 (đã được người dùng đồng ý). Đối chiếu ảnh tạm (412 dp × 1.0 và 360 dp × 1.3, không commit) với Figma, ngoài DT-32:
  - G06 412 dp: nút chữ "Quay lại" nằm dưới khối trạng thái, phải cuộn mới thấy (Figma thấy cả trong khung 1192 dp); "Tiếp tục" ghim đáy như Figma.
  - G07: dòng "Gợi ý của Mai · 9:00 sáng · 15 phút" xuống 2 dòng ở 412 dp.
  - Tiêu đề / câu phụ G07, G09 căn giữa như Figma; thẻ việc ô icon nền màu đậm như Figma G07 / G09.
- `flutter analyze` / `flutter test`: analyze còn 1 warning có sẵn (`app_router.dart:40`). Test: 326 qua / 66 lỗi – 66 lỗi trùng đúng danh sách có sẵn; 21 test mới đều qua, gồm: chọn 1 việc → đúng 1 việc trong lịch, status `partial`, G07 / G07b đúng việc, `accept_suggestion { partial: true }`; chưa chọn → không lưu, không log; bỏ qua → không còn trong `watchPending`, lịch không đổi, **`senderNotified == 0`**, `dismiss_suggestion { items: 2 }`; "Hoàn tác" → lại `pending`, về G03, `undo_action { action: dismiss_suggestion }`; widget G03 → G06 → G07 và G03 → G09 → Hoàn tác → G03, không có SnackBar; 360 / 412 dp × 1.3 / 2.0 không tràn, nút chính luôn thấy.
- Việc người dùng cần làm tay:
  - Chụp ảnh G06, G07, G07b, G09 ở 360 dp × 1.3 trên emulator (không có snackbar vì người dùng chọn chỉ nút "Hoàn tác").
  - Nhờ Hương (S09 Gia đình): liệt kê gợi ý `partial` / `dismissed` và mở `/today/suggestions/<id>?from=family` để Bác nhận tiếp / xem lại ("Bác có thể thêm sau trong Gia đình", "xem lại gợi ý bất cứ lúc nào trong Gia đình"). Cần thêm hàm đọc gợi ý cũ vào `SuggestionService` (đề xuất: `watchOpen(momUid)` trả `partial` + `dismissed`) – chốt với Hiếu.
  - Nếu muốn khớp Figma hơn: thêm vào F0 chip "Gợi ý của …", tuỳ chọn viền nét đứt cho thẻ, kiểu chip "Bỏ qua" nền đỏ (commit F0 riêng), rồi bỏ dòng tương ứng trong DT-32.
  - Thử lại `get_screenshot` cho G06 / G07 / G07b / G09 khi Figma MCP ổn định.
- Commit gợi ý: `feat(F12): G06/G07/G09 chọn từng việc, bỏ qua và hoàn tác gợi ý`
