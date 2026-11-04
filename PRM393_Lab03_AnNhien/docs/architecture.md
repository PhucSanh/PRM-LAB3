# Kiến trúc – MVVM + Riverpod

Chủ file: **Sanh**. Sửa file này khi đổi cấu trúc thư mục, thêm ViewModel / service hoặc đổi dữ liệu Firestore. Bản Firebase của service do **Hiếu** viết.

Nguồn: `lab2/flutter-handoff.md` (route map, Bảng 1 token, Bảng 2 component), `lab2/PRD.md` (FR / NFR), `lab2/user-flow.md` (IA 2 chế độ), code hiện có trong `lib/`.

## 1. Tổng quan

- App Android 360 × 800 dp, **hai chế độ** chọn ở C01: **Bác** (người lớn tuổi, 4 tab) và **Con cháu** (ghép nối, lập lịch cho mẹ, gửi gợi ý).
- **MVVM**: View (`screens/`, `widgets/`) ↔ ViewModel (Riverpod `Notifier` giữ `UiState`) → Service (interface) → Firebase.
- Mỗi service có **2 bản**: `Fake…` (chạy ngay, dùng cho test và khi chưa nối Firebase) và `Firebase…` (Hiếu viết). Chọn bản ở **một chỗ duy nhất**: `lib/services/providers.dart`.
- Dữ liệu: Firestore (bật offline persistence → dùng được khi mất mạng, FR13), Storage cho PDF, FCM + local notification cho lời nhắc / gợi ý.

## 2. Thư mục

| Thư mục | Chứa gì | Được import | Chủ |
| --- | --- | --- | --- |
| `lib/models/` | Lớp Dart thuần, `fromMap/toMap` | không import gì của app | Hiếu |
| `lib/services/` | Interface + `Fake…` + `Firebase…`; `providers.dart` chọn bản dùng | `models/`, `utils/` | Hiếu |
| `lib/viewmodels/` | `Notifier` giữ `UiState`, gọi service, ghi analytics | `services/`, `models/`, `utils/` | người làm feature |
| `lib/screens/<feature>/` | Màn hình; chỉ đọc state và gửi sự kiện cho ViewModel | `viewmodels/`, `widgets/`, `theme/` | người làm feature |
| `lib/widgets/` | Component Lab 2 dùng chung (mục 9) | `theme/` | Sanh (F0) |
| `lib/theme/` | Token: `AppColors`, `HabitPalette`, `AppSpacing`, `AppRadius`, `AppSizes`, `AppTheme` | — | Sanh (F0) |
| `lib/router/` | `go_router`, khai báo route (Sanh); điều kiện chặn đăng nhập / vai trò (Hiếu) | `screens/`, `viewmodels/` | Sanh + Hiếu |
| `lib/utils/` | `AppException` (lỗi đã dịch sang câu cho Bác) | — | Hiếu |
| `test/` | Test ViewModel bằng service giả | — | mỗi người |
| `e2e_test/` | ARTEMIS (pytest) | — | Hương điều phối |
| `firebase/` | `firestore.rules`, `storage.rules`, `remote-config-defaults.json` | — | Hiếu |

## 3. Sơ đồ lớp

```mermaid
flowchart TD
  V[screens/ + widgets/] -->|sự kiện| VM[viewmodels/ Riverpod Notifier]
  VM -->|UiState| V
  VM --> S[services/ interface]
  S --> FK[Fake… dùng cho test]
  S --> FB[(Firebase: Auth, Firestore, Storage, FCM, Analytics, Crashlytics, Remote Config)]
  S --> DEV[(Thiết bị: local notification, TTS, speech, danh bạ, share)]
  M[models/] -.dùng chung.- VM
  M -.dùng chung.- S
```

## 4. Luồng mẫu: Đánh dấu "Đã xong" ở Hôm nay (chỉ số M1 ≤ 2 chạm)

```mermaid
sequenceDiagram
  actor Bac as Bác
  participant UI as TodayScreen
  participant VM as TodayViewModel
  participant R as TaskRepository
  participant A as AnalyticsService
  Bac->>UI: bấm "Đã xong"
  UI->>UI: showDialog(DLG-Done)
  Bac->>UI: "Đúng, đã xong"
  UI->>VM: markDone(id)
  VM->>R: setStatus(id, done)
  VM->>A: logEvent(complete_task)
  VM->>R: tasksForDay(today)
  R-->>VM: List<TaskItem>
  VM-->>UI: UiData(TodayData)
  UI-->>Bac: "Đã xong 4/6 việc" + Snackbar Hoàn tác
```

## 5. Luồng gợi ý lịch giữa 2 máy (F12 + F13 + F14)

```mermaid
sequenceDiagram
  actor Mai as Con cháu (máy Mai)
  participant C as CaregiverTaskForm / SuggestionCompose
  participant SS as SuggestionService
  participant FS as Firestore users/{momUid}/suggestions
  participant FCM as FCM
  actor Lan as Bác (máy mẹ)
  participant SR as SuggestionReviewViewModel
  participant TR as TaskRepository
  Mai->>C: Gửi gợi ý (G01 / C08)
  C->>SS: send(momUid, suggestion)
  SS->>FS: create {status: pending}
  FS-->>FCM: (Cloud trigger hoặc gửi từ máy Mai)
  FCM-->>Lan: thông báo "Mai gửi lịch cho Bác"
  Lan->>SR: mở G11 → G03
  SR->>SS: watch(id)
  Lan->>SR: "Thêm 2 việc vào lịch"
  SR->>TR: save(task) × n
  SR->>SS: setStatus(accepted / partial / dismissed)
  Note over SR,SS: Bỏ qua KHÔNG báo lại cho Mai (FR08)
```

## 6. Trạng thái màn (`UiState`) – bị chấm

```dart
sealed class UiState<T> {}            // lib/viewmodels/ui_state.dart
final class UiLoading<T> ...          // LoadingView
final class UiEmpty<T>   ...          // EmptyView (vd. ST-Empty)
final class UiError<T>   ...          // ErrorView + "Thử lại" (message lấy từ AppException.userMessage)
final class UiData<T>    ...          // nội dung
```

