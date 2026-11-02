# Kết quả xác minh Firebase – 02/11/2026

Đây là kết quả đã chạy trên máy hiện tại, không phải tuyên bố hoàn thành tích hợp production.

| Hạng mục | Kết quả | Bằng chứng / giới hạn |
|---|---|---|
| Git trước chỉnh sửa | PASS | `git status --short` trống |
| Phiên bản SDK | PASS | `flutter --version`: Flutter 3.47.3 stable, Dart 3.13.3; phù hợp SDK constraints trong lockfile |
| Sinh Android platform | PASS | `flutter create . --org com.annhien --project-name an_nhien --platforms android --no-pub`, exit 0. Giữ source hiện có; xóa counter test mới sinh, khôi phục lockfile trước pub get |
| Kiểm tra generated files | PASS | Đọc Gradle/settings/properties, manifests, activity, XML resources, metadata và wrapper; kiểm tra định dạng/kích thước PNG và nội dung JAR. Chưa chạy Android UI |
| `flutter pub get` | PASS | Exit 0, dependencies resolved |
| Cài 9 Firebase packages | PASS | `flutter pub add ...`, exit 0. Giữ flutter_riverpod 3.4.3 và go_router 18.1.2 |
| Baseline `flutter analyze` | FAIL (đã sửa) | Warning invalid_null_aware_operator ở FakeTaskRepository; sửa một biểu thức khởi tạo list |
| Baseline `flutter test` | FAIL (đã sửa test) | Test gọi load trong khi build cũng lên lịch load, dispose container trước Future thứ hai hoàn thành |
| `flutter analyze` sau sửa | PASS | `No issues found!`, exit 0. Loại trừ Dart templates trong node_modules khỏi app analysis |
| `flutter test` sau sửa | PASS | 3 tests: hai Today tests + một auth routing test; `All tests passed!` |
| Auth-based routing bằng Fake | PASS | Test widget xác minh chưa đăng nhập → /sign-in; đăng nhập → /today; đăng xuất → /sign-in. Không sửa router hoặc ViewModel |
| Android toolchain | PASS | SDK tại /data/qtram/android-sdk, platform 36/build-tools 36.0.0/NDK 28.2.13676358. `flutter doctor -v`: No issues found, licenses accepted |
| Android debug APK | PASS | `flutter build apk --debug` exit 0, assembleDebug 681.0s ở lần build đầu. Artifact: build/app/outputs/flutter-apk/app-debug.apk (~165 MiB), versionName 0.1.0/versionCode 1 |
| APK package / signature | PASS | aapt2 xác nhận com.annhien.an_nhien, compileSdk 36. apksigner verify thành công; SHA-1 và SHA-256 khớp certificate đã đăng ký Firebase |
| Native Firebase/OAuth resources | PASS | processDebugGoogleServices sinh app ID/project ID/default_web_client_id khớp JSON thật và web OAuth client |
| FlutterFire cấu hình thật | PASS | CLI đã đăng nhập; chọn dự án PRM393/prm393-145c9. CLI configure exit 0, tạo options/JSON và Google Services 4.4.4 + Crashlytics 3.0.7 plugins; config app/project/key/sender được đối chiếu khớp |
| Google provider / SHA / OAuth config | PASS | Người dùng bật Google; đã đăng ký SHA-1/SHA-256 debug qua CLI và refresh JSON, có client types 1 và 3 |
| Firestore provisioning / rules deployment | PASS | Người dùng phê duyệt. Tạo Standard/Native (default), asia-southeast1, freeTier=true. Deploy firestore:rules exit 0; rules compiled/released |
| Firestore catalog bootstrap | PASS | 9 habits tạo thành công và đọc lại bằng CLI quản trị. Lần chạy lại: 0 created, 9 verified. Không coi đây là xác minh app-user authentication |
| Firestore deny anonymous trên cloud | PASS | REST GET habits/move với public client API key nhưng không có user token trả 403 PERMISSION_DENIED |
| Firebase Core initialization trên Android | BLOCKED | Đã có config thật và SDK; main dùng generated options. Chưa chạy trên thiết bị Android nên chưa báo runtime PASS |
| Google Sign-In / Sign-Out thật | BLOCKED | Config/project/provider/SHA/OAuth đã hoàn tất. Chưa có Android device/emulator để thử tương tác đăng nhập và đăng xuất thật |
| Firestore read/write với user thật | BLOCKED | Dự án/database/rules/catalog đã sẵn sàng. Chưa đăng nhập app-user trên Android; admin bootstrap không thay thế app-user read/write verification |
| Task scheduling / completion | BLOCKED | Thiếu date, weekdays, timezone, occurrence status. Adapter chủ động báo chờ schema; chưa sửa shared model |
| Analytics / Crashlytics / Remote Config / FCM runtime | BLOCKED | Adapter và startup hooks đã viết, analyzer PASS; project đã có; chưa có Android device để kiểm tra Console, token, crash hoặc thông báo |
| Storage upload thật | BLOCKED | Chờ renderer PDF từ F7, dự án/bucket và xác nhận gói Blaze; chưa tạo URL production |
| Emulator Security Rules | PASS | `npm test --prefix firebase/tests` với Node 22.23.4 / Java 21: 6 tests, 6 pass, 0 fail; script exit 0. Firestore emulator 1.22.0, Storage rules runtime 1.1.3. Các log PERMISSION_DENIED là ca kiểm tra bị từ chối theo dự kiến |
| `git diff --check` | PASS | Exit 0 |

## Phạm vi test và sửa lỗi

Today test mới chờ state tải tự động kết thúc thay vì gọi load chồng lên build; override task, analytics và crash bằng Fake. ViewModel không đổi. Routing test dùng FakeAuthService để kiểm tra sessionProvider/router đang có, không thay thế việc thử Google login thật.

Rules tests đặt tại `firebase/tests/rules.test.mjs`, dùng Firebase Emulator Suite với project demo, không truy cập production. Bao gồm owner/stranger/anonymous, validation field/enums/type/extra fields, contact không cấp quyền, client không tạo được caregiver grant, sender giả, owner-only status transition, revoke grant, catalog read-only, backend-only notifications, deny-by-default và Storage PDF ownership/type/size/extension/delete.

## Những phần chưa hoàn thành

- Firebase config/project/CLI login/Google provider/SHA đã hoàn tất; cần xác minh runtime trên thiết bị.
- Android SDK đã cài; chưa có thiết bị Android hoặc emulator có Google Play services.
- Thống nhất schema lịch/occurrence với nhóm trước khi viết truy vấn ngày và mutation trạng thái.
- Thống nhất contract stream để ViewModel dùng realtime; hiện Family có snapshots adapter nhưng UI giữ interface Future.
- Trusted pairing backend cấp/revoke caregiver grant; rules không mở quyền ghép nối từ client.
- Suggestion payload đầy đủ, undo/accept một phần và liên kết occurrence chưa thiết kế; rules hiện chỉ bảo vệ transport tối thiểu được mô tả trong setup doc.
- Profile/role first-login persistence và các feature riêng không được tự thêm ngoài phạm vi interface hiện có.
- Renderer PDF từ F7; Cloud Storage cần Blaze theo tài liệu Firebase hiện hành. Chưa xem/thay đổi billing dự án.
- FCM inbox bền vững/background data handling, consumer onOpened trong router và kiểm tra real device.
- Đã deploy riêng Firestore rules theo phê duyệt của người dùng. Dùng dự án PRM393 đã tồn tại, không tạo dự án khác. Chưa deploy Storage, chưa đổi billing, chưa commit/push.

Các bước Console và lệnh chạy lại: xem [firebase-setup.md](firebase-setup.md).

Công cụ Node 22.23.4 được tải vào `/tmp`, kiểm tra SHA-256 theo SHASUMS256.txt từ nodejs.org. Firebase CLI và test dependencies nằm cục bộ trong `firebase/tests/node_modules` (không commit); lockfile npm được giữ để chạy lại bằng npm ci. FlutterFire CLI nằm trong pub global cache.

Cập nhật thiết lập máy: Node/Firebase CLI đã cài lâu dài trong ~/.local; không còn phụ thuộc Node trong /tmp để chạy terminal. Cấu hình shell nằm ở ~/.config/annhien/android-env.sh. Debug keystore nằm ngoài repo; SHA được ghi trong setup doc.

## Build APK và chạy thử trên Android

APK debug tại `build/app/outputs/flutter-apk/app-debug.apk`. Đã xác minh chữ ký của APK thật, không chỉ keystore đầu vào. Build lần đầu phát cảnh báo các plugin Firebase còn dùng KGP, deprecation trong native plugin và SDK XML parser; build hiện tại vẫn exit 0. Không tự đổi phiên bản plugin chỉ để loại bỏ cảnh báo tương thích tương lai.

`adb devices -l` hiện không có thiết bị. Khi kết nối máy Android có Google Play services và bật USB debugging, chạy `flutter run` hoặc `adb install -r build/app/outputs/flutter-apk/app-debug.apk`, rồi thử Google login/cancel/logout, routing, đọc catalog và lưu người thân. Đây là bước runtime còn thiếu; không coi build APK là bằng chứng Google Sign-In/Core/FCM đã chạy thành công.

Trước khi mở lịch thật, cần thống nhất reset/invalidate state theo UID khi đổi tài khoản và contract realtime với các ViewModel hiện có; hiện TaskRepository vẫn chủ động chặn các thao tác chưa có schema lịch.
