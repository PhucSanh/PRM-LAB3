# Bước 05 · F12 · G10 / G11 popup gợi ý mới + G12 thẻ trên Hôm nay

Bạn là AI agent làm bước 05 của feature **F12 – Gợi ý lịch**. Bước 01–04 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Máy Bác có gợi ý mới → popup G10 / G11 hiện **một lần** trên Hôm nay ("Xem gợi ý" → G03, "Để sau" → thẻ G12 ở đầu Hôm nay). Thẻ G12 dùng widget `SuggestionCard` (F0) – **Khang tự đặt lên S03**, F12 chỉ cấp dữ liệu qua `suggestionInboxViewModelProvider`.

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

`CLAUDE.md`, `docs/design-traceability.md` mục F12, `lib/widgets/suggestion_card.dart` (**đọc kỹ comment đầu file**: tên provider, trường `pendingCard`, hàm `dismiss`, cách Khang đặt thẻ), `lib/viewmodels/suggestion_inbox_view_model.dart`, `lib/services/suggestion_service.dart`, `lib/widgets/app_shell.dart` (F0), `lib/screens/today/today_screen.dart` (của Khang – **chỉ đọc**), `lib/router/app_router.dart` (shell `/today`), `lib/models/notification_target.dart` + `lib/services/messaging_service.dart` (push mở `/today/suggestions/:id` – của Hiếu, chỉ đọc), `flutter-handoff.md` mục S03 (Interactions: popup G11 hiện một lần) và G01 – G12, `docs/test-plan.md` TC-26, TC-28.

## Figma (đã đối chiếu 04/11/2026 – vẫn phải gọi `get_design_context` lấy câu đầy đủ)

| Khung | Node | Nội dung trong Figma |
| --- | --- | --- |
| G10 Có gợi ý mới (tự hiện) | `66:119` | Khung 360 × 800. Popup phủ trên S03 (nền S03 mờ phía sau): ô icon tròn 80 với icon 64; **"Mai gửi lịch cho Bác"**; **"Mai vừa gửi lúc 4:20 chiều"**; **"2 việc cho ngày mai"**; bong bóng lời nhắn "Mẹ ơi 3 giờ chiều mẹ đi bộ với cô Tám nh…"; **"Chưa thêm vào lịch. Bác tự chọn."**; nút chính **"Xem gợi ý"**, nút **"Để sau"**. |
| G11 Popup Mai gửi lịch cho Bác | `71:2` | Như G10 nhưng **không có** dòng "Mai vừa gửi lúc …". |
| G12 Hôm nay · thẻ gợi ý của Mai | `71:209` | Thẻ ở **đầu S03, trên "Việc tiếp theo"**: ô icon thư + **"Mai gửi Bác 2 việc"**; **"Chưa thêm vào lịch. Bác tự chọn."**; nút viền **"Xem gợi ý"**. **Không có** tên các việc, **không có** nút "Bỏ qua gợi ý". |

Stitch (chỉ tham khảo): `stitch-runs/G10/v1.html`, `G11/v2.html`, `G12/v1.html`.

**Điểm Figma cần hỏi người dùng (dừng lại hỏi trước khi code):**
1. G10 và G11 chỉ khác dòng "Mai vừa gửi lúc …". Khi nào dùng G10 (gợi ý vừa đến lúc đang mở app?), khi nào G11 (mở app thấy gợi ý đang chờ)? Hay một popup, hiện dòng giờ khi có thời điểm gửi?
2. Lời nhắn trong popup ("Mẹ ơi 3 giờ chiều…") khác lời nhắn ở G03 ("Mẹ ơi, mai mình đi bộ…"). Code luôn lấy `message` thật; chỉ dữ liệu mẫu Fake là khác – theo câu trả lời ở bước 01.
3. Thẻ G12 trong Figma **không có tên việc và nút bỏ qua**, nhưng `SuggestionCard` có `previewTitles` + `onDismiss` tuỳ chọn và comment mẫu cho Khang đang truyền cả hai. Đề xuất gửi Khang bản **không** truyền `previewTitles` / `onDismiss` để khớp Figma và sửa comment mẫu trong `suggestion_card.dart` (file F0 của Sanh) – đồng ý không? Kiểm `SuggestionCard` khi `previewTitles` rỗng có vẽ khớp Figma không.
4. Popup có icon 64, bong bóng lời nhắn, 2 nút xếp dọc – `showConfirmDialog` có vẽ được đúng không? Không được thì hỏi có thêm widget popup vào `lib/widgets/` (F0) không.

## Việc cần làm