Màn dùng `switch (state)` để vẽ đủ 4 trạng thái. Hành động một lần (lưu, xoá, dời…) trả về kết quả cho View để hiện Snackbar / điều hướng; không để View tự gọi service.

## 7. Điều hướng

### 7.1 Điều kiện chặn (redirect) – Hiếu viết, Sanh khai báo route

| Điều kiện | Đi tới |
| --- | --- |
| Chưa đăng nhập | `/sign-in` (A01) |
| Đã đăng nhập, chưa chọn vai trò (`users/{uid}.role == null`) | `/role` (C01) |
| Vai trò Bác, chưa onboarding (`onboarded == false`) | `/welcome` (S01) |
| Vai trò Con cháu, chưa ghép nối | `/caregiver/pair` (C02) |
| Còn lại | Bác → `/today`; Con cháu → `/caregiver/schedule` |

### 7.2 Route map (theo `lab2/flutter-handoff.md`, chỉnh cho Lab 3)

| Route | Màn | Feature | Trong `app_router.dart` |
| --- | --- | --- | --- |
| `/sign-in` | A01 | F1 | có |
| `/role` | C01 | F1 | có; chờ kiểm chứng Firebase trên máy |
| `/welcome` · `/setup` · `/setup/notifications` | S01 · S02 · S13 / S13d | F2 | `/welcome` có (`WelcomeScreen`), `/setup` có (`SetupProfileScreen`, 3 state + DLG-WakeTime); `/setup/notifications` có (`NotificationsScreen`, S13 / S13d) |
| `/setup/try-reminder` · `/setup/first-task` | N01–N03 · N04 → N05 → N18 → N19 | F2 | `/setup/try-reminder` có (`TryReminderScreen`, N01 / N02 / N03); `/setup/first-task` có (`FirstTaskScreen`, N04 / N05 / N18); N19 là state S03 của Khang |
| `/today` (tab 0) | S03 + mọi state S03-*, ST-Empty, N17, G11 / G12 | F3 | có |
| `/today/task/:id` · `/today/task/:id/edit` | S04 · S15 | F3 · F4 | placeholder |
| `/today/add` · `/today/add/time` · `/today/add/result` | S05 · S06 · ST-Loading / Saved / Error, N16 | F4 | placeholder |
| `/task/date` · `/task/repeat` · `/task/scope` | N11 · N12 · N13 (màn con, `pop(result)`) | F4 | placeholder |
| `/today/voice` | V00–V05 | F5 | placeholder |
| `/today/all` | S11 chế độ hôm nay | F7 | placeholder |
| `/today/suggestions/:id?from=popup\|card\|push\|family` | G03–G09 (state của `SuggestionReviewScreen`, xong bước 03–04) | F12 | có |
| `/reminder/:taskId` | S14 (mở từ notification `fullScreenIntent`; `?preview=true` từ S10) | F6 | placeholder |
| `/week` (tab 1) · `/week/:date` · `/week/:date/task/:id` | S07 · S11 / S11b · S04 | F7 | placeholder |
| `/habits` (tab 2) · `/habits/:key` | S08 · S16 | F9 | placeholder |
| `/family` (tab 3) · `/family/add` · `/family/:personId/edit` · `/family/:personId/share` | S09 · S12 · N09 · S17 | F11 | placeholder |
| `/settings` · `/settings/profile` | S10 · N06 (+ khu demo F10) | F8 | `/settings` có (`SettingsScreen`, S10 – bước 02); `/settings/profile` có (`ProfileScreen`, N06 – bước 03; cuối màn là `FirebaseDemoEntry` → `/settings/firebase-demo`, khu demo F10 của Hiếu) |
| `/settings/reminders` · `/settings/help` · `/settings/data` | N07 · N08 · N20 | F6 · F8 · F8 | `/settings/reminders` placeholder; `/settings/help` có (`HelpScreen`, tĩnh – bước 04); `/settings/data` có (`DataScreen`, tĩnh – bước 04, câu chữ DT-30) |
| `/inbox` | Hộp thông báo | F10 | placeholder |
| `/caregiver/pair` | C02 / C02e | F13 | placeholder |
| `/caregiver/schedule?view=day\|week\|month` | C03 / C04 / C05 | F14 | placeholder |
| `/caregiver/task/new` → `/repeat` → `/review` → `/caregiver/task/sent` | C06 → C07 → C08 (+ C08w) → C09 | F14 | placeholder |
| `/caregiver/task/:id` | C10 (+ C11, C12 dialog) | F14 | placeholder |
| `/caregiver/suggest` | G01 → G01b → G02 (state của một màn `SuggestionComposeScreen`) | F12 | có |
| `/dev/widgets` | Trang xem thử widget F0 (`WidgetGallery`) – **chỉ khai báo khi `kDebugMode`**; khi bật `redirect` thì phải đăng nhập mới vào được | F0 | có (debug) |

Việc của F0 (Sanh) – đã làm ở bước 01 (02/11/2026): mọi route trên đã khai báo trong `app_router.dart`, màn chưa làm là `FeaturePlaceholder` ghi mã màn · feature · người theo bản chia task 02/11; nhóm route theo feature bằng comment `// F<số> <tên> – <người>`. `/caregiver/schedule` chọn C03 / C04 / C05 theo query `view`. Kiểm tra bằng `test/router_test.dart`. Khối `redirect` (chưa đăng nhập → `/sign-in`, đã đăng nhập ở `/sign-in` → `/today`) **đang tạm comment** để test UI không cần đăng nhập Google; bỏ comment trước khi nộp (đề chấm: chưa đăng nhập không vào được app). Khi còn comment thì `test/auth_routing_test.dart` fail.

Quy tắc điều hướng từ handoff: tab dùng `StatefulShellRoute`; Back hệ thống ở S03 thoát app; kết quả lưu (`/today/add/result`) dùng `go` (thay thế, không chồng); màn con N11–N13 trả kết quả bằng `pop(result)`; S04 mở từ 2 nơi nên nút Back ghi "Quay lại".

## 8. Service

### 8.1 Đã có (interface + Fake trong `lib/services/`)

