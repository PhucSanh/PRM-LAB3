# Bước 03 · F11 · S12 Thêm người thân (danh bạ / tự nhập) + S12a / S12e

Bạn là AI agent làm bước 03 của feature **F11 – Gia đình**. Bước 01–02 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Bác thêm người thân bằng **danh bạ** (nhanh nhất) hoặc **tự nhập**; thiếu / sai số thì hiện lỗi có "Ví dụ" và giữ nguyên tên + quan hệ; **từ chối quyền danh bạ vẫn tự nhập được**; lưu xong về S09 với banner S09b.

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

`CLAUDE.md`, `docs/design-traceability.md` mục F11, `docs/prompt/F11/01-service-viewmodel.md` + `02-s09-gia-dinh.md` (Kết quả chạy), `lib/viewmodels/relative_form_view_model.dart`, `lib/services/family_repository.dart`, `ContactsService` (bước 01), `lib/widgets/app_text_field.dart`, `lib/widgets/choice_group.dart`, `lib/widgets/form_parts.dart` (`FieldMessage`), `lib/widgets/confirm_dialog.dart`, `lib/screens/onboarding/setup_profile_screen.dart` (cách F2 vẽ lỗi có "Ví dụ" – chỉ đọc), `lib/router/app_router.dart` (dòng `/family/add`), `docs/analytics-plan.md` (`add_relative`), `flutter-handoff.md` mục S12.

## Figma (đã đối chiếu 04/11/2026 – vẫn phải gọi `get_design_context` + `get_screenshot`)

| Khung | Node | Nội dung trong Figma |
| --- | --- | --- |
| S12 Thêm người thân | `1:2110` | Back chữ "Gia đình"; tiêu đề có icon **"Thêm người thân"**; nút (cao 72) **"Chọn từ danh bạ"** (icon danh bạ); chữ **"hoặc"**; nút **"Tự nhập"** (icon bút). Không có form. |
| S12 – chọn từ danh bạ | `1:2146` | Back "Gia đình"; tiêu đề có icon **"Chọn từ danh bạ"**; ô **"Tìm tên"** (icon kính lúp, gợi ý "Nhập tên người thân"); danh sách liên hệ: avatar chữ cái, tên, dòng "Con gái · 0912 345 678", chevron phải (5 người mẫu – bước 01). Không có nút ghim đáy. |
| S12 – tự nhập | `1:2215` | Back "Gia đình"; tiêu đề có icon "Thêm người thân"; ô **"Tên gọi"** (vd. "Mai"); nhãn **"Là gì của Bác?"** + 4 thẻ radio xếp dọc **Con / Cháu / Bạn bè / Khác** (thẻ đang chọn nền xanh nhạt); ô **"Số điện thoại"**; nút chính ghim đáy **"Lưu người thân"** (icon lưu). Không có nút danh bạ, không có công tắc "Gọi nhanh". |
| S12a Thêm người thân · chưa có số | `14:120` | Back "Gia đình"; tiêu đề "Thêm người thân"; nút **"Chọn từ danh bạ"**; chữ **"hoặc tự nhập"**; ô "Tên gọi" trống + dòng gợi ý có icon **"Ví dụ: Mai, Hùng"**; "Là gì của Bác?" 4 thẻ, **"Khác" đang chọn** (chữ "(Đang chọn)"); ô "Số điện thoại" trống + gợi ý **"Ví dụ: 0912 345 678"**; dòng có icon **"Chỉ gửi tin khi Bác chọn gửi."**; nút ghim đáy **"Lưu người thân"**. |
| S12e Thêm người thân · số sai | `14:196` | Như S12a, tên đã nhập, **"Con" đang chọn** (chữ "Đang chọn"); dưới ô số: lỗi có icon **"Bác chưa nhập số điện thoại."** + **"Ví dụ: 0912 345 678"** + dòng có icon **"Bác chạm “Chọn từ danh bạ” ở trên cho nh…"** (đọc đủ câu). |

Stitch (chỉ tham khảo): `stitch-runs/S12/v1.html`, `S12a/v0.html`, `S12e/v1.html`. Handoff Lab 2 có công tắc "Gọi nhanh cho người thân" và nhãn "Là gì của bà?" – **Figma không có công tắc, nhãn là "Là gì của Bác?" → theo Figma**.

