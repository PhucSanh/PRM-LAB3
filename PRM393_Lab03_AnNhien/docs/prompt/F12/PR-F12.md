# feat(F12): Gợi ý lịch – con cháu gửi, Bác nhận / đổi giờ / chọn từng việc / bỏ qua

Nhánh `feat/F12-suggest-schedule` → `main`. Người làm: Sanh (AI agent hỗ trợ theo `docs/prompt/F12/01…06`).

Con cháu (đã ghép nối) soạn 2 việc cho ngày mai, chọn giờ, gửi kèm lời nhắn → máy Bác mở Hôm nay thấy popup "Mai gửi lịch cho Bác" **một lần**, "Để sau" thì còn thẻ ở đầu Hôm nay → Bác nhận hết (**2 chạm**), đổi giờ, chọn từng việc, hoặc bỏ qua (có Hoàn tác). Lịch của Bác **chỉ đổi khi Bác bấm nhận**; bỏ qua **không báo lại** cho người gửi.

## Làm gì

1. **Service + model + khung ViewModel** (bước 01): `SuggestionService` (interface + `FakeSuggestionService` dùng chung cho "2 máy"), model `Suggestion` / `SuggestionItem` / `SuggestionTime`; `TaskItem` thêm `startDate`, `durationMin` (tuỳ chọn).
2. **G01 / G01b / G02** (bước 02): máy con cháu soạn 2 việc, chọn 1 giờ / việc, lời nhắn không bắt buộc → hỏi lại "Gửi gợi ý cho mẹ?" → "Đã gửi gợi ý cho mẹ". Chưa ghép nối → dẫn tới `/caregiver/pair`.
3. **G03 / G03b / G04 / G05 / G05b** (bước 03): Bác xem gợi ý, "Thêm vào lịch" 1 chạm, đổi giờ (G04 state toàn trang) → G03b → G05b. Lỗi giữa chừng → xoá các việc vừa lưu (lịch không nửa vời).
4. **G06 / G07 / G07b / G09** (bước 04): chọn từng việc (chọn nhiều, mặc định chọn hết) → nhận một phần (`partial`); bỏ qua → G09 → "Hoàn tác".
5. **G10 / G11 / G12** (bước 05): popup tự hiện ở tab Hôm nay, một lần, không tự đóng; thẻ G12 cho Khang đặt trên S03.
6. **Kiểm tra** (bước 06): test cả luồng 2 máy, ma trận tràn chữ (360×800 / 412×915 × 1.0 / 1.3 / 2.0 × thường / tương phản cao), quét luật bị chấm, sửa khoảng cách vùng chạm 20 dp, tự chấm `rule.md`, docs, đề xuất G08 cho Hương.

## Màn + route

| Route | Màn / state | Màn hình | ViewModel |
| --- | --- | --- | --- |
| `/caregiver/suggest` (máy con cháu, ngoài shell) | G01 · G01b · G02 · chưa ghép nối | `SuggestionComposeScreen` | `SuggestionComposeViewModel` (autoDispose) |
| `/today/suggestions/:id?from=popup\|card\|push\|family` (shell Bác) | G03 · G03b · G04 · G05 · G05b · G06 · G07 · G07b · G09 · không còn / lỗi | `SuggestionReviewScreen` | `SuggestionReviewViewModel` (autoDispose, family `(id, entry)`) |
| (popup trên tab Hôm nay) | G10 · G11 | `SuggestionPopupListener` + `SuggestionPopup` (bọc nội dung `AppShell`) | `SuggestionInboxViewModel` |
| (đầu S03 – Khang đặt) | G12 | `SuggestionCard` (F0) | `suggestionInboxViewModelProvider` |
| `/week/:date` | G08 · G08b · G08c · G08d | S11 của Hương – **chưa làm**, xem "Đề xuất G08" | `DayDetailViewModel` (Hương) |

Biến thể Figma là **state** (không thêm route). `app_router.dart`: chỉ thay 2 dòng placeholder (`/caregiver/suggest`, `suggestions/:id`) + import.

## Service / model / ViewModel mới

