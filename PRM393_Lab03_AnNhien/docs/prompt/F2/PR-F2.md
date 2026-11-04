# feat(F2): Onboarding của Bác (Flow 1) – cỡ chữ, hồ sơ, nhắc việc, thử lời nhắc, việc đầu tiên

Nhánh `feat/F2-onboarding` → `main`. Người làm: Hương (AI agent hỗ trợ theo `docs/prompt/F2/01…07`).

Lần đầu mở app, Bác chọn cỡ chữ → xác nhận tên, cách gọi, giờ thức dậy → cho phép nhắc việc → thử một lời nhắc → chọn và lưu việc đầu tiên → về Hôm nay. Xong thì `users/{uid}.onboarded = true` và ghi `tutorial_complete`.

## Làm gì

1. **Service + khung ViewModel** (bước 01): `SettingsService`, `ReminderService` (interface + Fake), model `AppSettings`; dùng lại `ProfileService` của Hiếu (không viết bản thứ hai).
2. **S01** (bước 02): chọn cỡ chữ Vừa / Lớn / Rất lớn, chữ toàn app đổi ngay khi chạm, lưu qua `SettingsService`.
3. **S02 + DLG-WakeTime** (bước 03): 3 state cùng route – xác nhận tên Google, nhập lại tên (lỗi có icon + "Ví dụ"), cách gọi Ông / Bà + giờ thức dậy. Lưu qua `ProfileSetupService` **tạm** (xem "Sửa ngoài phạm vi").
4. **S13 / S13d** (bước 04): giải thích trước rồi mới hỏi quyền; từ chối / "Để sau" → S13d nói rõ hậu quả + cách bật lại; đã có quyền sẵn thì bỏ qua.
5. **N01–N03** (bước 05): gửi lời nhắc thử → hỏi đã nhận chưa → chưa nhận thì 3 chỗ kiểm tra + "Thử lại".
6. **N04 → N05 → N18** (bước 06): chọn 1 trong 9 thói quen → xem lại + đổi giờ → lưu việc lặp mỗi ngày (đặt lời nhắc nếu đã cho phép) → `markOnboarded` → Hôm nay.
7. **Kiểm tra** (bước 07): test cả luồng, test tràn chữ cho mọi state, gộp khung lặp lại thành `OnboardingLayout`, tự chấm `rule.md`, docs.

## Màn + route

| Route | Màn / state | Màn hình | ViewModel |
| --- | --- | --- | --- |
| `/welcome` | S01 | `WelcomeScreen` | `OnboardingViewModel` |
| `/setup` | S02 xác nhận tên · nhập lại tên · giới thiệu về Bác, DLG-WakeTime | `SetupProfileScreen` | `OnboardingViewModel` |
| `/setup/notifications` | S13 · S13d | `NotificationsScreen` | `OnboardingViewModel` |
| `/setup/try-reminder` | N01 · N02 · N03 | `TryReminderScreen` | `TryReminderViewModel` |
| `/setup/first-task` | N04 · N05 · N18 | `FirstTaskScreen` | `FirstTaskViewModel` |

Biến thể Figma là **state** của route (không thêm route). Trong `app_router.dart` chỉ thay đúng 5 dòng placeholder + import. Khung chung `lib/screens/onboarding/onboarding_layout.dart` (nội dung cuộn + thanh nút ghim đáy) chỉ ghép widget F0 có sẵn.

## Service / model / ViewModel mới

| Loại | Tên | Ghi chú |
| --- | --- | --- |
| Service | `SettingsService` + `FakeSettingsService(failOnSave:)` | `watch()`, `setFontScale`, `setHighContrast`, `setReadAloud`, `setVibrate`. Chỉ có Fake |
| Service | `ReminderService` + `FakeReminderService(permissionGranted:, alreadyGranted:, failOnShowTest:)` | `hasPermission`, `requestPermission`, `schedule`, `cancel`, `snooze`, `showTest`. Chỉ có Fake |
| Service (tạm) | `ProfileSetupService` + `FakeProfileSetupService(failOnSave:)` | `saveSetup(uid, ProfileSetup)` → `displayName`, `honorific` (`ong` / `ba`), `wakeTime` (`"HH:mm"`). Chờ Hiếu gộp vào `ProfileService` |
| Model | `lib/models/app_settings.dart` | `fontScale` (lưu 1.0 / 1.15 / 1.3), `highContrast`, `readAloud`, `vibrate`; `fromMap` / `toMap`. Đề xuất, Hiếu chốt |
| Provider | `settingsServiceProvider`, `reminderServiceProvider`, `profileSetupServiceProvider` | Trỏ bản Fake, có `TODO(Hiếu)` |
| ViewModel | `OnboardingViewModel` | S01, S02, DLG-WakeTime, S13 / S13d |
| ViewModel | `TryReminderViewModel` | N01–N03 |
| ViewModel | `FirstTaskViewModel` | N04, N05, N18 |

## Event analytics (`docs/analytics-plan.md`)

| Event | Khi nào | Tham số |
| --- | --- | --- |
| `test_reminder` | N02 bấm "Đã nhận được" / "Chưa nhận được" (1 lần mỗi câu trả lời) | `received` (bool) |
| `add_task` | N05 lưu được việc đầu tiên | `habit_key`, `repeat`, `source: first_task`, `duration_sec` |
| `tutorial_complete` ★ | N18 "Xem lịch" / "Thêm việc khác", hoặc "Để sau" ở N04 | `font_size` (`vua` / `lon` / `rat_lon`), `notifications_on`, `has_first_task` |

Không gửi tên Bác, tên việc (có test kiểm). Cách lấy bằng chứng DebugView: `docs/analytics-plan.md` › Bằng chứng.

## Lệch Figma

DT-23 → DT-27 cuối `docs/design-traceability.md`; 13 dòng F2 chuyển `changed`, N19 giữ `todo` (chờ Khang). Chính:

- **DT-23 S01**: logo `IconCircle` 112 (Figma 72); icon mũi tên trước chữ.
- **DT-24 S02**: tên gợi ý lấy từ Google ("Tên này lấy từ tài khoản Google của Bác."); lỗi tên trống / quá dài theo style guide; không có ô số điện thoại; cách gọi chỉ Ông / Bà, giờ mặc định 6:00 sáng (theo Figma).
- **DT-25 S13 / S13d**: hộp gợi ý vàng → `FieldMessage.hint`; câu dặn "Bác bấm Cho phép" đưa lên trước thẻ ví dụ; "Bật nhắc việc" ở S13d chỉ hỏi lại quyền (không mở cài đặt hệ thống).
- **DT-26 N01–N03**: N02 là bước hỏi lại ("Đã gửi lời nhắc thử" / "Bác đã nhận được chưa?"); nút "Tôi đã nhận được" → "Đã nhận được" (R-LANG-02).
- **DT-27 N04–N18**: N04 là 9 thói quen (chưa có `Habit.suggestions`); N05 chỉ đổi giờ, ngày / nhịp chỉ xem; N18 không có "Nhắc trước 10 phút".

Cột "Đã sửa Figma?" của DT-23 → DT-27 còn ☐: cần sửa Figma.

## Sửa ngoài phạm vi F2 (đã hỏi trước)

- `lib/services/providers.dart` (Hiếu): **chỉ thêm** 3 provider trỏ Fake + 3 import (người dùng đồng ý ở bước 01, 03).
- `lib/models/app_settings.dart` (thư mục của Hiếu): file mới, người dùng đồng ý đặt ở đây.
- `docs/analytics-plan.md` (Hiếu): chỉ thêm đoạn "Cách lấy bằng chứng event F2" trong mục Bằng chứng.
- Không sửa `profile_service.dart`, `firebase_*`, `user_profile.dart`, `lib/theme/`, `lib/widgets/`, `today_*`.

## Việc nhờ người khác

**Hiếu**

1. **`FirebaseTaskRepository.save()` / `tasksForDay()` đang luôn ném** "Lịch đang chờ thống nhất dữ liệu ngày và lặp lại." → trên máy thật N05 luôn báo lỗi, Hôm nay không tải được. Cần chốt schema `TaskItem` (ngày bắt đầu, lặp, `remindBeforeMin`).
2. **Bỏ comment khối `redirect`** + điều kiện mục 7.1: `role == null` → `/role`; Bác chưa `onboarded` → `/welcome`; đã `onboarded` không vào lại `/welcome`. Hiện "mở lại app không hỏi lại" mới đúng ở mức ViewModel.
3. Gộp `saveSetup` vào `ProfileService` + `FirebaseProfileService`, thêm `honorific`, `wakeTime` vào `UserProfile`, rồi bỏ `ProfileSetupService` tạm. Tới lúc đó S02 chỉ lưu trong bộ nhớ.
4. Bản Firebase `SettingsService` (Firestore `users/{uid}` + cache máy), chốt `AppSettings`.
5. Thêm `Habit.suggestions` (Firestore `habits/{key}.suggestions[]`) để N04 khớp Figma.
6. `FakeProfileService.watch()` dùng `Stream.multi` – không phát trong `testWidgets` (F2 gặp với `FakeSettingsService`, đã đổi sang `async*`); có thể liên quan 68 test lỗi sẵn ở `router_test` / `auth_routing_test` / `text_scale_overflow_test` / `theme_test`.

**Hiếu / Khang**: bản thật `ReminderService` (flutter_local_notifications; `POST_NOTIFICATIONS` Android 13+, `USE_FULL_SCREEN_INTENT`, `SCHEDULE_EXACT_ALARM` 14+; cách mở cài đặt hệ thống khi đã bị từ chối hẳn). Chốt có gộp quyền FCM vào S13 không.

**Khang (F3 – N19)**: S03 khi có đúng 1 việc vừa thêm (Figma `47:225`): lời chào theo tên, thẻ "Việc tiếp theo" + "Dời lại", "Việc hôm nay" 1 dòng, "Thêm việc khác", nút đáy "Đã xong". `TodayViewModel` đọc cùng `TaskRepository`; nếu S03 đã tạo trước đó thì cần `load()` lại khi quay về. `/today/add` (S05) vẫn placeholder.

**Sanh (F0)**:

- Thêm vào `AppIcons` (F2 đang dùng `Icons.*` trực tiếp): `spa_outlined` (logo), `text_fields` (cỡ chữ), `favorite_border` (cách gọi), `alarm` (giờ thức dậy), `notifications_off_outlined` (nhắc việc tắt), `notifications_active_outlined` (chuông reo / gửi thử), `smartphone_outlined` (âm lượng máy), `event_outlined` (ngày bắt đầu), `add` (thêm việc).
- Widget `InlineHint` (nền `warning-container` / ô ghi chú màu) + vai trò màu warning cho tương phản cao → thay `FieldMessage.hint` ở S13, S13d, N01, N02, N04, N05.
- `IconCircle` thêm tham số cỡ (logo S01 72 / 40, S13 80 / 56, N18 128 / 72).
- Cân nhắc đưa `OnboardingLayout` (nội dung cuộn + thanh nút ghim đáy) vào `lib/widgets/` nếu màn khác cần.
- Prompt F2 ghi "chạy `dart format lib test`": lệnh này định dạng lại file của mọi người (đã xảy ra ở bước 03, đã khôi phục) → sửa thành chỉ format file của feature.

## Tự chấm `rule.md` (11 nhóm luật) – phạm vi F2

