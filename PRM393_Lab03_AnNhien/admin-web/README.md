# An Nhiên — admin/API local + Firebase production

## Production trên Azure — 08/11/2026

- Admin/API/worker: https://an-nhien-admin.bluerock-e6f4ebd4.japaneast.azurecontainerapps.io.
- Link cũ https://prm393-145c9-admin.web.app được chuyển hướng sang Azure.
- Subscription Azure for Students, app `an-nhien-admin` trong resource group `an-nhien-rg`, dùng environment Japan hiện có và repository image riêng `an-nhien/admin`.
- Một replica 0.25 CPU / 0.5 GiB luôn bật cho worker; dùng hạn mức/credit Azure. Backend local đã dừng để tránh chạy hai worker.
- Firestore/Auth/FCM giữ ở project production prm393-145c9. Service account Azure riêng có Datastore User, Firebase Auth Viewer và Firebase Cloud Messaging API Admin. Credential chỉ lưu trong Azure Container App secret, không trong image/repo/APK.
- Các ID và image đã deploy ở `deploy/azure-admin.json`; file này không chứa private key.
- Image build bằng `Dockerfile.admin`; `.dockerignore` chỉ cho phép source cần thiết, không bao gồm `.env.real`, `.secret.local` hoặc tài khoản Firebase CLI.
- APK dùng URL production: `flutter build apk --release --dart-define=BACKEND_URL=https://an-nhien-admin.bluerock-e6f4ebd4.japaneast.azurecontainerapps.io`.
- Health HTTPS, đăng nhập/dashboard Firestore và FCM dry-run bằng service account Azure đều đã kiểm tra thành công. APK release 75.3 MB đã build với URL HTTPS production. Chưa chứng minh delivery push trên hai điện thoại thật. APK release hiện dùng signing debug của dự án lab; chưa cấu hình khóa phát hành Play Store.

Các hướng dẫn local bên dưới vẫn dành cho phát triển. Không bật worker local đồng thời worker Azure.

## Chạy thật, không Emulator

Admin web, API và notification worker chạy chung Node.js; Firebase Auth, Firestore và FCM dùng production project `prm393-145c9`. Không cần Blaze cho server standalone này. Không tạo user/dữ liệu demo.

```bash
# Từ thư mục PRM393_Lab03_AnNhien, cần Node 22:
npm ci --prefix firebase/functions
npm ci --prefix firebase/tests
# Nếu máy chưa đăng nhập CLI:
firebase/tests/node_modules/.bin/firebase login
cd admin-web
npm run dev
```

Mở http://127.0.0.1:3000, đăng nhập **admin / admin** theo yêu cầu. Lần đầu script tạo `.env.real` trong firebase/functions (gitignore, quyền 0600). Chỉnh config/mật khẩu tại đó rồi restart server. Phiên quản trị được ký ở backend, hết hạn sau 8 giờ hoặc restart; không được dùng để giả làm user app.

`USE_FIREBASE_CLI_CREDENTIAL=1` chỉ cho máy phát triển: dùng lại tài khoản đã `firebase login`, token ở bộ nhớ, không chép credential vào repo/APK. Trên Azure/server khác dùng ADC/service account qua `GOOGLE_APPLICATION_CREDENTIALS`, đặt `USE_FIREBASE_CLI_CREDENTIAL=0`. Xem `firebase/functions/real-server.env.example`.

Backend và worker cần luôn bật, hiện thiết kế cho một server. Cho phép origin localhost và IP LAN của máy; origin khác khai báo ALLOWED_ORIGINS. Dùng HTTPS khi phục vụ qua Internet.

## APK dùng chung hệ thống

APK vẫn đăng nhập Firebase Auth thật và đọc/ghi Firestore thật. BACKEND_URL chỉ thay nơi gọi API; Firebase SDK đính kèm ID token, server kiểm tra token và trạng thái thu hồi.

Ví dụ IP máy server hiện tại là 192.168.2.98, điện thoại cùng Wi-Fi:

```bash
bash scripts/build-real-apk.sh http://192.168.2.98:3000 debug
# hoặc chạy trực tiếp:
flutter run --dart-define=BACKEND_URL=http://192.168.2.98:3000
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Dùng `lib/main.dart`, không dùng main_dev/main_emulator. Không dùng localhost trên điện thoại khác. IP đổi thì build lại hoặc dùng một URL HTTPS ổn định. Máy chạy server cần truy cập được từ điện thoại và cho phép port 3000 qua firewall.

```bash
# Release bắt buộc HTTPS:
bash scripts/build-real-apk.sh https://YOUR_BACKEND_HOST release
```

Cài cùng APK lên hai điện thoại, đăng nhập hai tài khoản khác nhau, chọn Ba mẹ/Con cháu và ghép mã. OS cần cấp quyền thông báo và hỗ trợ FCM. App đọc được dữ liệu cache khi offline nhưng API cần mạng/server.

## Luồng thống nhất

- Admin tạo campaign → adminCampaigns trong Firestore → worker 10 giây → inbox user → FCM. Có segment và lịch gửi; chỉ hủy khi queued.
- Ghép nối bằng createPairing/redeemPairing/revokePairing → domain transaction kiểm tra role/mã/expiry/rate limit → grants chung trong Firestore → thông báo hai bên.
- Gợi ý lịch bằng sendSuggestion/resolveSuggestion/undoDismiss → kiểm tra caregiver → transaction cập nhật inbox/lịch.
- Con cháu cập nhật/hoàn tác lịch → cùng transaction ghi scheduleEvents → worker thông báo Ba mẹ. Rules chỉ cho caregiver đã ghép nối tạo event với actorUid đúng, server timestamp; không cho client sửa/xóa event.
- Ba mẹ hoàn thành việc → completion.updatedAt → worker kiểm tra kết nối còn hiệu lực → inbox/FCM cho Con cháu.
- Đăng nhập/quay lại foreground → recordAppActivity → DAU/WAU/MAU trong dashboard.

Tương tác gia đình ở đây là các chức năng hiện có của app, không phải chat tự do giữa mọi user. Các provider Gemini/local vẫn giữ nguyên; adapter giọng nói/trợ lý Groq cũng hiểu BACKEND_URL nếu được chọn và server có GROQ_API_KEY.

## Worker và số liệu

Cursor lưu trong serverRuntime; receipt/lease lưu trong serverPushReceipts. Lần bật đầu chỉ xử lý sự kiện từ lúc kích hoạt, không phát lại toàn bộ lịch sử. Restart bắt kịp từ cursor. ID inbox ổn định tránh tạo lặp; FCM có thể gửi lại nếu process chết sau gửi trước lưu receipt (at least once), tag ổn định giúp hạn chế trùng.

Index đã deploy production. Trong lúc index collection-group được Google xây, worker/dashboard tự truy vấn collection theo từng user và lưu cursor riêng. Fallback tốn nhiều lượt đọc hơn; tự trở về query group khi index sẵn sàng. Không chạy đồng thời worker standalone và Cloud Functions gửi cùng inbox. Quy mô lớn cần aggregate và queue chuyên dụng; báo cáo giới hạn 10.000 hồ sơ.

`enqueued` = inbox đã tạo, không khẳng định thiết bị nhận. GET /health báo server/project. Số liệu: role, growth 24 giờ/7/30/90 ngày, DAU/WAU/MAU, phiên, first heartbeat, người quay lại, lịch/completion, gia đình, FCM devices, inbox mới/đọc, CSV. Lượt tải store/retention D7 chưa có nguồn đúng, không điền số giả. Heartbeat cần cài APK mới để bắt đầu tích lũy.

## Trạng thái kiểm chứng

- Admin đọc được Firestore production; đã deploy rules/indexes cho worker thật.
- FCM dry-run thành công trên token thật, không phát thông báo thử vào thiết bị user.
- APK debug LAN đã build. Chưa kiểm chứng toàn bộ flow trên hai điện thoại thật.
- Website https://prm393-145c9-admin.web.app hiện chuyển hướng tới Azure production. Port 3000 chỉ dành cho chạy local khi phát triển. Không cần Blaze hoặc deploy Functions.

Kiểm thử không Emulator:

```bash
npm run check --prefix firebase/functions
node --test firebase/functions/test/real-server.test.cjs firebase/functions/test/real-worker.test.cjs firebase/functions/test/push-delivery.test.cjs
```

Các bộ test Emulator cũ vẫn còn để kiểm thử khác; không cần bật Emulator để chạy hệ thống này.
