# feat(F8): Cài đặt hiển thị & hồ sơ – cỡ chữ toàn app, tương phản cao, sửa hồ sơ, cách dùng, dữ liệu, đăng xuất

Nhánh `feat/F8-setting` → `main`. Người làm: Sanh (AI agent hỗ trợ theo `docs/prompt/F8/01…05`).

Từ Hôm nay bấm "Cài đặt" → S10. Bác đổi cỡ chữ (cả app đổi ngay khi chạm), bật chữ và nền rõ hơn, đọc to, rung. Từ S10 Bác sửa thông tin của mình (N06), xem cách dùng (N08), xem dữ liệu nằm ở đâu (N20) và đăng xuất. Mọi thay đổi có Hoàn tác; đăng xuất và bỏ thay đổi chưa lưu đều hỏi lại. Cài đặt đã lưu được áp cho toàn app **ngay khi mở lại app**, không cần qua S01.

## Làm gì

1. **ViewModel + nạp cài đặt khi mở app** (bước 01): `SettingsViewModel`, `ProfileViewModel`, `displaySettingsSyncProvider`. Trước đó mở lại app thì cỡ chữ / tương phản cao đã lưu **không** được áp (chỉ S01 đọc cỡ chữ, tương phản cao không ai nạp).
2. **S10** (bước 02): chọn cỡ chữ Vừa / Lớn / Rất lớn + câu xem thử, 3 công tắc, "Xem thử lời nhắc", 4 hàng điều hướng, nút Đăng xuất (đề bắt buộc).
3. **N06** (bước 03): sửa tên (lỗi có icon + "Ví dụ: Lan"), cách gọi Ông / Bà, giờ thức dậy; "Lưu thông tin" có Hoàn tác; rời màn khi chưa lưu thì hỏi lại. Cuối màn giữ lối vào khu demo Firebase của Hiếu (F10).
4. **N08 + N20** (bước 04): hai màn tĩnh. Câu chữ N20 **đổi cho đúng Lab 3** (lịch lưu trên tài khoản Google, không phải "chỉ ở điện thoại này").
5. **Kiểm tra** (bước 05): test cả luồng trên `AnNhienApp` thật, test tràn chữ mọi state, quét luật bị chấm, tự chấm `rule.md`, chốt docs.

## Màn + route

| Route | Màn / state | Màn hình | ViewModel |
| --- | --- | --- | --- |
| `/settings` | S10 (`1:2325` + `1:2474` cuộn xuống), hộp hỏi đăng xuất | `SettingsScreen` | `SettingsViewModel` (+ `SignOutViewModel` của F1) |
| `/settings/profile` | N06, lỗi tên, hộp hỏi bỏ thay đổi, lỗi lưu; cuối màn lối vào F10 | `ProfileScreen` | `ProfileViewModel` |
| `/settings/help` | N08 | `HelpScreen` | — (tĩnh) |
| `/settings/data` | N20 | `DataScreen` | — (tĩnh) |

Trong `app_router.dart` chỉ thay 4 dòng F8 + import. `/settings/firebase-demo` (F10) và `/settings/reminders` (N07 – Khang) giữ nguyên.

Đường vào S10: đã có sẵn nút "Cài đặt" trên S03 (`today_screen.dart`, Khang) → `context.push('/settings')`.

## ViewModel / service / widget mới

| Loại | Tên | Ghi chú |
| --- | --- | --- |
| ViewModel | `SettingsViewModel` | `UiState<AppSettings>`; `setFontScale` / `setHighContrast` / `setReadAloud` / `setVibrate` → `SettingChange` (để View hiện Hoàn tác), `undo`, `retry`. Đổi cỡ chữ / tương phản: áp ngay trên máy rồi mới lưu; lưu lỗi thì giữ giá trị, ghi Crashlytics non-fatal, báo nhẹ trong Snackbar |
| ViewModel | `ProfileViewModel` | `UiState<ProfileForm>`; `load` / `retry`, `changeName` / `changeHonorific` / `changeWakeTime` (tự tính `dirty`), `save` → `ProfileSaved`, `undo`, `discard`. Kiểm tra tên chép **logic** S02 (không import ViewModel của Hương) |
| Provider | `displaySettingsSyncProvider` (`lib/viewmodels/display_settings_sync.dart`) | Lắng `SettingsService.watch()` → `fontScaleProvider`, `highContrastProvider`. Bật bằng 1 dòng `ref.watch` trong `AnNhienApp.build()` |
| Service (thêm hàm) | `ProfileSetupService.watchSetup(uid)` → `Stream<ProfileSetup?>` | Interface + Fake (Fake có `seed:`). Bản Firebase: nhờ Hiếu |
| Widget F0 | `SectionCard`, `NavRow` (`lib/widgets/`) | Khung thẻ có icon + tiêu đề; hàng điều hướng dạng thẻ. Commit F0 riêng |
| Icon F0 | `AppIcons.settings`, `textSize`, `contrast`, `vibrate`, `bellRing`, `bookOpen`, `smartphone`, `logout`, `smile`, `sunrise` | Commit F0 riêng |

## Event analytics (`docs/analytics-plan.md`)

| Event | Khi nào | Tham số |
| --- | --- | --- |
| `change_font_size` | S10 đổi cỡ chữ (cả khi bấm Hoàn tác – chiều ngược lại); chạm lại đúng cỡ đang dùng thì không ghi | `from`, `to` (`vua` / `lon` / `rat_lon`) |
| `logout` | S10 xác nhận Đăng xuất | — (ghi trong `SignOutViewModel` của F1, đúng 1 lần – có test) |

N06, N08, N20 không có event trong analytics-plan nên không ghi; không tự đặt event mới. Không gửi tên Bác (có test kiểm). User property `font_size`, `high_contrast` **chưa đặt được** (thiếu `setUserProperty` – xem việc nhờ Hiếu). Cách lấy bằng chứng DebugView: `docs/analytics-plan.md` › Bằng chứng › "Cách lấy bằng chứng event F8".

## Lệch Figma

DT-28 → DT-31 cuối `docs/design-traceability.md`; 5 dòng F8 chuyển `changed`. Chính:

- **DT-28 S10**: thanh trên "Quay lại" (Figma "‹ Hôm nay"), tiêu đề "Cài đặt hiển thị" đặt ở đầu nội dung; khung xem thử viền liền (Figma viền đứt); **thêm nút Đăng xuất** + hộp hỏi lại (Figma không vẽ).
- **DT-29 N06**: cách gọi chỉ Ông / Bà (Figma có thêm "Bác" – giữ khớp S02 và dữ liệu `ong` / `ba`); ô lưu ý nền xanh → `FieldMessage.hint`; "Khu thử tính năng" ở cuối phần cuộn; thêm hộp hỏi bỏ thay đổi + câu lỗi lưu.
- **DT-30 N20**: **câu chữ đổi cho đúng sự thật** (người dùng duyệt 04/11): "Lịch của Bác được lưu trên tài khoản Google của Bác." · "Mất mạng, Bác vẫn xem được lịch đã tải về máy." · "Đổi điện thoại vẫn còn lịch – Bác đăng nhập lại là thấy lịch cũ." · "Chỉ người thân Bác đã ghép nối mới xem được lịch." (thay "Lịch chỉ ở điện thoại này", DT-05).
- **DT-31 N08**: 3 bước cùng một kiểu (bỏ ô chuông cam chỉ có ở bước 2); thẻ trấn an nền trắng.

Cột "Đã sửa Figma?" của DT-28 → DT-31 còn ☐: cần sửa Figma.

## Sửa ngoài phạm vi F8 (đã hỏi trước)

- `lib/app.dart` (F0): **1 dòng** `ref.watch(displaySettingsSyncProvider)` + 1 import (người dùng đồng ý ở bước 01).
- `lib/services/profile_setup_service.dart` (F2 thêm, tạm): thêm `watchSetup` vào interface + Fake (người dùng chọn phương án (a) ở bước 01). Bản Fake dùng `Stream.multi` với `onCancel` không trả Future (xem lỗi Fake ở dưới). Test F2 (`f2_view_models_test`, `setup_profile_screen_test`, `onboarding_flow_test`) vẫn qua.
- `lib/widgets/section_card.dart`, `lib/widgets/nav_row.dart`, `lib/theme/app_icons.dart` (F0): người dùng đồng ý ở bước 02, 03.
- `test/router_test.dart`: bỏ 4 route F8 khỏi danh sách placeholder (đã là màn thật).
- `docs/analytics-plan.md` (Hiếu): chỉ thêm đoạn "Cách lấy bằng chứng event F8" trong mục Bằng chứng.
- **Không** sửa `providers.dart`, `firebase_*`, `models/`, `android/`, `firebase/`, `lib/screens/account|firebase_demo|onboarding|today/`, ViewModel của người khác. **Không xoá** `profile_demo_entry_screen.dart` (của Hiếu).

## Việc nhờ người khác

**Hiếu**

1. Thêm `setUserProperty` vào `AnalyticsService` (+ Firebase, Fake) để đặt user property `font_size`, `high_contrast` (đã để `TODO(Hiếu)` trong `settings_view_model.dart`).
2. Bản Firebase `SettingsService` (Firestore `users/{uid}` + cache máy). Hiện `settingsServiceProvider` vẫn trỏ Fake → cài đặt chỉ giữ trong bộ nhớ, **mở lại app trên máy thật chưa giữ được** (cơ chế nạp đã có và đã test bằng Fake).
3. Bản Firebase `ProfileSetupService.watchSetup` + `saveSetup` (đọc / ghi `users/{uid}`: `displayName`, `honorific` `ong` / `ba`, `wakeTime` "HH:mm"); về sau gộp vào `ProfileService` / `UserProfile`.
4. Dọn `lib/screens/firebase_demo/profile_demo_entry_screen.dart`: không còn route nào dùng (N06 đã có `FirebaseDemoEntry` ở cuối màn).
5. Sửa `FakeProfileService.watch`: `sink.onCancel = () { subscription.cancel(); };`. Hiện `onCancel` trả Future hoàn tất ở root zone nên `.first` **treo trong `testWidgets`** (F8 phải dùng lớp con `StaticProfileService` trong test). Có thể là nguyên nhân một phần các test lỗi sẵn ở `router_test` / `auth_routing_test`.
6. Bỏ comment khối `redirect`: hiện S10 tự `go('/sign-in')` sau khi đăng xuất thành công (vẫn an toàn khi bật lại redirect).
7. Nếu muốn cách gọi "Bác" như Figma N06: thêm vào `Honorific` + rules, và báo Hương (S02 sẽ tự hiện thêm lựa chọn).

**Khang**

- S14 (`/reminder/:taskId`) cần chế độ xem thử: S10 "Xem thử lời nhắc" và N08 "Thử lời nhắc" mở `/reminder/preview?preview=true` – không ghi gì, không log `reminder_action`.
- N07 (`/settings/reminders`) mở từ hàng "Lời nhắc" ở S10. Công tắc "Rung khi có lời nhắc" và "Đọc to nội dung" ở S10 lưu vào `AppSettings.vibrate` / `readAloud` – `ReminderService` / S14 nên đọc 2 cờ này.
- Đường vào S10 trên S03 đã có (nút "Cài đặt"), không cần sửa.

**Sanh (F0)**

- Commit F0 riêng: `SectionCard`, `NavRow`, 10 icon mới; thêm 2 widget vào `WidgetGallery`.
- Cân nhắc widget `InlineHint` (hộp lưu ý có nền) – N06, N08 đang thay bằng `FieldMessage.hint` / `SectionCard` (cùng S13, N01 của F2).
- Cân nhắc đưa "nội dung cuộn + thanh nút ghim đáy" vào `lib/widgets/` (N06, N08, N20 và `OnboardingLayout` của F2 đang lặp cùng một khung).

## Tự chấm `rule.md` (11 nhóm luật) – phạm vi F8

| Nhóm luật | Kết quả | Chỗ chưa đạt / ghi chú |
| --- | --- | --- |
| 1. Đọc được ngay (R-TXT-01/02, R-CON-01/02, R-LAY-01) | Đạt | Chữ lấy từ theme (≥ 20 sp), màu qua `ColorScheme`. `settings_overflow_test`: 11 state × 360×800 / 412×915 × 1.0 / 1.3 / 2.0 × thường / tương phản cao – không tràn |
| 2. Ít chữ, nhiều icon (R-TXT-03/04, R-ICON-02/03) | Đạt | Câu dài nhất 12 tiếng; nhãn nút ≤ 4 tiếng; mọi mục cài đặt, mọi nút có icon từ `AppIcons`; "thử lời nhắc" ở S10 và N08 cùng icon `bellRing` |
| 3. Màu sắc (R-COL-01…04) | Đạt | Lựa chọn có dấu tích + "Đang chọn"; công tắc có "Đang bật / Đang tắt"; không dùng màu làm tín hiệu duy nhất |
| 4. Chạm trúng (R-TAP-01/02/03) | Đạt | Ô chọn, công tắc, hàng điều hướng, nút cao ≥ 72; cách nhau 20; nút chính full-width ở đáy (N06, N08, N20) |
| 5. Không phải đoán (R-ICON-01, R-NAV-02, R-GES-01) | Đạt | Back luôn "Quay lại"; back hệ thống ở N06 khi chưa lưu cũng hỏi lại; không thao tác vuốt |
| 6. Biết làm hay chưa (R-STA-01/02) | Không áp dụng | F8 không có thẻ việc |
| 7. Một việc mỗi màn (R-ONE-01, R-CEN-01) | Đạt | Mỗi màn tối đa 1 nút filled (S10 không có; N06 "Lưu thông tin"; N08 "Mở cài đặt"; N20 "Về Cài đặt"); form và danh sách căn trái |
| 8. Không sợ sai (R-SAFE-01/02) | Đạt | Đổi cỡ chữ, tương phản, công tắc, lưu hồ sơ đều có Hoàn tác (không tự tắt); đăng xuất và bỏ thay đổi hỏi lại, nói rõ hậu quả; lỗi tên có icon + câu + "Ví dụ: Lan"; lưu lỗi giữ chữ đã gõ |
| 9. Giọng đọc (R-VOI-01/02) | Chưa đạt một phần | **Chưa:** ô tên N06 không có nút "🎤 Nói…" (R-VOI-02, warn) – cần `SpeechService` của F5. Công tắc "Đọc to nội dung" mới lưu cờ, chưa có TTS |
| 10. Lời lẽ (R-LANG-01/02/03, R-VOC-01) | Đạt | 100 % tiếng Việt, gọi "Bác"; nút là động từ + việc; câu N20 đã sửa cho đúng sự thật (DT-30) |
| 11. Phong cách (R-STY-01/02/03) | Đạt | Màu, font, bo góc, lề 20 / khoảng cách 16 từ `lib/theme/`; quét không còn `Color(0x…)`, `Colors.*`, `fontSize:`, `Icons.*`, số cứng (vạch ngăn S10 đã đổi sang `AppSpacing.xl`) |

## Đối chiếu "Xong khi" (`An-Nhien_Chia-task_Lab3.md` › F8)

| Tiêu chí | Kết quả | Bằng chứng / còn thiếu |
| --- | --- | --- |
| Đổi cỡ chữ áp dụng toàn app | Đạt | `settings_flow_test` trên `AnNhienApp` thật: chọn "Rất lớn" ở S10 → về Hôm nay `textScaler` ×1.3; dựng lại app với cùng Fake (mở lại app) → vẫn ×1.3 |
| Đúng ở 360 và 412 dp, không tràn chữ | Đạt | `settings_overflow_test` (60 test): mọi màn / state F8 ở 360×800 và 412×915, ×1.0 / 1.3 / 2.0, thường và tương phản cao |
| (Máy thật) giữ cài đặt sau khi tắt app | Chưa | Cần bản Firebase `SettingsService` (Hiếu). Cơ chế nạp khi mở app đã có |

## Test

| File | Nội dung |
| --- | --- |
| `settings_view_model_test.dart` | ViewModel S10 + `displaySettingsSyncProvider` (11) |
| `profile_view_model_test.dart` | ViewModel N06: nạp, lỗi + thử lại, tên trống / quá dài, lưu, lỗi lưu, Hoàn tác, bỏ thay đổi (13) |
| `settings_screen_test.dart` | S10: cỡ chữ, tương phản, Hoàn tác, lỗi lưu, Error + Thử lại, điều hướng, đăng xuất (16) |
| `profile_screen_test.dart` | N06: hỏi khi rời màn (Quay lại / Hủy / back hệ thống), lưu + Hoàn tác, lỗi, bàn phím mở (17) |
| `settings_static_screens_test.dart` | N08, N20: chữ, điều hướng, nút ghim đáy (21) |
| `settings_flow_test.dart` | Cả luồng trên `AnNhienApp` thật (4) |
| `settings_overflow_test.dart` | Tràn chữ mọi state (60) |

## Ảnh cần chụp (máy ảo 360 dp)

S10 ở cỡ Vừa / Lớn / **Rất lớn** · S10 khi bật "Chữ và nền rõ hơn" · S10 Snackbar "Đã đổi cỡ chữ sang Rất lớn." · hộp hỏi đăng xuất · N06 (×1.3) · N06 lỗi tên trống · hộp hỏi "Bác chưa lưu thay đổi" · N08 (×1.3) · N20 (×1.3) · Hôm nay sau khi chọn "Rất lớn" (chứng minh đổi toàn app).

## Checklist trước khi mở PR (`CLAUDE.md`)

- [x] `flutter analyze` sạch (chỉ còn 1 warning có sẵn ở `app_router.dart`, không phải F8); `flutter test`: không lỗi mới (lỗi có sẵn ở `router_test`, `text_scale_overflow_test`, `auth_routing_test`, `theme_test`).
- [x] Màn tải dữ liệu (S10, N06) vẽ đủ Loading / Error + Thử lại / Data; Empty không áp dụng (ghi lý do đầu file). N08, N20 tĩnh.
- [x] Không màu / cỡ chữ / spacing cứng; chỉ dùng widget trong `lib/widgets/` (2 widget mới thêm vào F0).
- [x] Đúng ở 360 và 412 dp, `textScaler` 1.3 và 2.0 không tràn (cả tương phản cao).
- [x] Có test ViewModel với service Fake (cả nhánh Error, lưu lỗi).
- [x] Event analytics theo `docs/analytics-plan.md` (`change_font_size`; `logout` qua F1).
- [x] Cập nhật trạng thái màn trong `docs/design-traceability.md` (`changed` + DT-28 → DT-31).
- [x] Đối chiếu mục "Xong khi" (bảng trên).

## Thứ tự commit gợi ý

1. `feat(F0): thêm SectionCard, NavRow và icon cài đặt / hồ sơ vào AppIcons`
2. `feat(F8): SettingsViewModel + ProfileViewModel, nạp cài đặt hiển thị khi mở app` (bước 01)
3. `feat(F8): S10 Cài đặt hiển thị – cỡ chữ, tương phản cao, công tắc, Hoàn tác, đăng xuất có hỏi lại` (bước 02)
4. `feat(F8): N06 Thông tin của Bác – sửa tên, cách gọi, giờ thức dậy, Hoàn tác, hỏi khi bỏ thay đổi` (bước 03)
5. `feat(F8): N08 Cách dùng đơn giản + N20 Dữ liệu trên điện thoại (câu chữ đúng Lab 3)` (bước 04)
6. `test(F8): test cả luồng + tràn chữ, chốt docs, PR-F8` (bước 05)
