# Bước 06 · F0 · Trang xem thử widget, kiểm tra, cập nhật docs

Bạn là AI agent làm bước cuối của feature **F0 – Nền tảng** cho app An Nhiên. Bước 01–05 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Chốt F0 đạt "Xong khi": màn của mọi người chỉ dùng widget trong `lib/widgets/`, không còn màu / cỡ chữ cứng, `flutter analyze` sạch; docs cập nhật, sẵn sàng mở PR `feat/F0-nen-tang` → `main`.

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

`CLAUDE.md`, `docs/architecture.md` mục 12, 13, 15, `docs/design-traceability.md` phần "Cách dùng" và F0, `lib/theme/`, `lib/widgets/`, `lib/router/app_router.dart`, `../../prm393-lab2-an-nhien/rule.md`, `accessibility.md`.

Figma: đối chiếu lại các node đã dùng ở bước 02–05 nếu cần.

## Việc cần làm

1. Tạo `lib/widgets/dev/widget_gallery.dart`: một màn liệt kê mọi widget F0 theo nhóm (nút, thanh, dialog, snackbar, state views, form, nội dung) với dữ liệu mẫu; thanh trên cùng đổi cỡ chữ (1.0 / 1.15 / 1.3 / 2.0) và bật tương phản cao qua `fontScaleProvider` / `highContrastProvider`. Thêm route `/dev/widgets` trong `app_router.dart`, chỉ khai báo khi `kDebugMode`.
2. Tạo `test/widgets/gallery_overflow_test.dart`: render gallery ở 360×800 và 412×915, `textScaler` 1.0 / 1.3 / 2.0; có lỗi overflow thì test fail.
3. Quét `lib/widgets/` và `lib/screens/`: liệt kê chỗ còn `Color(0x…)`, `Colors.*`, `fontSize:`, `EdgeInsets` số cứng, widget tự chế lặp lại widget F0. Sửa trong `lib/widgets/`; ở màn của người khác chỉ **liệt kê**, không sửa.
4. Tự chấm theo `rule.md` (11 luật): vùng chạm ≥ 72 dp, cách nhau ≥ 20, chữ ≥ 20 sp, Back có chữ, có Hoàn tác, contrast. Lập bảng luật | đạt / chưa | chỗ chưa đạt.
5. Cập nhật `docs/architecture.md` mục 12, 13 (tên widget, API thật, trạng thái "có"). Cập nhật `docs/design-traceability.md`: 2 dòng F0 sang `done`, hoặc `changed` + thêm dòng `DT-xx` cuối file nếu lệch Figma (lệch gì, vì sao).
6. Trong `lib/router/app_router.dart`, khối `redirect` đang bị comment tạm (để test UI không cần đăng nhập). Bỏ comment để trả lại đúng như cũ (đề chấm: chưa đăng nhập không vào được app), và xoá 2 dòng ghi chú "TẠM TẮT…" phía trên nó. Chạy lại `flutter test`.
7. Soạn mô tả PR (tiếng Việt) lưu vào `docs/prompt/F0/PR-F0.md`: làm gì, widget mới + API, route mới, ảnh cần chụp (gallery ở 360 dp, `textScaler` 1.3), checklist "Checklist trước khi mở PR" trong `CLAUDE.md`.

Được sửa: `lib/widgets/`, `lib/router/app_router.dart` (thêm route dev, bỏ comment `redirect`), `test/`, `docs/architecture.md`, `docs/design-traceability.md`, `docs/prompt/F0/`.

## Đầu ra mong đợi