| Nhóm luật | Kết quả | Chỗ chưa đạt / ghi chú |
| --- | --- | --- |
| 1. Đọc được ngay (R-TXT-01/02, R-CON-01/02, R-LAY-01) | Đạt | Chữ lấy từ theme (≥ 20 sp), màu qua `ColorScheme`. `onboarding_overflow_test`: 12 state × 360×800 / 412×915 × 1.0 / 1.3 / 2.0 × thường / tương phản cao – không tràn. Ngoại lệ F0: "Bước x/y" thu nhỏ khi ×2.0 (DT-21) |
| 2. Ít chữ, nhiều icon (R-TXT-03/04/05, R-ICON-02/03) | Đạt một phần | Câu dài nhất 15 tiếng; nhãn nút ≤ 4 tiếng; mọi nút có icon. **Chưa:** 9 icon `Icons.*` ngoài `AppIcons`; `AppIcons.later` (alarm-clock-plus) dùng cho "Để sau"; `AppIcons.tabWeek` dùng cho nút "Xem lịch" |
| 3. Màu sắc (R-COL-01…04) | Đạt | Thẻ việc / thói quen dùng `TaskRow`, `HabitTile`, `HabitAccentCard` (ô màu nhấn + vạch trái); lựa chọn có dấu tích + chữ "Đang chọn" / "Đã chọn" |
| 4. Chạm trúng (R-TAP-01/02/03) | Đạt | Nút, ô nhập, ô giờ, thẻ cao ≥ 72; nút chính full-width ở đáy; nút đáy cách 20; thẻ thói quen N04 cách 20 (đã sửa từ 16 ở bước 07). Ô trong hộp chọn giờ theo DT-12 (F0) |
| 5. Không phải đoán (R-ICON-01, R-NAV-01/02, R-GES-01/02) | Đạt | Back luôn "Quay lại"; N18 là màn kết quả không có Back (theo Figma); không thao tác vuốt. Onboarding không có bottom nav (nằm ngoài `AppShell`) |
| 6. Biết làm hay chưa (R-STA-01/02) | Đạt | Thẻ việc mẫu / N05 có chip "○ Chưa làm" |
| 7. Một việc mỗi màn (R-ONE-01/02, R-CEN-01) | Đạt một phần | Mỗi màn tối đa 1 nút filled. S01, S13, S13d, N18 căn giữa; S02 căn giữa theo chiều dọc như Figma. **Lưu ý:** N02 (hộp hỏi lại) căn trái theo Figma |
| 8. Không sợ sai (R-SAFE-01/02) | Đạt | Lỗi tên có icon + câu + "Ví dụ: Lan, Sáu, Tư" (+ `liveRegion`); lưu lỗi giữ dữ liệu, nút "Thử lại"; không có thao tác xoá |
| 9. Giọng đọc (R-VOI-01/02/03) | Chưa đạt một phần | **Chưa:** ô nhập tên S02 không có nút "🎤 Nói…" (R-VOI-02, warn) – cần `SpeechService` của F5 |
| 10. Lời lẽ (R-LANG-01/02/03, R-VOC-01) | Đạt | 100 % tiếng Việt, gọi "Bác" (đã đổi "Tôi đã nhận được" → "Đã nhận được"); nút là động từ + việc; không lời lẽ gây áp lực |
| 11. Phong cách (R-STY-01/02/03) | Đạt | Màu, font, bo góc, lề 20 / khoảng cách 16 lấy từ `lib/theme/`; không `Color(0x…)`, `Colors.*`, `fontSize:`, khoảng cách số cứng |

## Đối chiếu "Xong khi" (`An-Nhien_Chia-task_Lab3.md` › F2)

| Tiêu chí | Kết quả | Bằng chứng / còn thiếu |
| --- | --- | --- |
| Đi hết S01 → Hôm nay có việc đầu tiên | Đạt với Fake; **chưa** trên máy thật | `onboarding_flow_test` đi hết luồng, việc được lưu + đặt lời nhắc. Máy thật chờ Hiếu (`FirebaseTaskRepository.save`) và Khang (N19) |
| Từ chối quyền thì hiện S13d | Đạt | `notifications_screen_test`, `onboarding_flow_test` (S13d → "Vẫn để sau" → N04) |
| Mở lại app không hỏi lại | Một phần | `finish()` → `markOnboarded` (`onboarded == true`, có test). Router chưa đọc `onboarded` (khối `redirect` đang comment) – chờ Hiếu |

## Ảnh cần chụp (máy ảo 360 dp, cỡ chữ "Rất lớn" ×1.3)

S01 · S02 xác nhận tên · S02 nhập lại tên **có lỗi tên trống** · S02 giới thiệu về Bác · DLG-WakeTime · S13 · **S13d** · N01 · N02 · **N03** · N04 · N05 · N18 · Hôm nay sau onboarding (N19 khi Khang xong). Để chụp được N05 → N18 trên máy cần tạm đổi `taskRepositoryProvider` sang `FakeTaskRepository()` (trả lại trước khi commit).

## Test

| File | Nội dung |
| --- | --- |
| `test/f2_services_test.dart` | Fake lưu rồi `watch()` phát lại; cờ lỗi ném `AppException` |
| `test/f2_view_models_test.dart` | 3 ViewModel: Loading / Empty / Error → Thử lại / Data, S01 / S02 / S13 / N01–N03 / N04–N18, event + tham số (không tên) |
| `test/welcome_screen_test.dart`, `setup_profile_screen_test.dart`, `notifications_screen_test.dart`, `try_reminder_screen_test.dart`, `first_task_screen_test.dart` | Từng màn: điều hướng, lỗi, 360 / 412 × 1.3 / 2.0 |
| `test/onboarding_flow_test.dart` | Cả luồng + nhánh tên trống, từ chối quyền, chưa nhận lời nhắc; `tutorial_complete` đúng 1 lần |
| `test/onboarding_overflow_test.dart` | 12 state × 2 khung × 3 cỡ chữ × thường / tương phản cao |

`flutter test`: 239 qua, 68 lỗi **có sẵn** trước F2 (`router_test` 44, `text_scale_overflow_test` 14, `auth_routing_test` 9, `theme_test` 1 – đã kiểm bằng cách bỏ thay đổi F2: số lỗi giữ nguyên). `flutter analyze`: 1 warning có sẵn (`pendingNotification` trong `app_router.dart`, không thuộc F2).

## Checklist trước khi mở PR (CLAUDE.md)

- [x] `flutter analyze` sạch với code F2 (còn 1 warning có sẵn ở `app_router.dart:37`, không thuộc F2), `flutter test` qua toàn bộ test F2 (68 lỗi có sẵn ngoài F2 – xem trên).
- [x] Màn tải dữ liệu vẽ đủ Loading / Empty / Error + Thử lại / Data (S02 / S13 nạp onboarding; N04 nạp gợi ý); màn không tải dữ liệu (S01, N01–N03) ghi lý do trong comment đầu file.
- [x] Không màu / cỡ chữ / spacing cứng; chỉ dùng widget trong `lib/widgets/` (+ `OnboardingLayout` ghép widget có sẵn). Còn 9 `Icons.*` chờ Sanh thêm vào `AppIcons`.
- [x] Đúng ở 360 và 412 dp, `textScaler` 1.3 (và 2.0, tương phản cao) không tràn.
- [x] Có test ViewModel với service Fake (cả nhánh Empty / Error).
- [x] Event analytics đã gắn theo `docs/analytics-plan.md` (`test_reminder`, `add_task`, `tutorial_complete`).
- [x] Cập nhật trạng thái màn trong `docs/design-traceability.md` (13 dòng `changed` + DT-23…27; N19 `todo` chờ Khang).
- [x] Đối chiếu mục "Xong khi" của F2 (bảng trên – 2 điểm chờ Hiếu / Khang).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
