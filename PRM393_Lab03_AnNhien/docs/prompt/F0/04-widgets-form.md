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

- Ngày chạy: 02/11/2026
- File đã tạo / sửa:
  - Tạo: `lib/widgets/app_text_field.dart` (`AppTextField`), `lib/widgets/time_field.dart` (`TimeField`, `showTimeWheel`, `TimeGridDialog`, `formatTimeOfDay`), `lib/widgets/switch_row.dart` (`SwitchRow`), `lib/widgets/choice_group.dart` (`ChoiceGroup<T>`, `ChoiceOption<T>`, `ChoiceLayout`), `lib/widgets/form_parts.dart` (`FieldLabel`, `FieldMessage.error` / `.hint`, `exampleHint`); `test/widgets/app_text_field_test.dart`, `time_field_test.dart`, `switch_row_test.dart`, `choice_group_test.dart`.
  - Sửa: `docs/architecture.md` mục 13 (4 dòng "cần làm" → "có", thêm dòng `FieldLabel` / `FieldMessage`; `ChoiceCard` đổi tên thành `ChoiceGroup`); `docs/design-traceability.md` (DT-12 → DT-15). Không đổi trạng thái F0.
- Lệch Figma (nếu có, lý do):
  - **Lệch prompt (người dùng đã chốt theo Figma):** hộp chọn giờ là lưới nút chạm như Figma DLG-TaskTime / DLG-WakeTime (giờ 1–12, Sáng / Chiều, phút 00 / 15 / 30 / 45, "Lưu giờ" + "Hủy"), không phải 3 cột `ListWheelScrollView` phút bước 5 + "Xong". Giữ tên `showTimeWheel()` để khớp API.
  - DT-12: ô giờ cao 72 (Figma 48); Sáng / Chiều lên ngay dưới giờ, phút xuống cuối; "Bác chọn: …" + 2 nút ghim đáy, lưới cuộn; "Hủy" có icon ✕; giữ ô phút lẻ đã lưu.
  - DT-13: ô nhập / ô giờ cao ≥ 72 (Figma 60); "6:00 sáng" thay "6 : 00 sáng"; ô giờ luôn có "Đổi giờ ⌄".
  - DT-14: `SwitchRow` thêm "Đang bật / Đang tắt" dưới câu phụ (N07 đặt dưới công tắc, S10 không có); công tắc kích thước Material.
  - DT-15: `ChoiceGroup` một kiểu cho mọi khung: dấu tích bên trái + "Đang chọn" bên phải, ô ≥ 72 cách nhau 20 (prompt ghi ≥ 52, dùng 72 vì không có token 52 và rule.md R-TAP-01).
- `flutter analyze` / `flutter test`: analyze sạch. 33 test mới qua (lỗi nhập + liveRegion, chọn giờ trả đúng `TimeOfDay` kể cả 12 giờ sáng / chiều và Hủy / chạm ngoài, bấm cả hàng `SwitchRow`, `ChoiceGroup` đổi lựa chọn + Semantics radio + chữ mẫu S01 đúng cỡ; 360 / 412 dp × 1.3 / 2.0 không tràn, "Bác chọn" + 2 nút luôn thấy). Toàn bộ 140 qua, trừ `auth_routing_test` lỗi có sẵn từ trước (khối `redirect` đang tắt, như bước 03).
- Việc người dùng cần làm tay: thêm vào `lib/theme/app_icons.dart` (bước này không được sửa `lib/theme/`) rồi bỏ các `TODO(F0)`: `AppIcons.info` (`Icons.info_outline`, `form_parts.dart`), `chevronDown` (`Icons.keyboard_arrow_down`, `time_field.dart`), `save` (`Icons.save_outlined`, `time_field.dart`), `radioOn` / `radioOff` (`Icons.check_circle` / `Icons.radio_button_unchecked`, `choice_group.dart`). Cân nhắc thêm token `AppSizes.choiceTile` nếu nhóm muốn ô lựa chọn 52 như prompt. Sửa Figma theo DT-12 → DT-15 (cột "Đã sửa Figma?").
- Commit gợi ý: `feat(F0): widget form – AppTextField, TimeField + hộp chọn giờ dạng lưới, SwitchRow, ChoiceGroup`
