# Bước 02 · F12 · G01 / G01b / G02 Con cháu soạn và gửi gợi ý

Bạn là AI agent làm bước 02 của feature **F12 – Gợi ý lịch**. Bước 01 (`SuggestionService`, khung ViewModel) đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Trên máy con cháu (đã ghép nối): soạn gợi ý vài việc cho ngày mai, chọn giờ gợi ý, gửi cho mẹ; G02 báo đã gửi và nói rõ **mẹ tự chọn** nhận, đổi giờ hoặc bỏ qua. Lịch của mẹ **chưa đổi** khi gửi.

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

`CLAUDE.md`, `docs/design-traceability.md` mục F12, `docs/prompt/F12/01-service-viewmodel.md` (Kết quả chạy), `lib/viewmodels/suggestion_compose_view_model.dart`, `lib/services/suggestion_service.dart`, `lib/services/habit_repository.dart` (9 thói quen – không hard-code), `lib/widgets/time_field.dart`, `lib/widgets/choice_group.dart`, `lib/widgets/app_text_field.dart`, `lib/router/app_router.dart` (dòng `/caregiver/suggest`, các route `/caregiver/*` của Hiếu), `flutter-handoff.md` mục G01 – G12.

## Figma (đã đối chiếu 04/11/2026 – vẫn phải gọi `get_design_context` lấy câu đầy đủ)

| Khung | Node | Nội dung trong Figma |
| --- | --- | --- |
| G01 Con cháu soạn lịch gợi ý | `52:161` | Nút back chữ **"Gia đình"**; tiêu đề **"Gợi ý lịch cho mẹ"**; câu "Mẹ sẽ tự chọn nhận, đổi giờ hoặc bỏ qua."; **2 thẻ việc cố định** (ô icon thói quen + tên "Đi bộ nhẹ nhàng" / "Thư giãn nhẹ nhàng" + dòng "Vận động tự nhiên · 20 phút" / "Thư giãn mỗi ngày · 15 phút"), mỗi thẻ có **2 nút giờ nằm ngang** "8:00 sáng" / "9:00 sáng" (có icon); thẻ "Lời nhắn gửi kèm" + nhãn "Không bắt buộc" + ô nhập; khối có icon "Lịch của mẹ chỉ thay đổi khi mẹ bấm nhận"; nút chính ghim đáy **"Gửi gợi ý cho mẹ"**. Không có bottom nav, không có nút thêm / bỏ việc, không chọn thói quen. |
| G01b Soạn gợi ý · chọn giờ | `52:230` | Cùng khối như G01 nhưng 2 nút giờ **xếp dọc**; tiêu đề "Gợi ý lịch cho Bác", câu "Bác sẽ tự chọn nhận, đổi giờ hoặc bỏ qua", khối "Lịch của Bác chỉ thay đổi khi Bác bấm nh…"; **chân màn là bước xác nhận**: "Gửi gợi ý cho Bác?" + câu "Lịch của Bác chỉ cập nhật khi Bác bấm nh…" + nút chính **"Gửi gợi ý"** + nút **"Sửa lại"**. |
| G02 Đã gửi gợi ý | `56:2` | Back "Quay lại"; ô icon tròn; chip "Mai · Con gái"; tiêu đề **"Đã gửi gợi ý cho mẹ"**; "Mẹ sẽ tự chọn nhận, đổi giờ hoặc bỏ qua."; khối có icon "Lịch của mẹ chưa thay đổi. Việc chỉ vào …"; "2 việc gợi ý cho ngày mai" + 2 thẻ (icon, tên, icon đồng hồ + "8:00 sáng · 20 phút", chip "Chưa làm"); nút chính **"Về Gia đình"**; **bottom nav 4 tab** (Hôm nay · Lịch tuần · Thói quen · Gia đình). |

Codex (chỉ tham khảo): `codex-runs/G01/v2.html`, `G01b/v2.html`, `G02/v1.html`.