| Service | Hàm chính | Bản Firebase (Hiếu) |
| --- | --- | --- |
| `AuthService` | `authStateChanges()`, `signInWithGoogle()`, `signOut()` | Firebase Auth + google_sign_in |
| `TaskRepository` | `tasksForDay(day)`, `save(task)`, `setStatus(id, status)`, `delete(id)` | Firestore `users/{uid}/tasks` |
| `HabitRepository` | `all()`, `byKey(key)` | Firestore `habits` (nạp sẵn 9 thói quen) |
| `FamilyRepository` | `all()`, `save(relative)`, `delete(id)` | Firestore `users/{uid}/family` |
| `AnalyticsService` | `logEvent(name, params)`, `setUserId(uid)` | Firebase Analytics |
| `CrashService` | `recordError`, `setCustomKey`, `setUserId`, `testCrash` | Crashlytics |
| `RemoteConfigService` | `init()`, `getInt`, `getBool`, `onUpdated` | Remote Config |
| `MessagingService` | `requestPermission()`, `inbox()`, `onOpened` | FCM + `users/{uid}/notifications` |
| `ReportService` | `exportWeek(weekStart)` → `Stream<UploadProgress>` | package `pdf` + Storage `reports/{uid}/` |
| `ProfileService` | `ensureProfile(user)`, `watch(uid)`, `setRole(uid, role)`, `markOnboarded(uid)` | Firestore `users/{uid}` (`FirebaseProfileService`, đã có). **Thiếu** hàm lưu hồ sơ S02 (`displayName`, `honorific`, `wakeTime`) – F2 đề xuất, chờ Hiếu |
| `SettingsService` (F2 thêm, **chỉ có Fake**) | `watch()` → `AppSettings`, `setFontScale`, `setHighContrast`, `setReadAloud`, `setVibrate`; `FakeSettingsService(failOnSave:)` | TODO(Hiếu): Firestore `users/{uid}` + cache máy. Model `lib/models/app_settings.dart` (F2 đề xuất) |
| `ReminderService` (F2 thêm, **chỉ có Fake**) | `hasPermission()`, `requestPermission()`, `schedule(task)`, `cancel(id)`, `snooze(id, minutes)`, `showTest()`; `FakeReminderService(permissionGranted:, alreadyGranted:, failOnShowTest:)` | TODO(Hiếu / Khang): flutter_local_notifications (đề xuất package trong PR) |
| `ProfileSetupService` (F2 thêm, **tạm**, chỉ có Fake) | `saveSetup(uid, ProfileSetup)` – `displayName`, `honorific` (`ong` / `ba`), `wakeTime` ("HH:mm"); F8 thêm `watchSetup(uid)` → `Stream<ProfileSetup?>` (N06 đọc cách gọi + giờ thức dậy, `null` = chưa lưu); `FakeProfileSetupService(failOnSave:, seed:)` | TODO(Hiếu): gộp vào `ProfileService` + bản Firebase ghi / đọc `users/{uid}` (cả `watchSetup`), thêm `honorific` / `wakeTime` vào `UserProfile`, rồi xoá service tạm |
| `SuggestionService` (F12 thêm, **chỉ có Fake**; provider `suggestionServiceProvider`) | `send(momUid, s)`, `watchPending(momUid)` → `Stream<List<Suggestion>>` (chỉ `pending`, mới nhất trước), `byId(momUid, id)`, `markPopupShown(momUid, id)`, `accept(momUid, id, items)` (chỉ đổi `status`: hết → `accepted`, còn việc → `partial`; gọi lại được để nhận tiếp), `dismiss(momUid, id)`, `undoDismiss(momUid, id)` – không báo người gửi (FR08); **không** tạo việc (ViewModel gọi `TaskRepository.save`). `FakeSuggestionService(withSample:, delay:, failOnSend:, failOnLoad:, failOnAccept:)`, `momNotified`, `senderNotified` (= 0), `figmaSample()`. Model `lib/models/suggestion.dart` | TODO(Hiếu): Firestore `users/{momUid}/suggestions` + FCM "có gợi ý mới" mở `/today/suggestions/:id`; rules con cháu đã ghép nối **tạo**, mẹ cập nhật `status` / `popupShown` / `items[].accepted` |

F14 C08 và demo Firebase giữ contract `ScheduleSuggestion` trong `caregiver_suggestion_service.dart`, qua `caregiverSuggestionServiceProvider`. `TaskItem` giữ schema lịch v2 (`startDate` dạng `yyyy-MM-dd`, `durationMinutes`); `SuggestionItem.toTask` chuyển dữ liệu F12 sang schema này. `TaskItem.fromMap` cũng đọc được `durationMin` của incoming. `FirebaseProfileSetupService` đã hỗ trợ cả `saveSetup` và `watchSetup`.

### 8.2 Cần thêm (người làm feature thêm interface + Fake, Hiếu viết bản Firebase)

| Service | Hàm đề xuất | Dùng cho | Nền tảng |
| --- | --- | --- | --- |
| `TaskRepository` (bổ sung) | `tasksInRange(from, to)`, `postpone(id, to)`, `undo(change)`, `softDelete(id, scope)` | F3, F4, F7, F9 | Firestore |
| `SpeechService` | `listen()` → text, `parse(text)` → `TaskDraft`, `speak(text)` | F5, đọc to ở S04 / S14 / S16 | speech_to_text, flutter_tts (`vi-VN`) |
| `PairingService` | `createCode()` (máy mẹ), `pair(code)` (máy con cháu), `pairedMom()` | F13 | Firestore `pairings/{code}` (hết hạn 10 phút) |
| `CaregiverScheduleService` | `tasksOfMom(range)`, `checkConflict(draft)`, `recurringDetail(id)`, `updateRecurring(id, scope)`, `stopRecurring(id)` | F14 | Firestore `users/{momUid}/tasks` (quyền qua ghép nối) |

Thêm package không phải Firebase (speech_to_text, flutter_tts, pdf, share_plus, url_launcher, flutter_contacts, permission_handler, flutter_local_notifications): người làm feature đề xuất trong PR; package Firebase: Hiếu thêm.