| Loại | Tên | Ghi chú |
| --- | --- | --- |
| Service | `SuggestionService` + `FakeSuggestionService(withSample:, delay:, failOnSend:, failOnLoad:, failOnAccept:)` | `send`, `watchPending`, `byId`, `markPopupShown`, `accept` (chỉ đổi `status`: hết → `accepted`, còn → `partial`, gọi lại được), `dismiss`, `undoDismiss`. Fake đếm `momNotified`, `senderNotified` (luôn 0). **Chỉ có Fake** |
| Model | `lib/models/suggestion.dart` | `Suggestion { id, fromUid, fromName, fromRelation*, message, items, status, popupShown, createdAt }`, `SuggestionItem { title, habitKey, date, hour, minute, durationMin, timeOptions*, accepted* }` (* = trường đề xuất, Hiếu chốt) |
| Model (sửa) | `TaskItem.startDate`, `TaskItem.durationMin` | Tuỳ chọn; `toMap` chỉ ghi khi có (`yyyy-MM-dd`), dữ liệu cũ vẫn đọc được |
| Provider | `suggestionServiceProvider` | `FakeSuggestionService(withSample: true, delay: Duration.zero)` + `TODO(Hiếu)` |
| ViewModel | `SuggestionComposeViewModel` | G01–G02: `selectTime`, `setMessage`, `requestSend`, `editAgain`, `send` |
| ViewModel | `SuggestionReviewViewModel` | G03–G09: `startChangeTime`, `pickTime`, `saveNewTime`, `cancelChangeTime`, `acceptAll`, `startChoosing`, `toggle`, `backToReview`, `continueChoosing`, `dismiss`, `undoDismiss` |
| ViewModel | `SuggestionInboxViewModel` | G10–G12: `pendingCard`, `popupToShow`, `sentToday`, `dayLabel`, `markPopupShown`, `later`; theo dõi `sessionProvider` (đổi tài khoản nghe đúng uid) |

## Event analytics (`docs/analytics-plan.md`)

| Event | Khi nào | Tham số |
| --- | --- | --- |
| `send_suggestion` | G01b "Gửi gợi ý" thành công | `items`, `source: suggest` |
| `accept_suggestion` ★ | G05 / G05b / G07 / G07b | `count`, `changed_time`, `partial`, `taps` (M6 – popup / thẻ + "Thêm vào lịch" = 2) |
| `dismiss_suggestion` | G09 | `items` |
| `undo_action` | "Hoàn tác" ở G09 | `action: dismiss_suggestion` |

Không gửi tên người gửi, lời nhắn, tên việc, uid (có test quét mọi tham số). Cách lấy bằng chứng DebugView (2 máy): `docs/analytics-plan.md` › Bằng chứng.

## Đối chiếu Figma (G01 → G12)

Đã gọi `get_design_context` + `get_screenshot` từng node (Figma MCP chập chờn: G05b chỉ có ảnh, G07b chỉ có code – đã ghi ở Kết quả chạy bước 03, 04). Ảnh Flutter tạm (đúng bề rộng khung, ×1.0) so từng khối với ảnh Figma.

| Node | Khớp / lệch | DT |
| --- | --- | --- |
| G01 `52:161`, G01b `52:230` | Lệch: gọi "mẹ" cả màn, back "Quay lại", nút giờ xếp dọc + "Đang chọn", ô lời nhắn trống + "Ví dụ", khối thông báo không viền, icon nút gửi là mũi tên; G01b nút giờ chỉ xem | DT-29 |
| G02 `56:2` | Lệch: không bottom nav, "Về lịch của mẹ", chip chỉ tên (chưa có quan hệ), thẻ việc `TaskRow` | DT-30 |
| G03 `56:107`, G03b `56:201`, G04 `57:2` | Lệch: "Đổi giờ đi bộ nhẹ nhàng", G03b hiện giờ đã đổi, back theo nơi mở, luôn có nav, "Đọc to" tắt, thẻ trích dẫn / khối trạng thái ghép F0, `TaskRow`; ở 412 dp G03 phải cuộn mới thấy thẻ 2 (4 nút đáy cao 72) | DT-31 |
| G05 `57:128`, G05b `58:2` | Lệch: back / nút phụ theo nơi mở, `TaskRow`, khối G05b bằng `FieldMessage.hint` | DT-31 |
| G06 `58:117` | Lệch: `HabitTile` (✓ + "Đã chọn"), câu phụ "…khi Bác bấm Tiếp tục.", câu nhắc khi chưa chọn | DT-32 |
| G07 `61:2`, G07b `61:118` | Lệch: việc chưa nhận không chip / viền nét đứt, câu "…thêm sau trong Gia đình." cho cả G07b | DT-32 |
| G09 `66:2` | Lệch: "Hoàn tác" chỉ là nút trên màn (không snackbar), chip "Bỏ qua" kiểu F0 (xám) | DT-32 |
| G10 `66:119`, G11 `71:2` | Lệch: một popup (dòng giờ chỉ khi gửi hôm nay), vòng icon 112, lời nhắn thật (mẫu có ngoặc kép – DT-28), ×1.3 phải cuộn trong popup tới 2 nút | DT-33, DT-28 |
| G12 `71:209` | Khớp (không tên việc, không "Bỏ qua gợi ý"); nút cao 72 | DT-33 |
| G08 – G08d | Chưa làm (S11 của Hương) | – |

