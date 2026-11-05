# Bước 05 · F11 · S17 Nhắn tin cho người thân → S17b / N10

Bạn là AI agent làm bước 05 của feature **F11 – Gia đình**. Bước 01–04 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Bác chọn gửi bằng Zalo (khuyên dùng) hoặc SMS, app mở ứng dụng nhắn tin với nội dung soạn sẵn; sau đó hiện S17b / N10 nói rõ **chưa xác nhận đã gửi** – **không bao giờ** báo "Đã gửi".

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

`CLAUDE.md`, `docs/design-traceability.md` mục F11, `docs/prompt/F11/01-service-viewmodel.md` (Kết quả chạy – service mở Zalo / SMS, câu trả lời về package), `lib/viewmodels/share_message_view_model.dart`, `lib/services/family_repository.dart`, `lib/services/task_repository.dart` (handoff: tin có thể kể việc đã xong hôm nay), `lib/widgets/choice_group.dart`, `lib/router/app_router.dart` (dòng `:personId/share`), `docs/analytics-plan.md` (`share`), `docs/test-plan.md` TC-31, `flutter-handoff.md` mục S17.

## Figma (đã đối chiếu 04/11/2026 – vẫn phải gọi `get_design_context` + `get_screenshot`)

| Khung | Node | Nội dung trong Figma |
| --- | --- | --- |
| S17 Nhắn tin cho người thân | `1:2278` | Back "Gia đình"; **khoảng trống lớn** dưới thanh back (khung có thể thiếu nội dung – xem điểm cần hỏi 1); tiêu đề có icon tin nhắn **"Nhắn tin cho Mai"**; **"Gửi bằng"** + 2 thẻ radio **"Zalo"** (đang chọn, nền xanh nhạt) / **"Tin nhắn SMS"**; dòng có icon **"An Nhiên sẽ giúp Bác mở Zalo."**; nút chính ghim đáy **"Tiếp tục nhắn tin cho Mai"** (mũi tên phải). |
| S17b Nhắn tin · đã mở chia sẻ | `26:122` | Back "Gia đình"; tiêu đề có icon **"Nội dung gửi cho Mai"**; khối có icon **"Bác bấm gửi trong Zalo nhé."** + "An Nhiên chưa biết tin này đã đến Mai ch…" (đọc đủ câu); **"Mai sẽ thấy"** + thẻ xem trước "Mẹ nhớ con. Hôm nay mẹ khỏe, con nhé!"; chân màn: nút **"Gọi điện cho Mai"** + nút chính **"Về trang Gia đình"**. |
| N10 Đã mở ứng dụng chia sẻ | `41:205` | Back "Gia đình"; tiêu đề có icon **"Đã mở ứng dụng nhắn tin"**; khối "Người nhận" / **"Con gái Mai"**; khối có icon **"Chưa xác nhận đã gửi"** + "Bác bấm gửi trong ứng dụng nhắn tin nhé."; chân màn: nút **"Xem lại nội dung"** + nút chính **"Về Gia đình"**. |

Stitch (chỉ tham khảo): `stitch-runs/S17/v1.html`, `S17b/v1.html`, `N10/v0.html`.

