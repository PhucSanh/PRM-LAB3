# Bước 05 · F0 · Widget nội dung: việc, thói quen, đọc to, thẻ gợi ý

Bạn là AI agent làm bước 05 của feature **F0 – Nền tảng** cho app An Nhiên. Bước 01–04 đã xong. Đọc hết file này rồi thực hiện.

## Mục tiêu

Các thẻ / hàng hiển thị dữ liệu dùng ở Hôm nay, lịch, thói quen, và thẻ gợi ý G12 (F12 đặt lên S03 mà không sửa code F3 của Khang).

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

`CLAUDE.md`, `docs/architecture.md` mục 9, 10 (9 khoá thói quen), 13, `lib/theme/*.dart`, `lib/widgets/*.dart`, `lib/models/task_item.dart` và `lib/models/habit.dart` (chỉ đọc), `lib/screens/today/today_screen.dart` (chỉ đọc), `../../prm393-lab2-an-nhien/flutter-handoff.md` mục S03, S04, S05, S08, S16, G01–G12, "Bảng 2", `assets/stitch/vocabulary.md` (tên 9 thói quen), `AppStyleGuide.md`.

## Figma

| Widget | Khung | Node |
| --- | --- | --- |
| `TaskRow`, `NextTaskCard` | S03 · S03 xem từng việc · S03b · S03-skip · S03-later | `1:270` · `1:487` · `12:2` · `10:193` · `8:189` |
| `HabitBadge`, `HabitTile` | S04 · S05 · S08 · S16 | `1:580` · `1:688` · `1:1590` · `1:1934` |
| `ReadAloudButton` | S04 · S14 · S16 | `1:580` · `1:635` · `1:1934` |
| `SuggestionCard` | G12 Hôm nay · thẻ gợi ý của Mai | `71:209` |

## Việc cần làm

1. Widget **không** import `services/` hay `viewmodels/`, không đọc provider; chỉ nhận giá trị thuần hoặc model trong `lib/models/` + callback.
2. `TaskRow({time, title, habitKey, status: upcoming|done|skipped|postponed, note, onTap})`: trạng thái phân biệt bằng icon + chữ (không chỉ màu), cả hàng ≥ 72 dp, Semantics đọc kiểu "6 giờ sáng, Đi bộ, đã xong".
3. `NextTaskCard({time, title, habitKey, onDone, onLater, onSkip, onTap})`: nút "Đã xong" là `AppButton` primary.
4. `HabitBadge({habitKey, size})`, `HabitTile({habitKey, name, description, selected, onTap})`: màu theo `HabitPalette`, icon theo `AppIcons`, tên mặc định theo `vocabulary.md` cho 9 khoá `move`, `purpose`, `downshift`, `eighty`, `plant`, `tea`, `belong`, `family`, `tribe`.
5. `ReadAloudButton({onPressed, speaking = false})`: "Đọc to" / "Đang đọc…" kèm icon loa, ≥ 72 dp. Chưa gọi TTS.
6. `SuggestionCard({fromName, itemCount, previewTitles, onOpen, onDismiss})` đúng G12. **Không** sửa `lib/screens/today/`; ghi trong comment của widget cách Khang đặt nó lên đầu S03.
7. Test widget trong `test/widgets/`: mỗi trạng thái `TaskRow` đúng nhãn, bấm nút gọi đúng callback, `HabitBadge` đủ 9 khoá không lỗi; 360 dp + `textScaler` 1.3 / 2.0 không tràn.

Chỉ sửa `lib/widgets/` và `test/widgets/`.

## Đầu ra mong đợi

- `TaskRow`, `NextTaskCard`, `HabitBadge`, `HabitTile`, `ReadAloudButton`, `SuggestionCard`, test qua, `flutter analyze` sạch.
- In cho người dùng bảng: widget | API | khung Figma | lệch Figma (nếu có, lý do).

## Kết quả chạy (agent tự điền khi xong)

- Ngày chạy:
- File đã tạo / sửa:
- Lệch Figma (nếu có, lý do):
- `flutter analyze` / `flutter test`:
- Việc người dùng cần làm tay:
- Commit gợi ý:
