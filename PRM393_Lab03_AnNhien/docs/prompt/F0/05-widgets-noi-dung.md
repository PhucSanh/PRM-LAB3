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

- Ngày chạy: 02/11/2026
- File đã tạo / sửa:
  - Tạo: `lib/widgets/task_widgets.dart` (`TaskRow`, `NextTaskCard`, `TaskStatusChip`, `TaskStatus.label`), `lib/widgets/habit_widgets.dart` (`HabitBadge`, `HabitTile`, `HabitAccentCard`, `HabitStyle`), `lib/widgets/read_aloud_button.dart` (`ReadAloudButton`), `lib/widgets/suggestion_card.dart` (`SuggestionCard`, comment hướng dẫn Khang đặt lên S03); `test/widgets/task_widgets_test.dart`, `habit_widgets_test.dart`, `read_aloud_suggestion_test.dart`.
  - Sửa: `lib/widgets/time_field.dart` (`formatTimeOfDay(…, wholeHourInWords)` cho "3 giờ chiều", thêm `speakTimeOfDay` cho TalkBack) + test trong `time_field_test.dart`.
  - **Ngoài phạm vi, người dùng đã đồng ý:** `lib/theme/app_icons.dart` thêm 7 icon thói quen (`habitPurpose` … `habitTribe`; `move` dùng `walk`, `family` dùng `home`) và 8 icon thẻ việc (`statusSkipped`, `statusPostponed`, `later`, `skipToday`, `stopReading`, `suggestion`, `view`, `chevronRight`) theo Từ điển icon DESIGN.md.
  - Docs: `docs/architecture.md` mục 12 (dòng `app_icons.dart`, ngoại lệ màu cảnh báo) + mục 13 (4 dòng "cần làm" → "có", tách `NextTaskCard`); `docs/design-traceability.md` DT-16 → DT-20. Không đổi trạng thái F0.
- Lệch Figma (nếu có, lý do):
  - DT-16: `NextTaskCard` theo khung mới (S03b / G12), "Đã xong" nằm trong thẻ (Figma đặt ở thanh đáy) + thêm "Hôm nay bỏ qua" – theo API prompt.
  - DT-17: `TaskRow` chip "Chưa làm" (S03 cũ ghi "Đang chờ"), icon "Đã dời" = `redo-2`, nền thẻ trắng, giờ chẵn "3 giờ chiều".
  - DT-18: `HabitTile` S05 chữ "Đã chọn / Chọn" dưới tên (Figma dưới dấu chọn) để không tràn ở cỡ 2.0; Figma S05 dùng ✓ cho đang chọn còn Từ điển icon ghi `circle-dot` → cần nhóm chốt.
  - DT-19: `ReadAloudButton` "Đang đọc…" + nút "Dừng đọc" full-width (S14 nút nhỏ).
  - DT-20: `SuggestionCard` thêm tên việc gợi ý + "Bỏ qua gợi ý" tuỳ chọn (G12 Figma không có).
- `flutter analyze` / `flutter test`: analyze sạch. `test/widgets/` 103/103 qua (mỗi trạng thái `TaskRow` đúng chữ + icon + câu TalkBack, nút `NextTaskCard` / `SuggestionCard` / `ReadAloudButton` gọi đúng callback, `HabitBadge` đủ 9 khoá đúng màu + icon + nhãn, 360 / 412 dp × 1.3 / 2.0 không tràn). Toàn bộ 170: 169 qua, `auth_routing_test` lỗi có sẵn từ trước (khối `redirect` đang tắt). Widget không import `services/`, `viewmodels/`, không đọc provider.
- Việc người dùng cần làm tay:
  - Chốt với nhóm icon "Đang chọn": ✓ tròn đặc (Figma S05, đang dùng `AppIcons.radioOn`) hay `circle-dot` (Từ điển icon) (DT-18).
  - Cân nhắc gán màu cảnh báo vào `tertiary` / `tertiaryContainer` của 2 `ColorScheme` để `TaskStatusChip` thôi đọc `AppColors` trực tiếp (architecture.md mục 12).
  - Báo Khang: thay `_TaskTile` trong `today_screen.dart` bằng `TaskRow` / `NextTaskCard` (TODO sẵn trong file của Khang); đặt `SuggestionCard` theo comment trong `suggestion_card.dart` khi F12 có `SuggestionInboxViewModel`.
  - Sửa Figma theo DT-16 → DT-20.
- Commit gợi ý: `feat(F0): widget nội dung – TaskRow, NextTaskCard, HabitBadge/HabitTile, ReadAloudButton, SuggestionCard`
