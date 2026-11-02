# feat(F0): Nền tảng – theme, widget dùng chung, điều hướng

Nhánh `feat/F0-nen-tang` → `main`. Người làm: Sanh (AI agent hỗ trợ theo `docs/prompt/F0/01…06`).

**F0 phải merge trước khi mọi người code màn** (CLAUDE.md › Git). Sau khi merge: màn của mọi người **chỉ** dùng widget trong `lib/widgets/`, màu / cỡ chữ / khoảng cách lấy từ `lib/theme/`.

## Làm gì

1. **Route** (bước 01): khai báo đủ route theo `architecture.md` mục 7.2, màn chưa làm là `FeaturePlaceholder` (mã màn · feature · người). Khối `redirect` (chưa đăng nhập → `/sign-in`) **vẫn đang tạm comment** để test UI không cần đăng nhập Google – **phải bỏ comment trước khi nộp**.
2. **Theme** (bước 02): token Lab 2 → `AppColors`, `AppColorsHighContrast`, `HabitPalette`, `AppSpacing`, `AppRadius`, `AppSizes`, `AppTheme.light()` / `highContrast()`, `AppText`, `AppIcons`; cỡ chữ (`fontScaleProvider` 1.0 / 1.15 / 1.3, trần 2.0) và tương phản cao (`highContrastProvider`).
3. **Widget dùng chung** (bước 03–05): nút, thanh, hộp thoại, snackbar Hoàn tác, state views, form, thẻ việc / thói quen, đọc to, thẻ gợi ý G12 (bảng dưới).
4. **Trang xem thử** (bước 06): `/dev/widgets` (chỉ bản debug) + test tràn chữ cho cả trang.

## Widget mới / đổi

| Widget | API chính | Dùng ở |
| --- | --- | --- |
| `AppButton` | `label, icon, onPressed, kind: primary / secondary / tonal / text / danger / dangerOutline, busy` | mọi màn |
| `AppBackBar` + `AppBarEditButton` | `backLabel, step, trailing, onBack` | màn cấp 2–3 |
| `AppShell` | bottom nav 4 tab có nhãn | 4 tab |
| `showConfirmDialog<T>` + `ConfirmOption`, `ConfirmDetail` | `icon, title, message, details, options, danger` → `T?` | DLG-Done / Later / Skip / Delete, N13, N14 |
| `showUndoSnackbar` | `title, subtitle, onUndo` – không tự tắt | S03-*, G09, C12 |
| `LoadingView` / `EmptyView` / `ErrorView`, `IconCircle` | ST-Loading / Empty / Error (Error luôn có "Thử lại") | mọi màn tải dữ liệu |
| `AppTextField` + `FieldLabel`, `FieldMessage` | `label, hint ("Ví dụ: …" tự thêm), controller, errorText, keyboardType, maxLength, onChanged, icon` | S02, S06, S12, C06 |
| `TimeField` + `showTimeWheel()` + `formatTimeOfDay()` / `speakTimeOfDay()` | `label, value: TimeOfDay?, onChanged`; hộp chọn giờ dạng lưới chạm (DT-12) | S02, S06, S15, N05, C06 |
| `SwitchRow` | `title, subtitle, value, onChanged, icon` – cả hàng bấm được, "Đang bật / Đang tắt" | S10, S12, N07, C08 |
| `ChoiceGroup<T>` + `ChoiceOption<T>` | `options, value, onChanged, layout: list / segmented`; `previewScale` cho S01 | S01, S02, S06, S10, S12, N12, C07 |
| `TaskRow` + `TaskStatusChip` | `time: TimeOfDay, title, habitKey, status: TaskStatus, note, onTap, showChevron` | S03, S11, S16, C03 |
| `NextTaskCard` | `time, title, habitKey, onDone, onLater, onSkip, onTap, durationMinutes` | S03 |
| `HabitBadge`, `HabitTile`, `HabitAccentCard`, `HabitStyle` | `habitKey`, tên mặc định theo vocabulary.md (tên thật nạp từ `habits/{key}`) | S04, S05, S08, S16, C06 |
| `ReadAloudButton` | `onPressed, speaking` – không tự gọi TTS | S04, S14, S16 |
| `SuggestionCard` | `fromName, itemCount, previewTitles, onOpen, onDismiss` – comment trong file hướng dẫn Khang đặt lên S03 | S03 (G12) |
| `WidgetGallery` (dev) | `animate` | `/dev/widgets` |

API đầy đủ: `docs/architecture.md` mục 12, 13.

## Route mới

| Route | Ghi chú |
| --- | --- |
| `/dev/widgets` | `WidgetGallery`, chỉ khai báo khi `kDebugMode` |

## Sửa ngoài phần của F0 (đã hỏi trước)

- `lib/screens/sign_in/sign_in_screen.dart` (Hiếu): bọc nội dung trong `SingleChildScrollView` + `IntrinsicHeight`, logo `size: 96` → `AppSizes.logo`. Lý do: khi bật `redirect` thì màn này hiện lúc mở app và tràn 213 dp ở 360 dp × chữ 2.0 (`text_scale_overflow_test` fail). Bố cục khi đủ chỗ không đổi. **Nhờ Hiếu duyệt.**

## Lệch Figma

DT-09 → DT-21 cuối `docs/design-traceability.md` (icon Material thay Lucide, snackbar 2 tầng, hộp chọn giờ dạng lưới, vùng chạm 72 thay 48 / 60, `NextTaskCard` có nút "Đã xong" trong thẻ, …). 2 dòng F0 trong bảng traceability chuyển sang `changed`. Các ô "Đã sửa Figma?" còn ☐: cần sửa Figma.

## Tự chấm `rule.md` (11 nhóm luật) – phạm vi widget F0

| Nhóm luật | Kết quả | Chỗ chưa đạt / ghi chú |
| --- | --- | --- |
| 1. Đọc được ngay (R-TXT-01/02, R-CON-01/02, R-LAY-01) | Đạt | 15 kiểu chữ của theme ≥ 20 sp. Tương phản đo được: chữ phụ 6.6 : 1, "Đã xong" 6.7 : 1, "Chưa làm" 5.9 : 1, lỗi 5.8 : 1, viền ô nhập 3.7 : 1, icon trắng trên 9 màu thói quen 3.2–3.3 : 1. Không tràn ở 360 / 412 dp × 1.0 / 1.3 / 2.0 (`gallery_overflow_test`). Ngoại lệ: số trong ô chọn giờ và "Bước x/y" / "Sửa" được thu nhỏ khi chữ ×2.0 thiếu chỗ (có thể < 20 sp) |
| 2. Ít chữ, nhiều icon (R-TXT-03/04/05, R-ICON-02/03) | Đạt một phần | Nút luôn có icon + chữ ≤ 5 tiếng; thẻ việc đúng 4 thành phần + 1 dòng phụ. **Chưa:** icon "Đang chọn" là ✓ tròn đặc (Figma S05) trong khi Từ điển icon ghi `circle-dot` (DT-18) |
| 3. Màu sắc (R-COL-01…04) | Đạt | Trạng thái luôn icon + chữ; thẻ việc / thói quen có ô màu nhấn + vạch trái theo `HabitPalette` |
| 4. Chạm trúng (R-TAP-01/02/03) | Đạt một phần | Nút, ô nhập, hàng, thẻ cao ≥ 72; khoảng cách 20 (`betweenTargets`). **Chưa:** ô giờ trong hộp chọn giờ rộng 62 dp, cách nhau 8 dp (theo lưới 4 cột Figma, DT-12); nút "Sửa" có thể < 72 dp khi chữ ×2.0 (DT-21) |
| 5. Không phải đoán (R-ICON-01, R-NAV-01/02, R-GES-01/02) | Đạt | Không nút chỉ-icon; bottom nav 4 tab có nhãn; Back luôn có chữ; chọn giờ bằng chạm, không bắt vuốt |
| 6. Biết làm hay chưa (R-STA-01/02) | Đạt một phần | Có ✓ Đã xong · ○ Chưa làm · ⊖ Bỏ qua · ↷ Đã dời. **Chưa:** nhãn "🔔 Đến giờ" (chưa có trong `TaskStatus` của model – Hiếu / Khang) |
| 7. Một việc mỗi màn (R-ONE-01/02, R-CEN-01) | Đạt (mức widget) | Mỗi widget tối đa 1 nút filled. Lưu ý cho màn S03: `NextTaskCard` đã có nút "Đã xong" filled, màn không thêm nút filled khác |
| 8. Không sợ sai (R-SAFE-01/02) | Đạt | `showConfirmDialog`, `showUndoSnackbar` (không tự tắt), lỗi nhập có icon + câu + ví dụ |
| 9. Giọng đọc (R-VOI-01/02/03) | Đạt (mức widget) | Có `ReadAloudButton`; nút "Nói…" và xác nhận 2 kênh là việc của màn F4 / F5 |
| 10. Lời lẽ (R-LANG-01/02/03, R-VOC-01) | Đạt | Chữ trên widget và trang thử đều tiếng Việt, nút là động từ + việc ("Đúng, đã xong", "Lưu giờ") |
| 11. Phong cách (R-STY-01/02/03) | Đạt | Màu, font Be Vietnam Pro, bo thẻ 16 / nút 14, lề 20 lấy từ `lib/theme/` |

