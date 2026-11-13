# F11 — Gia đình: checklist kiểm thử

Chủ feature: Hương. Nhánh: `feat/F11-Family`. Flow liên quan: 5, 9.
Đặc tả gốc: [f11-family-management-spec.md](f11-family-management-spec.md).
Tài liệu này chỉ mô tả và hướng dẫn kiểm thử, không thay đổi luồng chạy code.

## Phần đã triển khai

| Thành phần | File | Ghi chú |
| --- | --- | --- |
| Màn danh sách gia đình | `lib/screens/calm/family_screen.dart` (`FamilyScreen`) | Khối kết nối gia đình + danh bạ người thân, có Loading/Empty/Error |
| Thêm/sửa người thân | `FamilyEditorScreen` cùng file | Hỏi xác nhận khi thoát mà còn thay đổi chưa lưu |
| Xem chi tiết người thân | `FamilyContactScreen` cùng file | Nút quay lại về `/family` nếu không pop được |
| ViewModel | `lib/viewmodels/family_actions_view_model.dart` | Gọi điện, bật/tắt yêu thích, hoàn tác |
| Repository | `lib/services/family_repository.dart` | `FamilyRepository`, `FavoriteFamilyRepository`, bản Fake cho test |
| Thẻ liên hệ | `lib/widgets/family_contact_card.dart` | Dùng trong danh bạ |

## Route

| Path | Màn |
| --- | --- |
| `/family` | `FamilyScreen` (người chăm sóc được chuyển sang `/caregiver/family`) |
| `/family/add` | `FamilyEditorScreen` thêm mới |
| `/family/:personId/edit` | `FamilyEditorScreen` sửa |
| `/family/:personId/share` | Chia sẻ thông tin người thân |

## Hành vi của `FamilyActionsViewModel`

- `call(person)`: mở trình quay số với `person.phone` qua `contactLauncherServiceProvider`.
- `toggleFavorite(person)`:
  - Đang xử lý (`state == true`) thì bỏ qua, trả `null` để chống bấm liên tục.
  - Chưa đăng nhập thì báo lỗi "Bác đăng nhập lại nhé."
  - Thành công thì làm mới `familyListProvider` và trả về `FavoriteChange` để hoàn tác.
- `undo(change)`: chỉ hoàn tác khi UID hiện tại trùng UID lúc thay đổi; khác thì báo
  "Tài khoản đã thay đổi. Bác mở lại Gia đình nhé."
- Repository có `setFavorite` riêng thì dùng nó, không thì lưu lại cả bản ghi qua `save`.

## Checklist kiểm thử thủ công

Đánh dấu khi đã chạy trên máy thật hoặc emulator.

### Danh bạ gia đình
- [ ] Mở `/family` lúc đang tải: hiện "Đang tải người thân…".
- [ ] Danh sách rỗng: hiện EmptyView, nút thêm người thân vẫn bấm được.
- [ ] Lỗi tải: hiện ErrorView, bấm thử lại thì tải lại được.
- [ ] Có dữ liệu: mỗi người thân hiện một thẻ, bấm sửa mở `/family/:personId/edit`.

### Thêm / sửa người thân
- [ ] Thêm người thân mới, lưu xong quay về `/family` và thấy người vừa thêm.
- [ ] Sửa một trường rồi bấm quay lại: hiện hộp thoại "Bỏ thay đổi chưa lưu?".
- [ ] Chọn "Tiếp tục chỉnh sửa": ở lại form, dữ liệu còn nguyên.
- [ ] Chọn "Bỏ thay đổi": thoát, dữ liệu cũ không đổi.
- [ ] Lưu lỗi: hiện thông báo lỗi dưới form, không mất dữ liệu đã nhập.

### Yêu thích và gọi điện
- [ ] Bật yêu thích: thẻ cập nhật ngay, có lựa chọn hoàn tác.
- [ ] Bấm hoàn tác: trạng thái yêu thích trở về như cũ.
- [ ] Bấm yêu thích liên tục nhiều lần: chỉ ghi nhận một lần cho mỗi thao tác.
- [ ] Bấm gọi: mở trình quay số với đúng số điện thoại.

### Kết nối gia đình
- [ ] Khối kết nối đang tải: hiện "Đang tải kết nối gia đình…".
- [ ] Lỗi tải kết nối: nút "Thử tải lại kết nối" tải lại được.
- [ ] Nút ghép nối mở đúng `/caregiver/pair` hoặc `/pairing/code` theo vai trò.

## Test tự động

- Golden: `test/goldens/calm_family.png`.
- Gợi ý lịch từ gia đình: `test/firebase_family_suggestion_test.dart`.
- Chạy: `flutter test`.

Khi golden test fail, Flutter sinh ảnh so sánh trong `test/failures/`. Thư mục này đã
được thêm vào `.gitignore`, không commit. Nếu giao diện thay đổi có chủ đích thì cập
nhật golden bằng `flutter test --update-goldens`.

## Lưu ý bảo mật

`firebase/functions/.secret.local` chứa API key cho Cloud Functions và đã nằm trong
`.gitignore`. Không commit file này. GitHub Push Protection sẽ chặn push nếu trong
commit có key.