## 9. ViewModel ↔ service (đề xuất cho toàn bộ màn)

Mỗi ViewModel còn dùng `AnalyticsService` (ghi event) và `CrashService` (lỗi thật). Cột "Có sẵn" = đã có file trong `lib/viewmodels/`. ViewModel dùng chung giữa nhiều feature có **một chủ**; người khác thêm state qua PR và nhờ chủ duyệt.

| ViewModel | Feature | Người | Màn / state | Service | Có sẵn |
| --- | --- | --- | --- | --- | --- |
| `SessionViewModel` | F1 | Hiếu | (toàn app – theo dõi đăng nhập) | AuthService | ✅ |
| `TodayViewModel` | F3 (chủ), F2, F4, F6 thêm state | Khang (chủ) | S03, N19, S03b, S03-alldone, N17, ST-Empty, DLG-Done, DLG-Later, DLG-Skip, S03-later, S03-later4, S03-tomorrow, S03-skip, S03-edited, S03-deleted, S03-snooze | TaskRepository, ReminderService | ✅ |
| `SignInViewModel` | F1 | Hiếu | A01, A02, A02e, A03, A04 | AuthService | ✅ |
| `RoleViewModel` | F1 | Hiếu | C01 | ProfileService | ✅ |
| `OnboardingViewModel` | F2 | Hương | S01, S02, DLG-WakeTime, S13, S13d | SettingsService, AuthService (tên gợi ý, uid), ProfileSetupService (tạm thay ProfileService), ReminderService | S01, S02, S13 / S13d xong (bước 02–04) |
| `TryReminderViewModel` | F2 | Hương | N01, N02, N03 | ReminderService | xong (bước 05) |
| `FirstTaskViewModel` | F2 | Hương | N04, N05, N18 | HabitRepository, TaskRepository, ProfileService (`markOnboarded`), ReminderService (`schedule`), AuthService (uid) | xong (bước 06) |
| `TaskDetailViewModel` | F3 | Khang | S04 | TaskRepository |  |
| `TaskFormViewModel` | F4 | Khang | S05, S06, S06e, S06o, ST-Validation, DLG-TaskTime, N11, N12, N13, N14, ST-Loading, ST-Loading-offline, ST-Saved, ST-Error, N16, S15, DLG-Delete | HabitRepository, TaskRepository, CrashService, ReminderService |  |
| `VoiceAddViewModel` | F5 | Khang | V00, V01, V02, V03, V04, V05 | SpeechService, RemoteConfigService, TaskRepository |  |
| `ReminderViewModel` | F6 | Khang | S14 | ReminderService, RemoteConfigService |  |
| `ReminderSettingsViewModel` | F6 | Khang | N07 | ReminderService, SettingsService |  |
| `WeekViewModel` | F7 | Hương | S07 | TaskRepository, ReportService |  |
| `DayDetailViewModel` | F7 (chủ), F12 thêm state G08* | Hương (chủ) | S11, S11b, G08, G08b, G08c, G08d | TaskRepository |  |
| `SettingsViewModel` | F8 | Sanh | S10 | SettingsService; Đăng xuất dùng `SignOutViewModel` (F1, đã log `logout` + xoá dữ liệu trên máy), không gọi `AuthService` trực tiếp | S10 xong (bước 02, `SettingsScreen`); khung từ bước 01: `UiState<AppSettings>`, `setFontScale` / `setHighContrast` / `setReadAloud` / `setVibrate` → `SettingChange`, `undo`, `retry` |
| `displaySettingsSyncProvider` | F8 | Sanh | (toàn app – `app.dart` watch) | SettingsService → `fontScaleProvider`, `highContrastProvider` | ✅ (bước 01): áp cài đặt đã lưu khi mở lại app |
| `ProfileViewModel` | F8 (chủ), F10 thêm khu demo | Sanh (chủ) | N06 | ProfileService (tên), ProfileSetupService (`watchSetup` / `saveSetup` – cách gọi, giờ thức dậy), AuthService (uid) | N06 xong (bước 03, `ProfileScreen`): `UiState<ProfileForm>`, `load` / `retry`, `changeName` / `changeHonorific` / `changeWakeTime` (tính `dirty`), `save` → `ProfileSaved` (Hoàn tác: `undo`), `discard`; không log analytics (analytics-plan không có event N06) |
| `HabitsViewModel` | F9 | Hương | S08 | HabitRepository, TaskRepository |  |
| `HabitDetailViewModel` | F9 | Hương | S16 | HabitRepository, TaskRepository |  |
| `FamilyViewModel` | F11 | Hương | S09, S09b, N21 | FamilyRepository, SuggestionService |  |
| `RelativeFormViewModel` | F11 | Hương | S12, S12a, S12e, N09, N15 | FamilyRepository |  |
| `ShareMessageViewModel` | F11 | Hương | S17, S17b, N10 | FamilyRepository, TaskRepository |  |
| `SuggestionComposeViewModel` (autoDispose) | F12 | Sanh | G01, G01b, G02 | SuggestionService, ProfileService (`pairedMomUid`), AuthService, HabitRepository (tên thói quen) | xong (bước 02): `selectTime`, `setMessage`, `requestSend`, `editAgain`, `send` |
| `SuggestionReviewViewModel` (autoDispose, family `(id, entry)`) | F12 | Sanh | G03, G03b, G04, G05, G05b, G06, G07, G07b, G09 | SuggestionService, TaskRepository, ReminderService | xong G03 → G09 (bước 03–04): `load`, `startChangeTime`, `pickTime`, `saveNewTime`, `cancelChangeTime`, `acceptAll`, `startChoosing`, `toggle`, `backToReview`, `continueChoosing`, `dismiss`, `undoDismiss` |
| `SuggestionInboxViewModel` | F12 | Sanh | G10, G11, G12 | SuggestionService, sessionProvider (uid Bác) | xong (bước 05): `pendingCard`, `popupToShow`, `sentToday`, `dayLabel`, `markPopupShown`, `later`; popup qua `SuggestionPopupListener` (bọc `AppShell`) |
| `PairingViewModel` | F13 | Hiếu | C02, C02e | PairingService |  |
| `MomScheduleViewModel` | F14 | Hiếu | C03, C04, C05 | CaregiverScheduleService |  |
| `CaregiverTaskFormViewModel` | F14 | Hiếu | C06, C06e, C07, C07m, C08, C08w, C09 | CaregiverScheduleService, SuggestionService |  |
| `RecurringTaskViewModel` | F14 | Hiếu | C10 | CaregiverScheduleService |  |

## 10. Dữ liệu Firestore (Hiếu chốt; người làm feature đề xuất trường mới trong PR)

| Đường dẫn | Trường chính | Ai đọc / ghi | Feature |
| --- | --- | --- | --- |
| `users/{uid}` | `role` (`elder` / `caregiver`), `displayName`, `honorific` (Ông / Bà / Bác), `wakeTime`, `onboarded`, `fontScale` (1.0 / 1.15 / 1.3), `highContrast`, `readAloud`, `vibrate`, `pairedMomUid` (máy con cháu), `fcmTokens[]` | chủ tài khoản | F1, F2, F8 |
| `users/{uid}/tasks/{taskId}` | `title` (≤ 80), `habitKey`, `hour`, `minute`, `startDate` (`TaskItem.startDate`, F12 thêm, lưu `yyyy-MM-dd` – Hiếu chốt), `repeat` (`once` / `daily` / `someDays`) + `weekdays[]` hoặc `rrule` (việc con cháu lập, RFC 5545), `durationMin` (`TaskItem.durationMin`, F12 thêm), `remind`, `remindBeforeMin`, `createdBy`, `deletedAt` (xoá mềm 7 ngày) | chủ; con cháu đã ghép nối **đọc** | F3, F4, F5, F7, F14 |
| `users/{uid}/completions/{date_taskId}` | `taskId`, `date`, `status` (done / postponed / skipped), `postponedTo`, `reason`, `at` | chủ; con cháu đã ghép nối **đọc** (C10 "6 lần gần nhất") | F3, F6, F9, F14 |
| `users/{uid}/family/{personId}` | `name`, `relation` (Con / Cháu / Bạn bè / Khác), `phone`, `quickCall`, `lastCalledAt` | chủ | F11 |
| `users/{uid}/notifications/{id}` | `title`, `body`, `receivedAt`, `route`, `read` | chủ | F10 |
| `users/{momUid}/suggestions/{id}` | `fromUid`, `fromName`, `message`, `fromRelation` (F12 đề xuất), `items[{title, habitKey, date (`yyyy-MM-dd`), hour, minute, durationMin, timeOptions[{hour, minute}] (F12 đề xuất), accepted (F12 đề xuất)}]`, `status` (pending / accepted / partial / dismissed), `popupShown`, `createdAt` – Hiếu chốt các trường đề xuất | con cháu đã ghép nối **tạo**; mẹ đọc + cập nhật | F12, F14 |
| `pairings/{code}` | `momUid`, `expiresAt` (+10 phút), `usedBy` | máy mẹ tạo; con cháu đọc 1 lần khi nhập mã | F13 |
| `habits/{key}` | `name`, `description`, `order`, `origin` (Blue Zones), `suggestions[]` | ai đăng nhập cũng đọc; không ai ghi từ app | F9 |
| Storage `reports/{uid}/{week}.pdf` | PDF ≤ 5 MB | chủ | F7 |

9 khoá thói quen: `move`, `purpose`, `downshift`, `eighty`, `plant`, `tea`, `belong`, `family`, `tribe` (tên hiển thị theo `lab2/vocabulary.md`, màu theo `HabitPalette`).

**Rules hiện tại** (`firebase/firestore.rules`) chỉ cho chủ tài khoản. **TODO(Hiếu)**: thêm `pairings`, `completions`, quyền đọc `tasks` / `completions` và tạo `suggestions` cho người đã ghép nối (F13 "Xong khi": người lạ không đọc được lịch của mẹ).

## 11. Remote Config (`firebase/remote-config-defaults.json`)

| Khoá | Mặc định | Dùng ở | Demo trên console |
| --- | --- | --- | --- |
| `snooze_minutes` | 10 | S14 "Nhắc lại sau N phút", S03-snooze | đổi 10 → 15, nút S14 đổi theo |
| `voice_input_enabled` | true | nút "Nói việc" ở S05 (F5) | tắt → nút biến mất, không build lại |
| `home_max_upcoming` | 6 | số việc tối đa ở S03 | — |

## 12. Theme (F0 – Sanh)

Token lấy từ `lab2/design-tokens.md` (bảng `colors`, `typography`, `spacing`, `rounded`) và `lab2/flutter-handoff.md` › Bảng 1. File trong `lib/theme/`:

| File | Nội dung |
| --- | --- |
| `app_colors.dart` | `AppColors` (đủ màu DESIGN.md, thêm `success`, `warningStrong`, `shadowLevel1/2`), `AppColorsHighContrast`, `HabitPalette` (9 màu + `onAccent` trắng) |
| `app_spacing.dart` | `AppSpacing` (4…48, `screen` 20, `betweenTargets` 20), `AppRadius` (8, 12, 14, 16, 24, `full` 999 + `…All`), `AppSizes` (`minTarget` 72, `icon` 32, `habitIcon` 48, `accentBar` 6, `border` 2, `appBar` 88, `navBar` 96…) |
| `app_theme.dart` | `AppTheme.light()`, `AppTheme.highContrast()` (cùng hàm dựng, chỉ đổi `ColorScheme`), `AppText.bodyLgStrong`, `AppText.numericLg` |
| `display_settings.dart` | `AppFontScale { vua 1.0, lon 1.15, ratLon 1.3 }`, `fontScaleProvider` (mặc định `lon` theo Figma S01/S10), `highContrastProvider` (mặc định tắt), `maxTextScale` 2.0 – giữ trong bộ nhớ; F8 nối `SettingsService` qua `displaySettingsSyncProvider` (`lib/viewmodels/display_settings_sync.dart`, `app.dart` watch) |
| `app_icons.dart` | `AppIcons`: 22 icon khung Components (`138:2`) + 4 icon tab + nhóm Form (`info`, `chevronDown`, `save`, `radioOn/Off`) + 7 icon thói quen `habit…` (cùng `walk`, `home`) + nhóm thẻ việc (`statusSkipped`, `statusPostponed`, `later`, `skipToday`, `stopReading`, `suggestion`, `view`, `chevronRight`) + nhóm Cài đặt S10 (`settings`, `textSize`, `contrast`, `vibrate`, `bellRing`, `bookOpen`, `smartphone`, `logout` – F8 bước 02, DT-28) + hồ sơ N06 (`smile`, `sunrise` – F8 bước 03, DT-29) → `IconData` Material gần nhất (DT-09) |