## Chỗ viết cứng / tự chế ở màn của người khác (chỉ liệt kê, không sửa)

`lib/widgets/` không còn `Color(0x…)`, `Colors.*`, `fontSize:`, `EdgeInsets` số cứng. Ngoại lệ đã ghi: `TaskStatusChip` đọc `AppColors.warning*` (ColorScheme chưa có màu cảnh báo); `undo_snackbar.dart:88` còn `Icons.undo` (TODO thêm `AppIcons.undo`).

**Khang – `lib/screens/today/today_screen.dart`:**

- `:65–106` `_TaskTile` tự chế (Card + vạch màu + chip) → thay bằng `TaskRow` / `NextTaskCard`.
- `:73` giờ ghép tay `'${task.hour}:…'` → `formatTimeOfDay(…, wholeHourInWords: true)`.
- `:90` `Icons.spa` cho mọi thói quen → `HabitBadge(habitKey: …)`.
- `:98` `Icons.check_circle` / `radio_button_unchecked` tự vẽ trạng thái → `TaskStatusChip`.
- `:50` `TextButton.icon` "Cài đặt" tự chế, `Icons.settings_outlined` → dùng `AppButton(kind: text)` hoặc báo Sanh nếu cần nút trên header.
- `:27`, `:29`, `:58` `Icons.event_available_outlined`, `Icons.add` chưa có trong `AppIcons` → báo Sanh thêm `AppIcons.plus`, …
- Thẻ G12: đặt `SuggestionCard` theo comment trong `lib/widgets/suggestion_card.dart`.

**Hiếu – `lib/screens/sign_in/sign_in_screen.dart`:** `:28` `Icons.spa_outlined`, `:42` `Icons.login` chưa có trong `AppIcons`.

## Ảnh cần chụp (dán vào PR)

1. `/dev/widgets` ở 360 dp, cỡ chữ "Rất lớn ×1.3": nhóm Nút, Form, Nội dung (3 ảnh cuộn).
2. Cùng trang, bật "Tương phản cao".
3. Hộp chọn giờ (nút "Mở hộp chọn giờ") và snackbar "Hoàn tác".
4. `/sign-in` ở cỡ chữ hệ thống lớn nhất (cho Hiếu xem phần cuộn).

Cách mở: app chưa có nút dẫn tới `/dev/widgets`. Chạy `flutter run -d emulator-5554` (debug) rồi tạm thêm một lệnh `context.push('/dev/widgets')` ở chỗ tiện (vd. nút trong màn đang làm) – **không commit** lệnh tạm đó.

## Checklist trước khi mở PR (CLAUDE.md)

- [ ] `flutter analyze` sạch; `flutter test` 178 / 179 – `auth_routing_test` fail vì khối `redirect` đang comment. Bỏ comment trước khi nộp thì 179 / 179 qua.
- [x] Màn vẽ đủ Loading / Empty / Error + Thử lại / Data – F0 cung cấp `LoadingView` / `EmptyView` / `ErrorView`; trang thử hiện đủ 3.
- [x] Không màu / cỡ chữ / spacing cứng trong `lib/widgets/` (ngoại lệ `AppColors.warning*` có ghi); chỉ dùng widget trong `lib/widgets/`.
- [x] Đúng ở 360 và 412 dp, `textScaler` 1.3 (và 2.0) không tràn – `gallery_overflow_test`, `text_scale_overflow_test`.
- [x] Test: F0 không có ViewModel mới; có test widget cho từng widget (`test/widgets/`, cả nhánh lỗi / rỗng của form và state views).
- [ ] Event analytics theo `docs/analytics-plan.md` – không áp dụng cho F0 (widget không ghi event; ViewModel của từng màn ghi).
- [x] Cập nhật `docs/design-traceability.md` (F0 → `changed`, DT-09 → DT-21) và `docs/architecture.md` (mục 7, 12, 13).
- [x] Đối chiếu "Xong khi" của F0: widget dùng chung đủ; không màu / cỡ chữ cứng trong `lib/widgets/`; `flutter analyze` sạch. Màn của người khác còn chỗ tự chế (danh sách trên) – báo từng người.
- [ ] Sửa Figma theo các dòng DT còn ☐.