**Điểm Figma cần hỏi người dùng (dừng lại hỏi trước khi code):**
1. **Hai cách bố trí khác nhau:** S12 (`1:2110`) là màn chọn cách "Chọn từ danh bạ" / "Tự nhập" rồi sang 2 khung riêng; còn S12a / S12e là **một màn** có nút danh bạ ở trên + form ngay dưới. Làm theo cách nào? Đề xuất: `/family/add` = bố cục S12a (nút danh bạ + form) vì đó là state lỗi mà đề chấm; chọn liên hệ ở danh sách `1:2146` thì điền sẵn tên + số rồi quay về form. Không bỏ khung nào mà không hỏi.
2. **"Số sai"**: Figma S12e chỉ vẽ lỗi **thiếu số** ("Bác chưa nhập số điện thoại."). File chia task yêu cầu "Số sai hiện S12e có ví dụ". Câu lỗi khi số sai (không đủ 10 số, có chữ…) là gì? Đề xuất "Số điện thoại chưa đúng." + cùng dòng "Ví dụ: 0912 345 678" – cần người dùng duyệt, ghi `DT-xx`.
3. **Từ chối quyền danh bạ** (Figma không vẽ): hiện gì? Đề xuất: ở lại form, hiện dòng có icon dùng `FieldMessage` "Bác có thể tự nhập tên và số ở dưới." – cần duyệt, ghi `DT-xx`. Danh bạ trống / tìm không thấy: `EmptyView`.
4. Chọn liên hệ có nhãn "Con gái" / "Hàng xóm"… nhưng form chỉ có Con / Cháu / Bạn bè / Khác → điền sẵn quan hệ thế nào (theo câu trả lời điểm 1 ở bước 01)?
5. Rời màn khi đã nhập (handoff: hỏi "Bỏ người thân đang nhập?") – Figma không vẽ hộp thoại. Có thêm không? Nếu có thì dùng `showConfirmDialog`, câu chữ người dùng duyệt, ghi `DT-xx`.

## Việc cần làm

1. Điền `RelativeFormViewModel` (chế độ thêm):
   - Tên, quan hệ (mặc định **"Khác"** như S12a), số; `pickFromContacts()`: `requestPermission` → được thì mở danh sách (state danh bạ), `search(query)`, `selectContact(c)` điền sẵn tên + số (+ quan hệ theo điểm 4), `fromContacts = true`; bị từ chối → state form + câu theo điểm 3, **không chặn** tự nhập.
   - Validate khi bấm "Lưu người thân": thiếu số → lỗi S12e; số sai (bỏ khoảng trắng, chấp nhận `+84` → `0`, đúng 10 chữ số) → lỗi theo điểm 2; tên trống → lỗi theo Figma (không có thì hỏi). **Giữ nguyên** tên + quan hệ đã nhập khi lỗi. Tự chèn khoảng trắng 4-3-3 khi hiển thị số.
   - `save()`: `FamilyRepository.save`; log `add_relative { relation, from_contacts, had_error }` (`had_error` = đã từng gặp lỗi nhập trong lần này); lỗi lưu → `CrashService.recordError` + `userMessage`; xong → trả kết quả để View `pop` về S09 và gọi `FamilyViewModel.showAdded` (banner S09b).
2. Tạo `lib/screens/family/relative_form_screen.dart` (dùng chung cho N09 ở bước 04) + màn / state danh bạ, vẽ **đúng bảng Figma** theo cách bố trí người dùng chọn ở điểm 1 – từng khối, từng chữ; 4 thẻ quan hệ bằng `ChoiceGroup` (có chữ "Đang chọn" + dấu tích, không chỉ màu); gợi ý / lỗi bằng `AppTextField` + `FieldMessage` (lỗi có icon, `liveRegion`). Đang lưu: nút "Lưu người thân" ở trạng thái tải. Nút Lưu không bị bàn phím che.
3. Thay đúng dòng placeholder `/family/add` trong `app_router.dart` (chỉ dòng đó + import).
4. Test: ViewModel (thiếu số → lỗi đúng câu S12e, giữ tên + quan hệ; số sai → lỗi; `+84 912 345 678` hợp lệ; từ chối quyền → vẫn lưu được bằng tự nhập; chọn liên hệ → điền sẵn, `from_contacts: true`; event không chứa tên / số; lưu lỗi). Widget (S12a → bấm Lưu → S12e có "Ví dụ: 0912 345 678"; nhập số → lưu → về S09 có banner "Đã thêm …"; **mọi chữ trong bảng Figma** có trên màn; 360 / 412 dp × 1.3 / 2.0, bàn phím mở, không tràn; tương phản cao).
5. Đổi 3 dòng S12, S12a, S12e sang `doing` trong `docs/design-traceability.md`; mỗi chỗ lệch Figma (đã được đồng ý) thêm `DT-xx`.

Được sửa: `lib/screens/family/`, `lib/viewmodels/relative_form_view_model.dart`, dòng `/family/add` trong `app_router.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- Thêm người thân được bằng danh bạ (Fake) và tự nhập; lỗi thiếu / sai số có "Ví dụ"; từ chối quyền vẫn tự nhập được (có test).
- In cho người dùng: ảnh cần chụp (S12, danh bạ, tự nhập, S12a, S12e ở 360 dp × 1.3), lệch Figma, câu chữ đã được duyệt.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 04–05/11/2026 (nhánh `feat/F11-Family`). Đã gọi `get_design_context` + `get_screenshot` cho `1:2110`, `1:2146`, `1:2215`, `14:120`, `14:196` (câu S12e đầy đủ: "Bác chạm “Chọn từ danh bạ” ở trên cho nhanh.").
- Trả lời các điểm cần hỏi (người dùng chọn 04/11): (1) **một màn bố cục S12a**, danh bạ là bước con, khung `1:2110` không dùng; (2) số sai **"Số điện thoại chưa đúng."**, tên trống **"Bác chưa nhập tên gọi."**, cả hai kèm "Ví dụ…" + dòng "Bác chạm “Chọn từ danh bạ”…"; (3) từ chối quyền → dòng ⓘ **"Bác có thể tự nhập tên và số ở dưới."**, tìm không thấy → `EmptyView` "Không thấy tên này trong danh bạ" + "Bác thử tên khác hoặc tự nhập." + "Tự nhập"; (4) nhãn liên hệ **quy về 4 nhóm**; (5) rời màn khi đã nhập **hỏi lại** "Bỏ người thân đang nhập?"; thêm: quay lại ở danh bạ → **về form, nhãn "Quay lại"**; widget / icon thiếu **thêm vào F0** (Sanh duyệt).
- File đã tạo / sửa:
  - Mới: `lib/screens/family/relative_form_screen.dart` (form S12a / tự nhập / S12e + bước danh bạ; Loading / Error / Empty cho chế độ sửa), `lib/widgets/contact_row.dart` (`ContactRow`), `test/f11_relative_form_test.dart` (43 test).
  - Sửa: `lib/viewmodels/relative_form_view_model.dart` (`pickFromContacts`, `search`, `closeContacts`, `selectContact`, `setPhone` tự chèn 4-3-3, `save` + validate + `add_relative`; bỏ bước `choose`), `lib/widgets/app_text_field.dart` (+`prefixIcon`, `placeholder`), `lib/theme/app_icons.dart` (+`contact`, `search`), `lib/widgets/relative_card.dart` (avatar = chữ cái **từ cuối** của tên, như Figma "Cô Tám" → T), `lib/router/app_router.dart` (chỉ dòng `/family/add` + import), `test/f11_view_models_test.dart` (bỏ bước `choose`), `docs/design-traceability.md` (5 dòng S12 → `doing (DT-35)`, thêm DT-35), `docs/architecture.md` (7.2, 9, 13).
- Lệch Figma (nếu có, lý do): ghi đủ ở **DT-35**. So ảnh 360 dp × 1.0 với `get_screenshot`: S12a, tự nhập, S12e, danh bạ – thứ tự khối, chữ, nút ghim đáy **khớp**. Còn khác: (a) khung chọn cách `1:2110` không dùng; (b) danh bạ ghi "Quay lại" (Figma "Gia đình"); (c) nút danh bạ viền + chữ xanh ở mọi state (Figma S12a viền xám chữ đen, S12e viền xanh); (d) ô quan hệ đang chọn có dấu ✓ tròn của `ChoiceGroup` (Figma chấm tròn), chữ "Đang chọn" không ngoặc (Figma S12a "(Đang chọn)"); (e) icon tiêu đề danh bạ màu xanh (Figma đen). Figma không vẽ: lỗi số sai / tên trống, từ chối quyền, tìm không thấy, đang mở danh bạ, lưu lỗi, hộp hỏi khi rời màn.
- `flutter analyze` / `flutter test`: analyze còn 1 cảnh báo **có sẵn** (`app_router.dart` `pendingNotification`). Test: trước bước 593 qua / 62 lỗi có sẵn → sau bước **636 qua / 62 lỗi** (43 test mới đều qua, không thêm lỗi).
- Việc người dùng cần làm tay: chụp trên emulator ở 360 dp × 1.3: S12a, danh bạ, tự nhập (đã điền), S12e, từ chối quyền (Fake `granted: false`). Báo **Sanh** duyệt `ContactRow`, `AppTextField.prefixIcon` / `placeholder`, `AppIcons.contact` / `search`, và đổi `RelativeCard.initial` (chữ cái từ cuối). Khi Hiếu có bản thật `ContactsService` thì kiểm lại hộp xin quyền của Android.
- Commit gợi ý: `feat(F11): S12 thêm người thân – danh bạ / tự nhập, lỗi S12e có ví dụ (ContactRow)`