**Điểm Figma cần hỏi người dùng (dừng lại hỏi trước khi code):**
1. **S17 thiếu phần soạn nội dung.** Handoff Lab 2 có "Chọn điều Bác muốn kể. Xem lại trước khi gửi.", nhóm chủ đề (Hỏi thăm con cháu / Kể việc đi bộ / Kể việc chăm cây), khung xem trước, "Thêm một câu (không bắt buộc)"; Figma S17 chỉ còn "Gửi bằng" và một **khoảng trống** phía trên tiêu đề. Nội dung tin lấy từ đâu? (a) chờ Sanh sửa Figma vẽ đủ phần chọn chủ đề; (b) làm phần chọn chủ đề theo handoff / Stitch `S17/v1.html` và ghi `DT-xx`; (c) dùng một câu soạn sẵn như S17b. **Không tự chọn.** Tham số `topic` của event `share` phụ thuộc câu trả lời này.
2. **S17b và N10 dùng khi nào?** Cả hai là màn sau khi mở app nhắn tin nhưng khác chữ / nút (S17b nhắc Zalo + xem trước + "Gọi điện cho Mai"; N10 "Người nhận" + "Xem lại nội dung"). Đề xuất: S17b khi gửi bằng Zalo, N10 khi gửi bằng SMS – cần duyệt.
3. S17b nhắc "Bác bấm gửi trong **Zalo** nhé." – khi gửi bằng SMS thì câu là gì (hay dùng N10)?
4. Không mở được Zalo (máy không cài) – Figma không vẽ. Đề xuất: ở lại S17, câu lỗi `userMessage` + gợi ý chọn "Tin nhắn SMS", ghi `DT-xx`.
5. "Tin nhắn gửi Con gái Mai" / xưng "Mẹ – con": cách xưng hô lấy theo quan hệ (bước 01 điểm 1).

## Việc cần làm

1. Điền `ShareMessageViewModel`:
   - `load(personId)`: người nhận từ `FamilyRepository` (không tìm thấy → `UiEmpty`; lỗi → `UiError` + `retry()`); nội dung theo câu trả lời điểm 1; kênh mặc định **Zalo**.
   - `selectChannel(zalo | sms)`; `send()` ("Tiếp tục nhắn tin cho Mai"): gọi `openZalo` / `openSms` của service; mở được → state S17b / N10 theo điểm 2; log `share { method: 'zalo' | 'sms', topic }` (không gửi nội dung, tên, số); không mở được → theo điểm 4.
   - Tuyệt đối **không** có state / chữ "Đã gửi".
2. Tạo `lib/screens/family/share_message_screen.dart` (S17, S17b, N10 là state của cùng route), vẽ **đúng bảng Figma** – từng khối, từng chữ; 2 thẻ radio bằng `ChoiceGroup` (có chữ / dấu, không chỉ màu); dòng "An Nhiên sẽ giúp Bác mở Zalo." đổi theo kênh (SMS → câu gì: hỏi nếu Figma không có). S17b "Gọi điện cho Mai" gọi service gọi điện; "Về trang Gia đình" / "Về Gia đình" → `/family`; N10 "Xem lại nội dung" → về S17 giữ nội dung.
3. Thay đúng dòng placeholder `:personId/share` dưới `/family` trong `app_router.dart` (chỉ dòng đó + import).
4. Test: ViewModel (mặc định Zalo; đổi SMS; `send` gọi đúng service với đúng số + nội dung; event `share` đúng `method`, không có nội dung / tên; không mở được → lỗi, ở lại S17). Widget (S17 → "Tiếp tục nhắn tin cho Mai" → S17b / N10; **không** có `find.text('Đã gửi')` ở mọi state (TC-31); **mọi chữ trong bảng Figma** có trên màn; 360 / 412 dp × 1.3 / 2.0 không tràn; tương phản cao).
5. Đổi S17, S17b, N10 sang `doing` trong `docs/design-traceability.md`; mỗi chỗ lệch Figma (đã được đồng ý) thêm `DT-xx`.

Được sửa: `lib/screens/family/`, `lib/viewmodels/share_message_view_model.dart`, dòng `:personId/share` trong `app_router.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- Nhắn tin mở đúng Zalo / SMS (qua Fake), sau đó hiện S17b / N10 đúng Figma, không có chữ "Đã gửi".
- In cho người dùng: ảnh cần chụp (S17, S17b, N10 ở 360 dp × 1.3), lệch Figma, việc cần Sanh sửa Figma S17 (nếu chọn (a)).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy:
- File đã tạo / sửa:
- Lệch Figma (nếu có, lý do):
- `flutter analyze` / `flutter test`:
- Việc người dùng cần làm tay:
- Commit gợi ý:
