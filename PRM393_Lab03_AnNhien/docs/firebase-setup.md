# Thiết lập Firebase Android – An Nhiên

Cập nhật 02/11/2026. Giữ nguyên MVVM, Riverpod 3.4.3, GoRouter 18.1.2, routes, màn hình và ViewModels. Các provider production dùng adapter Firebase; test phải override các service được sử dụng. Không tự chuyển sang Fake nếu Firebase lỗi.

## Trạng thái

Android được sinh bằng `flutter create . --org com.annhien --project-name an_nhien --platforms android --no-pub`. Đã kiểm tra Gradle, manifest, activity, resources, metadata và wrapper; bỏ counter test mẫu không thuộc app. Lệnh create tự thay lockfile: đã khôi phục trước `flutter pub get`. Wrapper scripts và JAR được bỏ khỏi cả hai ignore files để có thể commit. Manifest bổ sung INTERNET và POST_NOTIFICATIONS, nhãn An Nhiên. Android application ID: `com.annhien.an_nhien`.

Flutter 3.47.3 / Dart 3.13.3 tương thích lockfile yêu cầu Flutter >=3.47 / Dart >=3.13. Các phiên bản Firebase thật được solver chọn nằm trong pubspec.lock; không đổi phiên bản Riverpod / GoRouter.

**Đã cấu hình Firebase thật:** dự án PRM393 (`prm393-145c9`), Android app `1:784239891940:android:35a2b841ff2447720a63f1`, package `com.annhien.an_nhien`. FlutterFire CLI sinh `lib/firebase_options.dart` và `android/app/google-services.json`, thêm Google Services 4.4.4 / Crashlytics 3.0.7 vào Gradle. `main.dart` dùng DefaultFirebaseOptions trước khi dựng app. Rules/emulator config được giữ trong firebase.json. Chưa xác minh runtime trên thiết bị Android. Không dùng thông tin Firebase giả.

## Thiết lập máy phát triển đã thực hiện

- Node.js 22.23.4: `/home/qhius/.local/share/annhien-node-v22.23.4`, lệnh node/npm trong `~/.local/bin`.
- Firebase CLI 15.34.2 cài trong `~/.local`, FlutterFire CLI 1.4.1 có lệnh trong `~/.local/bin`.
- Đã đăng nhập Firebase CLI qua Google OAuth; không lưu token vào repo. Dự án PRM393 đã được xác nhận qua Firebase CLI và chọn để cấu hình Android.
- Android SDK đã cài tại `/data/qtram/android-sdk`: platform android-36 và android-34 (Gradle tự cài thêm cho dependency), build-tools 36.0.0, platform-tools 37.0.1 và NDK 28.2.13676358. `flutter doctor -v` PASS toàn bộ, Android licenses accepted.
- `~/.config/annhien/android-env.sh` được nạp từ `.bashrc` và `.profile`. Với terminal đang mở, chạy `source ~/.config/annhien/android-env.sh` hoặc mở terminal mới.
- Gradle Wrapper 9.3.1 đã chạy thành công với Java 21.
- Debug keystore được tạo tại `~/.android/debug.keystore` (không đưa vào Git).
- Debug SHA-1: `85:F3:15:A1:4D:1E:68:DC:FA:5F:AE:25:A3:07:CE:19:67:DC:2C:29`.
- Debug SHA-256: `35:CE:48:C9:06:0E:53:C8:36:5B:4E:34:4F:68:58:28:A6:20:FB:38:34:08:83:05:9E:0C:15:BD:91:D0:9A:A1`.

## Các bước Console và chạy lại cần thực hiện

1. Máy hiện tại đã có Android command-line SDK và Flutter config; không cần Android Studio để build. Trên máy mới có thể cài Android Studio và Android SDK. Chạy `flutter doctor -v`, cấu hình đường dẫn bằng `flutter config --android-sdk <đường-dẫn-sdk>`, rồi `flutter doctor --android-licenses`. Cần thiết bị Android/emulator có Google Play services.
2. Dùng **một dự án Firebase hiện có của nhóm**. Xác nhận project ID và quyền truy cập. Không bật billing tự động.
3. Cài Node.js và Firebase CLI: `npm install -g firebase-tools`. Chạy `firebase login` (hoặc `firebase login --no-localhost` trên máy không mở được callback), rồi `firebase projects:list` để xác nhận dự án. Không gửi token đăng nhập vào chat hoặc Git.
4. FlutterFire CLI 1.4.1 đã cài qua `dart pub global activate flutterfire_cli`. Thêm `$HOME/.pub-cache/bin` vào PATH. Từ thư mục app, chạy:

   ```bash
   flutterfire configure --project=prm393-145c9 --platforms=android --android-package-name=com.annhien.an_nhien
   ```

   Kiểm tra mọi thay đổi Gradle mà CLI tạo, `lib/firebase_options.dart`, `android/app/google-services.json` và project ID bên trong. Nếu CLI sửa firebase.json, giữ lại đường dẫn rules và cấu hình emulator hiện có. Không chọn tạo dự án mới khi CLI không tìm thấy dự án.
5. Đã đăng ký SHA-1 và SHA-256 debug ở trên bằng Firebase CLI. Người dùng đã bật Google provider trên Console; google-services.json đã được refresh và xác minh có OAuth client types 1 (Android) và 3 (web). Cần thử đăng nhập thật trên thiết bị. Với máy mới hoặc release build: Console → Authentication → Sign-in method → Google: bật và chọn support email. Project settings → Android app: thêm SHA-1 và SHA-256 của debug key từ `cd android && ./gradlew signingReport`; thêm SHA release khi dùng chữ ký release. Sau khi thêm SHA/bật Google, chạy lại FlutterFire configure để lấy OAuth client phù hợp. Google Sign-In 7.2 dùng singleton `initialize()` một lần, `authenticate()`, ID token → Firebase credential; cần web OAuth client tương ứng trong google-services.json.
6. Firestore `(default)` đã tạo ở `asia-southeast1` (Singapore), Standard/Native, free tier bật. Người dùng đã phê duyệt tạo DB và deploy rules; `firebase deploy --project=prm393-145c9 --only firestore:rules --non-interactive` đã thành công. Catalog 9 thói quen đã được nạp và đọc lại bằng phiên CLI quản trị; không tạo user/task giả. Chạy lại bootstrap nếu cần: `node firebase/scripts/seed-habits.cjs prm393-145c9` (cần npm ci tại firebase/tests). Catalog trong `firebase/habits.json`; script không ghi đè document đã tồn tại. Client chỉ đọc catalog sau đăng nhập.
7. Console → Remote Config: tạo đúng `snooze_minutes=10`, `voice_input_enabled=true`, `home_max_upcoming=6`; giữ đúng kiểu dữ liệu rồi publish khi nhóm đồng ý. App có defaults/cached values khi fetch lỗi.
8. Console → Analytics / Crashlytics: kiểm tra event và non-fatal trên thiết bị. Test crash chỉ chạy chủ động trên bản thử; mở lại app để gửi report. FlutterFire phải thêm Gradle plugin cần thiết cho Crashlytics.
9. Console → Messaging: gửi test notification tới registration token lấy bằng debugger/dev tooling; xin quyền qua MessagingService. Thử foreground, background và cold start. Không có server key trong app. Inbox hiện chỉ lưu trong RAM theo phiên, tối đa 100 thông báo; chưa có persistent background inbox, local foreground banner hoặc router consumer cho onOpened. Payload route chưa được tin cậy để tự điều hướng.
10. Storage: tài liệu Firebase hiện yêu cầu gói Blaze để dùng Cloud Storage, kể cả bucket mặc định. Chưa biết gói billing của dự án nhóm. Nếu dự án đang ở Spark thì đây là blocker; dừng và xin chủ dự án duyệt. Không kích hoạt billing. Adapter upload nhận renderer PDF do F7 cung cấp; chưa có renderer nên trả AppException rõ ràng, không trả URL giả. Storage rule giới hạn MIME/size/extension; MIME không chứng minh nội dung file là PDF.
11. File options thật đã được sinh và main đã gọi `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`. Khi thêm platform/package Firebase mới, chạy lại FlutterFire configure và kiểm tra Gradle diff.
12. Firestore rules đã deploy sau khi được người dùng đồng ý rõ ràng. Storage rules chưa deploy; chỉ triển khai khi được cho phép và đã xử lý blocker billing/bucket. Không chạy deploy toàn bộ để tránh thay đổi ngoài phạm vi.

Tham chiếu chính thức: [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup), [Google Sign-In migration](https://github.com/flutter/packages/blob/main/packages/google_sign_in/google_sign_in/MIGRATION.md), [Firebase Storage billing](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024).

## Contract lịch cần cả nhóm thống nhất

TaskItem hiện chỉ có hour/minute, repeat, status. Thiếu ngày của việc once, weekdays của someDays, ngày bắt đầu/kết thúc, timezone, trạng thái theo từng occurrence và cách xác định occurrence khi setStatus chỉ nhận taskId. Không thể dùng một status chung cho mọi ngày của daily. Không được gán ngầm mọi task cho ngày truy vấn hoặc mặc định ngày tạo là hôm nay.

Đề xuất thảo luận: tách schedule template khỏi occurrence theo ngày địa phương, định nghĩa date `YYYY-MM-DD`, timezone IANA, weekdays, range, templateId/occurrenceId và chính sách postpone/undo. Cần thống nhất migration, ID của task qua routes, setStatus/undo và listener interface với Khang/Hương/Sanh trước khi sửa model. Chưa áp dụng đề xuất.

FirebaseTaskRepository đã đăng ký nhưng tasksForDay/save/setStatus chủ động ném AppException chờ schema. Delete có UID scope. Do đó F3/F4/F7 chưa hoạt động với Firebase. Không coi adapter này là hoàn chỉnh.

## Quyền gia đình và realtime

`users/{uid}/family` chỉ là danh bạ riêng. Không cấp quyền dựa vào số điện thoại, tên hay trường role do client sửa được. Grant `users/{uid}/caregivers/{caregiverUid}` chỉ do Admin SDK đáng tin tạo/xóa sau quy trình đồng ý của chủ tài khoản (chưa triển khai). Grant cho phép đọc task và gửi suggestion, chưa cho sửa lịch trực tiếp.

Rules suggestion hiện đề xuất transport tối thiểu `{senderUid,status,title,createdAt}`; caregiver chỉ tạo pending với server timestamp, owner chỉ đổi pending → accepted/rejected, không được sửa sender/content. Chưa tích hợp SuggestionService/UI; cần thống nhất với Sanh trước khi mở rộng payload. Notifications chỉ backend ghi, owner đọc/xóa. Mặc định chặn các đường dẫn khác.

FirebaseFamilyRepository có `watchAll()` dùng snapshots. Interface FamilyRepository/TaskRepository hiện chỉ có Future nên UI hiện tại chưa subscribe realtime. Chưa đổi interface/ViewModel của người khác; cần thống nhất thêm stream và hủy stream khi UID đổi. Không dùng FCM để thay thế listener Firestore.

## Kiểm tra cục bộ

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
cd firebase/tests
npm ci
npm test
```

Emulator tests dùng project **demo-an-nhien** độc lập, không phải Firebase project ID production. Java 21 và Node 22 cần có trên PATH. Không cần login để chạy test rules. Xem firebase-verification.md cho kết quả thực tế và hạn chế.

## Artifact Android đã build

`flutter build apk --debug` đã PASS với cấu hình Firebase PRM393 thật. APK: `build/app/outputs/flutter-apk/app-debug.apk`. Package `com.annhien.an_nhien`, version 0.1.0+1, compileSdk 36. Chữ ký APK đã được apksigner xác minh và khớp cả hai SHA đăng ký trên Firebase. Chưa thử runtime do chưa có Android device/emulator.