**Điểm Figma cần hỏi người dùng (dừng lại hỏi trước khi code):**
1. G01 gọi người nhận là **"mẹ"**, G01b gọi là **"Bác"** – dùng cách gọi nào cho cả G01 / G01b / G02 (hay lấy theo `honorific` của mẹ)?
2. 2 việc trong G01 là cố định trong Figma. Khi code lấy từ đâu: `habits/{key}.suggestions[]` (architecture mục 10, chưa có dữ liệu), 9 thói quen trong `HabitRepository`, hay danh sách mẫu trong Fake? (`CLAUDE.md` cấm hard-code danh sách thói quen.)
3. G01 có back "Gia đình", G02 có nút "Về Gia đình" + bottom nav của Bác, trong khi G01 chạy trên **máy con cháu** (`/caregiver/suggest` nằm ngoài shell của Bác). Giữ đúng Figma hay đổi theo điều hướng chế độ Con cháu (vd. về `/caregiver/schedule`) và ghi `DT-xx`?
4. G01: bấm một nút giờ là chọn giờ đó cho việc (một việc chọn đúng 1 giờ)? Đọc trong `get_design_context` nút nào đang ở trạng thái chọn; Figma không rõ thì hỏi.

## Việc cần làm

1. Điền `SuggestionComposeViewModel`:
   - `load()`: `pairedMomUid` + tên / quan hệ người gửi qua service; chưa ghép nối → state riêng (Figma không vẽ → `EmptyView` + nút đi `/caregiver/pair`, ghi `DT-xx`).
   - Danh sách việc theo câu trả lời điểm 2; `selectTime(itemIndex, option)` chọn trong các giờ của việc (Figma: 8:00 sáng / 9:00 sáng); `setMessage` (không bắt buộc).
   - `requestSend()` ("Gửi gợi ý cho mẹ") → state xác nhận G01b; `editAgain()` ("Sửa lại") → về G01, giữ nguyên dữ liệu; `send()` ("Gửi gợi ý") gọi `SuggestionService.send` → state G02; log `send_suggestion { items: n, source: 'suggest' }`; lỗi → `CrashService.recordError` non-fatal + `userMessage`, giữ nguyên dữ liệu; chống bấm 2 lần.
2. Tạo `lib/screens/suggestion/suggestion_compose_screen.dart`: G01, G01b, G02 là **state của cùng màn**, vẽ **đúng bảng Figma** – từng khối, từng chữ, đúng thứ tự, đúng nút chính / phụ. Nút giờ, ô lời nhắn, khối thông báo có icon, chip: chỉ dùng widget F0 (`ChoiceGroup`, `AppTextField`, `FieldMessage`…); thiếu widget cho thẻ việc có nút giờ thì **hỏi người dùng**. Lỗi gửi (Figma không vẽ): câu `userMessage` + "Thử lại", ghi `DT-xx`.
3. Đường vào G01: theo câu trả lời điểm 3. Màn của Hiếu chưa có lối vào thì **báo người dùng** (việc nhờ Hiếu), không tự sửa màn của Hiếu.
4. Thay đúng dòng placeholder `/caregiver/suggest` trong `app_router.dart` (chỉ dòng đó + import).
5. Test: ViewModel (chọn giờ → gửi đúng dữ liệu vào Fake; "Sửa lại" giữ dữ liệu; lỗi → giữ form; event `send_suggestion` đúng, không chứa tên / lời nhắn; chưa ghép nối); widget (G01 → chọn giờ → "Gửi gợi ý cho mẹ" → G01b → "Sửa lại" → G01 → gửi lại → "Gửi gợi ý" → G02; **mọi chữ trong bảng Figma** có trên màn bằng `find.text`; 360 / 412 dp × 1.3 / 2.0 không tràn).
6. Đổi G01, G01b, G02 sang `doing` trong `docs/design-traceability.md`; mỗi chỗ lệch Figma (đã được người dùng đồng ý) thêm `DT-xx`.

