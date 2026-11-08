# An Nhiên Admin — Firebase backend

Website quản trị HTML/CSS/JS, Firebase Auth + callable Functions, Firestore, FCM và scheduled worker. Không có dữ liệu demo cố định hoặc quyền đọc Firestore rộng trong frontend. Tất cả API admin yêu cầu custom claim `admin === true`.

## Trạng thái ngày 08/11/2026

- Đã tạo Web App `1:784239891940:web:48c5cf00af6deb700a63f1` và Hosting site riêng: https://prm393-145c9-admin.web.app.
- Đã deploy Hosting và Firestore indexes; không đổi rules.
- **Backend production chưa deploy**: Firebase từ chối bật Secret Manager vì project `prm393-145c9` đang Spark, cần Blaze. Chưa tạo được secret production hoặc đăng nhập production `admin/admin`. Không tự đổi gói thanh toán.
- Local Firebase Emulator có đăng nhập `admin / admin` qua callable `adminSignIn`, dùng secret local. Auth identity `an-nhien-admin` được tạo khi đăng nhập custom token lần đầu; không thêm profile người dùng app.
- Backend được kiểm thử bằng Firestore Emulator; chưa kiểm chứng nhận FCM trên thiết bị production.

## Chạy local

Cần Node 22, Java 21+, dependency trong `firebase/functions` và `firebase/tests` (`npm ci --prefix ...` nếu chưa có). Các CLI cần nằm trong PATH.

```bash
bash scripts/run-admin-local.sh
```

Mở http://127.0.0.1:5000/?emulator=1, đăng nhập `admin / admin`.
Script chỉ tạo/thêm khóa `ADMIN_LOGIN_PASSWORD=admin` trong `.secret.local` đã gitignore; không sửa các secret khác. Dữ liệu emulator mất khi tắt nếu không export.

Seed dữ liệu thử nghiệm trong terminal thứ hai, từ thư mục dự án:

```bash
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=demo-an-nhien node scripts/seed-admin-emulator.cjs
```

Seed 30 hồ sơ, role, heartbeat, lịch, kết nối gia đình **chỉ trong Emulator**, không ghi dữ liệu giả vào production. Mode emulator chỉ bật khi có `?emulator=1` trên localhost và hiển thị badge riêng; dùng project `demo-an-nhien`.

Thông báo gửi ngay kích hoạt Firestore worker trong emulator. Script local chạy thêm queue worker mỗi 10 giây để xử lý lịch hẹn/batch tiếp theo (Firebase scheduler không tự chạy trong Emulator). Có thể chạy `scripts/tick-admin-queue.cjs` với hai biến môi trường emulator như lệnh seed để tick thủ công. Production dùng scheduler mỗi phút.

## Số liệu

- Tổng hồ sơ, ba mẹ (`elder`), con cháu (`caregiver`), chưa chọn vai trò; người mới hôm nay.
- Growth theo 24 giờ gần nhất, hôm nay, 7/30/90 ngày, so với kỳ trước cùng độ dài. Hồ sơ thiếu `createdAt` vẫn nằm trong tổng nhưng không được tự gán ngày tạo.
- DAU theo ngày UTC+7; WAU/MAU theo 7/30 ngày gần nhất. Tỷ lệ DAU/MAU; độ phủ heartbeat.
- Phiên hoạt động (server giới hạn một phiên/người/30 phút, qua ngày vẫn ghi nhận); lần đầu ghi nhận app; người quay lại hôm nay.
- Tổng mẫu lịch, số completion `done`, `skipped`, `postponed` trong ngày. Không suy ra tỷ lệ hoàn thành lịch lặp khi chưa tính occurrence.
- Kết nối caregiver hiện có; số thiết bị cập nhật FCM token trong 30 ngày; thông báo tạo hôm nay và đánh dấu đã đọc hôm nay.
- 100 hồ sơ mới nhất có tìm kiếm; xuất CSV cùng snapshot với dữ liệu đang xem.
- Lượt tải từ store và retention D7 chưa có nguồn chính xác, hiển thị chưa có dữ liệu. Heartbeat đầu tiên không được gọi là lượt tải/cài đặt.

Backend đọc tối đa 10.000 hồ sơ và bản ghi presence; nếu vượt sẽ trả lỗi yêu cầu chuyển sang aggregate thay vì trả tổng bị cắt. Cần chuyển sang aggregate/BigQuery khi mở rộng. Các count query dùng Firestore aggregate + indexes.

## Push

5 segment: tất cả, ba mẹ, con cháu, người mới 7 ngày, không hoạt động 7 ngày (chỉ người đã có heartbeat). Kiểm tra nội dung 65/240 ký tự, lịch tối đa 90 ngày, idempotency request ID, chống tạo lặp và giới hạn 10 giây/chiến dịch/admin.

Worker xử lý 150 hồ sơ/batch, dùng transaction lease/cursor và tạo inbox cùng transaction, tránh tạo lặp khi retry. Segment được đánh giá khi xử lý. Inbox trigger gửi qua FCM tối đa 500 token/batch, loại token quá 30 ngày và dọn token đã bị hủy. Nội dung admin campaign được gửi trong notification; nội dung riêng tư của thông báo gia đình vẫn dùng nội dung tổng quát như trước.

Trạng thái `enqueued` = đã xếp vào inbox, **không phải xác nhận thiết bị nhận hay người dùng đọc**. Có thể hủy khi `queued`, không xóa log audit đã gửi. Các campaign và telemetry được bảo vệ bởi catch-all deny hiện có; chỉ Admin SDK backend truy cập.

## Đưa backend production lên

Chủ project cần tự bật Blaze: https://console.firebase.google.com/project/prm393-145c9/usage/details. Đây là bước liên quan thanh toán, chưa thực hiện.

Sau đó, từ thư mục dự án:

```bash
firebase functions:secrets:set ADMIN_LOGIN_PASSWORD --project prm393-145c9
# Nhập mật khẩu seed được yêu cầu vào prompt, không commit vào source.
firebase deploy --project prm393-145c9 --only functions:an-nhien:adminSignIn,functions:an-nhien:adminDashboard,functions:an-nhien:adminCreateCampaign,functions:an-nhien:adminCancelCampaign,functions:an-nhien:recordAppActivity,functions:an-nhien:dispatchAdminCampaign,functions:an-nhien:processAdminCampaignQueue,functions:an-nhien:notifyInbox
firebase deploy --project prm393-145c9 --only hosting,firestore:indexes
```

Runtime service account phải có quyền ký Firebase custom token (`iam.serviceAccounts.signBlob`); nếu project không cấp mặc định, cấu hình quyền Token Creator trên đúng service account theo Firebase Admin SDK docs. Không đưa service-account private key vào website.

Google login là tùy chọn cho tài khoản có custom claim do chủ dự án cấp; cần bật Google provider và Authorized domains cho Hosting domain. Tài khoản seed dùng username/password qua backend, không cần Email/Password provider.

Flutter đã thêm heartbeat vào `FirebaseAnalyticsService`, gọi `recordAppActivity` khi set user và app về foreground. Cần build/cài bản app mới và deploy callable để tích lũy số liệu; không backfill lịch sử không tồn tại.

## Kiểm tra

```bash
npm run check --prefix firebase/functions
firebase/tests/node_modules/.bin/firebase emulators:exec --project demo-an-nhien --only firestore 'node --test --test-concurrency=1 firebase/functions/test/*.test.cjs'
```

Tham khảo API: https://firebase.google.com/docs/functions/callable ; https://firebase.google.com/docs/auth/admin/create-custom-tokens ; https://firebase.google.com/docs/cloud-messaging/send/admin-sdk .
