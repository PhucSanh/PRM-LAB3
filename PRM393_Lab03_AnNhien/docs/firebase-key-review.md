# Rà soát Firebase client API key – 02/11/2026

## Thay đổi đã thực hiện

Theo lựa chọn của người dùng, giữ nguyên key hiện tại và siết restrictions trên Google Cloud. Không tạo key mới, không rotate/revoke, không thay đổi billing hoặc Security Rules. Không ghi lại giá trị key trong tài liệu này.

Dự án: PRM393 (`prm393-145c9`). Key: Android key (auto created by Firebase), không gắn service account.

- Application restriction: package `com.annhien.an_nhien`.
- Certificate SHA-1: `85:F3:15:A1:4D:1E:68:DC:FA:5F:AE:25:A3:07:CE:19:67:DC:2C:29`.
- API allowlist thu hẹp từ 27 xuống 13 API cho các sản phẩm Firebase đã tích hợp. Loại bỏ SQL Admin, Firebase AI Logic và các sản phẩm không dùng. Generative Language API không được phép.
- Đã đọc lại metadata từ API Keys API sau cập nhật và đối chiếu package, certificate cùng toàn bộ allowlist.
- Cấu hình trước thay đổi được giữ tại `/tmp/annhien-api-key-before-restrictions.json` trên máy thực hiện để hỗ trợ khôi phục; file này không nằm trong Git.

## Kiểm chứng trực tiếp sau thay đổi

| Request | Kết quả |
|---|---|
| Firebase Auth project config, đúng X-Android-Package/X-Android-Cert | PASS: HTTP 200 |
| Cùng endpoint, không có Android headers | PASS: HTTP 403, API_KEY_ANDROID_APP_BLOCKED |
| Sai package | PASS: HTTP 403, API_KEY_ANDROID_APP_BLOCKED |
| Sai certificate SHA-1 | PASS: HTTP 403, API_KEY_ANDROID_APP_BLOCKED |
| Firestore đọc habits/move, đúng Android headers nhưng không có user token | PASS: HTTP 403, Missing or insufficient permissions |

Các request kiểm tra chỉ đọc config hoặc thử quyền đọc; không tạo tài khoản hoặc dữ liệu người dùng.

## Giới hạn và cách làm việc của nhóm

Android package/certificate restrictions kiểm tra thông tin request; các header có thể bị giả mạo. Đây không phải bằng chứng một request thật sự đến từ APK tin cậy và không thay thế Firebase Authentication, Security Rules hoặc App Check. App Check chưa được tích hợp/enforce trong phiên làm việc này.

Chưa có Android device/emulator kết nối nên chưa kiểm thử đăng nhập Google/FCM/Remote Config trên SDK thật sau thay đổi restrictions. Các kiểm tra REST ở trên không được báo thành runtime verification của app. APK không cần rebuild chỉ để thay key vì giá trị key không đổi; vẫn phải thử các flow Firebase trên thiết bị.

Hiện chỉ cho phép debug certificate của máy này. Thành viên nhóm dùng debug keystore khác phải thêm package/SHA-1 tương ứng vào key restrictions và Firebase Android app trước khi thử đăng nhập. Với release/Google Play App Signing, thêm SHA-1 của certificate ký app thực tế. Không đưa private keystore vào repo.

## Cảnh báo GitHub

Firebase client configuration được thiết kế để có mặt trong app và có thể được commit theo hướng dẫn chính thức; chỉ biết API key không tự cho quyền đọc Firestore. Việc chuyển key sang .env không làm key trở thành secret trong APK đã phát hành.

Alert GitHub chưa được đóng. Không đánh dấu revoked vì key chưa thu hồi. Nếu chính sách repo chấp nhận public Firebase client config, có thể xử lý cảnh báo là false positive/intended client configuration, kèm kết quả restrictions và kiểm chứng ở trên. Nếu chính sách bắt buộc revoke mọi key xuất hiện trên Git, cần một quy trình rotation riêng: cấu hình key mới, cập nhật app, kiểm thử rồi mới thu hồi key cũ.

Chưa kiểm tra đầy đủ security/access logs và không có kết luận về việc key từng bị lạm dụng. API-key restrictions cũng không chứng minh rằng không từng có truy cập bất thường.

Tham chiếu: [Firebase API keys](https://firebase.google.com/docs/projects/api-keys), [Google Cloud API-key management](https://docs.cloud.google.com/docs/authentication/api-keys).

## Allowlist sau cập nhật

- `firebase.googleapis.com`
- `logging.googleapis.com`
- `firebaseinstallations.googleapis.com`
- `identitytoolkit.googleapis.com`
- `securetoken.googleapis.com`
- `firebaserules.googleapis.com`
- `datastore.googleapis.com`
- `firestore.googleapis.com`
- `fcmregistrations.googleapis.com`
- `firebasestorage.googleapis.com`
- `firebaseremoteconfig.googleapis.com`
- `firebaseremoteconfigrealtime.googleapis.com`
- `cloudconfig.googleapis.com`
