# F10 — Firebase, thông báo và khu demo

Ngày 02/11/2026. Chủ: Hiếu. Trạng thái: đã triển khai phần code F10 dưới đây;
chưa đủ điều kiện nghiệm thu Firebase thật/ARTEMIS. Nhánh hiện tại `feat/noti-demo`.
Phân công 02/11 là nguồn hiện hành; bảng chủ feature trong README cũ không thay thế phân công.

## Phần đã triển khai

- `/settings/profile` có điểm vào F10, ghi rõ phần sửa hồ sơ F8 đang chờ Sanh.
  Widget dùng chung `FirebaseDemoEntry` để Sanh đặt vào form thật. `/account` cũng
  có lối vào để thử khi onboarding của Hương chưa hoàn tất.
- `/settings/firebase-demo`: đọc 3 giá trị Remote Config, nhận cập nhật realtime,
  tải lại, tạo và upload PDF thử, tiến độ, URL thật sau upload, thông báo lỗi.
  PDF ghi rõ là tệp thử, không giả lập lịch tuần F7. Có font tiếng Việt kèm license.
- Crashlytics nhận lỗi thật của thao tác tạo/upload tệp, custom keys `feature=F10`,
  `operation=upload_demo_file`. Nút test crash có xác nhận và nhắc mở lại app.
  Không coi test Fake hoặc lỗi chủ động là bằng chứng non-fatal thật trên Console.
- `/inbox`: Loading/Empty/Error/Data, Thử lại, xin quyền, nhánh từ chối, mở nội dung.
  Danh sách Firestore tối đa 100 mục, mới nhất trước, theo UID, hủy listener khi
  đóng màn/đăng xuất. Firestore cache giữ thông báo qua lần mở app; đăng xuất xóa cache.
- FCM: foreground có banner với nút Xem; background dùng `onMessageOpenedApp`,
  cold start dùng `getInitialMessage`. Inbox tồn tại ngay cả khi thông báo chưa
  được bấm vì bên gửi lưu Firestore **trước** khi gửi push. Không cần client
  background handler để ghi inbox và không mở quyền client tạo thông báo.
- Payload phải có `recipient_uid` khớp tài khoản đang dùng. Route chỉ nhận `/inbox`,
  `/reminder/<id>`, `/today/suggestions/<id>`; URL ngoài/route khác về inbox.
  Auth/role/onboarding guards vẫn áp dụng. Màn F6/F12 đích hiện còn placeholder.
- Đăng ký token sau khi có quyền và khi khôi phục phiên; cập nhật timestamp khi
  token đổi. Trước xóa cache, cố gắng vô hiệu token và xóa đăng ký máy; dù cleanup
  FCM lỗi vẫn chạy xóa cache rồi kết thúc auth theo F1. Không ghi token vào log.
- `firebase/scripts/send-notification.cjs`: công cụ cho người vận hành đã đăng nhập
  Firebase CLI, ghi inbox trước, gửi HTTP v1 tới đăng ký còn hạn 30 ngày, dọn đăng
  ký khi FCM trả UNREGISTERED. Không có server credential trong app. Không chạy
  gửi tin tới người dùng trong lần triển khai này. Nội dung trên system tray là
  câu chung, nội dung riêng chỉ đọc từ inbox qua rules. Script có kiểm tra syntax;
  **chưa** được nghiệm thu gửi HTTP v1 thật.
- Giữ transport token cũ có chủ đích để tương thích HTTP v1 script: SDK 17.0.1
  còn hỗ trợ `getToken/onTokenRefresh/deleteToken` nhưng đã deprecated. Migration
  FID `register/onRegistered` cần đổi cả sender; không trộn FID với legacy token.
- Rules mới: owner được đọc/ghi/xóa `users/{uid}/devices/{token}`, validate đúng
  token ID, platform, server timestamp và trường cho phép. Inbox chỉ backend ghi.
  Rules mới được kiểm thử Emulator và đã deploy production sau khi người dùng đồng ý; xem cập nhật cloud bên dưới.

## Thiết kế và kiến trúc

Đã dùng component và font Be Vietnam Pro có sẵn trong Figma; layer chỉnh sửa được,
không dùng ảnh chụp làm UI. Đã kiểm tra ảnh màn thiết kế, không tràn/cắt chữ.

- [Khu thử tính năng](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=153-224)
- [Hộp thông báo](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=153-264)
- [N06 thêm nút F10](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-187)

Chưa nối tương tác prototype giữa các frame F10. Phần sửa hồ sơ F8 chưa implement.
Flutter theo MVVM + Riverpod; widget chỉ đọc ViewModel, service được tiêm tại
providers.dart. AppButton có `wrapLabel` opt-in cho chữ 200%, không đổi mặc định
các màn khác. Dùng khoảng cách/theme/widget chung; không thêm màu/cỡ chữ cứng.

Các file `docs/lab2/` được tham chiếu nhưng chưa tồn tại trong repo này; lần làm
này đọc bản gốc ở `../Lab2-prm/` (tính từ thư mục workspace), không sửa bản Lab 2.

## Kiểm tra

- `flutter test`: PASS 25 tests (16 trước F10 + 9 mới).
- F10 tests: inbox Loading/Empty/Data/Error/Retry, permission denied, target allowlist,
  upload thành công/lỗi và không bịa URL, Remote Config lỗi, PDF thật có font,
  360/412 dp với textScaler 2.0, hủy hộp xác nhận không gọi crash.
- Routing test: push hợp lệ mở đúng route, URL ngoài về inbox, push không vượt auth gate.
- `npm test --prefix firebase/tests`: PASS 9 nhóm Emulator tests (7 cũ + 2 F10).
- `node --check firebase/scripts/send-notification.cjs`: PASS.
- `flutter analyze`: PASS, không có issues.
- `flutter build apk --debug`: PASS; APK tại `build/app/outputs/flutter-apk/app-debug.apk`.
  Gradle còn warning tương thích KGP tương lai từ các Firebase plugins có sẵn; không phải build failure.
- `adb devices`: không có thiết bị. Không chạy/khẳng định ARTEMIS ≥3 lần.

## Kiểm tra cloud chỉ đọc và phần cần làm tiếp

Đã đọc Firebase project `prm393-145c9` bằng phiên CLI quản trị, không in credential:
Remote Config chưa có 3 key `snooze_minutes`, `voice_input_enabled`,
`home_max_upcoming`; danh sách bucket Storage rỗng. Chưa publish RC, deploy rules,
khởi tạo bucket, bật billing hoặc thay API key/provider.

1. Theo firebase-setup.md mục 7/12, publish RC khi nhóm đồng ý và deploy riêng
   Firestore rules đã kiểm thử. Storage chỉ deploy sau khi được cho phép và có bucket;
   không bật billing tự động. App vẫn đọc defaults/cache khi fetch RC lỗi.
2. Nếu chấp nhận Blaze: chủ dự án bật billing/tạo bucket và cấu hình Storage, sau
   đó deploy storage.rules. Nếu không, chốt phương án thay thế với thầy trước.
3. Bật lại Google provider theo chủ dự án; dùng Android với SHA được phép. Kiểm
   chứng quyền/từ chối, token, đổi tài khoản, inbox qua restart, foreground/background/
   cold start, bấm mở đúng route. Firebase Console test push riêng không ghi inbox:
   để kiểm tra inbox bền vững phải dùng trusted sender.
4. Publish thay đổi RC và quan sát UI. Upload thành công, lỗi upload thật →
   non-fatal/custom keys; test crash → mở lại app → đợi Console ghi nhận.
5. Chụp evidence mỗi dịch vụ, ít nhất 7 events theo analytics-plan. Event F10
   bổ sung không thay cho 7 business events ★ của cả nhóm. Không tạo ảnh Console giả.
6. Chạy ARTEMIS mỗi test ≥3 lần sau khi fixture ARTEMIS của Hương hoạt động.

Firebase service dùng chung chưa có contract thống nhất (Settings F8, Suggestion
F12, Task occurrence, renderer lịch tuần F7) giữ blocker như audit, không coi F10
lần này đã tự hoàn thành các feature đó. Backend tự động gửi FCM khi có suggestion
cần tích hợp sau contract F12/F13; script vận hành không thay trigger đó.

## Chạy sender sau khi thiết bị đã đăng ký

Tạo payload JSON ngoài Git, dùng UID thật của tài khoản thử do nhóm sở hữu:

```json
{"id":"f10-demo-01","recipientUid":"UID_CUA_TAI_KHOAN_THU","title":"Thông báo thử","body":"Bác đã nhận được thông báo.","route":"/inbox"}
```

```bash
node firebase/scripts/send-notification.cjs prm393-145c9 /tmp/f10-payload.json --send
```

ID trùng ghi đè một mục inbox, không đảm bảo push chỉ gửi một lần. Sender phải có
quyền Firestore + FCM ở project chỉ định. Không đưa nội dung riêng/token vào analytics.

Tham khảo: [FCM Flutter receive](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages),
[quản lý đăng ký](https://firebase.google.com/docs/cloud-messaging/manage-tokens).

## Cập nhật cloud sau phê duyệt — 02/11/2026

Người dùng đã đồng ý publish ba giá trị mặc định và deploy riêng Firestore rules.

- Remote Config project `prm393-145c9`, version **1**: `snooze_minutes=10`
  (NUMBER), `voice_input_enabled=true` (BOOLEAN), `home_max_upcoming=6` (NUMBER).
  Publish có ETag, giữ template hiện có; đọc lại đã xác minh đúng cả ba key/type/value.
- `firebase deploy --project=prm393-145c9 --only firestore:rules --non-interactive`:
  compile PASS, released to `cloud.firestore`, deploy complete.
- Đọc lại active ruleset bằng Rules API và so sánh với file local: PASS, khớp chính xác.
- Không thay billing, không tạo bucket, không deploy Storage, không đổi Google provider/API key.

Các dòng mô tả RC/rules chưa publish ở phần kiểm tra trước đó là trạng thái lịch sử.
Bước 1 phần cloud đã hoàn tất cho RC và Firestore. Còn bucket Storage, thiết bị
Android, Console evidence, ARTEMIS và các contract dùng chung như đã ghi.
