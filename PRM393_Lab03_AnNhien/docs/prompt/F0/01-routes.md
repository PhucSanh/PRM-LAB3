# Bước 01 · F0 · Hoàn thiện route map

Bạn là AI agent làm bước 01 của feature **F0 – Nền tảng** cho app An Nhiên (Flutter, go_router, Riverpod). Đọc hết file này rồi thực hiện.

## Mục tiêu

Mọi màn trong `docs/architecture.md` mục 7.2 đều có route (màn chưa làm = `FeaturePlaceholder`), tên người phụ trách đúng bản chia task 02/11/2026, để cả nhóm có chỗ gắn màn ngay.

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

`CLAUDE.md`, `docs/architecture.md` mục 7 (7.1 điều kiện chặn, 7.2 route map, quy tắc điều hướng), `../An-Nhien_Chia-task_Lab3.md` (bảng feature + người làm), `lib/router/app_router.dart`, `lib/widgets/feature_placeholder.dart`, `lib/widgets/app_shell.dart`.

Figma: không cần cho bước này.

## Việc cần làm

1. Trong `lib/router/app_router.dart`, thêm mọi route đang ghi "chưa có" ở bảng 7.2, dùng `FeaturePlaceholder` qua hàm `ph(...)`:
   - `/role` (C01 · F1 · Hiếu)
   - `/setup/try-reminder` (N01 · F2 · Hương), `/setup/first-task` (N04 · F2 · Hương)
   - `/today/add/result` (ST-Saved · F4 · Khang)
   - `/task/date` (N11), `/task/repeat` (N12), `/task/scope` (N13) – F4 · Khang. Khai báo ở cấp gốc, ngoài shell; sau này trả kết quả bằng `pop(result)`.
   - `/today/all` (S11 · F7 · Hương), `/week/:date/task/:id` (S04 · F3 · Khang)
   - `/family/:personId/edit` (N09 · F11 · Hương)
   - `/settings/reminders` (N07 · F6 · Khang), `/settings/help` (N08 · F8 · Sanh), `/settings/data` (N20 · F8 · Sanh)
   - `/caregiver/pair` (C02 · F13 · Hiếu), `/caregiver/schedule` (C03 · F14 · Hiếu, đọc query `view=day|week|month`)
   - `/caregiver/task/new`, `/caregiver/task/new/repeat`, `/caregiver/task/new/review`, `/caregiver/task/sent` (C06–C09 · F14 · Hiếu), `/caregiver/task/:id` (C10 · F14 · Hiếu)
   - `/caregiver/suggest` (G01 · F12 · Sanh)
   - Mọi route `/caregiver/*` nằm **ngoài** `StatefulShellRoute` của Bác.
2. Sửa tên người trên placeholder đang có cho đúng bản 02/11: F2 (S01, S02, S13) = Hương; `/today/suggestions/:id` (G03) = Sanh; `/settings/profile` (N06) = "Sanh (khu demo: Hiếu)". Rà lại mọi placeholder còn lại.
3. Nhóm route theo feature, mỗi nhóm một comment `// F<số> <tên> – <người>`.
4. **Không** đụng khối `redirect` (đang comment tạm, điều kiện chặn do Hiếu phụ trách) và không đổi `initialLocation`.
5. Tạo `test/router_test.dart`: `ProviderContainer` override `authServiceProvider` bằng `FakeAuthService(signedIn: AppUser(...))`, lấy `routerProvider`, `router.go(path)` cho từng path mẫu (thay `:id`, `:date`… bằng giá trị giả), `pumpAndSettle`, kiểm tra không lỗi và thấy mã màn trên placeholder.

Chỉ sửa `lib/router/` và `test/`.

## Đầu ra mong đợi

- `app_router.dart` có đủ route của mục 7.2, route đã có giữ nguyên builder.
- Placeholder ghi đúng mã màn · feature · người.
- `test/router_test.dart` qua; `flutter analyze` sạch.
- In cho người dùng bảng: route | mã màn | feature | người | trạng thái (mới thêm / đã có / sửa tên).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy: 02/11/2026
- File đã tạo / sửa: `lib/router/app_router.dart` (sửa: thêm 20 route placeholder, sửa tên người F2 → Hương, G03 → Sanh, N06 → "Sanh (khu demo: Hiếu)", nhóm route theo feature); `test/router_test.dart` (tạo: 44 path mẫu); `docs/architecture.md` mục 7.2 (cột "Trong `app_router.dart`" hết "chưa có", ghi chú việc F0 đã làm).
- Lệch Figma (nếu có, lý do): không (bước này không vẽ giao diện). `/caregiver/schedule` chọn C03 / C04 / C05 theo query `view` (mặc định `day`). C06 → C07 → C08 khai báo lồng (`/caregiver/task/new/repeat|review`) để `go` dựng sẵn ngăn xếp Quay lại; `new` và `sent` đặt trước `:id`.
- `flutter analyze` / `flutter test`: analyze sạch. `test/router_test.dart` 44/44 qua; `today_view_model_test.dart` qua. **`test/auth_routing_test.dart` lỗi có sẵn từ trước** (commit 3027a49 tắt khối `redirect` nên mở app vào `/today` thay vì `/sign-in`), không do bước này; bước này không được đụng `redirect`.
- Việc người dùng cần làm tay: quyết định cách xử lý `auth_routing_test.dart` (bật lại `redirect` – việc của Hiếu – hoặc tạm `skip` test có ghi lý do). Chạy app xem thử vài route `/caregiver/*` (không có bottom nav) nếu muốn.
- Commit gợi ý: `feat(F0): hoàn thiện route map – thêm placeholder mọi màn mục 7.2, sửa người phụ trách theo chia task 02/11, thêm router_test`
