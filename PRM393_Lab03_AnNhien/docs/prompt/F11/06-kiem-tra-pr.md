# Bước 06 · F11 · Kiểm tra cả feature, đối chiếu Figma, chốt docs, soạn PR

Bạn là AI agent làm bước 06 (cuối) của feature **F11 – Gia đình**. Bước 01–05 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Chắc chắn F11 đạt "Xong khi", khớp Figma, không vi phạm luật bị chấm, docs khớp code, có sẵn mô tả PR.

**Xong khi (file chia task):** Số sai hiện S12e có ví dụ; từ chối quyền danh bạ vẫn tự nhập được; xoá người thân có xác nhận.

## Quy tắc chung (áp dụng cho mọi bước)

- Làm việc ở thư mục gốc repo `PRM393_Lab03_AnNhien`, nhánh F11 (kiểm bằng `git branch --show-current`, dạng `feat/F11-…`, vd. `feat/F11-gia-dinh`). Đọc `CLAUDE.md` trước tiên và tuân theo. Người chạy prompt là **Hương** (chủ F11).
- **Figma là nguồn đúng duy nhất cho giao diện và câu chữ.** File key `K3JczHkChbUWoDBkXZYMhR`. Trước khi viết code một màn / state: gọi `get_design_context` **và** `get_screenshot` cho **từng** node được liệt kê (không bỏ node nào, kể cả state). Chép **nguyên văn** mọi chữ trong Figma (tiêu đề, câu mô tả, nhãn nút, gợi ý "Ví dụ: …", lỗi, nhãn nút Quay lại). Nhiều layer chữ trong Figma tên là "Text" hoặc bị cắt ở 40 ký tự → phải đọc câu đầy đủ từ `get_design_context` / ảnh. Giữ đúng thứ tự khối, nút nào là nút chính / phụ, nút xếp ngang hay dọc, có hay không có bottom nav, icon nào ở đâu. **Không tự thêm** khối, nút, câu chữ, hộp thoại mà Figma không có; **không bỏ** thứ Figma có. Bảng "Figma" trong file này là bản tóm tắt đã đối chiếu ngày 04/11/2026 – vẫn phải gọi Figma MCP; Figma khác bảng thì **theo Figma**.
- Figma không vẽ (đang tải / lỗi / trống / bị từ chối quyền) thì dùng `LoadingView` / `ErrorView` / `EmptyView` có sẵn và ghi `DT-xx`. Figma mâu thuẫn với chính nó, với handoff Lab 2, với luật đề / `rule.md` / `CLAUDE.md`, hoặc không vẽ được bằng widget F0 → **dừng lại hỏi người dùng** (mỗi file có mục "Điểm Figma cần hỏi"), không tự chọn. Chỉ lệch Figma khi người dùng đồng ý, và mọi chỗ lệch phải có dòng `DT-xx`.
- Làm xong mỗi màn: dựng màn Flutter đúng bề rộng khung Figma (**360 dp**, `textScaler` 1.0), chụp ảnh tạm (không commit) và **so từng khối với ảnh `get_screenshot`**; liệt kê mọi chỗ khác trong "Kết quả chạy".
- Không có Figma MCP thì **dừng lại báo người dùng**, không tự làm theo Stitch. Stitch HTML (`../../prm393-lab2-an-nhien/stitch-runs/<mã màn>/`) và `flutter-handoff.md` chỉ để tham khảo hành vi; lệch thì **Figma thắng**.
- Tài liệu Lab 2 (chỉ đọc) ở `../../prm393-lab2-an-nhien/`: `flutter-handoff.md` mục S09, S12, S17 và bảng "N01 – N21" (N09, N10, N15, N21), `ux/user-flow.md` (Flow 5, Flow 9), `rule.md`, `accessibility.md`, `assets/stitch/DESIGN.md`, `assets/stitch/AppStyleGuide.md`, `assets/stitch/vocabulary.md`.
- **Luật riêng của F11 (đề + Lab 2, bị chấm):** số sai / thiếu số hiện lỗi **có "Ví dụ: …"** và giữ nguyên tên + quan hệ đã nhập; **từ chối quyền danh bạ vẫn tự nhập được**; xoá người thân **phải hỏi lại** (N15) và nói rõ hậu quả; app **không bao giờ** báo "Đã gửi" tin nhắn (S17b / N10 chỉ nói "chưa xác nhận"); "Gọi điện" mở ngay, không hộp thoại phụ.
- **Chỉ dùng widget trong `lib/widgets/`** (`AppButton`, `AppBackBar`, `AppTextField`, `ChoiceGroup`, `FieldMessage`, `showConfirmDialog`, `showUndoSnackbar`, `IconCircle`, `LoadingView` / `EmptyView` / `ErrorView`…). Icon chỉ lấy từ `AppIcons`. Thiếu widget / icon (vd. thẻ người thân có 2 nút, hàng danh bạ, thẻ radio có icon) thì **dừng lại, báo Sanh (F0)** – không tự làm bản riêng trong thư mục màn.
- **Không được sửa**: `android/`, `firebase/`, `lib/main.dart`, `lib/app.dart`, `lib/theme/`, `lib/widgets/` (Sanh), bản `Firebase…` của service, `lib/services/providers.dart`, service có sẵn và `lib/models/` (Hiếu) – muốn sửa thì **hỏi người dùng trước**, không được thì in đoạn code để gửi Hiếu / Sanh. Không sửa màn / ViewModel của người khác (`lib/screens/today/`, `lib/screens/suggestion/` + ViewModel F12 của Sanh – chỉ **đọc / dùng** `suggestionInboxViewModelProvider`). Trong `app_router.dart` chỉ thay đúng dòng placeholder của F11 + import. **Không tự thêm package** (`url_launcher`, `share_plus`, `flutter_contacts`, `permission_handler`…): hỏi người dùng, đề xuất trong PR theo `CLAUDE.md`.
- Kiến trúc: View chỉ vẽ `UiState` bằng `switch` và gửi sự kiện; logic, validate, gọi service, log analytics nằm trong ViewModel (`Notifier`). Gọi điện / mở Zalo / SMS / đọc danh bạ **chỉ qua service** (interface + Fake), không gọi plugin trong widget. Hành động một lần (lưu, xoá, mở app nhắn tin…) trả kết quả về View để điều hướng / hiện thông báo.
- Không viết cứng màu / cỡ chữ / khoảng cách: chỉ dùng `lib/theme/` (màu qua `Theme.of(context).colorScheme` để tương phản cao có tác dụng). Chữ ≥ 20 sp, vùng chạm ≥ 72 dp, cách nhau `AppSpacing.betweenTargets`; kiểm tra 360 và 412 dp, `textScaler` 1.3 và 2.0 không tràn (cả khi bàn phím mở), cả chế độ tương phản cao. Ô số điện thoại `keyboardType: TextInputType.phone`, `autofillHints: [AutofillHints.telephoneNumber]`.
- Câu chữ theo `AppStyleGuide.md` + `vocabulary.md` (gọi người dùng là "Bác", nút = động từ + việc, lỗi có "Ví dụ: …").
- Analytics chỉ gửi khoá / số / cờ (**không** gửi tên người thân, số điện thoại, nội dung tin nhắn). Tên event theo `docs/analytics-plan.md` (`add_relative`, `share`); **không tự đặt event mới**.
- Gặp chỗ không chắc (thiếu file, Figma mâu thuẫn, cần sửa file ngoài phạm vi, cần package) thì **dừng lại hỏi**, không đoán.
- Docs: màn đang làm thì đổi cột Trạng thái trong `docs/design-traceability.md` mục F11 từ `todo` → `doing` (bước 06 mới chốt `done` / `changed`). Lệch Figma thì thêm dòng `DT-xx` cuối file (lấy số tiếp theo sau dòng `DT-` lớn nhất hiện có). Thêm / đổi service, ViewModel, route thì cập nhật `docs/architecture.md` (mục 7, 8, 9).
- Không tự `git commit` / `push`. Trước khi sửa, chạy `flutter test` một lần và ghi lại số lỗi **có sẵn**; chỉ chịu trách nhiệm lỗi mới. `dart format` **chỉ cho file F11 đã tạo / sửa** (chạy `dart format lib test` sẽ định dạng lại file của người khác). Chạy `flutter analyze` và `flutter test` tới khi không có lỗi mới rồi mới báo xong.
- Xong việc: điền mục **"Kết quả chạy"** ở cuối chính file này (thay các dòng trống), rồi in tóm tắt cho người dùng.

## Đọc trước

`CLAUDE.md` (mục "Luật bị chấm", "Checklist trước khi mở PR"), `../An-Nhien_Chia-task_Lab3.md` mục F11, `docs/design-traceability.md` mục F11, `docs/architecture.md` mục 7–9, 15, `docs/analytics-plan.md`, `docs/test-plan.md` (TC-08, TC-31 – Hương là chủ file), `rule.md` (11 nhóm luật), `docs/prompt/F11/0*.md` (Kết quả chạy các bước trước), `docs/prompt/F2/PR-F2.md` (mẫu PR), `docs/prompt/F2/07-kiem-tra-pr.md` (cách F2 kiểm tra).

## Việc cần làm

1. **Test cả luồng**: `test/family_flow_test.dart` – `ProviderScope` override toàn bộ service bằng Fake, mở `/family`:
   - Flow 5: S09 → "Thêm người thân" → bấm "Lưu người thân" khi chưa có số → S12e có "Ví dụ: 0912 345 678", tên + quan hệ còn nguyên → nhập số sai → lỗi → sửa đúng → lưu → S09b có banner, người mới ở cuối (TC-08).
   - Danh bạ: chọn liên hệ → điền sẵn → lưu (`from_contacts: true`); **từ chối quyền** → vẫn tự nhập và lưu được.
   - Sửa / xoá: chạm người thân → N09 → sửa → lưu (Hoàn tác theo bước 04); → "Xóa khỏi An Nhiên" → N15 → "Giữ lại" (không xoá) → lại → xoá → N21 → "Hoàn tác" → người thân quay lại.
   - Flow 9: "Nhắn tin" → S17 → Zalo → "Tiếp tục nhắn tin cho Mai" → S17b / N10; **không có chữ "Đã gửi"** ở bất kỳ màn nào (TC-31); event `share` đúng.
   - Hàng "Gợi ý từ Mai" có khi `FakeSuggestionService` có gợi ý, bấm → `/today/suggestions/<id>?from=family`.
   - Event `add_relative` / `share` không chứa tên, số, nội dung tin.
