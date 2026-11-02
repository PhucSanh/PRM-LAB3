# Bước 07 · F2 · Kiểm tra cả luồng, docs, PR

Bạn là AI agent làm bước 07 (cuối) của feature **F2 – Onboarding của Bác**. Bước 01–06 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Chắc chắn F2 đạt mục "Xong khi", không vi phạm luật bị chấm, docs khớp code, có sẵn mô tả PR.

## Quy tắc chung (áp dụng cho mọi bước)

- Làm việc ở thư mục gốc repo `PRM393_Lab03_AnNhien`, nhánh `feat/F2-onboarding`. Đọc `CLAUDE.md` trước tiên và tuân theo.
- Figma file key `K3JczHkChbUWoDBkXZYMhR`. Nếu có Figma MCP: gọi `get_design_context` + `get_screenshot` cho từng node được liệt kê. Nếu không có: dùng Stitch / Codex HTML ở `../../prm393-lab2-an-nhien/stitch-runs/<mã màn>/` hoặc `codex-runs/<mã màn>/` (bản `v` số lớn nhất, xem cột Stitch trong `docs/design-traceability.md`). Figma lệch Stitch thì **Figma thắng**.
- Tài liệu Lab 2 (chỉ đọc) ở `../../prm393-lab2-an-nhien/`: `flutter-handoff.md`, `ux/user-flow.md` (Flow 1), `rule.md`, `accessibility.md`, `assets/stitch/DESIGN.md`, `assets/stitch/AppStyleGuide.md`, `assets/stitch/vocabulary.md`.
- **Chỉ dùng widget trong `lib/widgets/`** (`AppButton`, `AppBackBar`, `AppTextField`, `TimeField` / `showTimeWheel`, `ChoiceGroup`, `SwitchRow`, `HabitTile`, `TaskRow`, `showConfirmDialog`, `showUndoSnackbar`, `LoadingView` / `EmptyView` / `ErrorView`, `IconCircle`…). Thiếu widget thì **dừng lại báo**, không tự làm bản riêng trong thư mục màn.
- **Không được sửa**: `android/`, `firebase/`, `lib/theme/`, `lib/widgets/`, bản `Firebase…` của service, `lib/main.dart`, màn / ViewModel của người khác (nhất là `lib/screens/today/`, `today_view_model.dart` của Khang). `lib/services/providers.dart` và `lib/models/` là của Hiếu: muốn sửa thì **hỏi người dùng trước**. Không thêm package.
- Kiến trúc: View chỉ vẽ `UiState` bằng `switch` và gửi sự kiện; logic, validate, gọi service, log analytics nằm trong ViewModel (`Notifier`). Hành động một lần (lưu, xin quyền…) trả kết quả về View để điều hướng / hiện Snackbar. Không gọi `FirebaseXxx.instance` trong widget.
- Không viết cứng màu / cỡ chữ / khoảng cách: chỉ dùng `lib/theme/` (màu qua `Theme.of(context).colorScheme` để tương phản cao có tác dụng). Chữ ≥ 20 sp, vùng chạm ≥ 72 dp, cách nhau `AppSpacing.betweenTargets`; kiểm tra 360 và 412 dp, `textScaler` 1.3 và 2.0 không tràn.
- Câu chữ theo `AppStyleGuide.md` + `vocabulary.md` (gọi người dùng là "Bác", nút = động từ + việc, lỗi có "Ví dụ: …").
- Analytics chỉ gửi khoá / số / cờ (không gửi tên, số điện thoại, tên việc tự gõ). Tên event theo `docs/analytics-plan.md`.
- Gặp chỗ không chắc (thiếu file, Figma mâu thuẫn tài liệu, cần sửa file ngoài phạm vi) thì **dừng lại hỏi**, không đoán.
- Docs: màn đang làm thì đổi cột Trạng thái trong `docs/design-traceability.md` mục F2 từ `todo` → `doing` (bước 07 mới chốt `done` / `changed`). Lệch Figma thì thêm dòng `DT-xx` (số tiếp theo) cuối file. Thêm / đổi service, ViewModel, route thì cập nhật `docs/architecture.md` (mục 7, 8, 9).
- Không tự `git commit` / `push`. Chạy `dart format lib test`, `flutter analyze` và `flutter test` tới khi sạch rồi mới báo xong (`auth_routing_test` có thể lỗi sẵn nếu khối `redirect` đang comment – ghi lại, không sửa).
- Xong việc: điền mục **"Kết quả chạy"** ở cuối chính file này (thay các dòng trống), rồi in tóm tắt cho người dùng.

