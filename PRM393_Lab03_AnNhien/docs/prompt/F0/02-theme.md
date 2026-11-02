# Bước 02 · F0 · Theme: font, token, cỡ chữ, tương phản cao

Bạn là AI agent làm bước 02 của feature **F0 – Nền tảng** cho app An Nhiên. Bước 01 (route) đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

`lib/theme/` là nguồn duy nhất cho màu / chữ / khoảng cách, khớp token Lab 2; app hỗ trợ cỡ chữ người dùng chọn (1.0 / 1.15 / 1.3) và chế độ tương phản cao (S01, S10).

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

`CLAUDE.md`, `docs/architecture.md` mục 12, `lib/theme/*.dart`, `lib/app.dart`, `pubspec.yaml`, `../../prm393-lab2-an-nhien/assets/stitch/DESIGN.md` (colors, typography, spacing, rounded, 9 màu thói quen, từ điển icon), `../../prm393-lab2-an-nhien/flutter-handoff.md` mục "Bảng 1 – Token → Flutter", S01, S10, `rule.md`, `accessibility.md`.

## Figma

| Khung | Node | Lấy gì |
| --- | --- | --- |
| Components | `138:2` | Bộ icon 32 dp (Lucide), nút, thanh tiêu đề |
| S01 Chào mừng – chọn cỡ chữ | `1:2` | 3 mức cỡ chữ |
| S10 Cài đặt hiển thị | `1:2325`, `1:2474` | Cỡ chữ, tương phản cao |
| S03 Hôm nay | `1:270` | Đối chiếu màu / chữ thực tế |

## Việc cần làm

1. Kiểm tra `assets/fonts/` có `BeVietnamPro-Regular.ttf`, `BeVietnamPro-SemiBold.ttf`, `BeVietnamPro-Bold.ttf`. **Nếu thiếu: dừng và báo người dùng tải từ Google Fonts**, không tự tạo file. Có rồi thì mở khối `fonts:` đang comment trong `pubspec.yaml`.
2. Rà từng token trong `DESIGN.md` + Bảng 1 với `AppColors`, `HabitPalette`, `AppSpacing`, `AppRadius`, `AppSizes`, `AppTheme.textTheme`. Thiếu thì thêm, sai thì sửa, ghi nguồn trong comment. Không có chữ < 20 sp.
3. Thêm `enum AppFontScale { vua(1.0), lon(1.15), ratLon(1.3) }` và `fontScaleProvider` (Riverpod `Notifier`, giữ trong bộ nhớ, mặc định `vua`) ở `lib/theme/`. Thêm `highContrastProvider` (bool) tương tự. F8 sẽ nối `SettingsService` sau.
4. Thêm `AppTheme.highContrast()`: `ColorScheme` tương phản cao (chữ chính đạt 7:1) theo S10.
5. `lib/app.dart`: chọn theme theo `highContrastProvider`; bọc `builder` bằng `MediaQuery` với `textScaler = TextScaler.linear(fontScale)` (trần 2.0). Chỉ sửa phần theme / textScaler, giữ `routerConfig`.
6. Tạo `lib/theme/app_icons.dart`: mỗi icon trong khung Components (mic, phone, lock, fingerprint, check, check-circle, refresh, volume, list, chevron-left, alert, clock, repeat, bell, arrow-right, x, square, shield, pencil, user, home, walk) → hằng `IconData` Material gần nhất. Không thêm package icon.
7. Tìm trong `lib/widgets/` và `lib/screens/` mọi `Color(0x…)`, `Colors.*`, `fontSize:`, `EdgeInsets` số cứng → thay bằng token. Ở `lib/screens/today/` (code của Khang) chỉ thay token, không đổi logic.

Được sửa: `lib/theme/`, `lib/app.dart`, `lib/widgets/`, `lib/screens/today/` (chỉ token), `pubspec.yaml` (khối fonts), `test/`.

## Đầu ra mong đợi

- Font đã khai báo, app hiển thị Be Vietnam Pro.
- Token khớp `DESIGN.md`; có `AppFontScale`, `fontScaleProvider`, `highContrastProvider`, `AppTheme.highContrast()`, `AppIcons`.
- Đổi `fontScaleProvider` thì toàn app đổi cỡ chữ.
- Không còn giá trị cứng trong `lib/widgets/`, `lib/screens/`.
- In cho người dùng: token thêm / sửa (cũ → mới, nguồn), chỗ hard-code đã thay, việc cần làm tay.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 02/11/2026
- File đã tạo / sửa:
  - Tạo: `lib/theme/display_settings.dart` (`AppFontScale`, `fontScaleProvider`, `highContrastProvider`, `maxTextScale`), `lib/theme/app_icons.dart`, `test/theme_test.dart`, `test/text_scale_overflow_test.dart`.
  - Sửa: `pubspec.yaml` (mở khối `fonts:`), `lib/theme/app_colors.dart`, `app_spacing.dart`, `app_theme.dart` (`highContrast()`, `AppText`, đủ 15 kiểu chữ ≥ 20), `lib/app.dart` (theme theo `highContrastProvider`, `textScaler` = hệ thống × cỡ Bác chọn, trần 2.0), `lib/widgets/app_back_bar.dart`, `app_button.dart`, `app_shell.dart`, `state_views.dart`, `lib/screens/today/today_screen.dart` (chỉ token), `docs/architecture.md` mục 12–13, `docs/design-traceability.md` (DT-09).
- Lệch Figma (nếu có, lý do): DT-09 – icon Lucide thay bằng icon Material gần nhất (không thêm package). Mặc định cỡ chữ là **Lớn (1.15)** theo Figma S01/S10 (người dùng chốt), khác dòng "mặc định `vua`" trong prompt này. Bảng màu tương phản cao không có trong Figma (S10 chỉ có công tắc): dựng từ màu đậm sẵn có trong DESIGN.md, chữ chính 18.6 : 1.
- `flutter analyze` / `flutter test`: analyze sạch. `theme_test` 4/4, `text_scale_overflow_test` 16/16 (360 + 412 dp, Rất lớn, trần 2.0), `router_test` 44/44 qua. `auth_routing_test` vẫn lỗi có sẵn từ trước (khối `redirect` đang tắt) – người dùng chưa cần xử lý.
- Việc người dùng cần làm tay: `flutter run` lại (đổi `pubspec.yaml` nên hot reload không nạp font). `lib/screens/sign_in/sign_in_screen.dart` (của Hiếu) còn `size: 96` cứng → nhờ Hiếu đổi thành `AppSizes.logo`. Nhắn nhóm: màn lấy màu qua `colorScheme`, không đọc `AppColors` trực tiếp, thì tương phản cao mới có tác dụng. Commit 3 file font `assets/fonts/*.ttf` (giấy phép OFL).
- Commit gợi ý: `feat(F0): theme – bundle Be Vietnam Pro, đủ token DESIGN.md, cỡ chữ 3 mức + tương phản cao, AppIcons, bỏ giá trị cứng trong widgets`
