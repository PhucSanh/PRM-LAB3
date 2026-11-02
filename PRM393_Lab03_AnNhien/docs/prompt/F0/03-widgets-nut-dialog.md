# Bước 03 · F0 · Widget: nút, thanh Quay lại, hộp thoại, Hoàn tác, trạng thái

Bạn là AI agent làm bước 03 của feature **F0 – Nền tảng** cho app An Nhiên. Bước 01–02 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Bộ widget hành động và phản hồi mà màn nào cũng dùng, đặt trong `lib/widgets/`.

## Quy tắc chung (áp dụng cho mọi bước)

- Làm việc ở thư mục gốc repo `PRM393_Lab03_AnNhien`, nhánh `feat/F0-nen-tang`. Đọc `CLAUDE.md` trước tiên và tuân theo.
- Figma file key `K3JczHkChbUWoDBkXZYMhR`. Nếu có Figma MCP: gọi `get_design_context` + `get_screenshot` cho từng node được liệt kê. Nếu không có: dùng Stitch HTML ở `../../prm393-lab2-an-nhien/stitch-runs/<mã màn>/` (bản `v` số lớn nhất). Figma lệch Stitch thì **Figma thắng**.
- Tài liệu Lab 2 (chỉ đọc) ở `../../prm393-lab2-an-nhien/`: `flutter-handoff.md`, `rule.md`, `accessibility.md`, `assets/stitch/DESIGN.md` (token), `assets/stitch/AppStyleGuide.md`, `assets/stitch/vocabulary.md`.
- **Không được sửa**: `android/`, `firebase/`, `lib/services/`, `lib/models/`, `lib/main.dart`, `lib/screens/` của người khác. Không thêm package nếu bước này không cho phép.
- Không viết cứng màu / cỡ chữ / khoảng cách: chỉ dùng `lib/theme/`. Chữ ≥ 20 sp, vùng chạm ≥ 72 dp, kiểm tra 360 và 412 dp, `textScaler` 1.3 và 2.0 không tràn.
- Gặp chỗ không chắc (thiếu file, Figma mâu thuẫn tài liệu, cần sửa file ngoài phạm vi) thì **dừng lại hỏi**, không đoán.
- Docs: nếu bước này làm lệch Figma (đổi icon, đổi bố cục, bỏ chi tiết…), thêm dòng `DT-xx` (số tiếp theo) vào cuối `docs/design-traceability.md` ghi lệch gì, vì sao. Không đổi cột Trạng thái của F0 (đang `doing`, bước 06 mới chốt). Thêm / đổi widget, route, provider thì cập nhật luôn `docs/architecture.md` (mục 7, 12, 13).
- Không tự `git commit` / `push`. Chạy `flutter analyze` và `flutter test` tới khi sạch rồi mới báo xong.
- Xong việc: điền mục **"Kết quả chạy"** ở cuối chính file này (thay các dòng trống), rồi in tóm tắt cho người dùng.

## Đọc trước

`CLAUDE.md`, `docs/architecture.md` mục 13 + 15, `lib/theme/*.dart`, `lib/widgets/*.dart`, `../../prm393-lab2-an-nhien/flutter-handoff.md` mục "States & Dialog dùng chung" và "Bảng 2 – Component → Widget", `assets/stitch/AppStyleGuide.md` (nhãn nút, câu xác nhận, hoàn tác), `rule.md`.

## Figma

| Widget | Khung | Node |
| --- | --- | --- |
| `AppButton` | Nút/Chính (filled), Nút/Phụ (viền) | `138:103`, `138:107` |
| `AppBackBar` | Thanh tiêu đề/Quay lại + bước; Back + "Sửa" ở S04 | `138:111`, `1:580` |
| `ConfirmDialog` | DLG-Done · DLG-Later · DLG-Skip · DLG-Delete · N13 Phạm vi · N14 Chưa lưu | `29:125` · `29:156` · `29:211` · `29:98` · `43:195` · `43:239` |
| `UndoSnackbar` | S03b · S03-skip · G09 | `12:2` · `10:193` · `66:2` |
| State views | ST-Loading · ST-Empty · ST-Error | `26:191` · `15:39` · `26:159` |

## Việc cần làm

1. `AppButton`: thêm biến thể `tonal`, `text`, `dangerOutline` (`danger` = nền đỏ, `dangerOutline` = viền đỏ) theo Bảng 2. Giữ API hiện có để không vỡ code đang dùng.
2. `AppBackBar`: thêm tham số `trailing` (vd. nút "Sửa" ở S04), giữ `backLabel` + `step`.
3. `ConfirmDialog` + `Future<T?> showConfirmDialog<T>({icon, iconColor, title, message, required List<ConfirmOption<T>> options})`: icon 64, nút xếp dọc full-width, cách nhau `AppSpacing.betweenTargets`, lựa chọn huỷ luôn ở cuối; dựng được đủ DLG-Done / Later / Skip / Delete, N13, N14. Tiêu đề có `Semantics(header: true)`.
4. `showUndoSnackbar(context, {title, subtitle, onUndo})`: 2 tầng chữ, nút "Hoàn tác" ≥ 48 dp, **không tự tắt**, có nút đóng.
5. `state_views.dart`: so lại với ST-*; `EmptyView` nhận icon + tiêu đề + mô tả + action tuỳ chọn; `ErrorView` luôn có nút "Thử lại" và `liveRegion`.
6. Câu chữ mặc định theo `AppStyleGuide.md`.
7. Test widget trong `test/widgets/`: render từng biến thể, bấm trả đúng giá trị, snackbar còn sau 10 giây, 360 dp + `textScaler` 1.3 không tràn.

Chỉ sửa `lib/widgets/` và `test/widgets/`.

## Đầu ra mong đợi

- `AppButton` 6 biến thể, `AppBackBar` 3 biến thể, `ConfirmDialog`, `showUndoSnackbar`, state views khớp ST-*.
- Test qua, `flutter analyze` sạch.
- In cho người dùng bảng: widget | API | khung Figma | lệch Figma (nếu có, lý do).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 02/11/2026
- File đã tạo / sửa:
  - Tạo: `lib/widgets/confirm_dialog.dart` (`ConfirmDialog`, `ConfirmOption`, `ConfirmDetail`, `showConfirmDialog`), `lib/widgets/undo_snackbar.dart` (`showUndoSnackbar`), `lib/widgets/icon_circle.dart` (`IconCircle`); `test/widgets/harness.dart`, `app_button_test.dart`, `confirm_dialog_test.dart`, `undo_snackbar_test.dart`, `state_views_test.dart`.
  - Sửa: `lib/widgets/app_button.dart` (6 biến thể), `app_back_bar.dart` (`trailing` + `AppBarEditButton`), `state_views.dart` (khớp ST-*); `docs/architecture.md` mục 13; `docs/design-traceability.md` (DT-10, DT-11).
- Lệch Figma (nếu có, lý do): DT-10 – snackbar 2 tầng (chữ trên, nút dưới) + thêm nút "Đóng", nút "Hoàn tác" cao 72 (Figma 48). DT-11 – icon hộp thoại / ST-* 64 trong vòng 112 (Figma ≈ 44 / 80), nút cao 72 (Figma 60). Lệch prompt: "lựa chọn huỷ luôn ở cuối" chỉ áp cho DLG-Done / Later / Skip / N13; DLG-Delete và N14 theo Figma + SG-19 (nút an toàn là nút chính, đứng trên) – `showConfirmDialog` vẽ đúng thứ tự `options` truyền vào. `AppButtonKind.danger` đổi từ viền đỏ sang **nền đỏ** theo prompt; viền đỏ nay là `dangerOutline` (chưa màn nào dùng `danger`).
- `flutter analyze` / `flutter test`: analyze sạch. `test/widgets/` 37/37 qua (6 biến thể nút, 3 biến thể thanh Quay lại, 6 hộp thoại × 360 dp ×1.3 / ×2.0, snackbar còn sau 10 giây + 5 phút, state views ở 360 / 412 dp ×1.3 / ×2.0). Toàn bộ 107 qua, trừ `auth_routing_test` lỗi có sẵn (khối `redirect` đang tắt).
- Việc người dùng cần làm tay: thêm `AppIcons.undo` (`Icons.undo`) vào `lib/theme/app_icons.dart` ở bước sau rồi bỏ TODO trong `undo_snackbar.dart` (bước này không được sửa `lib/theme/`). Báo nhóm: snackbar không tự tắt, màn tự gọi `ScaffoldMessenger.of(context).hideCurrentSnackBar()` khi rời màn nếu cần.
- Commit gợi ý: `feat(F0): widget dùng chung – AppButton 6 biến thể, AppBackBar trailing, ConfirmDialog, UndoSnackbar, state views theo ST-*`