## Đọc trước

`CLAUDE.md` (mục "Luật bị chấm", "Checklist trước khi mở PR"), `../An-Nhien_Chia-task_Lab3.md` mục F2 ("Xong khi"), `docs/design-traceability.md` mục F2, `docs/architecture.md` mục 7–9, 15, `docs/analytics-plan.md`, `rule.md` (11 nhóm luật), `docs/prompt/F2/0*.md` (mục "Kết quả chạy" các bước trước), `docs/prompt/F0/PR-F0.md` (mẫu PR).

## Việc cần làm

1. **Test cả luồng**: tạo `test/onboarding_flow_test.dart` – `ProviderScope` override toàn bộ service bằng Fake, mở `/welcome`, bấm đi hết S01 → S02 (nhập tên, đổi giờ) → S13 (cho phép) → N01 (đã nhận) → N04 → N05 → N18 → thấy `/today`. Thêm nhánh: tên trống → lỗi; từ chối quyền → S13d → N04; thử lời nhắc chưa nhận → N03. Kiểm tra event `tutorial_complete` được log 1 lần.
2. **Quét luật bị chấm** trong `lib/screens/onboarding/` và 3 ViewModel F2: không `FirebaseXxx.instance` / `http` trong widget; không logic trong `build()`; màn tải dữ liệu có đủ Loading / Empty / Error + Thử lại / Data; không `Color(0x…)`, `Colors.*`, `fontSize:`, `EdgeInsets` số cứng, `Icons.*` ngoài `AppIcons` (thiếu icon thì liệt kê để báo Sanh); không widget tự chế lặp lại widget F0. Sửa chỗ sai trong phạm vi F2.
3. **Kiểm tra giao diện**: test tràn chữ cho mọi màn / state F2 ở 360×800 và 412×915, `textScaler` 1.0 / 1.3 / 2.0, có tương phản cao.
4. **Tự chấm `rule.md`** (11 nhóm): bảng nhóm luật | đạt / chưa | chỗ chưa đạt, cho phạm vi F2.
5. **Docs**:
   - `docs/design-traceability.md` mục F2: từng dòng → `done` (khớp Figma) hoặc `changed` + dòng `DT-xx` cuối file. N19 ghi theo thực tế (chờ Khang nếu chưa xong).
   - `docs/architecture.md`: mục 7.2 (5 route F2 không còn "placeholder"), mục 8 (3 service), mục 9 (cột "Có sẵn" của 3 ViewModel).
   - `docs/analytics-plan.md` mục Bằng chứng: chỉ ghi cách lấy bằng chứng (DebugView), **không** sửa phần khác (file của Hiếu).
6. **Soạn `docs/prompt/F2/PR-F2.md`** (tiếng Việt, theo mẫu `PR-F0.md`): làm gì, màn + route, service / ViewModel mới, event analytics, lệch Figma (DT-xx), sửa ngoài phạm vi (nếu có, đã hỏi), việc nhờ Hiếu / Khang / Sanh, ảnh cần chụp (mỗi màn ở 360 dp × 1.3; S13d; N03; lỗi tên), checklist "trước khi mở PR" trong `CLAUDE.md` đã tick.
7. Chạy `dart format lib test`, `flutter analyze`, `flutter test`.

Được sửa: `lib/screens/onboarding/`, 3 ViewModel F2, `test/`, `docs/design-traceability.md`, `docs/architecture.md`, `docs/analytics-plan.md` (mục Bằng chứng), `docs/prompt/F2/`.

## Đầu ra mong đợi

- Test cả luồng qua; analyze sạch; docs khớp code; `PR-F2.md` sẵn sàng.
- In cho người dùng: bảng đối chiếu "Xong khi" (đạt / chưa), bảng tự chấm `rule.md`, danh sách việc nhờ người khác, danh sách ảnh cần chụp.

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy:
- File đã tạo / sửa:
- Lệch Figma (nếu có, lý do):
- `flutter analyze` / `flutter test`:
- Việc người dùng cần làm tay:
- Commit gợi ý:
