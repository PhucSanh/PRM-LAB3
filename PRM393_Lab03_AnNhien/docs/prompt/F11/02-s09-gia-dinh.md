# Bước 02 · F11 · S09 Gia đình / S09b đã thêm người thân

Bạn là AI agent làm bước 02 của feature **F11 – Gia đình**. Bước 01 (service + khung ViewModel) đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Tab Gia đình (tab 4): danh sách người thân, mỗi người có "Gọi" (mở gọi ngay) và "Nhắn tin" (→ S17); hàng "Gợi ý từ Mai" khi có gợi ý (→ G03 của F12); nút "Thêm người thân" (→ S12); sau khi thêm hiện banner S09b.

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

`CLAUDE.md`, `docs/design-traceability.md` mục F11, `docs/prompt/F11/01-service-viewmodel.md` (Kết quả chạy), `lib/viewmodels/family_view_model.dart`, `lib/services/family_repository.dart`, service gọi điện ở bước 01, `lib/viewmodels/suggestion_inbox_view_model.dart` (F12 – chỉ dùng, không sửa: `suggestionInboxViewModelProvider`, `pendingCard`), `lib/widgets/app_shell.dart` (tab 4), `lib/widgets/state_views.dart`, `lib/router/app_router.dart` (dòng `/family`), `flutter-handoff.md` mục S09.

## Figma (đã đối chiếu 04/11/2026 – vẫn phải gọi `get_design_context` + `get_screenshot`)

| Khung | Node | Nội dung trong Figma |
| --- | --- | --- |
| S09 Gia đình | `1:1993` | Tiêu đề **"Gia đình"** (không có câu phụ); hàng viền **"Gợi ý từ Mai" / "2 việc"** (ô icon thư mở + chevron phải); thẻ người thân Mai / Hùng / Bin: ô avatar (icon người), tên, quan hệ ("Con gái", "Con trai"…), **2 nút viền nằm ngang** "**Gọi**" (icon điện thoại) và "**Nhắn tin**" (icon tin nhắn); nút chính ghim trên bottom nav **"Thêm người thân"** (icon thêm người); bottom nav 4 tab, tab "Gia đình" đang chọn. |
| S09b Gia đình · đã thêm người thân | `26:2` | Tiêu đề "Gia đình" + câu **"Bác chọn điều muốn kể cho con"**; banner thành công (icon) **"Đã thêm Cháu Bin"** + "Bác có thể gọi hoặc nhắn tin ngay."; thẻ "Gợi ý từ Mai · 2 việc"; thẻ người thân có **avatar chữ cái** (M / H / B), nút **"Gọi điện"** / "Nhắn tin"; người mới (Bin) ở **cuối** danh sách; nút "Thêm người thân"; bottom nav. |

Stitch (chỉ tham khảo): `stitch-runs/S09/v0.html`, `S09b/v1.html`. Handoff Lab 2 có câu phụ "Gọi nhanh, trò chuyện và nhận gợi ý từ người thân.", lần gọi cuối, câu nhắc "Bà có muốn gọi cho Hùng hôm nay không?" – **Figma không có, không làm**.

**Điểm Figma cần hỏi người dùng (dừng lại hỏi trước khi code):**
1. Nút gọi: S09 ghi **"Gọi"**, S09b / N21 ghi **"Gọi điện"**. Dùng chữ nào cho thống nhất?
2. Avatar: S09 là **icon người**, S09b / N21 là **chữ cái đầu**. Dùng kiểu nào?
3. Câu phụ dưới tiêu đề: S09 không có, S09b "Bác chọn điều muốn kể cho con", N21 "Người thân của Bác". Giữ theo từng state hay thống nhất?
4. Chạm vào **tên / thẻ** người thân để mở N09 (handoff Lab 2) – Figma không vẽ chỗ chạm riêng. Làm cả thẻ (trừ 2 nút) chạm được → `/family/:personId/edit`? Có cần nút "Sửa" hiện rõ không (Figma không có)?
5. Banner S09b không tự tắt (handoff) – có nút đóng không? Figma không có nút đóng → banner mất khi nào (rời tab / mở lại)?

## Việc cần làm

1. Điền `FamilyViewModel`:
   - `load()`: `FamilyRepository.all()` → `UiData`; rỗng → `UiEmpty`; lỗi → `UiError` + `retry()`.
   - Hàng gợi ý: đọc `suggestionInboxViewModelProvider` (F12) → có `pendingCard` thì hiện "Gợi ý từ <tên>" + "<n> việc"; đang tải / lỗi / không có thì **không chiếm chỗ**. Chạm → `context.push('/today/suggestions/<id>?from=family')`.
   - `call(relative)`: gọi service gọi điện; không mở được → trả `userMessage` cho View.
   - `showAdded(relative)`: bật banner S09b (gọi từ bước 03 sau khi lưu).
2. Tạo `lib/screens/family/family_screen.dart` (S09, S09b là state), vẽ **đúng bảng Figma** – từng khối, từng chữ, đúng thứ tự, 2 nút trên thẻ nằm ngang, nút "Thêm người thân" ghim trên bottom nav. Thẻ người thân 2 nút: dùng widget F0 nếu có, thiếu thì **báo Sanh** (không tự làm widget riêng). Trống (Figma không vẽ): `EmptyView` theo handoff ("Thêm số điện thoại con cháu") + nút "Thêm người thân", ghi `DT-xx`. Lỗi: `ErrorView` + "Thử lại".
   - "Nhắn tin" → `context.push('/family/<id>/share')`; "Thêm người thân" → `context.push('/family/add')`; chạm thẻ → theo câu trả lời điểm 4.
3. Thay đúng dòng placeholder `/family` trong `app_router.dart` (chỉ builder của dòng đó + import; **giữ nguyên** các route con).
4. Test: ViewModel (Data / Empty / Error + retry; có / không có gợi ý; "Gọi" gọi service đúng số; gọi lỗi → message). Widget (**mọi chữ trong bảng Figma** có trên màn bằng `find.text`; "Nhắn tin" → đúng route có `personId`; S09b có banner và người mới ở cuối; 360 / 412 dp × 1.3 / 2.0 không tràn; tương phản cao).
5. Đổi S09, S09b sang `doing` trong `docs/design-traceability.md`; mỗi chỗ lệch Figma (đã được đồng ý) thêm `DT-xx`.

Được sửa: `lib/screens/family/`, `lib/viewmodels/family_view_model.dart`, dòng `/family` trong `app_router.dart`, `test/`, `docs/`.

## Đầu ra mong đợi

- Tab Gia đình hiện đúng Figma, gọi điện / nhắn tin / thêm / mở gợi ý điều hướng đúng.
- In cho người dùng: ảnh cần chụp (S09, S09b ở 360 dp × 1.3; trống; lỗi), lệch Figma, widget cần báo Sanh.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 04/11/2026 (nhánh `feat/F11-Family`). Đã gọi `get_design_context` + `get_screenshot` cho S09 `1:1993` và S09b `26:2`.
- Trả lời các điểm cần hỏi (người dùng chọn 04/11): (1) nút **"Gọi điện"** ở mọi state; (2) avatar **chữ cái đầu**; (3) câu phụ **theo từng state** (S09 không có, S09b "Bác chọn điều muốn kể cho con", N21 "Người thân của Bác"); (4) **chạm đầu thẻ** (avatar + tên + quan hệ) → `/family/:id/edit`, không thêm nút "Sửa"; (5) banner S09b không nút đóng, **mất khi rời tab / mở S12 · S17 · N09**. Thêm: hàng gợi ý dùng `NavRow` theo S09 ở mọi state; widget / icon thiếu được **thêm vào F0, ghi "F11 đề xuất, Sanh duyệt"**.
- File đã tạo / sửa:
  - Mới: `lib/screens/family/family_screen.dart` (S09 + S09b; Loading / Empty / Error + Thử lại / Data), `lib/widgets/relative_card.dart` (`RelativeCard`), `lib/widgets/status_banner.dart` (`StatusBanner`), `test/f11_family_screen_test.dart` (36 test: ViewModel, chữ Figma, điều hướng, gọi điện, trống, lỗi, S09b, không tràn 360 / 412 × 1.0 / 1.3 / 2.0 × thường / tương phản cao).
  - Sửa: `lib/viewmodels/family_view_model.dart` (`call`, `showAdded`, `dismissAdded`), `lib/theme/app_icons.dart` (+`message`, `userPlus`), `lib/router/app_router.dart` (chỉ builder `/family` + import), `docs/design-traceability.md` (S09, S09b → `doing (DT-34)`, thêm DT-34), `docs/architecture.md` (7.2, 9, 13).
- Lệch Figma (nếu có, lý do): ghi đủ ở **DT-34**. So ảnh 360 dp × 1.0 (font Be Vietnam Pro, có bottom nav) với `get_screenshot`: thứ tự khối, tiêu đề, banner, hàng gợi ý, 3 thẻ, 2 nút ngang, nút "Thêm người thân" ghim trên nav **khớp**. Còn khác: (a) quan hệ hiện "Con" / "Cháu" thay vì "Con gái" / "Con trai" (chờ `relationLabel` – Hiếu); (b) S09 nút "Gọi" → "Gọi điện", avatar icon → chữ cái (đã chọn); (c) hàng gợi ý viền nhạt (Figma S09 viền xanh 2 dp), S09b vẫn 2 dòng icon thư (Figma 1 dòng icon ⓘ); (d) viền 2 nút thẻ màu `primary` (Figma S09 xám, S09b xanh); (e) ở ×1.3 / ×2.0 hai nút thẻ xếp dọc. Figma không vẽ: Trống, Lỗi, gọi không được (SnackBar).
- `flutter analyze` / `flutter test`: analyze còn 1 cảnh báo **có sẵn** (`app_router.dart` `pendingNotification`), không có lỗi mới. Test: trước bước 557 qua / 62 lỗi có sẵn → sau bước **593 qua / 62 lỗi** (36 test mới đều qua, không thêm lỗi).
- Việc người dùng cần làm tay: chụp ảnh S09 / S09b ở 360 dp × 1.3, màn Trống, màn Lỗi trên emulator (ảnh tạm 360 × 1.0 không commit). Báo **Sanh** duyệt `RelativeCard`, `StatusBanner`, `AppIcons.message` / `userPlus` (đã thêm vào `lib/widgets/`, `lib/theme/`) và có thể thêm vào `WidgetGallery`. Nhắc **Hiếu** trường `relationLabel` (để thẻ hiện "Con gái"). Bước 03 gọi `familyViewModelProvider.notifier.showAdded(relative)` sau khi lưu, rồi `pop`.
- Commit gợi ý: `feat(F11): S09 Gia đình + S09b đã thêm người thân (RelativeCard, StatusBanner)`
