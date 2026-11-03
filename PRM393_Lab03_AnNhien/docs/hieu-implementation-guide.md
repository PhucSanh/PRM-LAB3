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
