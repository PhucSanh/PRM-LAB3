# Bước 04 · F0 · Widget nhập liệu: ô nhập, chọn giờ, công tắc, lựa chọn

Bạn là AI agent làm bước 04 của feature **F0 – Nền tảng** cho app An Nhiên. Bước 01–03 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Bộ widget form dùng ở onboarding, thêm việc, người thân, cài đặt, con cháu lập lịch.

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

`CLAUDE.md`, `docs/architecture.md` mục 13, `lib/theme/*.dart`, `lib/widgets/*.dart`, `../../prm393-lab2-an-nhien/flutter-handoff.md` mục S01, S02, S06, S10, S12, "States & Dialog dùng chung", "Bảng 2", `assets/stitch/AppStyleGuide.md` (câu báo lỗi có ví dụ), `rule.md`, `accessibility.md`.

## Figma

| Widget | Khung | Node |
| --- | --- | --- |
| `AppTextField` | S02 · S02 Nhập lại tên · S06e · S12e · ST-Validation | `1:103` · `1:176` · `12:193` · `14:196` · `29:2` |
| `TimeField` + `showTimeWheel()` | DLG-TaskTime · DLG-WakeTime · S06 | `29:256` · `31:2` · `1:890` |
| `SwitchRow` | S10 (2 khung) · N07 | `1:2325` · `1:2474` · `41:2` |
| `ChoiceGroup` | S01 chọn cỡ chữ · N12 Lặp lại · C07 Lặp lại | `1:2` · `43:95` · `1:2764` |

## Việc cần làm

1. `AppTextField({label, hint, controller, errorText, keyboardType, maxLength, onChanged})`: nhãn đặt **trên** ô (không floating label), `hint` tự thêm tiền tố "Ví dụ: ", `errorText` có icon cảnh báo + màu error, `Semantics(liveRegion: true)` khi lỗi, cao ≥ `AppSizes.minTarget`.
2. `TimeField({label, value, onChanged})` hiển thị kiểu "6:00 sáng"; bấm mở `Future<TimeOfDay?> showTimeWheel(context, {initial, title})`: 3 cột `ListWheelScrollView` (giờ 1–12, phút bước 5, sáng / chiều), nút Hủy + Xong ≥ 72 dp. Chữ "sáng / chiều / tối" theo `AppStyleGuide.md`.
3. `SwitchRow({title, subtitle, value, onChanged})`: cả hàng bấm được, `Semantics(toggled: …)`, ≥ 72 dp.
4. `ChoiceGroup<T>({options: List<ChoiceOption<T>>, value, onChanged, layout: list | segmented})`: mỗi lựa chọn có nhãn + mô tả + icon tuỳ chọn, đang chọn có dấu tích (không chỉ dựa vào màu), ≥ 52 dp, Semantics radio. Dùng cho S01: mỗi lựa chọn hiện chữ mẫu đúng cỡ.
5. Test widget trong `test/widgets/`: nhập lỗi hiện `errorText`, chọn giờ trả đúng `TimeOfDay`, bấm cả hàng `SwitchRow` đổi giá trị, `ChoiceGroup` đổi lựa chọn; 360 dp + `textScaler` 1.3 / 2.0 không tràn.

Chỉ sửa `lib/widgets/` và `test/widgets/`.

## Đầu ra mong đợi

- 4 nhóm widget trên, đúng Figma, test qua, `flutter analyze` sạch.
- In cho người dùng bảng: widget | API | khung Figma | lệch Figma (nếu có, lý do).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy:
- File đã tạo / sửa:
- Lệch Figma (nếu có, lý do):
- `flutter analyze` / `flutter test`:
- Việc người dùng cần làm tay:
- Commit gợi ý:
