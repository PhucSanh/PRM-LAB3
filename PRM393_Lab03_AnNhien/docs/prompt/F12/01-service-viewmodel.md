# Bước 01 · F12 · SuggestionService + model + khung 3 ViewModel

Bạn là AI agent làm bước 01 của feature **F12 – Gợi ý lịch: Con cháu gửi ↔ Bác nhận** cho app An Nhiên (Flutter, MVVM + Riverpod, go_router). F0 đã merge vào `main`. Đọc hết file này rồi thực hiện.

## Mục tiêu

Có `SuggestionService` (interface + bản Fake dùng chung cho "2 máy" trong test), model gợi ý, và khung 3 ViewModel để các bước 02–05 chỉ còn vẽ màn. Chạy được hoàn toàn bằng Fake, không cần mạng. Bản Firebase (Firestore `users/{momUid}/suggestions` + FCM) là việc của **Hiếu**.

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

`CLAUDE.md`; `../An-Nhien_Chia-task_Lab3.md` mục F12 (nếu không có thì `docs/design-traceability.md` mục F12); `docs/architecture.md` sơ đồ tuần tự gợi ý lịch (đầu file, `SuggestionService` ↔ `users/{momUid}/suggestions`), mục 7.2, 8 (dòng `SuggestionService`, `PairingService`), 9 (3 ViewModel F12, `DayDetailViewModel`, `FamilyViewModel`, `CaregiverTaskFormViewModel` cũng dùng `SuggestionService`), 10 (`users/{momUid}/suggestions/{id}`), 15; `docs/analytics-plan.md` (4 event F12, chỉ số M6); `docs/test-plan.md` TC-26 → TC-28.

Code (chỉ đọc): `lib/services/task_repository.dart`, `lib/models/task_item.dart`, `lib/models/user_profile.dart` (`pairedMomUid`, `role`), `lib/services/profile_service.dart`, `lib/services/auth_service.dart`, `lib/services/analytics_service.dart`, `lib/services/crash_service.dart`, `lib/services/providers.dart`, `lib/models/notification_target.dart` (push mở `/today/suggestions/:id`), `lib/widgets/suggestion_card.dart` (**comment ở đầu file định sẵn tên provider / trường mà Khang sẽ dùng**), `lib/viewmodels/ui_state.dart`, `lib/viewmodels/first_task_view_model.dart` + `test/f2_view_models_test.dart` (mẫu), `lib/utils/app_error.dart`.

Figma: bước này không vẽ màn, nhưng **model + dữ liệu mẫu phải khớp Figma** – xem mục dưới.

## Dữ liệu trong Figma (để làm model + Fake – đã đối chiếu 04/11/2026)

- Người gửi: **"Mai"**, quan hệ **"Con gái"** (G03 thẻ trích dẫn, G02 chip "Mai · Con gái"), avatar chữ cái đầu "M".
- 2 việc gợi ý cho **ngày mai**: "Đi bộ nhẹ nhàng" – thói quen "Vận động tự nhiên" (`move`) – 8:00 sáng · 20 phút; "Thư giãn nhẹ nhàng" – "Thư giãn mỗi ngày" (`downshift`) – 9:00 sáng · 15 phút.
- Mỗi việc có **các giờ để chọn** 8:00 sáng / 9:00 sáng (G01, G01b nút giờ; G04 "Chọn giờ đi bộ:" 2 lựa chọn).
- Lời nhắn G03: "“Mẹ ơi, mai mình đi bộ với cô Tám nhé?”"; lời nhắn trong popup G10 / G11: "Mẹ ơi 3 giờ chiều mẹ đi bộ với cô Tám nh…" (khác nhau – xem điểm cần hỏi).
- Popup G10: "Mai vừa gửi lúc 4:20 chiều" → cần thời điểm gửi.
- Sau khi nhận một phần (G07 / G07b): việc chưa nhận vẫn hiện chip "Gợi ý của Mai" và "Chưa thêm vào lịch. Bác có thể thêm sau…" → gợi ý `partial` vẫn còn việc nhận tiếp được.
- G09: "Bác có thể xem lại gợi ý bất cứ lúc nào…" → gợi ý đã bỏ qua vẫn đọc lại được.