Chữ (Be Vietnam Pro, bundle trong `assets/fonts/`, khai báo ở `pubspec.yaml`): `display` 34 · `headline` 30 · `title-md` 26 · `title-lg` 24 · `body-lg` 24 · `label-btn` 22 · `body-md` / `caption` / `label-nav` 20. Cả 15 kiểu của `TextTheme` đều được điền nên không có chữ < 20 sp (kể cả widget Material dùng `labelSmall`, `titleSmall`).

Cỡ chữ người dùng chọn (S01 / S10) = `textScaler` 1.0 / 1.15 / 1.3 toàn app, nhân với cỡ chữ hệ thống, trần 2.0 (`lib/app.dart` › `builder`). Đổi `fontScaleProvider` là cả app đổi ngay. Tương phản cao (S10) = `AppTheme.highContrast()`: nền trắng, chữ chính `#0F1411` (18.6 : 1), chữ phụ `#202B25` (14.7 : 1), nút `#174C37` (chữ trắng 9.9 : 1), lỗi `#912018` – chỉ dùng lại màu có trong DESIGN.md.

Màn và widget lấy màu qua `Theme.of(context).colorScheme` (để tương phản cao có tác dụng), không đọc `AppColors` trực tiếp. Ngoại lệ duy nhất: `TaskStatusChip` "Chưa làm" dùng `AppColors.warningContainer / onWarningContainer / warningStrong` vì `ColorScheme` chưa có vai trò màu cảnh báo (TODO: gán vào `tertiary…` của 2 scheme).

## 13. Widget dùng chung (F0 – Sanh) – theo `lab2/flutter-handoff.md` › Bảng 2