Được sửa: `lib/screens/suggestion/`, `lib/viewmodels/suggestion_compose_view_model.dart`, dòng `/caregiver/suggest` trong `app_router.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- `/caregiver/suggest` gửi được gợi ý vào Fake, đủ 3 state đúng Figma.
- In cho người dùng: ảnh cần chụp (G01, G01b, G02 ở 360 dp × 1.3; lỗi gửi), đường vào G01 có chưa, lệch Figma.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 04/11/2026, nhánh `feat/F12-suggest-schedule`. Đã gọi `get_design_context` + `get_screenshot` cho `52:161`, `52:230`, `56:2`.
- Người dùng trả lời: (1) gọi "mẹ" cho cả G01 / G01b / G02; (2) 2 việc là mẫu trong ViewModel, tên thói quen nạp từ `HabitRepository`; (3) điều hướng theo chế độ Con cháu (back "Quay lại", G02 "Về lịch của mẹ" → `/caregiver/schedule`, không bottom nav); (4) một việc chọn đúng một giờ. Thêm: ghép widget F0 + ghi DT (không thêm widget / icon); `fromRelation` để trống chờ Hiếu; ô lời nhắn để trống + "Ví dụ: …"; nút giờ luôn xếp dọc.
- File đã tạo / sửa:
  - Mới: `lib/screens/suggestion/suggestion_compose_screen.dart` (G01 / G01b / G02 + chưa ghép nối là state của một màn), `test/f12_compose_test.dart` (7 test ViewModel + 8 test widget).
  - Sửa: `lib/viewmodels/suggestion_compose_view_model.dart` (điền đủ: `load`, `selectTime`, `setMessage`, `requestSend`, `editAgain`, `send`; autoDispose; `suggestionClockProvider` để test cố định "ngày mai"), `lib/router/app_router.dart` (chỉ dòng `/caregiver/suggest` + import), `test/f12_view_models_test.dart` (override `habitRepositoryProvider`).
  - Docs: `docs/design-traceability.md` (G01, G01b, G02 → `doing`; DT-29, DT-30), `docs/architecture.md` mục 7 (route `/caregiver/suggest` có), mục 9 (ViewModel xong bước 02).
- Lệch Figma (nếu có, lý do): DT-29 (G01 / G01b) và DT-30 (G02, chưa ghép nối) – tất cả đã được người dùng đồng ý. Đối chiếu ảnh tạm (412 dp × 1.0, 360 dp × 1.3, không commit) với `get_screenshot`, ngoài các điểm trong DT:
  - G01: chỉ thấy 2 thẻ việc trong khung 921 dp; ô lời nhắn + khối thông báo nằm dưới, phải cuộn (nút giờ dọc 72 dp làm thẻ cao hơn).
  - Ô icon thói quen G02 nền màu đậm + icon trắng (`HabitBadge`), Figma nền nhạt.
  - Vạch màu trái của thẻ giữ 6 dp như Figma; thẻ dùng viền `outlineVariant` 1 dp (Figma 2 dp).
  - 360 dp × 1.3: tiêu đề xuống 2 dòng, "Đang chọn" xuống dưới giờ – không tràn.
- `flutter analyze` / `flutter test`: analyze còn 1 warning có sẵn (`app_router.dart:38` `pendingNotification`, dời 1 dòng vì thêm import). Test: trước khi sửa 270 qua / 66 lỗi; sau khi sửa 285 qua / 66 lỗi – 66 lỗi trùng đúng danh sách có sẵn, 15 test mới đều qua (gồm 360 / 412 dp × 1.3 / 2.0 không tràn, lỗi gửi ở 360 dp × 2.0 vẫn thấy "Thử lại" + "Sửa lại").
  - Ghi chú: `FakeProfileService.watch` và `FakeSuggestionService.watchPending` (`Stream.multi`) không phát trong fake-async của `testWidgets`; test widget dùng `OneShotProfileService` (`Stream.value`) và `tester.runAsync` để đọc Fake.
- Việc người dùng cần làm tay:
  - Chụp ảnh G01, G01b, G02 ở 360 dp × 1.3 và trạng thái lỗi gửi trên emulator (ảnh tạm của agent ở scratchpad, không commit).
  - **Chưa có đường vào G01**: màn C03 `/caregiver/schedule` (Hiếu, F14) còn là placeholder. Nhờ Hiếu thêm nút mở `/caregiver/suggest` (vd. trên C03) – không tự sửa màn của Hiếu.
  - Nhờ Hiếu: lưu quan hệ của con cháu với mẹ khi ghép nối (F13) để G02 hiện "Mai · Con gái"; `habits/{key}.suggestions[]` để thay 2 việc mẫu.
  - Nếu muốn khớp Figma hơn: thêm `AppIcons.send` (message-square), widget khối thông báo có viền + chữ đậm, chip nhỏ vào F0 (commit F0 riêng), rồi bỏ các dòng tương ứng trong DT-29 / DT-30.
- Commit gợi ý: `feat(F12): G01/G01b/G02 con cháu soạn và gửi gợi ý lịch`
