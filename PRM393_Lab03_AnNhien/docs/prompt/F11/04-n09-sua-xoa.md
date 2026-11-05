# Bước 04 · F11 · N09 Sửa người thân, N15 hỏi xoá, N21 đã xoá + Hoàn tác

Bạn là AI agent làm bước 04 của feature **F11 – Gia đình**. Bước 01–03 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Bác sửa tên / quan hệ / số của người thân (N09); xoá phải **hỏi lại** và nói rõ hậu quả (N15); xoá xong về Gia đình với banner có **"Hoàn tác"** (N21).

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

`CLAUDE.md`, `docs/design-traceability.md` mục F11, `docs/prompt/F11/03-s12-them-nguoi-than.md` (Kết quả chạy – form dùng chung), `lib/viewmodels/relative_form_view_model.dart`, `lib/viewmodels/family_view_model.dart`, `lib/screens/family/relative_form_screen.dart`, `lib/widgets/confirm_dialog.dart`, `lib/widgets/undo_snackbar.dart`, `lib/router/app_router.dart` (dòng `:personId/edit`), bảng "N01 – N21" trong `flutter-handoff.md` (N09, N15, N21).

## Figma (đã đối chiếu 04/11/2026 – vẫn phải gọi `get_design_context` + `get_screenshot`)

| Khung | Node | Nội dung trong Figma |
| --- | --- | --- |
| N09 Sửa người thân | `41:136` | Back "Gia đình"; tiêu đề có icon **"Sửa người thân"**; ô "Tên gọi" (có giá trị) + gợi ý "Ví dụ: Mai, Hùng"; "Là gì của Bác?" 4 thẻ, **"Con" – "Đang chọn"**; ô "Số điện thoại" (có giá trị) + gợi ý "Ví dụ: 0912 345 678"; chân màn ghim: nút chính **"Lưu thay đổi"**, nút **"Xóa khỏi An Nhiên"**. Không có nút danh bạ. |
| N15 Xóa người thân | `43:263` | **Hộp thoại** trên nền mờ: ô icon tròn 80 (icon 64); **"Xóa Con gái Mai?"**; **"Danh bạ điện thoại vẫn giữ nguyên."**; 2 nút xếp dọc: **"Giữ lại"** (trên) và **"Xóa khỏi An Nhiên"** (dưới) – xem trong Figma nút nào là nút chính / nút nguy hiểm. |
| N21 Gia đình sau khi xóa người thân | `52:48` | Tiêu đề "Gia đình" + **"Người thân của Bác"**; banner (icon) **"Con gái Mai đã được xóa"** + "Danh bạ điện thoại vẫn giữ nguyên." + nút **"Hoàn tác"** trong banner; thẻ người thân còn lại (avatar chữ cái, tên, quan hệ) với **2 nút viền xếp dọc, rộng hết thẻ** "Gọi điện" / "Nhắn tin"; chân màn: nút **"Về Hôm nay"** + nút chính **"Thêm người thân"**; bottom nav. |

Stitch (chỉ tham khảo): `stitch-runs/N09/v0.html`, `N15/v0.html`, `N21/v1.html`. Handoff Lab 2 N15 còn câu "Lịch sử hoạt động không bị xóa" – **Figma không có, không thêm**.

**Điểm Figma cần hỏi người dùng (dừng lại hỏi trước khi code):**
1. N21 là **state của `/family`** (S09) nhưng khác S09 ở: câu phụ "Người thân của Bác", 2 nút trên thẻ **xếp dọc**, có nút "Về Hôm nay". Giữ khác biệt theo Figma hay dùng chung thẻ / bố cục S09 và ghi `DT-xx`?
2. N09 "Lưu thay đổi": Figma không vẽ kết quả sau khi lưu. `CLAUDE.md` yêu cầu mọi thay đổi có Hoàn tác → về S09 + `showUndoSnackbar` ("Đã lưu thay đổi." / "Hoàn tác")? Câu chữ cần duyệt, ghi `DT-xx`.
3. Rời N09 khi đã sửa mà chưa lưu: hỏi lại như bước 03 điểm 5 (theo câu trả lời ở đó).
4. Banner N21 có nút "Hoàn tác" trong banner (không phải snackbar). Banner mất khi nào (rời tab / mở lại app)? Có nút đóng không (Figma không có)?

## Việc cần làm

1. `RelativeFormViewModel` (chế độ sửa, `personId`):
   - `load(personId)`: lấy người thân từ `FamilyRepository` (không có hàm `byId` thì lọc `all()`; không tìm thấy → `UiEmpty` "Không tìm thấy người thân này." – Figma không vẽ, ghi `DT-xx`); lỗi → `UiError` + `retry()`.
   - `save()`: validate như bước 03 (cùng câu lỗi, cùng "Ví dụ"); lưu; trả bản cũ để Hoàn tác theo điểm 2.
   - `requestDelete()` → View hiện N15; `confirmDelete()` ("Xóa khỏi An Nhiên"): `FamilyRepository.delete`, trả bản đã xoá cho `FamilyViewModel.showDeleted(relative)` → N21. "Giữ lại" chỉ đóng hộp thoại. **Không** đụng danh bạ điện thoại.
2. `FamilyViewModel`: `showDeleted(relative)` bật banner N21; `undoDelete()` ("Hoàn tác") lưu lại đúng người thân cũ (cùng `id`, cùng dữ liệu) và tắt banner.
3. Màn: N09 dùng lại `relative_form_screen.dart` ở chế độ sửa, vẽ **đúng bảng Figma** (tiêu đề "Sửa người thân", không có nút danh bạ, 2 nút ghim đáy). N15 là hộp thoại – dùng `showConfirmDialog` nếu vẽ được đúng Figma (icon 64, tiêu đề, câu, 2 nút xếp dọc), không được thì **báo Sanh** thiếu widget. N21 là state của `family_screen.dart` theo câu trả lời điểm 1.
4. Thay đúng dòng placeholder `:personId/edit` dưới `/family` trong `app_router.dart` (chỉ dòng đó + import).
5. Test: ViewModel (load đúng người; sửa số sai → lỗi có "Ví dụ"; lưu đúng; xoá chỉ xảy ra sau `confirmDelete`; "Giữ lại" không xoá; Hoàn tác trả lại đúng người, đúng `id`). Widget (N09 → "Xóa khỏi An Nhiên" → N15 có "Xóa Con gái Mai?" + "Danh bạ điện thoại vẫn giữ nguyên." → "Giữ lại" → vẫn ở N09; → xoá → N21 có banner + "Hoàn tác" → bấm → người thân quay lại; **mọi chữ trong bảng Figma** có trên màn; 360 / 412 dp × 1.3 / 2.0 không tràn).
6. Đổi N09, N15, N21 sang `doing` trong `docs/design-traceability.md`; mỗi chỗ lệch Figma (đã được đồng ý) thêm `DT-xx`.

Được sửa: `lib/screens/family/`, `relative_form_view_model.dart`, `family_view_model.dart`, dòng `:personId/edit` trong `app_router.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- Sửa / xoá có hỏi lại / Hoàn tác chạy đúng, đúng Figma.
- In cho người dùng: ảnh cần chụp (N09, N15, N21 ở 360 dp × 1.3), lệch Figma.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy:
- File đã tạo / sửa:
- Lệch Figma (nếu có, lý do):
- `flutter analyze` / `flutter test`:
- Việc người dùng cần làm tay:
- Commit gợi ý:
