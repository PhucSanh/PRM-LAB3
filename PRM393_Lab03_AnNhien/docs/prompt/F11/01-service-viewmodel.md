# Bước 01 · F11 · Service gọi điện / nhắn tin / danh bạ + khung 3 ViewModel

Bạn là AI agent làm bước 01 của feature **F11 – Gia đình: thêm người thân, nhắn tin (Flow 5, Flow 9)** cho app An Nhiên (Flutter, MVVM + Riverpod, go_router). F0 đã merge vào `main`. Đọc hết file này rồi thực hiện.

## Mục tiêu

Có đủ service (interface + bản Fake) cho người thân, danh bạ, gọi điện / mở Zalo / SMS, và khung 3 ViewModel để các bước 02–05 chỉ còn vẽ màn. Chạy được hoàn toàn bằng Fake, không cần mạng, không cần package mới.

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

`CLAUDE.md`; `../An-Nhien_Chia-task_Lab3.md` mục F11 ("Xong khi": số sai hiện S12e có ví dụ; từ chối quyền danh bạ vẫn tự nhập được; xoá người thân có xác nhận); `docs/design-traceability.md` mục F11; `docs/architecture.md` mục 7.2 (route `/family/*`), 8 (`FamilyRepository`), 9 (`FamilyViewModel`, `RelativeFormViewModel`, `ShareMessageViewModel`), 10 (`users/{uid}/family/{personId}`), 15; `docs/analytics-plan.md` (`add_relative`, `share`); `docs/test-plan.md` TC-08, TC-31.

Code (chỉ đọc): `lib/services/family_repository.dart` (interface + `FakeFamilyRepository`), `lib/services/firebase_repositories.dart` (`FirebaseFamilyRepository` – Hiếu), `lib/models/relative.dart`, `lib/services/providers.dart` (`familyRepositoryProvider`), `lib/services/analytics_service.dart`, `lib/services/crash_service.dart`, `lib/viewmodels/suggestion_inbox_view_model.dart` (F12 – Sanh: hàng "Gợi ý từ Mai" ở S09 dùng provider này), `lib/viewmodels/ui_state.dart`, `lib/utils/app_error.dart`, `lib/viewmodels/first_task_view_model.dart` + `test/f2_view_models_test.dart` (mẫu), `pubspec.yaml`.

## Dữ liệu trong Figma (để làm model + Fake – đã đối chiếu 04/11/2026)

- Người thân mẫu: **Mai – "Con gái"**, **Hùng – "Con trai"**, **Bin – "Cháu"** (S09, S09b, N21); avatar là **chữ cái đầu** (M / H / B) trong ô vuông bo góc.
- Danh bạ điện thoại mẫu (S12 "chọn từ danh bạ"): Mai "Con gái · 0912 345 678", Hùng "Con trai · 0903 222 111", Bin "Cháu nội · 0987 654 321", Cô Tám "Hàng xóm · 0938 111 222", Chị Hoa "Bạn · 0909 333 444". Số hiển thị dạng **4-3-3** có khoảng trắng.
- Form chỉ có 4 lựa chọn quan hệ: **Con / Cháu / Bạn bè / Khác** (mặc định "Khác" ở S12a), trong khi thẻ hiển thị "Con gái" / "Con trai" / "Cháu nội" / "Hàng xóm" / "Bạn".
- N15 / N21 / N10 gọi người thân bằng **quan hệ + tên**: "Xóa Con gái Mai?", "Con gái Mai đã được xóa", "Người nhận: Con gái Mai".
- S17b nội dung tin mẫu: "Mẹ nhớ con. Hôm nay mẹ khỏe, con nhé!" (xưng hô theo quan hệ: Mẹ – con).

**Điểm Figma cần hỏi người dùng (dừng lại hỏi trước khi viết code):**
1. `Relative.relation` chỉ có Con / Cháu / Bạn bè / Khác nhưng Figma hiện "Con gái", "Con trai", "Cháu nội", "Hàng xóm". Hiện chữ gì trên thẻ và trong "Con gái Mai"? Có thêm trường (vd. `relationLabel` tự do, hoặc giới tính) không? `lib/models/` là của Hiếu → nếu thêm thì đề xuất trong PR.
2. **Package**: repo chưa có `url_launcher`, `share_plus`, `flutter_contacts` (hoặc tương đương). Có cho đề xuất thêm trong PR không? Bước này **chỉ** viết interface + Fake; bản thật viết khi package được duyệt (ai viết – Hương hay Hiếu?).
3. Figma S12 "chọn từ danh bạ" là **danh sách danh bạ trong app** có ô "Tìm tên" (đọc danh bạ, cần quyền), không phải mở màn chọn của hệ thống như handoff Lab 2 (`openExternalPick`). Theo Figma (đọc danh sách) – đồng ý không?

## Việc cần làm

1. **Kiểm tra trùng trước**: `git branch -a` + `git log --all -S "ContactsService"` / `-S "FamilyViewModel"`. Đã có ở nhánh nào thì **dừng lại báo**. `FamilyRepository` đã có (Fake + Firebase của Hiếu): **dùng lại**, không viết bản thứ hai.
2. **Service mới** (mỗi service một file trong `lib/services/`, interface + Fake, kiểu giống `task_repository.dart`):
   - `ContactsService`: `Future<bool> hasPermission()`, `Future<bool> requestPermission()`, `Future<List<PhoneContact>> list({String query})`. `FakeContactsService(granted:, contacts:)` với danh bạ mẫu đúng Figma ở trên; `granted: false` để test nhánh từ chối.
   - `ContactLauncherService` (tên khác cũng được, ghi vào architecture): `Future<bool> call(String phone)`, `Future<bool> openZalo(String phone, String text)`, `Future<bool> openSms(String phone, String text)`. Trả `false` / ném `AppException` khi không mở được (vd. máy không có Zalo). `FakeContactLauncherService(failOn…)` ghi lại lần gọi để test.
   - Có lỗi → ném `AppException` có `userMessage` tiếng Việt cho Bác.
3. **Provider**: đề xuất `contactsServiceProvider`, `contactLauncherServiceProvider` trỏ **bản Fake** (ghi `// TODO: bản thật khi có package`). `providers.dart` là của Hiếu → **hỏi người dùng trước khi sửa**; không được thì tạm khai báo provider trong file service và in đoạn code gửi Hiếu.
4. **Khung 3 ViewModel** trong `lib/viewmodels/` (Riverpod `Notifier`, state định nghĩa trước, hàm để trống có `// TODO bước 0x`):
   - `family_view_model.dart` – `FamilyViewModel` (S09, S09b, N21): `UiState<FamilyList>` gồm danh sách người thân, banner vừa thêm (S09b), banner vừa xoá + bản để Hoàn tác (N21).
   - `relative_form_view_model.dart` – `RelativeFormViewModel` (S12 × 3 khung, S12a, S12e, N09, N15): chế độ thêm / sửa (`personId`), bước (chọn cách / danh bạ / tự nhập theo câu trả lời bước 03), tên, quan hệ (mặc định "Khác"), số, lỗi từng ô, cờ `dirty`, cờ đang lưu, nguồn (`fromContacts`), trạng thái quyền danh bạ.
   - `share_message_view_model.dart` – `ShareMessageViewModel` (S17, S17b, N10): người nhận, kênh (Zalo – mặc định / SMS), nội dung, kết quả đã mở app.
5. **Test** `test/f11_services_test.dart` + `test/f11_view_models_test.dart` (override bằng `overrideWithValue(Fake…)`): Fake danh bạ lọc theo tên; từ chối quyền → `requestPermission` trả `false`; launcher ghi đúng số / nội dung; cờ lỗi ném `AppException`; 3 ViewModel khung build được.
6. **Docs**: `docs/architecture.md` mục 8 (2 service mới "Đã có (Fake)", chữ ký thật), mục 9 (cột "Có sẵn" 3 ViewModel = khung).

Được sửa: `lib/services/` (file mới), `lib/viewmodels/` (3 file mới), `test/` (file mới), `docs/architecture.md`; `lib/models/`, `providers.dart`, `pubspec.yaml` chỉ khi người dùng đồng ý.

## Đầu ra mong đợi

- 2 service mới có interface + Fake, test qua; 3 ViewModel khung build được.
- In cho người dùng: bảng service | hàm | Fake có cờ gì; câu trả lời 3 điểm cần hỏi; danh sách việc nhờ Hiếu (bản thật / package, trường mới của `Relative` nếu có).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 04/11/2026 (nhánh `feat/F11-Family`). Kiểm trùng: không nhánh nào có `ContactsService`; `FamilyViewModel` chỉ xuất hiện trong docs. Figma MCP chạy được (đã xem S09 `1:1993`, S12 `1:2110`, danh bạ `1:2146`, `14:196`, S17 `1:2278`, S17b `26:122`, N21 `52:48`).
- Trả lời 3 điểm cần hỏi (người dùng chọn 04/11):
  1. Quan hệ: **đề xuất thêm `Relative.relationLabel`** (chữ tự do: "Con gái", "Hàng xóm"…; `relation` vẫn là 1 trong 4 nhóm cho form + analytics). Chưa sửa `lib/models/`; ViewModel dùng `relationText(r)` / `relativeTitle(r)` ("Con gái Mai") – hiện trả `r.relation`, TODO đổi thành `r.relationLabel ?? r.relation` khi Hiếu thêm trường.
  2. Package: **đề xuất trong PR F11, Hiếu viết bản thật** (`flutter_contacts`, `url_launcher`). Provider đang trỏ Fake + TODO(Hiếu).
  3. Danh bạ: **theo Figma** – danh sách trong app có ô "Tìm tên" (`ContactsService.list({query})`), không mở màn chọn của hệ thống.
  4. Người dùng đồng ý cho thêm 2 provider vào `providers.dart`.
- File đã tạo / sửa:
  - Mới: `lib/services/contacts_service.dart` (`ContactsService`, `PhoneContact`, `FakeContactsService`, `foldVietnamese`), `lib/services/contact_launcher_service.dart` (`ContactLauncherService`, `ShareChannel`, `LaunchRecord`, `FakeContactLauncherService`), `lib/viewmodels/family_view_model.dart`, `lib/viewmodels/relative_form_view_model.dart`, `lib/viewmodels/share_message_view_model.dart`, `test/f11_services_test.dart`, `test/f11_view_models_test.dart`.
  - Sửa: `lib/services/providers.dart` (+`contactsServiceProvider`, `contactLauncherServiceProvider` → Fake, được người dùng đồng ý), `docs/architecture.md` mục 8.1 (2 service), 9 (3 ViewModel = khung), 10 (đề xuất `relationLabel`). Gỡ luôn khối xung đột merge `<<<<<<< HEAD … >>>>>>> feat/F12-suggest-schedule` còn sót ở mục 8.1 (giữ dòng `ProfileSetupService` bản F8 + dòng `SuggestionService`).
  - Khung ViewModel: `load` / `retry` (cả 3), `chooseManual`, `setName/Relation/Phone`, `selectChannel` chạy được; các hàm còn lại để trống, có `// TODO bước 02–05`. Hàm số điện thoại `phoneDigits` / `isValidPhone` / `formatPhone` (4-3-3, nhận "+84") đặt trong `relative_form_view_model.dart`.
- Lệch Figma (nếu có, lý do): chưa có (bước này không vẽ màn). Lưu ý cho bước 02: `FakeFamilyRepository` (Hiếu) chỉ có Mai + Hùng, `relation: 'Con'` nên thẻ sẽ hiện "Con" cho tới khi có `relationLabel`; test dùng `SeededFamilyRepository` riêng (Mai, Hùng, Bin).
- `flutter analyze` / `flutter test`: analyze còn 1 cảnh báo **có sẵn** (`lib/router/app_router.dart:43` `pendingNotification` không dùng), không có lỗi mới. Test: trước khi sửa 535 qua / **62 lỗi có sẵn** (bắt đầu từ `auth_routing_test.dart`); sau khi sửa 557 qua / 62 lỗi – 22 test F11 mới đều qua, không có lỗi mới.
- Việc người dùng cần làm tay: gửi Hiếu (1) đề xuất trường `relationLabel` (String?, Firestore `users/{uid}/family/{id}.relationLabel`) cho `Relative` + `FirebaseFamilyRepository`; (2) bản thật `ContactsService` (`flutter_contacts` + quyền READ_CONTACTS) và `ContactLauncherService` (`url_launcher`: `tel:`, `sms:?body=`, `https://zalo.me/<số>`, khai báo `<queries>` trong AndroidManifest); (3) báo Sanh đã gỡ khối xung đột merge trong `docs/architecture.md`.
- Commit gợi ý: `feat(F11): service danh bạ / gọi điện / nhắn tin (Fake) + khung 3 ViewModel Gia đình`