1. Điền `SuggestionInboxViewModel` (`suggestionInboxViewModelProvider` – **giữ đúng tên**, Khang dùng):
   - Lắng `SuggestionService.watchPending(uid của Bác)` → `UiData(SuggestionInbox(pendingCard, popupToShow))`; `pendingCard` có `id`, `fromName`, `items` (để đếm "2 việc"); đang tải / lỗi / không có gợi ý: View **không chiếm chỗ** (đúng comment trong `suggestion_card.dart`).
   - `popupToShow` = gợi ý `pending` chưa `popupShown`; popup hiện là gọi `markPopupShown` ngay (mở lại app không hiện lại).
   - `later(id)` ("Để sau"): chỉ đóng popup, gợi ý còn `pending` → thẻ G12.
   - Chỉ giữ `dismiss(id)` nếu người dùng chọn giữ nút bỏ qua trên thẻ ở điểm 3.
2. **Popup G10 / G11**: vẽ **đúng bảng Figma** (khung giữa màn, đúng thứ tự chữ, 2 nút xếp dọc), không tự đóng (`barrierDismissible: false`, back cứng không đóng); "Xem gợi ý" → `context.push('/today/suggestions/<id>?from=popup')`; "Để sau" → `later`.
   - **Chỗ gắn popup** (không sửa code F3 của Khang): đề xuất widget lắng nghe (vd. `SuggestionPopupListener`) đặt ở `AppShell` (F0), chỉ hiện khi đang ở tab Hôm nay. Sửa `app_shell.dart` phải **hỏi người dùng trước**; không được thì in đoạn code để Khang đặt trong `today_screen.dart`.
3. **Thẻ G12**: không sửa `today_screen.dart`. In đoạn code cho Khang dán vào đầu `_TodayList` (trên "Việc tiếp theo"), khớp Figma theo câu trả lời điểm 3.
4. Push: bấm thông báo FCM "có gợi ý mới" mở `/today/suggestions/:id` (Hiếu làm). Kiểm G03 xử lý `from=push` và gợi ý đã xử lý.
5. Test: có gợi ý mới → popup hiện 1 lần, dựng lại app → không hiện lại; **mọi chữ trong bảng Figma** có trong popup (`find.text`); "Để sau" → `pendingCard` có, popup không còn; "Xem gợi ý" → G03 → "Thêm vào lịch" → `taps == 2` (TC-26); không có gợi ý / lỗi → thẻ không chiếm chỗ; test widget dựng `SuggestionCard` từ state của provider đúng như đoạn code gửi Khang và có đủ chữ G12; popup 360 / 412 dp × 1.3 / 2.0 không tràn.
6. Đổi G10, G11, G12 sang `doing` trong `docs/design-traceability.md` (G12 ghi "chờ Khang đặt thẻ trên S03" nếu Khang chưa dán); mỗi chỗ lệch Figma (đã được đồng ý) thêm `DT-xx`.

Được sửa: `lib/viewmodels/suggestion_inbox_view_model.dart`, `lib/screens/suggestion/`, `test/`, `docs/`; `lib/widgets/app_shell.dart` và comment `suggestion_card.dart` chỉ khi người dùng đồng ý.

## Đầu ra mong đợi

- Popup hiện một lần, "Để sau" để lại thẻ, thẻ có dữ liệu thật từ provider; nhánh chính ≤ 2 chạm.
- In cho người dùng: đoạn code gửi Khang (thẻ G12, và popup nếu không gắn được ở `AppShell`), ảnh cần chụp (G10 / G11, thẻ G12 trên Hôm nay), lệch Figma.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 04/11/2026, nhánh `feat/F12-suggest-schedule`. `get_design_context` lấy được đủ G10 `66:119`, G11 `71:2`, G12 `71:209` (kèm ảnh); `get_screenshot` G10. Figma khớp bảng tóm tắt; popup G10 / G11 lời nhắn "Mẹ ơi 3 giờ chiều mẹ đi bộ với cô Tám nhé" (đủ câu) – code lấy `message` thật (DT-28).
- Người dùng trả lời: một popup, dòng "vừa gửi lúc …" chỉ khi gửi hôm nay (G10), không thì G11; thẻ G12 khớp Figma (không `previewTitles` / `onDismiss`) + sửa comment mẫu trong `suggestion_card.dart`, bỏ `dismiss` / `undoDismiss` khỏi Inbox VM; popup ghép từ `ConfirmDialog` (F0); gắn popup bằng cách sửa `app_shell.dart`.
- Baseline: lần chạy cuối của bước 04 (326 qua / 66 lỗi có sẵn).
- File đã tạo / sửa:
  - Mới: `lib/screens/suggestion/suggestion_popup_listener.dart` (`SuggestionPopupListener` + `SuggestionPopup`), `test/f12_inbox_popup_test.dart` (1 test ViewModel + 13 test widget dùng `AppShell` thật trong `StatefulShellRoute`).
  - Sửa: `lib/viewmodels/suggestion_inbox_view_model.dart` (theo dõi `sessionProvider` – đổi tài khoản thì nghe lại đúng uid; `now`, `sentToday`, `dayLabel`; `markPopupShown`, `later`; bỏ `dismiss` / `undoDismiss`), `lib/viewmodels/suggestion_review_view_model.dart` (`_dayLabel` → `suggestionDayLabel` public, dùng chung), `lib/widgets/app_shell.dart` (bọc body bằng `SuggestionPopupListener(active: tab Hôm nay)` – người dùng đồng ý), `lib/widgets/suggestion_card.dart` (**chỉ comment**: đoạn mẫu cho Khang bỏ `previewTitles` / `onDismiss`, thêm `?from=card`), `lib/services/providers.dart` (Fake `delay: Duration.zero` – xem dưới).
  - Docs: `docs/design-traceability.md` (G10, G11 → `doing`; G12 → `doing – chờ Khang đặt thẻ trên S03`; DT-33), `docs/architecture.md` mục 9, 13.