- `/dev/widgets` chạy được ở debug, test overflow qua.
- Bảng tự chấm `rule.md` + danh sách chỗ hard-code ở màn người khác (để người dùng báo họ).
- Docs cập nhật, `PR-F0.md` sẵn sàng, `flutter analyze` + `flutter test` sạch.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 02/11/2026
- File đã tạo / sửa:
  - Tạo: `lib/widgets/dev/widget_gallery.dart` (`WidgetGallery`, tham số `animate` để test tắt hoạt ảnh), `test/widgets/gallery_overflow_test.dart` (9 test: 360×800 / 412×915 × `textScaler` 1.0 / 1.3 / 2.0 cuộn hết trang; chip ×2.0 + tương phản cao; chip cỡ chữ đổi provider; mở 3 hộp thoại + snackbar), `docs/prompt/F0/PR-F0.md`.
  - Sửa: `lib/router/app_router.dart` (route `/dev/widgets` chỉ khi `kDebugMode`; khối `redirect` **giữ comment** theo yêu cầu người dùng – không làm việc 6); `lib/widgets/app_back_bar.dart` ("Bước x/y" / `trailing` chuyển sang ô `title` co giãn – hết tràn 24 dp ở ×2.0); `lib/widgets/time_field.dart` ("Đổi giờ" co được – hết tràn 32 dp ở ×2.0); `docs/architecture.md` mục 7, 13; `docs/design-traceability.md` (2 dòng F0 → `changed`, DT-21).
  - **Ngoài phạm vi, người dùng đã đồng ý:** `lib/screens/sign_in/sign_in_screen.dart` (Hiếu) bọc cuộn + `AppSizes.logo` – khi bật `redirect` màn này tràn 213 dp ở 360 dp × 2.0 (phát hiện lúc thử bật).
- Lệch Figma (nếu có, lý do): DT-21 – thanh Quay lại: "Bước x/y" / nút "Sửa" thu nhỏ khi chữ ×2.0 thiếu chỗ. F0 tổng thể `changed` vì DT-09 → DT-21.
- `flutter analyze` / `flutter test`: analyze sạch; 178 / 179 test qua, không có cảnh báo chạm trượt. `auth_routing_test` fail vì khối `redirect` đang comment (lúc thử bật thì 179 / 179 qua).
- Tự chấm `rule.md`: bảng 11 nhóm trong `PR-F0.md`. Chưa đạt: icon "Đang chọn" ✓ vs `circle-dot` (DT-18); ô giờ 62 dp cách 8 dp (DT-12); "Sửa" có thể < 72 dp ở ×2.0 (DT-21); thiếu nhãn "🔔 Đến giờ" (model chưa có trạng thái này).
- Chỗ viết cứng ở màn người khác (chỉ liệt kê): `today_screen.dart` (Khang) – `_TaskTile` tự chế `:65–106`, giờ ghép tay `:73`, `Icons.spa` `:90`, trạng thái tự vẽ `:98`, `TextButton.icon` "Cài đặt" `:50`, `Icons.add` / `event_available_outlined` `:27,29,58`; `sign_in_screen.dart` (Hiếu) – `Icons.spa_outlined`, `Icons.login`. Chi tiết trong `PR-F0.md`.
- Việc người dùng cần làm tay:
  - Chụp ảnh gallery (360 dp, ×1.3, bật / tắt tương phản cao) dán vào PR; mở PR bằng nội dung `PR-F0.md`.
  - Nhờ Hiếu duyệt sửa `sign_in_screen.dart`; báo Khang danh sách ở `today_screen.dart`.
  - Thêm `AppIcons.undo`, `AppIcons.plus`, `AppIcons.trash` rồi bỏ `Icons.*` còn lại (undo_snackbar, gallery); chốt icon "Đang chọn"; gán màu cảnh báo vào `ColorScheme`.
  - Sửa Figma theo các dòng DT còn ☐.
  - **Bỏ comment khối `redirect` trong `app_router.dart` trước khi nộp** (đề chấm: chưa đăng nhập không vào được app).
  - Commit theo thứ tự bước 04 → 05 → 06 (hiện cả 3 bước đều chưa commit).
- Commit gợi ý: `feat(F0): trang xem thử widget /dev/widgets, test tràn chữ, cập nhật docs`