Cột "Đã sửa Figma?" của DT-28 → DT-33 còn ☐: cần sửa Figma. 17 dòng F12 → `changed`, G12 `changed – chờ Khang`, G08* `todo (chờ Hương – F7 S11)`.

## Sửa ngoài phạm vi F12 (đã hỏi trước)

- `lib/models/task_item.dart` (Hiếu): thêm `startDate`, `durationMin` tuỳ chọn + `dateKey` / `parseDateKey` (bước 01, người dùng chọn "sửa ngay").
- `lib/models/suggestion.dart` (thư mục của Hiếu): file mới, người dùng đồng ý.
- `lib/services/providers.dart` (Hiếu): **chỉ thêm** `suggestionServiceProvider` + import. Bước 05 đổi Fake sang `delay: Duration.zero` vì `text_scale_overflow_test` dựng cả app ở `/today` bị Timer treo khi popup hiện.
- `lib/widgets/app_shell.dart` (F0): bọc body bằng `SuggestionPopupListener` (người dùng đồng ý) – `lib/widgets` nay import `lib/screens/suggestion/`.
- `lib/widgets/suggestion_card.dart` (F0): **chỉ comment** đoạn mẫu cho Khang (bỏ `previewTitles` / `onDismiss`, thêm `?from=card`).
- `docs/analytics-plan.md`: chỉ thêm "Cách lấy bằng chứng event F12".
- Không sửa `lib/screens/today/`, `today_view_model.dart`, S09 / S11, `/caregiver/*` của Hiếu, `firebase/`, `android/`, `lib/theme/`.

## Việc nhờ người khác

**Hiếu**

1. Bản Firebase `SuggestionService`: Firestore `users/{momUid}/suggestions`; FCM "có gợi ý mới" cho máy Bác, payload `route: /today/suggestions/<id>?from=push`. `dismiss` / `undoDismiss` **không** gửi gì cho người gửi.
2. Rules: con cháu đã ghép nối **tạo** gợi ý; mẹ đọc + cập nhật `status`, `popupShown`, `items[].accepted`; người lạ không đọc được.
3. Chốt schema: `fromRelation`, `items[].timeOptions`, `items[].accepted`, `items[].date` (`yyyy-MM-dd`); chốt `lib/models/suggestion.dart`.
4. Chốt `TaskItem.startDate` / `durationMin`. **`FirebaseTaskRepository.save` đang ném `schemaPending`** → trên máy thật "Thêm vào lịch" báo lỗi (đã xoá việc vừa lưu, không hỏng dữ liệu). `FakeTaskRepository.tasksForDay` chưa lọc theo ngày.
5. Lưu quan hệ con cháu ↔ mẹ khi ghép nối (F13) để hiện "Mai · Con gái" ở G02 / G03.
6. Lối vào G01 (`/caregiver/suggest`) từ C03 `/caregiver/schedule`.
7. Đề xuất hàm `watchOpen(momUid)` (gợi ý `partial` + `dismissed`) cho S09 của Hương.
8. `FakeProfileService.watch()` (`Stream.multi`) không phát trong `testWidgets` – test F12 dùng bản tạm `OneShotProfileService`.

**Khang (F3)**: dán thẻ G12 vào `_TodayList.build`, phần tử đầu của `ListView` (trên "Việc tiếp theo") – đoạn code trong comment `lib/widgets/suggestion_card.dart` (không truyền `previewTitles` / `onDismiss`). Popup không cần làm gì. F5: `SpeechService` để bật nút "Đọc to" ở G03–G09.

**Hương (F7, F11)**

- **G08 – G08d trên S11 `/week/:date`** – xem "Đề xuất G08" dưới.
- **S09 Gia đình**: hàng "Gợi ý từ Mai" cho gợi ý `partial` / `dismissed` → `/today/suggestions/<id>?from=family` (G07 "Bác có thể thêm sau trong Gia đình", G09 "xem lại gợi ý bất cứ lúc nào trong Gia đình").

**Sanh (F0)** – nếu muốn khớp Figma hơn (rồi bỏ dòng tương ứng trong DT): `AppIcons.add` (+), `AppIcons.send` (message-square); widget thẻ trích dẫn (avatar chữ cái + bong bóng), khối thông báo có nền / viền + chữ đậm, chip "Gợi ý của …", tuỳ chọn viền nét đứt, chip "Bỏ qua" màu đỏ, `IconCircle` cỡ 80; chuyển `SuggestionPopupListener` sang `lib/widgets/` nếu muốn tách lớp.

## Đề xuất G08 gửi Hương (S11 `/week/:date`)

Figma (đã đọc `get_design_context` 4 node):

| Khung | Node | Nội dung |
| --- | --- | --- |
| G08 (sau G05) | `61:233` | Back "Quay lại"; "Ngày mai · Thứ Sáu, 9/10"; "Lịch của Bác"; 2 thẻ (ô icon, tên, chip "Chưa làm", 🕘 "8:00 sáng · 20 phút"); khối ⓘ "Bác có thể đổi giờ bất cứ lúc nào."; nút chính "Về Hôm nay"; nav, tab **Lịch tuần** sáng |
| G08b (sau G05b) | `63:2` | **Giống hệt G08** (vẫn "8:00 sáng" – Figma chưa vẽ giờ đã đổi; code nên hiện giờ thật) |
| G08c (sau G07) | `63:102` | "Lịch của Bác · 1 việc"; 1 thẻ (đi bộ); **không** có khối trấn an; "Về Hôm nay" |
| G08d (sau G07b) | `63:179` | Như G08c, thẻ thư giãn "9:00 sáng · 15 phút" |

Khác S11 thường: G08 **chỉ hiện các việc vừa nhận từ gợi ý** (không thấy việc khác của Bác ngày mai); tiêu đề "Ngày mai · <thứ>, d/m"; dòng phụ "Lịch của Bác" (+ " · N việc" khi nhận một phần); khối "Bác có thể đổi giờ bất cứ lúc nào." chỉ khi nhận hết; một nút chính "Về Hôm nay"; không có đánh dấu "Mai gợi ý" trên thẻ.

Cách truyền đề xuất: G05 / G07 gọi `context.go('/week/<yyyy-MM-dd>?from=suggestion&ids=sg-<suggestionId>-0,sg-<suggestionId>-1')` (id việc đã lưu = `sg-<suggestionId>-<chỉ số>`, xem `SuggestionReviewViewModel._accept`). `DayDetailViewModel` đọc `from` / `ids`: có thì lọc `tasksForDay(date)` theo `ids` và vẽ state G08* (`partial` = số id < số việc của gợi ý → G08c / G08d). Phương án khác: thêm trường `fromSuggestionId` vào `TaskItem` (Hiếu chốt). Hiện "Xem lịch ngày mai" đi `/week/<yyyy-MM-dd>` (chưa có query) – F12 sẽ thêm `?from=suggestion&ids=…` khi Hương chốt.

## Tự chấm `rule.md` (11 nhóm luật) – phạm vi F12

| Nhóm luật | Kết quả | Chỗ chưa đạt / ghi chú |
| --- | --- | --- |
| 1. Đọc được ngay | Đạt | Chữ từ theme (≥ 20 sp), màu qua `ColorScheme`. `f12_overflow_test`: mọi state × 360×800 / 412×915 × 1.0 / 1.3 / 2.0 × thường / tương phản cao – không tràn (48 test) |
| 2. Ít chữ, nhiều icon | Đạt một phần | Mọi nút có icon + chữ. **Chưa:** nhãn "Đổi giờ đi bộ nhẹ nhàng" 5 tiếng; icon thay thế ("Thêm vào lịch" ✓ thay +, gửi ➜ thay message-square); `AppIcons.later` dùng cho cả "Đổi giờ" và "Để sau" |
| 3. Màu sắc | Đạt | Vạch màu + ô icon thói quen trên mọi thẻ việc; chip "Chưa làm" / "Bỏ qua"; lựa chọn có ✓ + chữ |
| 4. Chạm trúng | Đạt | Nút / ô / thẻ ≥ 72; nút chính full-width ở đáy; các vùng chạm kề nhau cách 20 (đã sửa ở bước 06: thanh đáy và thẻ G06 trước đó 12 / 16) |
| 5. Không phải đoán | Đạt | Back luôn có chữ; không thao tác vuốt; popup chỉ đóng bằng nút |
| 6. Biết làm hay chưa | Đạt một phần | Thẻ việc có chip "Chưa làm" / "Bỏ qua"; việc chưa nhận ở G07 ghi "Gợi ý của Mai" bằng chữ (không chip) |
| 7. Một việc mỗi màn | Đạt | Mỗi màn / popup đúng 1 nút filled; G03 có 4 lựa chọn ở đáy theo Figma |
| 8. Không sợ sai | Đạt | Lịch chỉ đổi khi bấm nhận; G01b hỏi lại trước khi gửi; bỏ qua có "Hoàn tác"; lỗi giữ dữ liệu + "Thử lại"; chưa chọn việc có "Ví dụ: …"; lỗi giữa chừng không để lịch nửa vời |
| 9. Giọng đọc | Chưa đạt | "Đọc to" tắt tạm (chưa có `SpeechService` – F5); ô lời nhắn G01 không có nút nói |
| 10. Lời lẽ | Đạt | Tiếng Việt, gọi "Bác" (máy Bác) / "mẹ" (máy con cháu); nút là động từ + việc; tên người gửi giữ nguyên |
| 11. Phong cách | Đạt | Màu, chữ, khoảng cách, bo góc từ `lib/theme/`; quét không có `Color(0x…)`, `Colors.*`, `fontSize:`, số khoảng cách cứng, `Icons.*` ngoài `AppIcons` |

## Đối chiếu "Xong khi" (`An-Nhien_Chia-task_Lab3.md` › F12)

| Tiêu chí | Kết quả | Bằng chứng / còn thiếu |
| --- | --- | --- |
| Mẹ nhận gợi ý ≤ 2 lần chạm (#6) | Đạt (Fake) | `suggestion_flow_test` TC-26 / TC-28, `f12_inbox_popup_test`: popup / thẻ → "Thêm vào lịch" = `taps 2` |
| Nhận tạo đúng việc trong lịch của mẹ | Đạt với Fake; **chưa** trên máy thật | Đúng tên, `once`, ngày mai, giờ (kể cả giờ đã đổi), thời lượng; nhận một phần chỉ lưu việc đã chọn. Máy thật chờ Hiếu (`FirebaseTaskRepository.save`) |
| Bỏ qua không báo lại cho con | Đạt (Fake) | `senderNotified == 0` sau bỏ qua / hoàn tác / nhận (service + flow test). Bản Firebase phải giữ đúng (việc nhờ Hiếu #1) |
| Thẻ G12 trên S03 qua widget F0, không sửa code F3 | Một phần | `SuggestionCard` + đoạn code trong comment; test dựng thẻ đúng đoạn code. **Chờ Khang dán** vào `today_screen.dart` |

## Ảnh cần chụp (máy ảo 360 dp, cỡ chữ "Rất lớn" ×1.3)

G01 · G01b · G02 · chưa ghép nối · lỗi gửi (G01b "Thử lại") · G10 (gợi ý hôm nay) · G11 (gợi ý hôm trước) · thẻ G12 trên Hôm nay (sau "Để sau", khi Khang đã dán) · G03 · G04 · G03b · G05 · G05b · G06 · G06 chưa chọn · G07 · G07b · G09 · G03 lỗi lưu ("Thử lại"). Fake có sẵn gợi ý mẫu `sample-mai` (popup tự hiện ở Hôm nay; mở thẳng `/today/suggestions/sample-mai?from=card`). Để chụp được G05 / G07 trên máy cần tạm đổi `taskRepositoryProvider` sang `FakeTaskRepository()` (trả lại trước khi commit).

## Checklist trước khi mở PR (`CLAUDE.md`)

- [x] `flutter analyze` sạch (chỉ 1 warning có sẵn `app_router.dart` `pendingNotification`, không phải F12); `flutter test`: không có lỗi mới (66 lỗi có sẵn trước F12, xem Kết quả chạy bước 06).
- [x] Màn vẽ đủ Loading / Empty / Error + Thử lại / Data (compose, review; popup / thẻ không chiếm chỗ khi tải / lỗi / trống).
- [x] Không màu / cỡ chữ / spacing cứng; chỉ dùng widget trong `lib/widgets/`.
- [x] Đúng ở 360 và 412 dp, `textScaler` 1.3 / 2.0 không tràn, cả tương phản cao.
- [x] Có test ViewModel với service Fake (cả nhánh Empty / Error).
- [x] Event analytics đã gắn theo `docs/analytics-plan.md`.
- [x] Cập nhật trạng thái màn trong `docs/design-traceability.md` (`changed` + DT-28 → DT-33; G08* `todo`).
- [x] Đối chiếu mục "Xong khi" (bảng trên).

## Commit gợi ý (theo thứ tự bước)

1. `feat(F12): SuggestionService (Fake) + model gợi ý + khung 3 ViewModel` – `lib/models/suggestion.dart`, `lib/models/task_item.dart`, `lib/services/suggestion_service.dart`, `lib/services/providers.dart`, `test/suggestion_service_test.dart`, `test/f12_view_models_test.dart`, `docs/prompt/F12/01-*.md`.
2. `feat(F12): G01/G01b/G02 con cháu soạn và gửi gợi ý lịch` – `lib/viewmodels/suggestion_compose_view_model.dart`, `lib/screens/suggestion/suggestion_compose_screen.dart`, dòng `/caregiver/suggest` trong `app_router.dart`, `test/f12_compose_test.dart`, `docs/prompt/F12/02-*.md`.
3. `feat(F12): G03–G05b Bác xem, đổi giờ và nhận gợi ý lịch` – `lib/viewmodels/suggestion_review_view_model.dart`, `lib/screens/suggestion/suggestion_review_screen.dart`, dòng `suggestions/:id` trong `app_router.dart`, `test/f12_review_test.dart`, `docs/prompt/F12/03-*.md`.
4. `feat(F12): G06/G07/G09 chọn từng việc, bỏ qua và hoàn tác gợi ý` – `test/f12_choose_dismiss_test.dart`, `docs/prompt/F12/04-*.md`.
5. `feat(F12): G10/G11 popup gợi ý mới + G12 thẻ trên Hôm nay` – `lib/viewmodels/suggestion_inbox_view_model.dart`, `lib/screens/suggestion/suggestion_popup_listener.dart`, `lib/widgets/app_shell.dart`, `lib/widgets/suggestion_card.dart` (comment), `test/f12_inbox_popup_test.dart`, `docs/prompt/F12/05-*.md`.
6. `test(F12): luồng 2 máy, tràn chữ, docs + PR` – `test/suggestion_flow_test.dart`, `test/f12_overflow_test.dart`, `docs/design-traceability.md`, `docs/architecture.md`, `docs/analytics-plan.md`, `docs/prompt/F12/06-*.md`, `docs/prompt/F12/PR-F12.md`.

Code đã sửa qua nhiều bước nằm chung một file (ViewModel review, màn review) – commit 3 / 4 tách bằng `git add -p` nếu cần giữ đúng thứ tự, hoặc gộp 3 + 4.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