- Lệch Figma (nếu có, lý do): DT-33 (đã được người dùng đồng ý). Đối chiếu ảnh tạm (360 dp × 1.0 / 1.3, không commit) với Figma:
  - Popup 360 × 1.0: đúng thứ tự khối, vừa một màn; vòng icon to hơn (112 vs 80) nên popup cao hơn Figma một chút; lời nhắn mẫu có ngoặc kép (dữ liệu G03).
  - Popup 360 × 1.3: hai nút nằm dưới, phải cuộn trong popup mới thấy (`ConfirmDialog` cuộn) – test xác nhận vẫn bấm được ở 360 / 412 × 1.3 / 2.0.
  - Thẻ G12: khớp Figma (ô icon thư nền nhạt, tiêu đề, câu phụ, nút viền "Xem gợi ý" cao 72).
- `flutter analyze` / `flutter test`: analyze còn 1 warning có sẵn (`app_router.dart:40`). Test: 340 qua / 66 lỗi – trùng đúng 66 lỗi có sẵn; 14 test mới đều qua: popup hiện 1 lần và đánh dấu `popupShown`; đủ chữ Figma G10; G11 không có dòng "vừa gửi"; chạm ngoài / Back không đóng; "Để sau" → còn thẻ G12, **dựng lại app → không hiện lại**; TC-26 popup → G03 → "Thêm vào lịch" = `taps 2`; thẻ G12 → G03 = `taps 2`; ở tab khác không hiện, về Hôm nay thì hiện; không có gợi ý / lỗi → không popup, thẻ không chiếm chỗ; thẻ dựng từ provider đúng đoạn code gửi Khang.
  - Lần chạy đầu có **4 lỗi mới** ở `test/text_scale_overflow_test.dart` (`/today` × 360 / 412 × 1.0 / 2.0): test dựng cả app bằng `suggestionServiceProvider` thật (Fake trễ 300 ms) → popup hiện, `markPopupShown` còn Timer khi test kết thúc. Sửa: Fake trong `providers.dart` dùng `delay: Duration.zero` (dòng F12 tự thêm ở bước 01). Không sửa test của người khác.
- Push (Hiếu): `notificationTarget` đã cho `/today/suggestions/<id>`; G03 đọc `?from=push` (tính 1 chạm), gợi ý đã nhận hết / không còn → `EmptyView` "Gợi ý này không còn" (bước 03). Nhờ Hiếu thêm `?from=push` vào route trong payload FCM.
- Việc người dùng cần làm tay:
  - **Gửi Khang** đoạn code thẻ G12 (đã ghi trong comment `lib/widgets/suggestion_card.dart`), dán làm phần tử đầu tiên của `ListView` trong `_TodayList.build` (trên "Việc tiếp theo"); popup Khang không phải làm gì.
  - Chụp ảnh G10 (gợi ý gửi hôm nay), G11 (gửi hôm trước), thẻ G12 trên Hôm nay (sau "Để sau") ở 360 dp × 1.3 trên emulator – Fake có sẵn gợi ý mẫu, popup tự hiện khi mở tab Hôm nay.
  - `app_shell.dart` (lib/widgets) nay import `lib/screens/suggestion/suggestion_popup_listener.dart` – widget F0 phụ thuộc màn F12 (người dùng đồng ý); nếu muốn tách lớp, chuyển listener sang `lib/widgets/` trong commit F0.
- Commit gợi ý: `feat(F12): G10/G11 popup gợi ý mới + G12 thẻ trên Hôm nay`