| Widget | Dùng ở | Trạng thái |
| --- | --- | --- |
| `AppButton` (`AppButtonKind`: primary / secondary / tonal / text / danger / dangerOutline; cao ≥ 72, icon + chữ, `busy`) | mọi màn | có |
| `AppBackBar(backLabel, step, trailing, onBack)` (Back có chữ · + `step` "Bước x/y" · + `trailing`, vd. `AppBarEditButton` "Sửa" ở S04; `step` / `trailing` nằm ở ô co giãn, chữ ×2.0 không đủ chỗ thì thu nhỏ – DT-21) | màn cấp 2–3 | có |
| `AppShell` (bottom nav 4 tab theo Figma `1:451`: nền trắng viền trên, 4 ô rộng đều cách nhau 20, icon 32 + nhãn 20 đậm **2 dòng** "Hôm / nay", ô đang chọn nền `primaryContainer` bo 12 bọc cả icon lẫn nhãn; cao ≥ 96; chữ phóng to thì nhãn thu nhỏ vừa ô – DT-22) | 4 tab | có |
| `LoadingView` (`message`, `hint`) / `EmptyView` (`icon`, `title`, `message`, `action`, `secondaryAction`) / `ErrorView` (`message`, `onRetry`, `title`, `detail`, `extraActions`; luôn có "Thử lại", `liveRegion`) – khớp ST-Loading / ST-Empty / ST-Error | mọi màn tải dữ liệu | có |
| `IconCircle` (icon 64 trong vòng tròn nền nhạt; `danger` = nền `errorContainer`) | đầu hộp thoại, ST-*, màn "Đã lưu / Đã gửi" | có |
| `FeaturePlaceholder` | màn chưa làm | có |
| `WidgetGallery` (`lib/widgets/dev/widget_gallery.dart`, route `/dev/widgets` chỉ ở debug): mọi widget F0 theo nhóm nút · thanh · hộp thoại / snackbar · trạng thái · form · nội dung, hàng đổi cỡ chữ (Vừa / Lớn / Rất lớn + ×2.0) và tương phản cao; `animate: false` cho test. Không phải widget cho màn dùng | dev, `test/widgets/gallery_overflow_test.dart` | có |
| `TaskRow(time: TimeOfDay, title, habitKey, status: TaskStatus, note, onTap, showChevron)` (vạch màu · `HabitBadge` · giờ "6 giờ sáng" / "9:30 sáng" · tên · `TaskStatusChip` · dòng phụ = `note` hoặc tên thói quen; TalkBack "6 giờ sáng, Đi bộ, đã xong") + `TaskStatusChip(status)` (Chưa làm / Đã xong / Bỏ qua / Đã dời, icon + chữ) + `TaskStatus.label` | S03, S11, S16, C03 | có |
| `NextTaskCard(time, title, habitKey, onDone, onLater, onSkip, onTap, durationMinutes)` ("🔔 Việc tiếp theo · 9:30 sáng", nút "Đã xong" primary · "Dời lại" viền · "Hôm nay bỏ qua" chữ, nút không có callback thì ẩn; DT-16) | S03 | có |
| `HabitBadge(habitKey, size, icon, semanticLabel)` (ô màu nhấn, icon trắng, 48 → icon 32) · `HabitTile(habitKey, name, description, selected, onTap, icon)` (`selected` null = mũi tên ›; true / false = dấu chọn + "Đã chọn" / "Chọn") · `HabitAccentCard` (khung vạch màu dùng chung) · `HabitStyle.nameOf / descriptionOf / iconOf` (tên mặc định theo vocabulary.md, chỉ dự phòng – tên thật nạp từ `habits/{key}`) | S04, S05, S08, S16, C06 | có |
| `TimeField(label, value, onChanged, icon, dialogTitle, dialogIcon, errorText)` (nút "6:00 sáng · Đổi giờ ⌄", cao ≥ 72) + `showTimeWheel(context, initial, title, icon)` → `TimeOfDay?` (DLG-TaskTime / DLG-WakeTime: lưới nút chạm giờ 1–12, Sáng / Chiều, phút 00 / 15 / 30 / 45; "Bác chọn: …" + "Lưu giờ" / "Hủy" ghim đáy; mặc định 8:00 sáng; DT-12) + `formatTimeOfDay()` ("9:30 sáng", "3:00 chiều", "8:00 tối" – SG-10) | S02, S06, S15, N05, N06, C06 | có |
| `showConfirmDialog<T>(context, icon, title, message, details, options: [ConfirmOption(label, icon, value, kind)], danger)` + `ConfirmDetail` (dòng icon + chữ) – nút xếp dọc full-width theo thứ tự `options`, cách nhau 20; huỷ ở cuối, trừ khi hậu quả khó lấy lại thì nút an toàn là nút chính ở trên (SG-19); chạm ngoài / Back trả `null` | DLG-Done / Later / Skip / Delete, N13, N14, N15, C08w, C11, C12 | có |
| `showUndoSnackbar(context, title, subtitle, onUndo)` (2 tầng chữ, hàng nút "Đóng" · "Hoàn tác", `persist: true` – không tự tắt, `liveRegion`) | S03-*, G09, C12 | có |
| `AppTextField(label, hint, controller, errorText, keyboardType, maxLength, onChanged, icon, autofillHints, textInputAction)` (nhãn trên ô, `hint` hiện dưới ô với tiền tố "Ví dụ: ", lỗi: nền `errorContainer` + viền `error` + dòng ⓘ đỏ `liveRegion`, cao ≥ 72) | S02, S06, S12, N06, N09, C06, C08 | có |
| `FieldLabel(text, icon)` (nhãn 24 đậm trên ô / nhóm lựa chọn) · `FieldMessage.error` / `.hint` (dòng ⓘ dưới ô) · `exampleHint()` | mọi form | có |
| `SwitchRow(title, subtitle, value, onChanged, icon)` (cả hàng bấm được, "Đang bật / Đang tắt", `Semantics(toggled)`, cao ≥ 72; chữ > 1.5 thì công tắc xuống dòng) | S10, S12, N07, C08 | có |
| `ChoiceGroup<T>(options: [ChoiceOption(value, label, description, icon, previewScale)], value, onChanged, layout: ChoiceLayout.list / segmented)` (đang chọn: dấu tích + "Đang chọn" + nền `primaryContainer`; Semantics radio; mỗi ô cao ≥ 72, cách nhau 20; `previewScale` vẽ chữ mẫu đúng cỡ cho S01 / S10) | S01, S02, S06, S10, S12, N12, C01, C07 | có |
| `ReadAloudButton(onPressed, speaking)` ("🔊 Đọc to"; đang đọc: dòng "Đang đọc…" `liveRegion` + nút "Dừng đọc"). Widget không gọi TTS: ViewModel gọi `SpeechService` và trả `speaking` | S04, S14, S16 | có |
| `SuggestionCard(fromName, itemCount, previewTitles, onOpen, onDismiss)` (thẻ G12: "Mai gửi Bác 2 việc", tối đa 3 tên việc, "Chưa thêm vào lịch. Bác tự chọn.", "Xem gợi ý" + "Bỏ qua gợi ý" tuỳ chọn; cách đặt lên S03 ghi trong comment của widget) | S03 (F3 chỉ đặt widget, F12 làm nội dung) | có |
| `SectionCard(icon, title, child)` (khung thẻ trắng viền `outlineVariant`, bo 16; đầu thẻ icon 32 + tiêu đề `titleLarge` đọc là heading) – F8 bước 02 thêm | S10 (thẻ Cỡ chữ, thẻ công tắc); N06, F12 dùng được | có |
| `NavRow(icon, title, subtitle, onTap)` (hàng điều hướng dạng thẻ: ô icon 48 nền `primaryContainer`, chữ xuống dòng không cắt, › cuối hàng, cả hàng bấm, ≥ 72) – F8 bước 02 thêm | S10 (Cách dùng đơn giản, Thông tin của Bác, Lời nhắc, Dữ liệu trên điện thoại) | có |
| `SuggestionCard(fromName, itemCount, previewTitles, onOpen, onDismiss)` (thẻ G12: "Mai gửi Bác 2 việc", tối đa 3 tên việc, "Chưa thêm vào lịch. Bác tự chọn.", "Xem gợi ý" + "Bỏ qua gợi ý" tuỳ chọn; cách đặt lên S03 ghi trong comment của widget; S03 **không** truyền `previewTitles` / `onDismiss` – DT-33) | S03 (F3 chỉ đặt widget, F12 làm nội dung) | có |

Màn của mọi người **chỉ** dùng widget ở đây. Thiếu widget → báo Sanh, không tự làm bản riêng trong thư mục màn.

## 14. Lỗi, mất mạng, Crashlytics

- Service bắt exception của SDK → ném `AppException` (câu cho Bác, đã có `network`, `cancelled`, `unknown`). ViewModel chỉ đọc `userMessage`.
- Lỗi thật (lưu việc thất bại, upload PDF lỗi) → `CrashService.recordError(…, reason)` = non-fatal (F4, F7). Nút "Thử crash" chỉ ở khu demo F10.
- Mất mạng: Firestore offline persistence vẫn ghi được; màn lưu hiện ST-Loading-offline rồi ST-Saved khi có mạng, hoặc ST-Error sau thời gian chờ, giữ nguyên nội dung đang nhập (`lab2/flutter-handoff.md` › ST-Error).
- Mọi thay đổi có "Hoàn tác"; xoá / ngưng lịch phải hỏi lại và nói rõ hậu quả (NFR11).

## 15. Luật (bị chấm – đề Lab 3 mục 5)

1. Widget không gọi `FirebaseAuth.instance`, `FirebaseFirestore.instance`, `FirebaseAnalytics.instance`, `http`…
2. Logic nằm trong ViewModel / service, không nằm trong `build()`.
3. Mỗi màn tải dữ liệu có `UiState` riêng (Loading / Empty / Error / Data).
4. Service tiêm qua `providers.dart`; test ViewModel bằng `overrideWithValue(Fake…)`.
5. Không màu, cỡ chữ, khoảng cách viết cứng – chỉ dùng `lib/theme/` (F0 "Xong khi").
6. Câu chữ theo `lab2/AppStyleGuide.md` + `lab2/vocabulary.md`; luật thiết kế theo `lab2/rule.md`.

### F1 triển khai 02/11/2026

`UserProfile` tách khỏi `AppUser`. ProfileService tạo hồ sơ lần đầu bằng transaction,
không ghi đè role/onboarded đã có; stream theo UID. `/session` chờ auth/profile và
cho thử lại khi lỗi, `/account` xem tên/vai trò và xác nhận đăng xuất. UID thay đổi
sẽ reset Today/Role ViewModel cùng các repository theo phiên. SignOutViewModel
ngắt profile listener, xoá Firestore persistence rồi kết thúc Firebase/Google;
cache lỗi vẫn đăng xuất, lần đăng nhập tiếp theo phải xoá cache thành công.
Dữ liệu chưa đồng bộ có thể mất và được thông báo trước khi đăng xuất.

F2 gọi `markOnboarded(uid)` sau khi hoàn tất onboarding. F13/F14 vẫn là placeholder.
`role` và `pairedMomUid` chỉ điều hướng giao diện, không cấp quyền đọc lịch UID khác.
Google provider tạm tắt trên Console không tự ẩn nút; không đổi phương thức Auth.

### F10 triển khai 02/11/2026

`InboxViewModel` quản lý UiState, quyền và analytics; `FirebaseDemoViewModel`
quản lý RC realtime, upload tệp thử và Crashlytics. `/inbox`,
`/settings/firebase-demo`, điểm vào F10 ở `/settings/profile` và `/account`.
App quan sát foregroundNotificationProvider để hiện banner; router consume push
opened sau auth/profile guards. NotificationTarget chỉ nhận route nội bộ cho phép.
`MessagingService.onReceived` bổ sung để nhận foreground; bản Fake có stream rỗng.

Firestore `users/{uid}/notifications/{id}` = title/body/route/receivedAt(Timestamp),
backend ghi trước push, owner đọc/xóa. `users/{uid}/devices/{token}` = token,
updatedAt(server timestamp), platform(android); owner-only. Inbox limit 100 theo
receivedAt desc; hủy listener trước clearPersistence. Sender CLI dùng HTTP v1,
metadata recipient_uid/notification_id/route, system tray chỉ có nội dung chung.
Dọn token trước clearPersistence qua callback SessionDataService; cache vẫn được
xóa trong finally nếu cleanup FCM lỗi. Sender bỏ đăng ký cũ hơn 30 ngày.

`demoReportServiceProvider` dùng FirebaseReportService + renderDemoPdf riêng,
PDF tiếng Việt có DejaVu Sans và license. Không đổi reportServiceProvider của F7.
`FirebaseDemoEntry` là widget dùng chung cho F8 ghép vào form thật. AppButton
`wrapLabel=true` ở màn F10 cho phép xuống dòng tại textScaler=2.0.

Cập nhật sau phê duyệt: rules F10 đã deploy và RC version 1 đã có ba defaults;
bucket Storage vẫn chưa có. Giới hạn
và quy trình nghiệm thu: [f10-verification.md](f10-verification.md).

## Bổ sung Hiếu 04/11/2026 — F13/F14 và contract v2

Nguồn chi tiết và cách chạy: [hieu-implementation-guide.md](hieu-implementation-guide.md).

- `PairingService`: Fake và Firebase callable; `PairingViewModel` quản lý mã/busy/error. Grants, pointer mã và pairedMomUid chỉ backend ghi. Thu hồi grant không xoá tasks/completions.
- `CaregiverScheduleService`: templates + stream occurrence, create/change/undo; Fake/Firebase dùng cùng plan scope. `CaregiverScheduleViewModel` quản lý ngày/tuần/tháng, generation chống callback listener cũ. `CaregiverFormViewModel` giữ ba bước, xung đột giờ, idempotency và telemetry.
- `SuggestionService`: Fake/Firebase, send idempotent; receiver chỉ theo UID hiện tại. Backend resolve trong transaction. Màn demo F10 để test service, không thay màn G của Sanh.
- Task v2: startDate/endDate `YYYY-MM-DD`, weekly (weekdays 1–7), monthly (monthDays 1–31 và lastDayOfMonth), excludedDates, durationMinutes, revision, timezone UTC+7. Status thực theo ngày ở completions; status trên template luôn pending. `setStatus(id,status)` cũ chỉ tác động hôm nay UTC+7.
- V1 đọc tương thích có giới hạn được ghi trong guide; chưa migration cloud tự động. Settings/ProfileSetup đã có adapter Firebase, merge trên users/{uid}, không đổi chữ ký F2.
- Điểm vào: `/pairing/code` (Bác), `/caregiver/pair`, `/caregiver/schedule?view=day|week|month`, wizard `/caregiver/task/new[/repeat|/review]`, `/caregiver/task/sent`, `/caregiver/task/:id?date=YYYY-MM-DD`.
- Guard mặc định **tắt** theo yêu cầu demo; kiểm thử opt-in qua AUTH_GUARD. Rules không đổi thành public.

### Nhắc việc native — 04/11

ReminderService production đã chuyển sang LocalReminderService; ReminderRuntime
đồng bộ occurrence/completion theo UID khi start/resume và snapshot thay đổi.
Timezone UTC+7, cửa sổ 30 ngày/128 pending, inexact alarm; xem giới hạn và kiểm chứng
trong guide. Đăng xuất huỷ pending/active và chặn tap UID cũ. Fake giữ cho main_dev.
Template sau split có completionSourceId trỏ cha; đọc status theo ancestry có
chống vòng lặp, ưu tiên status trực tiếp của ID mới. Completions vẫn ở collection
cũ, không copy lịch sử và không mất trạng thái đã xong chỉ vì ID chuỗi đổi.
