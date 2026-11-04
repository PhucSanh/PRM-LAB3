# Công việc Hiếu — triển khai 03/11/2026

## Quyết định phiên làm việc

- Theo yêu cầu người dùng: **guard mặc định tắt**, mở `/today` để test demo. Không đổi Firebase rules thành public.
- `AUTH_GUARD=true` là tuỳ chọn kiểm thử nghiệm thu riêng; test auth tự bật bằng provider override.
- Commit theo mốc, ghi kết quả kiểm tra thật. Không coi test Fake là Firebase/thiết bị thật.
- Không bật billing, không tạo bucket hoặc tự bật Google provider. Không gửi thông báo cho người khác.

## Chạy

Từ thư mục `PRM393_Lab03_AnNhien`:

```bash
flutter pub get
flutter run -t lib/main_dev.dart  # demo Fake, không cần Firebase
flutter run -t lib/main.dart     # Firebase thật, guard vẫn tắt
flutter run --dart-define=AUTH_GUARD=true # chỉ khi cần nghiệm thu F1
flutter test test/auth_routing_test.dart test/account_view_model_test.dart test/f10_test.dart
```

## Mốc 1: demo và kiểm thử F1

Tách tuỳ chọn guard khỏi code comment; giữ mặc định false. Khôi phục logic auth/role/onboarding cho test opt-in; notification pending được xử lý độc lập khi demo. Không bật guard của bản demo. Test auth bật riêng nên không cần bỏ test hay thay expected cho qua.

Các phần tiếp theo và kết quả kiểm tra sẽ được bổ sung sau mỗi mốc.

## Mốc 2: contract lịch v2 và backend ghép nối/gợi ý

- TaskItem bổ sung startDate/endDate, weekly/monthly, weekdays/monthDays/cuối tháng, excludedDates, duration và revision. Ngày không tồn tại (31/2) không được tạo; ngày 31 hằng tháng bỏ qua tháng thiếu ngày 31. Giờ lịch cố định UTC+7 (`Asia/Ho_Chi_Minh`).
- `TaskRepository` giữ chữ ký cũ. `save()` tự thêm ngày bắt đầu nếu caller F2 chưa truyền; `tasksForDay()` lọc đúng ngày; `setStatus()` ghi `completions/{taskId}_YYYY-MM-DD`, không đổi trạng thái cả chuỗi. Caller chọn ngày khác hôm nay cần API riêng, không dùng setStatus cũ.
- Đọc v1 vẫn được; `someDays` cũ thiếu weekdays không tự đoán ngày. Daily v1 thiếu ngày vẫn chạy mỗi ngày, once v1 thiếu ngày không hiện. Save tiếp theo ghi v2; không có migration hàng loạt lên cloud.
- Sửa 1 lần: loại ngày đó khỏi chuỗi và tạo task once. Sửa từ lần này: kết thúc chuỗi cũ trước ngày chọn rồi tạo chuỗi mới. Sửa tất cả: giữ ID. Ngưng: endDate trước ngày chọn, có thể sớm hơn startDate để biểu diễn chuỗi chưa bắt đầu đã ngưng. Không xoá completions. Undo kiểm tra revision để không ghi đè sửa đổi mới của máy khác.
- SettingsService và ProfileSetupService có adapter Firebase, merge theo UID; giữ interface F2 để Hương không phải đổi ViewModel. UI áp dụng setting toàn app vẫn thuộc F8.
- Backend `firebase/functions`: create/redeem/revoke pairing, send/resolve suggestion, undo dismiss, trigger inbox → FCM. Auth qua callable SDK, quyền Admin chỉ ở backend. Mã một lần, TTL 10 phút, 5 lần thử/10 phút theo UID; mã mới vô hiệu mã trước, mã không đọc trực tiếp từ client. Quyền grant được thu hồi khi đổi mẹ hoặc ngưng ghép nối.
- Gợi ý default chờ mẹ nhận. Backend nhận tất cả/từng phần, đổi giờ, bỏ qua/hoàn tác bỏ qua; tạo tasks và cập nhật status cùng transaction. Request ID cố định tránh tạo trùng khi retry. Trạng thái bỏ qua và nội dung gợi ý chỉ Bác đọc; không gửi phản hồi bỏ qua cho Con cháu.
- Rules vẫn private dù guard UI tắt; grants/pairings/suggestion writes chỉ backend. Caregiver có grant được quản lý lịch của mẹ, không được tự ghi completions.

Kiểm chứng mốc: **9 tests Dart contract/scope/pairing/suggestion PASS**, **19 tests backend + Firestore/Storage Emulator PASS, 0 skip**. Bộ auth đang được cập nhật fixtures vì route F14 đã chuyển từ placeholder sang màn thật. Chưa deploy rules/functions mới lên project thật.

Tài liệu API tham khảo: [Firebase callable](https://firebase.google.com/docs/functions/callable), [Firestore transaction](https://firebase.google.com/docs/firestore/manage-data/transactions).

## Mốc 3: màn F13/F14 và demo hoàn chỉnh

- Thay placeholder C02/C02e, C03–C10 bằng màn thật và ViewModel Riverpod. C11/C12 là lựa chọn phạm vi và xác nhận ngưng, không thêm route giả.
- Ngày/tuần/tháng dùng dữ liệu live qua stream; chọn ngày để xem việc, tải lỗi có Thử lại. Form ba bước giữ bản nháp, kiểm tra tên/ngày/lặp, bấm lặp bị chặn, lỗi lưu giữ dữ liệu để retry.
- Kiểm tra trùng giờ theo toàn thời gian giao nhau của hai lịch, tính cả qua nửa đêm và các ngày ngoại lệ. Dùng chu kỳ lịch Gregorian 400 năm sau ngoại lệ cuối, không cắt ở 12 tháng.
- Mã ở máy Bác cần xác nhận trước khi tạo, có đếm hết hạn. Bác xem người thân đã ghép nối và thu hồi quyền; Con cháu cũng có thể ngưng ghép nối.
- Mặc định bật “Mẹ nhận trước khi thêm”. Khu thử F10 `/settings/firebase-demo/suggestions` cho phép nghiệm thu nhận từng việc, đổi giờ, bỏ qua và Hoàn tác. Màn G01–G12 đầy đủ vẫn thuộc Sanh; notification tới route G03 vẫn cần màn của Sanh. Không ghi nhận F12 đã xong thay thành viên khác.
- `main_dev.dart` override toàn bộ dịch vụ liên quan, vào `/demo`; dữ liệu Fake chia sẻ giữa gửi/nhận và lịch nên nhận gợi ý thực sự thêm vào lịch demo. Không cần sửa router để mở màn; dùng `INITIAL_ROUTE`.
- Có điều chỉnh responsive khi tái sử dụng F0: mã nhập bằng một ô có nhãn, nhóm ngày/tuần/tháng wrap khi chữ lớn, nhóm thói quen hai cột chuyển một cột. Các bản Figma gốc đã đọc; chưa coi UI pixel-perfect hoặc prototype Figma đã được cập nhật.
- Sửa nhẹ FeaturePlaceholder dùng vùng cuộn vì test đã phát hiện tràn ở Cài đặt 360dp/chữ 200%; không triển khai F8 thay Sanh.
- Test shell/route cũ từng kỳ vọng mã placeholder ở màn đã triển khai; nay dùng fixtures Fake đầy đủ, chỉ giữ bảng placeholder cho màn thật sự chưa làm. Test auth opt-in vẫn kiểm tra guard, bản demo mặc định false.

Kết quả tại mốc: **305 unit/widget tests PASS**, trong đó có flow gửi → mẹ nhận → lịch cập nhật, nhánh trùng giờ/lỗi/retry, và F13/F14 ở 360/412dp với chữ hệ thống 1x/2x. APK debug demo build PASS. Đang kiểm thử native Firebase trên Android Emulator; chưa dùng kết quả này để khẳng định cloud production hoặc ARTEMIS.

## Mốc 4: hạ tầng kiểm chứng và CI

### Kiểm tra tự động một lệnh

Cần Flutter 3.47.3/Dart 3.13, Node 22, Java 21+; từ thư mục app:

```bash
bash scripts/check-hieu.sh
```

Lệnh chạy analyzer, toàn bộ Flutter tests, cài dependency Node từ lockfile,
kiểm tra syntax Functions, rồi chạy rules/backend trên project `demo-an-nhien`.
Đóng Firebase Emulator đang mở trước khi chạy (cổng 8080/9199 cần trống).
Không đụng project production. `npm test --prefix firebase/functions` riêng cần
FIRESTORE_EMULATOR_HOST; dùng script trên để dựng môi trường đúng.

### Chạy giao diện Fake (không cần tài khoản/mạng)

```bash
flutter run -t lib/main_dev.dart
flutter run -t lib/main_dev.dart --dart-define=INITIAL_ROUTE=/caregiver/schedule
```

Hub `/demo` có các lối vào. Mã demo là `123456`. Trong lịch mẹ, tạo việc ba bước,
giữ “Mẹ nhận trước khi thêm”, gửi. Về hub → Nhận lịch gợi ý, chọn việc/giờ và nhận.
Mở lịch mẹ để thấy việc mới. Dữ liệu mẫu chỉ nằm trong RAM và mất khi restart.

### Firebase local thật trên hai Android Emulator

Đây là SDK Auth/Firestore/Functions thật nhưng server là Emulator, không phải cloud.
Bản `main_emulator.dart` dùng **named Firebase app** project `demo-an-nhien`,
key tổng hợp chỉ đúng định dạng, không phải key sử dụng được trên Firebase thật.
Tài khoản anonymous được tạo local; không cần bật Google provider của project thật.

Terminal 1 (giữ chạy):

```bash
npm ci --prefix firebase/functions
npm ci --prefix firebase/tests
./firebase/tests/node_modules/.bin/firebase emulators:start --project demo-an-nhien --only auth,firestore,functions
```

Terminal 2, seed catalog local:

```bash
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node firebase/scripts/seed-emulator.cjs
```

Hai AVD đang boot (thay ID bằng `flutter devices`):

```bash
flutter run -d emulator-5556 -t lib/main_emulator.dart --dart-define=DEMO_ROLE=elder
flutter run -d emulator-5558 -t lib/main_emulator.dart --dart-define=DEMO_ROLE=caregiver
```

Máy Bác: Tài khoản → Mã ghép nối → Đồng ý, tạo mã. Máy Con: nhập mã và xem lịch.
Tạo gợi ý, rồi trên máy Bác vào Tài khoản → Nhận lịch gợi ý (khu thử). Nhận việc,
đổi giờ hoặc bỏ qua. Ngưng ghép nối ở một trong hai máy rồi kiểm tra mất quyền.
Tắt guard mặc định vẫn áp dụng. HTTP local chỉ được phép trong Android debug manifest.

Mặc định host từ AVD là `10.0.2.2`. Máy thật trong LAN dùng
`--dart-define=EMULATOR_HOST=<IP-máy-tính>` và cấu hình emulator bind/LAN phù hợp;
chỉ dùng trên mạng thử nghiệm do nhóm kiểm soát. Đổi role trên cùng app/AVD cần xoá
**dữ liệu app local** hoặc dùng AVD khác; không tự đổi vai trò tài khoản đã chọn.

### Native integration tự dựng backend

Đóng backend Terminal 1 trước, giữ Android Emulator:

```bash
bash scripts/native-emulator-check.sh emulator-5556
```

Test tạo ba named Firebase apps/tài khoản khác nhau trên cùng AVD: mẹ/con/người lạ.
Kiểm tra ghép nối, sai/reuse mã, profile/settings, caregiver CRUD, nhận gợi ý một
phần/đổi giờ/idempotency, status theo ngày, sửa/undo và revoke. Không coi đây là
hai máy vật lý hoặc bài ARTEMIS. Log và số lần chạy thực tế ghi trong phần kết quả.

### GitHub

`.github/` nằm ở **gốc repository**, bên ngoài thư mục Flutter. CODEOWNERS dùng
username Hiếu từ git config và owner repo từ origin; không đoán username Hương/Khang.
CI `verify.yml` chạy analyze/test/APK và Node/Emulator khi có PR hoặc push main.
Chỉ kiểm tra syntax YAML local; chưa có GitHub Actions run vì chưa push.

AI review là opt-in: chủ repo thêm secret `OPENAI_API_KEY`, đặt repository variable
`AI_REVIEW_ENABLED=true`, rồi mở PR nội bộ. Action dùng sandbox read-only và drop-sudo,
chỉ đọc base checkout + diff, không chạy code PR; kết quả nằm trong Summary của check.
Không bật biến/secret, không gọi API và không phát sinh lượt review trong phiên này.
Không gửi comment cho người khác. Hướng dẫn theo [OpenAI Docs](https://learn.chatgpt.com/docs/github-action).

SDK backend đã nâng firebase-admin 14.5.0/firebase-functions 7.4.0; kiểm thử lại trên
Node 22. npm audit còn 6 advisory moderate transitive (glob/minimatch qua Google
SDK/rimraf); không ép override major ngoài contract của upstream. Không có high/critical
trong audit đã chạy; không coi điều đó là bảo đảm toàn bộ hệ thống an toàn.

## Mốc 5: ReminderService Android thật

Production `main.dart` đã dùng LocalReminderService và ReminderRuntime thay Fake:

- Xin/kiểm tra quyền Android; lời nhắc thử N01 hiện qua NotificationManager thật.
- Lập lịch UTC+7 cho occurrence chưa xong/chưa bỏ qua, loại ngày ngoài recurrence.
  Đồng bộ khi mở app, trở lại foreground hoặc tasks/completions đổi trên Firestore;
  lịch từ máy Con được đặt nhắc trên máy Bác khi máy Bác đồng bộ.
- Hẹn tối đa **128 occurrence gần nhất trong 30 ngày**. App cần được mở lại để
  gia hạn cửa sổ này; không cam kết chạy lịch vô hạn nếu app không mở hơn 30 ngày.
- Dùng inexactAllowWhileIdle, không xin SCHEDULE_EXACT_ALARM; Android có thể dời
  thời điểm khi Doze/tiết kiệm pin. Không hứa giao đúng phút trong mọi chế độ máy.
- Huỷ theo task, dời chỉ occurrence hôm nay (giữ những ngày sau), xoá pending/active
  khi đăng xuất. Payload gắn UID, không mở lời nhắc tài khoản cũ; tray không chứa
  tên việc riêng. Tap mở route F6, bản thân màn F6 vẫn thuộc Khang.
- Native init/tap events chỉ bật ở entrypoint Firebase; demo Fake và test fixtures
  tiếp tục không gọi plugin thật. main_emulator dùng SDK local; để thử độc lập
  notification plugin dùng integration test dưới đây.
- Android có drawable notification riêng, desugaring và receivers để khôi phục
  alarm sau reboot. Chưa chạy reboot/Doze/cold-start tap trên máy vật lý.

Test planner kiểm tra UTC+7, dedupe, giới hạn count, trạng thái, ngày và UID. Native
plugin trên AVD API 37 đã kiểm tra showTest hiện trong active notifications,
zonedSchedule tạo pending, snooze, cancel, clearAll. Test này không phải chứng
minh thông báo đã được Android giao đúng phút lúc ngủ máy.

```bash
bash scripts/native-notification-check.sh emulator-5556
# Nếu adb chưa có trong PATH:
ADB="$ANDROID_HOME/platform-tools/adb" bash scripts/native-notification-check.sh emulator-5556
```

Script chờ Flutter cài APK test rồi cấp quyền thông báo **chỉ trên AVD được chọn**,
chạy test và trả mã lỗi thật. Flutter có thể gỡ app test sau khi kết thúc.
Bản app thông thường xin quyền qua giao diện F2, không tự cấp quyền bằng adb.

Bổ sung CR-H03: khi tách chuỗi, `completionSourceId` trỏ ID cha. Đọc status đi qua
chuỗi cha nếu chưa có status trên occurrence mới, có chống vòng lặp. Status ghi
trên task mới luôn ưu tiên, gồm cả pending sau Hoàn tác. Nhờ đó sửa lịch của ngày
đã xong không làm ngày đó trở lại Chưa làm. Mỗi lần tách giữ các template cha và
completion cũ; không cần copy hàng loạt completion trong transaction.

## Phần cần nghiệm thu tiếp (không đánh dấu done)

1. Production: deploy Functions + rules v2 sau khi chủ dự án chốt môi trường/billing.
   Không deploy Storage khi chưa có bucket. Các lệnh dưới là hướng dẫn, chưa chạy:

   ```bash
   ./firebase/tests/node_modules/.bin/firebase deploy --project prm393-145c9 --only firestore:rules,functions
   ```

   Deploy cả bộ Functions gồm pairing, suggestion và inbox trigger. Không chuyển
   rules sang public khi guard UI đang tắt. Sao lưu/export dữ liệu trước migration
   nếu nhóm đã có task v1 thật; đọc tương thích không phải migration hoàn chỉnh.
2. Google Sign-In/cancel/logout và đổi tài khoản trên Firebase production. Native
   test local dùng Auth Emulator anonymous, không thay Google provider/OAuth/SHA.
3. FCM foreground/background/cold start, token đổi/thu hồi, notification tap thật,
   Crashlytics crash/non-fatal/custom keys, Remote Config đổi từ Console và ảnh
   DebugView ≥7 business events. Chưa có bằng chứng cloud mới trong phiên này.
4. Storage/billing/PDF tuần: renderer lịch F7 cần Hương inject; demo PDF không thay
   xuất lịch tuần. Không tự bật billing, tạo bucket hay dùng link upload giả.
5. ARTEMIS của nhóm: fixture còn TODO/skip. Các test Flutter/native đã chạy không
   đổi tên thành ARTEMIS. Cần chạy bài ARTEMIS thực mỗi test ≥3 lần và lưu evidence.
6. Figma: code đã đọc context gốc C02/C03/C06/C07/C08/C10; còn chốt/cập nhật các
   thay đổi responsive đã nêu. Chưa sửa file Figma hoặc hoàn thiện prototype F10.
7. GitHub: chưa push/mở PR/chạy Actions, chưa bật AI review ngoài repo. Commit
   CR-H01 có tự review local; điều kiện “review trên PR” vẫn cần link PR thật.
8. UI G01–G12 của Sanh và các màn F3–F9/F11 của thành viên khác giữ phạm vi cũ;
   đây là phần Hiếu và adapter, không ghi nhận toàn bộ Lab 3 đã hoàn thành.

## Đọc code để trình bày với thầy

- UI → `CaregiverFormViewModel` → interface `CaregiverScheduleService` hoặc
  `SuggestionService`; Firebase chỉ nằm ở adapter/backend. Fake override tại
  providers để test không phụ thuộc mạng.
- `CaregiverScheduleViewModel` có Loading/Empty/Error/Data; listener cũ bị chặn
  bằng generation khi đổi ngày hoặc phiên. Form có busy/error và giữ bản nháp.
- Rules dùng grant ở `users/{momUid}/caregivers/{childUid}`; role/pairedMomUid chỉ
  điều hướng, không thay quyền. Pairing transaction cấp grant sau khi consume mã.
- `resolveSuggestion` tạo task + đổi trạng thái atomically. Request retry cùng
  nội dung không tạo trùng; request ID cũ với nội dung khác báo lỗi.
- Tiến độ theo ngày nằm riêng; `completionSourceId` giữ lịch sử khi split. Revision
  ngăn Undo ghi đè một sửa đổi mới. Undo không phải ghi đè tuỳ ý snapshot cũ.
- ReminderRuntime theo dõi dữ liệu của UID hiện tại để đặt alarm Android; FCM là
  kênh thông báo server khác. Notification inbox được ghi trước push.
- Test Fake, Emulator, native Android và cloud Console là các lớp bằng chứng khác
  nhau. Bảng nghiệm thu chỉ ghi lớp đã thực sự chạy.

## Kết quả và artifact bàn giao

Bảng bằng chứng: [evidence/hieu/verification.md](evidence/hieu/verification.md).
Source đã qua analyzer sạch, 308 unit/widget tests, 19 rules/backend Emulator tests,
ít nhất ba lượt native Firebase thành công và native notification plugin test.
Lượt native cuối kiểm tra thêm CR-H03; ảnh AVD nằm trong thư mục evidence.

Tạo lại APK demo và APK Firebase (guard mặc định vẫn tắt):

```bash
flutter build apk --debug -t lib/main_dev.dart
cp build/app/outputs/flutter-apk/app-debug.apk build/app/outputs/flutter-apk/an-nhien-demo-debug.apk
flutter build apk --debug -t lib/main.dart
```

Demo: `build/app/outputs/flutter-apk/an-nhien-demo-debug.apk`.
Firebase: `build/app/outputs/flutter-apk/app-debug.apk`.
APK/debug build nằm trong thư mục ignored, không commit binary lớn vào Git.

Các mốc đã commit: `61ece98` (F1/demo), `11876cb` (backend), `1796edb` (F13/F14),
`b3a00a0` (CI/CR/native harness). Mốc nhắc việc native và CR-H03 nằm ở commit bàn giao
sau cùng; dùng `git log -5 --oneline` để xem SHA thay vì ghi SHA tự tham chiếu trong file.