2. **Đối chiếu Figma lần cuối**: với mỗi node của F11 (`1:1993`, `26:2`, `1:2110`, `1:2146`, `1:2215`, `14:120`, `14:196`, `41:136`, `43:263`, `52:48`, `1:2278`, `26:122`, `41:205`), dựng màn Flutter ở 360 dp, `textScaler` 1.0, so với `get_screenshot`; lập bảng node | khớp / lệch | DT-xx đưa vào `PR-F11.md`. Lệch mà chưa có `DT-xx` (chưa được người dùng đồng ý) thì sửa code cho khớp hoặc hỏi người dùng.
3. **Quét luật bị chấm** trong `lib/screens/family/` + 3 ViewModel F11 + 2 service mới: không `FirebaseXxx.instance` / `http` / plugin (`launchUrl`, `Share`, `FlutterContacts`) trong widget; không logic trong `build()`; đủ Loading / Empty / Error + Thử lại / Data; không `Color(0x…)`, `Colors.*`, `fontSize:`, `EdgeInsets` / `SizedBox` số cứng, `Icons.*` ngoài `AppIcons`; không widget tự chế lặp widget F0. Sửa chỗ sai trong phạm vi F11; thiếu widget / icon thì liệt kê để báo Sanh.
4. **Kiểm tra giao diện**: test tràn chữ cho mọi màn / state F11 ở 360×800 và 412×915, `textScaler` 1.0 / 1.3 / 2.0, thường và tương phản cao, form có bàn phím mở (nút Lưu không bị che).
5. **Tự chấm `rule.md`** (11 nhóm): bảng nhóm luật | đạt / chưa | chỗ chưa đạt, cho phạm vi F11.
6. **Docs**:
   - `docs/design-traceability.md` mục F11: 13 dòng → `done` (khớp Figma) hoặc `changed` + `DT-xx` (cột "Đã sửa Figma?" để ☐).
   - `docs/architecture.md`: mục 7.2 (4 route `/family*` không còn placeholder), mục 8 (2 service mới), mục 9 (cột "Có sẵn" 3 ViewModel F11).
   - `docs/analytics-plan.md`: chỉ thêm "Cách lấy bằng chứng event F11" trong mục Bằng chứng (DebugView), **không** sửa phần khác (file của Hiếu).
   - `docs/test-plan.md` (Hương là chủ): ghi tên file test Flutter tương ứng TC-08, TC-31; **không** điền kết quả ARTEMIS giả (chạy trên máy thật sau).
7. **Soạn `docs/prompt/F11/PR-F11.md`** (tiếng Việt, theo mẫu `PR-F2.md`): tiêu đề `feat(F11): …`, làm gì, màn + route, service / ViewModel mới, event analytics, lệch Figma (DT-xx), sửa ngoài phạm vi (nếu có, đã hỏi), package đề xuất (nếu có), **việc nhờ người khác** (Hiếu: bản thật service danh bạ / gọi điện / nhắn tin hoặc duyệt package, trường mới của `Relative`; Sanh: widget F0 còn thiếu, sửa Figma theo DT-xx, S17 thiếu phần soạn nội dung nếu có), ảnh cần chụp, checklist "trước khi mở PR" trong `CLAUDE.md` đã tick.
8. Chạy `dart format` cho file F11, `flutter analyze`, `flutter test`; so số lỗi với mức có sẵn ghi ở bước 01.

Được sửa: `lib/screens/family/`, 3 ViewModel F11, 2 service mới, `test/`, `docs/design-traceability.md`, `docs/architecture.md`, `docs/analytics-plan.md` (mục Bằng chứng), `docs/test-plan.md`, `docs/prompt/F11/`.

## Đầu ra mong đợi

- Test cả luồng qua; analyze không có lỗi mới; khớp Figma (hoặc có DT-xx được duyệt); docs khớp code; `PR-F11.md` sẵn sàng.
- In cho người dùng: bảng đối chiếu "Xong khi" (đạt / chưa), bảng đối chiếu Figma, bảng tự chấm `rule.md`, danh sách việc nhờ người khác, danh sách ảnh cần chụp, thứ tự commit gợi ý (mỗi bước 01–06 một commit).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy:
- File đã tạo / sửa:
- Lệch Figma (nếu có, lý do):
- `flutter analyze` / `flutter test`:
- Việc người dùng cần làm tay:
- Commit gợi ý:
