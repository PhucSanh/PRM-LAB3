# Bước 06 · F12 · G08 Lịch ngày mai, kiểm tra cả feature, chốt docs, soạn PR

Bạn là AI agent làm bước 06 (cuối) của feature **F12 – Gợi ý lịch**. Bước 01–05 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Nối G05 / G07 sang lịch ngày mai (G08–G08d trên S11 của Hương), chắc chắn F12 đạt "Xong khi", không vi phạm luật bị chấm, docs khớp code, có sẵn mô tả PR.

**Xong khi (file chia task):** Mẹ nhận gợi ý ≤ 2 lần chạm (chỉ số #6); nhận tạo đúng việc trong lịch của mẹ; bỏ qua không báo lại cho con. Thẻ G12 đặt trên S03 qua widget dùng chung của F0, không sửa vào code F3 của Khang.

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

`CLAUDE.md` (mục "Luật bị chấm", "Checklist trước khi mở PR"), `../An-Nhien_Chia-task_Lab3.md` mục F12, `docs/design-traceability.md` mục F12, `docs/architecture.md` mục 7–9 (dòng `DayDetailViewModel`: "F7 (chủ), F12 thêm state G08*"), 15, `docs/analytics-plan.md`, `docs/test-plan.md` TC-26 → TC-28, `rule.md` (11 nhóm luật), `docs/prompt/F12/0*.md` (Kết quả chạy các bước trước), `docs/prompt/F2/PR-F2.md` (mẫu PR), `docs/prompt/F2/07-kiem-tra-pr.md` (cách F2 kiểm tra).

## Figma (G08 – đã đối chiếu 04/11/2026, vẫn phải gọi `get_design_context` + `get_screenshot` cả 4 node)

| Khung | Node | Nội dung trong Figma |
| --- | --- | --- |
| G08 Lịch ngày mai | `61:233` | Sau G05. Back "Quay lại"; **"Ngày mai · Thứ Sáu, 9/10"**; **"Lịch của Bác"**; 2 thẻ việc (ô icon, tên, chip "Chưa làm", icon đồng hồ + "8:00 sáng · 20 phút"); khối có icon **"Bác có thể đổi giờ bất cứ lúc nào."**; nút chính **"Về Hôm nay"**; bottom nav, tab **"Lịch tuần"** đang chọn. |
| G08b Lịch ngày mai | `63:2` | Sau G05b (đã đổi giờ) – đọc trong Figma. |
| G08c Lịch ngày mai | `63:102` | Sau G07. **"Lịch của Bác · 1 việc"**, 1 thẻ (đi bộ), không có khối trấn an; "Về Hôm nay"; bottom nav. |
| G08d Lịch ngày mai | `63:179` | Sau G07b – đọc trong Figma. |

Trong Figma, G08 chỉ có các việc vừa nhận từ gợi ý (không thấy việc khác của Bác ngày mai) – ghi rõ điều này trong đề xuất gửi Hương.

## Việc cần làm

1. **G08 – G08d**: là state của S11 `/week/:date` (màn + `DayDetailViewModel` của **Hương**, F7). Kiểm S11 đã có chưa.
   - Chưa có / chưa có state này: **không tự làm S11**. Dùng bảng Figma ở trên + `get_design_context` 4 node, liệt kê khác biệt so với S11 thường (vd. đánh dấu việc vừa nhận từ gợi ý, câu "Mai gợi ý"), đề xuất cách truyền (vd. `/week/<date>?from=suggestion&ids=…` hoặc trường `fromSuggestionId` trên việc) và **in đề xuất để người dùng gửi Hương**. Giữ G08* ở `todo (chờ Hương – F7 S11)`.
   - Đã có và người dùng đồng ý: mở PR nhỏ nhờ Hương duyệt theo `CLAUDE.md` (ViewModel dùng chung có chủ), không sửa thẳng.
2. **Test cả luồng 2 máy**: `test/suggestion_flow_test.dart` – một `FakeSuggestionService` dùng chung, một `FakeTaskRepository` cho máy Bác:
   - Máy con cháu: `/caregiver/suggest` → soạn 2 việc → gửi → G02 (lịch Bác **chưa đổi**).
   - Máy Bác: mở Hôm nay → popup hiện **một lần** → "Xem gợi ý" → G03 → "Thêm vào lịch" → G05: đúng 2 việc, đúng giờ; `accept_suggestion.taps <= 2` (TC-26).
   - Nhánh: đổi giờ (G04 → G05b); chọn từng việc (G06 → G07, `partial`); bỏ qua → Hoàn tác (TC-27, số lần báo người gửi = 0); "Để sau" → thẻ G12, dựng lại app popup không hiện (TC-28).
   - Event không chứa tên người gửi / lời nhắn / tên việc.
3. **Đối chiếu Figma lần cuối**: với mỗi node G01 → G12, so ảnh màn Flutter (đúng bề rộng khung, `textScaler` 1.0) với `get_screenshot`; lập bảng node | khớp / lệch | DT-xx đưa vào `PR-F12.md`. Lệch mà chưa có `DT-xx` (chưa được người dùng đồng ý) thì sửa code cho khớp hoặc hỏi người dùng.
4. **Quét luật bị chấm** trong `lib/screens/suggestion/` + 3 ViewModel F12: không `FirebaseXxx.instance` / `http` trong widget; không logic trong `build()`; đủ Loading / Empty / Error + Thử lại / Data; không `Color(0x…)`, `Colors.*`, `fontSize:`, `EdgeInsets` / `SizedBox` số cứng, `Icons.*` ngoài `AppIcons`; không widget tự chế lặp widget F0. Sửa chỗ sai trong phạm vi F12; thiếu widget / icon thì liệt kê.
5. **Kiểm tra giao diện**: test tràn chữ cho mọi state F12 (G01 / G01b / G02, G03 / G03b / G04 / G05 / G05b / G06 / G07 / G07b / G09, popup G10 / G11, thẻ G12) ở 360×800 và 412×915, `textScaler` 1.0 / 1.3 / 2.0, thường và tương phản cao.
6. **Tự chấm `rule.md`** (11 nhóm): bảng nhóm luật | đạt / chưa | chỗ chưa đạt, cho phạm vi F12.
7. **Docs**:
   - `docs/design-traceability.md` mục F12: từng dòng → `done` / `changed` + `DT-xx` (cột "Đã sửa Figma?" để ☐); G08* và G12 ghi theo thực tế (chờ Hương / Khang).
   - `docs/architecture.md`: mục 7.2 (`/caregiver/suggest`, `/today/suggestions/:id` không còn placeholder), mục 8 (`SuggestionService`), mục 9 (3 ViewModel F12).
   - `docs/analytics-plan.md`: chỉ thêm "Cách lấy bằng chứng event F12" trong mục Bằng chứng (DebugView, cần 2 máy), **không** sửa phần khác.
   - `docs/test-plan.md`: **không** điền kết quả ARTEMIS (chạy trên máy thật sau); chỉ ghi tên file test Flutter tương ứng TC-26 → 28 nếu file có mục cho việc đó.
8. **Soạn `docs/prompt/F12/PR-F12.md`** (tiếng Việt, theo mẫu `PR-F2.md`): tiêu đề `feat(F12): …`, làm gì, màn + route, service / model / ViewModel mới, event analytics, lệch Figma (DT-xx), sửa ngoài phạm vi (nếu có, đã hỏi), **việc nhờ người khác** (Hiếu: Firebase `SuggestionService`, FCM, rules, trường ngày `TaskItem`, chốt model; Khang: dán thẻ G12 / popup; Hương: state G08* trên S11, hàng "Gợi ý từ Mai" ở S09 → `/today/suggestions/:id?from=family`), ảnh cần chụp, checklist "trước khi mở PR" trong `CLAUDE.md` đã tick.
9. Chạy `dart format` cho file F12, `flutter analyze`, `flutter test`; so số lỗi với mức có sẵn ghi ở bước 01.

Được sửa: `lib/screens/suggestion/`, 3 ViewModel F12, `lib/services/suggestion_service.dart`, `test/`, `docs/design-traceability.md`, `docs/architecture.md`, `docs/analytics-plan.md` (mục Bằng chứng), `docs/prompt/F12/`.

## Đầu ra mong đợi

- Test cả luồng 2 máy qua; analyze không có lỗi mới; docs khớp code; `PR-F12.md` sẵn sàng.
- In cho người dùng: bảng đối chiếu "Xong khi" (đạt / chưa), bảng tự chấm `rule.md`, đề xuất G08 gửi Hương, danh sách việc nhờ người khác, danh sách ảnh cần chụp, thứ tự commit gợi ý (mỗi bước 01–06 một commit).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 04/11/2026, nhánh `feat/F12-suggest-schedule`. Baseline trước bước 06: 340 qua / 66 lỗi có sẵn.
- G08 – G08d: S11 `/week/:date` vẫn là placeholder của Hương → **không tự làm**. Đã đọc `get_design_context` 4 node (`61:233` kèm ảnh, `63:2`, `63:102`, `63:179`): G08b giống hệt G08 (vẫn "8:00 sáng"); G08c / G08d "Lịch của Bác · 1 việc", không có khối trấn an. Đề xuất gửi Hương (lọc việc vừa nhận qua `/week/<date>?from=suggestion&ids=…` hoặc trường `fromSuggestionId`) ghi trong `PR-F12.md` › "Đề xuất G08". G08* giữ `todo (chờ Hương – F7 S11)`.
- File đã tạo / sửa:
  - Mới: `test/suggestion_flow_test.dart` (5 test luồng 2 máy: TC-26 / 27 / 28, đổi giờ, chọn từng việc; quét event không có tên / lời nhắn / tên việc / uid), `test/f12_overflow_test.dart` (48 test: G01→G02, G03→G04→G03b→G05b, G09→Hoàn tác→G06→G05, G06→G07, popup G10→G12 × 360×800 / 412×915 × 1.0 / 1.3 / 2.0 × thường / tương phản cao), `docs/prompt/F12/PR-F12.md`.
  - Sửa: `lib/screens/suggestion/suggestion_compose_screen.dart`, `suggestion_review_screen.dart` (R-TAP-03: nút ở thanh đáy và thẻ G06 cách nhau `AppSpacing.betweenTargets` 20 thay vì 12 / 16), `test/f12_inbox_popup_test.dart` (`App.pump` nhận `theme`).
  - Docs: `docs/design-traceability.md` (F12: 17 dòng `changed` + DT-29 → DT-33, G12 `changed – chờ Khang`, G08* `todo (chờ Hương – F7 S11)`), `docs/analytics-plan.md` (chỉ thêm "Cách lấy bằng chứng event F12"). `docs/architecture.md` mục 7.2 / 8 / 9 đã khớp từ bước 01–05 (không còn placeholder). `docs/test-plan.md` **không sửa** (không có cột / mục ghi file test Flutter cho TC-26 → 28; ARTEMIS chạy máy thật sau).
- Quét luật bị chấm (`lib/screens/suggestion/` + 3 ViewModel): không `Firebase…instance` / `http`, không `Color(0x…)` / `Colors.*` / `fontSize:` / khoảng cách số cứng / `Icons.*` ngoài `AppIcons`; màn không gọi service / log analytics; đủ Loading / Empty / Error + Thử lại / Data. Chỗ sai duy nhất: khoảng cách vùng chạm (đã sửa).
- Lệch Figma (nếu có, lý do): không thêm lệch mới. Bảng đối chiếu G01 → G12 (node | khớp / lệch | DT-28 → DT-33) trong `PR-F12.md`; mọi lệch đã được người dùng đồng ý ở bước 01–05.
- `flutter analyze` / `flutter test`: analyze còn 1 warning có sẵn (`app_router.dart:40` `pendingNotification`, không phải F12). Test: **393 qua / 66 lỗi** – 66 lỗi trùng đúng danh sách có sẵn ở bước 01 và đầu bước 06 (không có lỗi mới). 152 test F12 (8 file) đều qua.
- Việc người dùng cần làm tay:
  - Gửi Hương đề xuất G08 (PR-F12.md › "Đề xuất G08") + hàng "Gợi ý từ Mai" ở S09 → `/today/suggestions/<id>?from=family`.
  - Gửi Khang đoạn code thẻ G12 (comment `lib/widgets/suggestion_card.dart`); Khang F5: `SpeechService` cho "Đọc to".
  - Gửi Hiếu 8 việc trong PR-F12.md (bản Firebase `SuggestionService` + FCM `?from=push`, rules, chốt schema, `TaskItem.startDate` + `FirebaseTaskRepository.save` đang ném `schemaPending`, quan hệ khi ghép nối, lối vào G01 từ C03, `watchOpen`, `FakeProfileService.watch`).
  - Chụp ảnh theo danh sách trong PR-F12.md (360 dp × 1.3); sửa Figma cho DT-28 → DT-33 rồi tick ☐.
- Commit gợi ý: 6 commit theo thứ tự bước 01 → 06, danh sách file từng commit ở cuối `PR-F12.md` (commit 6: `test(F12): luồng 2 máy, tràn chữ, docs + PR`).