**Điểm Figma cần hỏi người dùng (dừng lại hỏi trước khi viết model):**
1. `architecture.md` mục 10 chưa có `fromRelation` ("Con gái") và giờ để chọn của từng việc (`timeOptions`). Đề xuất thêm 2 trường này vào model (ghi việc nhờ Hiếu chốt schema Firestore) – đồng ý không?
2. Fake dùng lời nhắn nào (G03 hay popup)? Đề xuất câu G03 cho cả hai, ghi `DT-xx` vì Figma lệch nhau.
3. `accept` một phần phải cho nhận tiếp việc còn lại sau này (G07 "Bác có thể thêm sau") – thêm hàm `acceptMore` / cho `accept` gọi nhiều lần trên gợi ý `partial`?


## Việc cần làm

1. **Kiểm tra trùng trước**: `git branch -a` + `git log --all -S "SuggestionService"`. Đã có ở nhánh nào (vd. Hiếu làm cho F14 C08) thì **dừng lại báo**, dùng bản đó, không viết bản thứ hai.
2. **Vấn đề ngày của việc**: gợi ý là việc cho **ngày mai** ("Ngày mai · 08:00 sáng · 15 phút"), nhưng `TaskItem` hiện **không có trường ngày** (chỉ `hour`, `minute`, `repeat`) và `FakeTaskRepository.tasksForDay` trả mọi việc. Kiểm lại; nếu vẫn vậy thì **dừng lại hỏi người dùng** chọn:
   - (a) đề xuất Hiếu thêm `date` (hoặc `startDate`) + `durationMin` vào `TaskItem` (`lib/models/` của Hiếu) – F12 tạm lưu việc nhận được với `repeat: once` và ghi `TODO(Hiếu)`; hoặc
   - (b) người dùng cho phép sửa `task_item.dart` ngay trong nhánh này (thêm trường tuỳ chọn, `fromMap` / `toMap` không phá dữ liệu cũ), ghi vào PR để Hiếu chốt.
3. **Model** (đúng `architecture.md` mục 10): `Suggestion { id, fromUid, fromName, message, items, status, popupShown, createdAt }`, `SuggestionItem { title, habitKey, date, hour, minute, durationMin }` (+ `fromRelation`, `timeOptions` nếu người dùng đồng ý ở điểm 1 mục "Dữ liệu trong Figma"), `enum SuggestionStatus { pending, accepted, partial, dismissed }`; có `fromMap` / `toMap` / `copyWith`. `lib/models/` là của Hiếu: **hỏi người dùng** đặt ở `lib/models/suggestion.dart` (đề xuất trong PR cho Hiếu chốt) hay tạm trong file service.
4. **`lib/services/suggestion_service.dart`** – interface theo `architecture.md` mục 8 (giữ đúng tên, thêm tham số cần thiết):
   - `Future<void> send(String momUid, Suggestion s)` (máy con cháu),
   - `Stream<List<Suggestion>> watchPending(String momUid)` (máy Bác, chỉ `pending`),
   - `Future<Suggestion?> byId(String momUid, String id)`,
   - `Future<void> markPopupShown(String momUid, String id)`,
   - `Future<void> accept(String momUid, String id, List<SuggestionItem> items)` – chỉ đổi `status` (`accepted` nếu nhận hết, `partial` nếu nhận một phần). **Tạo việc trong lịch do ViewModel gọi `TaskRepository.save`**, không làm trong service (để test được "lịch chỉ đổi khi bấm nhận").
   - `Future<void> dismiss(String momUid, String id)`, `Future<void> undoDismiss(String momUid, String id)` – không gửi gì cho người gửi.
   - **`FakeSuggestionService`**: lưu trong bộ nhớ theo `momUid`, có độ trễ nhỏ như `FakeTaskRepository`; một instance dùng chung được cho "máy con cháu gửi" và "máy Bác nhận" trong cùng test; có dữ liệu mẫu tuỳ chọn **đúng mục "Dữ liệu trong Figma"** ở trên (Mai · Con gái, "Đi bộ nhẹ nhàng" 8:00 sáng · 20 phút, "Thư giãn nhẹ nhàng" 9:00 sáng · 15 phút, cho ngày mai, lời nhắn theo câu trả lời điểm 2); cờ `failOnSend`, `failOnLoad`, `failOnAccept` ném `AppException` có `userMessage` cho Bác / con cháu; đếm số lần "báo cho người gửi" = 0 để test FR08.
5. **Provider**: đề xuất `suggestionServiceProvider` trỏ **bản Fake** (ghi `// TODO(Hiếu): bản Firebase`). `providers.dart` là của Hiếu → **hỏi người dùng trước khi sửa**; không được sửa thì in đoạn code để người dùng gửi Hiếu và tạm khai báo provider trong `suggestion_service.dart`.
6. **Khung 3 ViewModel** trong `lib/viewmodels/` (Riverpod `Notifier`, state định nghĩa trước, hàm để trống có `// TODO bước 0x`):
   - `suggestion_compose_view_model.dart` (G01, G01b, G02 – máy con cháu): form (danh sách việc, giờ từng việc, lời nhắn), cờ đang gửi, kết quả đã gửi. `momUid` lấy từ `UserProfile.pairedMomUid`; chưa ghép nối → state riêng (dẫn tới `/caregiver/pair`).
   - `suggestion_review_view_model.dart` (G03 → G07b, G09 – máy Bác): `UiState<SuggestionReview>` gồm gợi ý, giờ đã đổi theo từng việc, việc đang chọn (G06), bước hiện tại (`reviewing` / `choosing` / `accepted` / `acceptedPartial` / `dismissed`), số chạm từ lúc mở. Biến thể Figma là **state**, không phải route.
   - `suggestion_inbox_view_model.dart` (G10, G11, G12 – máy Bác): provider tên **`suggestionInboxViewModelProvider`**, state `UiState<SuggestionInbox>` có **`pendingCard`** (gợi ý `pending` mới nhất: `id`, `fromName`, `items[].title`) và `popupToShow` (gợi ý chưa `popupShown`); hàm `dismiss(id)`, `later(id)`. **Giữ đúng các tên này** vì `suggestion_card.dart` đã ghi sẵn cho Khang.
7. **Test** `test/suggestion_service_test.dart` + `test/f12_view_models_test.dart` (override bằng `overrideWithValue(Fake…)`): gửi rồi `watchPending` phát đúng; `accept` một phần → `partial`; `dismiss` → không còn trong `pending`, `undoDismiss` → trở lại; đếm báo người gửi = 0; cờ lỗi ném `AppException`; 3 ViewModel khung build được.
8. **Docs**: `docs/architecture.md` mục 8 (`SuggestionService` → "Đã có (Fake)", ghi chữ ký thật), mục 9 (cột "Có sẵn" 3 ViewModel = khung).

Được sửa: `lib/services/suggestion_service.dart` (mới), `lib/viewmodels/` (3 file mới), `test/` (file mới), `docs/architecture.md`; `lib/models/` và `providers.dart` chỉ khi người dùng đồng ý.

## Đầu ra mong đợi

- `SuggestionService` interface + Fake, test qua; 3 ViewModel khung build được.
- In cho người dùng: bảng hàm | Fake có cờ gì; câu trả lời mục 2; danh sách việc nhờ Hiếu (bản Firebase `SuggestionService` + FCM "có gợi ý mới" mở `/today/suggestions/:id`, rules cho con cháu đã ghép nối **tạo** gợi ý và mẹ cập nhật `status` / `popupShown`, trường ngày của `TaskItem`, chốt `lib/models/suggestion.dart`).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 04/11/2026, nhánh `feat/F12-suggest-schedule`. Không có `SuggestionService` ở nhánh nào khác (chỉ comment trong `suggestion_card.dart`).
- Người dùng trả lời: (1) thêm `fromRelation` + `timeOptions` (kèm `items[].accepted` để nhận tiếp gợi ý `partial`); (2) lời nhắn dùng câu G03 cho cả popup → DT-28; (3) `accept` gọi lại được trên gợi ý `partial`, không thêm hàm mới; ngày của việc: **(b)** sửa `task_item.dart` ngay (thêm `startDate`, `durationMin` tuỳ chọn); model đặt ở `lib/models/suggestion.dart`, provider thêm vào `providers.dart`.
- File đã tạo / sửa:
  - Mới: `lib/models/suggestion.dart`, `lib/services/suggestion_service.dart`, `lib/viewmodels/suggestion_compose_view_model.dart`, `lib/viewmodels/suggestion_review_view_model.dart`, `lib/viewmodels/suggestion_inbox_view_model.dart`, `test/suggestion_service_test.dart` (19 test), `test/f12_view_models_test.dart` (10 test).
  - Sửa (được đồng ý): `lib/models/task_item.dart` (`startDate`, `durationMin` tuỳ chọn; `toMap` chỉ ghi khi có; hàm `dateKey` / `parseDateKey`), `lib/services/providers.dart` (`suggestionServiceProvider` → `FakeSuggestionService(withSample: true)` + `TODO(Hiếu)`).
  - Docs: `docs/architecture.md` mục 8 (`SuggestionService` sang bảng "đã có – chỉ Fake", chữ ký thật), mục 9 (3 ViewModel = khung), mục 10 (trường đề xuất của suggestions, `startDate` / `durationMin` của tasks); `docs/design-traceability.md` DT-28. Trạng thái màn F12 giữ `todo` (bước này chưa vẽ màn).
- Lệch Figma (nếu có, lý do): DT-28 – lời nhắn popup G10 / G11 dùng câu G03 (Figma popup ghi "3 giờ chiều", mâu thuẫn giờ 8:00 / 9:00 sáng). Không vẽ màn nên chưa gọi Figma MCP; dữ liệu mẫu lấy từ bảng "Dữ liệu trong Figma" ở trên (đã đối chiếu 04/11) – bước 02–05 vẫn phải gọi Figma cho từng node.
- `flutter analyze` / `flutter test`: analyze còn 1 warning **có sẵn** (`app_router.dart:37` `pendingNotification` không dùng), không có lỗi mới. Test: trước khi sửa 241 qua / 66 lỗi; sau khi sửa 270 qua / 66 lỗi – 66 lỗi trùng đúng danh sách có sẵn (`auth_routing_test`, `router_test`…), 29 test F12 mới đều qua.
- Việc người dùng cần làm tay (gửi Hiếu):
  - Bản Firebase `SuggestionService` (Firestore `users/{momUid}/suggestions`) + FCM "có gợi ý mới" cho máy Bác, payload `route: /today/suggestions/{id}` (`notificationTarget` đã cho phép).
  - Rules: con cháu đã ghép nối **tạo** gợi ý; mẹ đọc + cập nhật `status` / `popupShown` / `items[].accepted`; người gửi không nhận gì khi mẹ bỏ qua (FR08).
  - Chốt schema: `fromRelation`, `items[].timeOptions`, `items[].accepted`, `items[].date` dạng `yyyy-MM-dd`; chốt `lib/models/suggestion.dart`.
  - Chốt `TaskItem.startDate` / `durationMin` (đang lưu chuỗi `yyyy-MM-dd`); `FirebaseTaskRepository.save` đang ném `schemaPending` nên nhận gợi ý bằng Firebase chưa lưu được; `FakeTaskRepository.tasksForDay` vẫn trả mọi việc, chưa lọc theo ngày (cần cho G08 "Lịch ngày mai").
- Commit gợi ý: `feat(F12): SuggestionService (Fake) + model gợi ý + khung 3 ViewModel`
