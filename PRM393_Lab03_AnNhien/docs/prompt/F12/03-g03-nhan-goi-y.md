# Bước 03 · F12 · G03 / G03b / G04 / G05 / G05b Bác xem và nhận gợi ý

Bạn là AI agent làm bước 03 của feature **F12 – Gợi ý lịch**. Bước 01–02 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Màn G03 trên máy Bác: xem lời nhắn và các việc gợi ý ("Chưa thêm vào lịch. Bác tự chọn việc và giờ phù hợp."); **nhận hết bằng 1 chạm** (G05), hoặc đổi giờ một việc (G04 → G03b → G05b). Chỉ khi bấm nhận thì việc mới vào lịch. Đây là nhánh chính của chỉ số M6 (≤ 2 chạm).

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

`CLAUDE.md`, `docs/design-traceability.md` mục F12, `docs/prompt/F12/01-service-viewmodel.md` (Kết quả chạy – nhất là cách lưu **ngày** của việc), `lib/viewmodels/suggestion_review_view_model.dart`, `lib/services/suggestion_service.dart`, `lib/services/task_repository.dart`, `lib/services/reminder_service.dart` (đặt lời nhắc cho việc vừa nhận, giống F2 N05), `lib/viewmodels/first_task_view_model.dart` (cách F2 lưu việc + đặt nhắc – chỉ đọc), `lib/widgets/task_widgets.dart` (`TaskRow`), `lib/widgets/time_field.dart`, `lib/router/app_router.dart` (dòng `today/suggestions/:id`), `docs/analytics-plan.md` (`accept_suggestion`, M6), `flutter-handoff.md` mục G01 – G12.

## Figma (đã đối chiếu 04/11/2026 – vẫn phải gọi `get_design_context` lấy câu đầy đủ)

| Khung | Node | Nội dung trong Figma |
| --- | --- | --- |
| G03 Lịch Mai gợi ý | `56:107` | Back chữ **"Gia đình"**; tiêu đề **"Mai gửi lịch cho Bác"**; thẻ trích dẫn: avatar chữ "M", "Mai", "Con gái", bong bóng "“Mẹ ơi, mai mình đi bộ với cô Tám nhé?”"; nút **"Đọc to"** rộng hết hàng; tiêu đề nhóm "2 việc gợi ý"; 2 thẻ việc có viền trái màu: ô icon, tên, chip "Chưa làm", dòng "8:00 sáng · 20 phút"; thẻ trạng thái có icon **"Chưa thêm vào lịch. Bác tự chọn."**; chân màn ghim đáy: nút chính **"Thêm vào lịch"**, nút **"Đổi giờ đi bộ"**, nút **"Chọn từng việc"**, nút chữ **"Bỏ qua gợi ý"**. **Không có** bottom nav. |
| G03b Lịch Mai gợi ý · đã đổi giờ | `56:201` | Như G03; thẻ trạng thái **"Bác đã đổi giờ đi bộ sang 9:00 sáng. Chư…"** (lấy đủ câu); **có** bottom nav. |
| G04 Đổi giờ đi bộ | `57:2` | **State toàn trang, không phải hộp thoại**: back "Gia đình"; tiêu đề **"Đổi giờ đi bộ"**; thẻ trích dẫn + "Đọc to"; "2 việc gợi ý"; thẻ đi bộ (chip "Chưa làm", "8:00 sáng"); khối **"Chọn giờ đi bộ:"** với 2 lựa chọn radio **"8:00 sáng (Đang chọn)"** / **"9:00 sáng"**; thẻ thư giãn; thẻ trạng thái "Chưa đổi trên máy của Bác. Lịch chỉ thay…"; nút chính **"Lưu giờ mới"**, nút **"Quay lại"**; bottom nav. |
| G05 Đã nhận gợi ý | `57:128` | Back **"Quay lại Gia đình"**; **"Đã thêm vào lịch"**; "2 việc của Mai đã vào lịch ngày mai."; "Đọc to"; "2 việc đã nhận"; 2 thẻ: tên, tên thói quen ("Vận động tự nhiên" / "Thư giãn mỗi ngày"), chip "Chưa làm", "8:00 sáng · 20 phút"; nút chính **"Xem lịch ngày mai"**, nút **"Về Gia đình"**; bottom nav. |
| G05b Đã nhận · đổi giờ | `58:2` | Như G05, dòng giờ có icon đồng hồ; thêm khối có icon **"Bác có thể đổi giờ hoặc ngưng nhắc."** |

Codex (chỉ tham khảo): `codex-runs/G03/v3.html`, `G03b/v2.html`, `G04/v2.html`, `G05/v3.html`, `G05b/v1.html`. Handoff Lab 2 ghi "Thêm 2 việc vào lịch" – **Figma ghi "Thêm vào lịch", theo Figma**.

**Điểm Figma cần hỏi người dùng (dừng lại hỏi trước khi code):**
1. Nút "Đổi giờ đi bộ" / G04 chỉ đổi được **việc đi bộ** trong Figma. Gợi ý có việc khác hoặc nhiều việc thì: nút đổi giờ cho việc nào, nhãn là gì ("Đổi giờ " + tên ngắn của việc?)? G04 chỉ cho chọn trong các giờ của việc (8:00 / 9:00 – `timeOptions` ở bước 01), không dùng bánh xe giờ.
2. G03b: thẻ đi bộ trong Figma **vẫn ghi 8:00** dù câu trạng thái nói đã đổi sang 9:00. Đề xuất hiện giờ đã đổi (đúng dữ liệu) và ghi `DT-xx` – đồng ý không?
3. Nút back **"Gia đình"** / **"Quay lại Gia đình"** / **"Về Gia đình"**: Figma coi G03 mở từ Gia đình, Lab 3 còn mở từ popup / thẻ trên Hôm nay và thông báo. Giữ chữ Figma ở mọi nơi mở, hay đổi theo nơi mở? (Kiểm `AppBackBar` có cho đổi nhãn không.)
4. Bottom nav: G03 **không có**, G03b / G04 / G05 / G05b **có**. Route `/today/suggestions/:id` hiện nằm trong shell của Bác (có nav). Làm theo từng state của Figma hay thống nhất có nav, ghi `DT-xx`?
5. "Đọc to": kiểm `ReadAloudButton` (F0) đọc bằng gì (repo chưa có `flutter_tts`). Không đọc được thì hỏi: giữ nút theo Figma và ghi `DT-xx`, hay chờ package.

## Việc cần làm

1. Điền `SuggestionReviewViewModel` (phần G03 → G05b):
   - `load(id, {entry})`: `SuggestionService.byId`; không tìm thấy / đã xử lý → state riêng (Figma không vẽ → `EmptyView` + về Hôm nay, `DT-xx`); lỗi → `UiError` + `retry()`. `entry` = `popup` / `card` / `push` / `family` để đếm chạm: vào từ popup hoặc thẻ tính **1 chạm**.
   - `startChangeTime(itemIndex)` → state G04; `pickTime(option)` chọn trong các giờ của việc; `saveNewTime()` ("Lưu giờ mới") → state G03b, **chưa** ghi gì vào lịch; `cancelChangeTime()` ("Quay lại") → G03.
   - `acceptAll()` ("Thêm vào lịch"): tạo việc thật qua `TaskRepository.save` cho từng việc (đúng giờ đã đổi, đúng **ngày mai** theo cách chốt ở bước 01), đặt lời nhắc nếu đã cho phép, rồi `SuggestionService.accept` → state G05 (không đổi giờ) hoặc G05b (đã đổi giờ); log `accept_suggestion { count, changed_time, partial: false, taps }`; lỗi giữa chừng → không để lịch nửa vời (xoá việc đã lưu trong lần này hoặc báo rõ – chọn một, ghi lý do) + `CrashService.recordError` + `userMessage`.
2. Tạo `lib/screens/suggestion/suggestion_review_screen.dart`: G03, G03b, G04, G05, G05b là **state của cùng màn**, vẽ **đúng bảng Figma** – từng khối, từng chữ, đúng thứ tự. G04 là state toàn trang với 2 lựa chọn radio (`ChoiceGroup`), **không** dùng `showTimeWheel`. Thẻ trích dẫn, thẻ việc có viền trái + chip, khối có icon: chỉ dùng widget F0; thiếu thì **hỏi người dùng**. Đang lưu: nút "Thêm vào lịch" ở trạng thái tải, không bấm lại được. "Xem lịch ngày mai" → `/week/<yyyy-MM-dd ngày mai>` (S11 của Hương; G08 ở bước 06); "Về Gia đình" → `/family`; "Chọn từng việc" và "Bỏ qua gợi ý" để bước 04 (tạm gọi hàm trống).
3. Thay đúng dòng placeholder `suggestions/:id` dưới `/today` trong `app_router.dart` (chỉ dòng đó + import); đọc `entry` từ query (`?from=popup`).
4. Test: ViewModel – **trước khi bấm "Thêm vào lịch", `FakeTaskRepository` không có việc mới**; nhận hết → đủ việc, đúng giờ, status `accepted`; đổi giờ → việc lưu đúng giờ mới, `changed_time: true`, state G05b; vào từ popup + "Thêm vào lịch" → `taps == 2`; lỗi lưu → không có việc rác; event không chứa tên. Widget – G03 → "Đổi giờ đi bộ" → G04 → chọn "9:00 sáng" → "Lưu giờ mới" → G03b → "Thêm vào lịch" → G05b; **mọi chữ trong bảng Figma** có trên màn (`find.text`); 360 / 412 dp × 1.3 / 2.0 không tràn.
5. Đổi G03, G03b, G04, G05, G05b sang `doing` trong `docs/design-traceability.md`; mỗi chỗ lệch Figma (đã được đồng ý) thêm `DT-xx`.

Được sửa: `lib/screens/suggestion/`, `lib/viewmodels/suggestion_review_view_model.dart`, dòng `today/suggestions/:id` trong `app_router.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- `/today/suggestions/:id` hiện G03 đúng Figma; nhận hết / đổi giờ tạo đúng việc; M6 ≤ 2 chạm có test chứng minh.
- In cho người dùng: ảnh cần chụp (G03, G03b, G04, G05, G05b ở 360 dp × 1.3), lệch Figma.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 04/11/2026, nhánh `feat/F12-suggest-schedule`. Figma MCP chập chờn: `get_design_context` lấy được G03 `56:107`, G03b `56:201`, G04 `57:2`, G05 `57:128` (kèm ảnh); **G05b `58:2` lỗi 4 lần** – chỉ có ảnh `get_screenshot` (đọc rõ đủ chữ, gồm "Bác có thể đổi giờ hoặc ngưng nhắc."). `get_screenshot` riêng cho G03 / G03b / G05 bị mất kết nối; dùng ảnh trong `get_design_context`.
- Figma khác bảng tóm tắt (theo Figma): G03b câu trạng thái là **"Bác đã chọn giờ đi bộ. Chưa thêm vào lịch."** (bảng ghi "Bác đã đổi giờ đi bộ sang 9:00 sáng…").
- Người dùng trả lời: (1) một nút đổi giờ cho việc chưa nhận đầu tiên có ≥ 2 giờ, nhãn "Đổi giờ " + tên việc viết thường; (2) G03b hiện giờ đã đổi; (3) nhãn back theo nơi mở (`?from=family` giữ chữ Figma, nơi khác "Quay lại" / "Về Hôm nay"); (4) luôn có bottom nav; (5) "Đọc to" giữ nút, tắt tạm; ghép widget F0 + DT; G04 dùng `ChoiceGroup`, giữ bố cục Figma; lỗi giữa chừng → xoá các việc vừa lưu.
- File đã tạo / sửa:
  - Mới: `lib/screens/suggestion/suggestion_review_screen.dart` (G03 / G03b / G04 / G05 / G05b + Empty / Error là state của một màn), `test/f12_review_test.dart` (12 test ViewModel + 8 test widget).
  - Sửa: `lib/viewmodels/suggestion_review_view_model.dart` (family `(id, entry)` + autoDispose; `SuggestionEntry`; `load`, `startChangeTime`, `pickTime`, `saveNewTime`, `cancelChangeTime`, `acceptAll` – lưu việc `once` đúng ngày + giờ đã chọn, rồi `accept`, rồi đặt nhắc nếu có quyền; lỗi → xoá việc vừa lưu + Crashlytics; log `accept_suggestion`), `lib/router/app_router.dart` (chỉ dòng `suggestions/:id` + 2 import), `test/f12_view_models_test.dart` (gọi provider theo `(id, entry)`).
  - Docs: `docs/design-traceability.md` (G03, G03b, G04, G05, G05b → `doing`; G04 sửa loại "Dialog" → "State (toàn trang)"; DT-31), `docs/architecture.md` mục 7 (route có `?from=`), mục 9.
- Lệch Figma (nếu có, lý do): DT-31 (đã được người dùng đồng ý). Đối chiếu ảnh tạm (412 dp × 1.0 và 360 dp × 1.3, không commit) với Figma, ngoài DT-31:
  - G03 412 dp: 4 nút ghim đáy cao 72 nên chỉ thấy thẻ đi bộ, thẻ thư giãn + khối trạng thái phải cuộn (Figma: 2 thẻ + khối trạng thái thấy hết trong khung 1123 dp).
  - 360 dp × 1.3 (trong shell): thanh đáy ~60% vùng nội dung; nút "Thêm vào lịch" luôn thấy, nút phụ cuộn trong thanh đáy.
  - Nút "Đọc to" tắt: chữ + icon xám nhưng viền vẫn màu `primary` (kiểu disabled của `AppButton`).
  - G05 tiêu đề + câu phụ căn giữa như Figma; thẻ việc ô icon nền màu đậm như Figma G05 (G03 Figma cũng nền đậm).
- `flutter analyze` / `flutter test`: analyze còn 1 warning có sẵn (`app_router.dart:40` `pendingNotification`, dời dòng vì thêm import). Test: trước khi sửa 285 qua / 66 lỗi; sau khi sửa 305 qua / 66 lỗi – 66 lỗi trùng đúng danh sách có sẵn; 20 test mới đều qua, gồm: trước "Thêm vào lịch" lịch không có việc mới; nhận hết đủ 2 việc đúng ngày mai + giờ, status `accepted`, đặt nhắc; đổi giờ lưu đúng 9:00, `changed_time: true`, G05b; vào từ popup + "Thêm vào lịch" → `taps == 2` (M6); lỗi lưu việc 2 / lỗi `accept` → không còn việc rác; event chỉ có số / cờ; 360 / 412 dp × 1.3 / 2.0 không tràn, nút chính luôn thấy.
- Việc người dùng cần làm tay:
  - Chụp ảnh G03, G03b, G04, G05, G05b ở 360 dp × 1.3 trên emulator (mở `/today/suggestions/sample-mai?from=card` – Fake có sẵn gợi ý mẫu).
  - Thử lại `get_design_context` cho G05b `58:2` khi Figma MCP ổn định, đối chiếu lại (đã đối chiếu bằng ảnh).
  - Nhờ Khang (F5): `SpeechService` để bật "Đọc to". Nhờ Hiếu: `FirebaseTaskRepository.save` còn ném `schemaPending` (bước 01) nên nhận gợi ý bằng Firebase chưa lưu được; S11 `/week/:date` (Hương) còn placeholder nên "Xem lịch ngày mai" mới mở placeholder (G08 ở bước 06).
  - Nếu muốn khớp Figma hơn: thêm vào F0 icon "+", widget thẻ trích dẫn (avatar chữ cái + bong bóng), khối trạng thái có nền / viền (commit F0 riêng), rồi bỏ dòng tương ứng trong DT-31.
- Commit gợi ý: `feat(F12): G03–G05b Bác xem, đổi giờ và nhận gợi ý lịch`
