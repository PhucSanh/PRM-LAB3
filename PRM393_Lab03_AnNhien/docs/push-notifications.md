# Push notifications: Gia đình và Hệ thống

## Phạm vi triển khai

| Sự kiện | Người nhận | Nguồn tạo tin | Màn mở |
| --- | --- | --- | --- |
| Con gửi lịch gợi ý | Cha/mẹ được ghép nối | Transaction `sendSuggestion` | `/inbox/suggestions/{id}` — dữ liệu Firebase thật |
| Con thêm/sửa/gỡ lịch trực tiếp | Cha/mẹ đang cấp quyền | `notifyScheduleChanged` với auth context của người ghi | Hôm nay |
| Cha/mẹ đánh dấu việc hoàn thành | Con còn ghép nối với đúng cha/mẹ | `notifyTaskCompleted` | Lịch của đúng ngày hoàn thành |
| Ghép nối/ngưng ghép nối | Hai bên | `notifyPairingChanged` | Hộp thông báo, nhóm Hệ thống |
| Thông báo vận hành từ An Nhiên | UID cụ thể do operator chọn | CLI có quyền Firebase quản trị | Hộp thông báo, nhóm Hệ thống |

Không gửi phản hồi khi cha/mẹ nhận/bỏ qua gợi ý, bỏ qua việc, hoàn tác hay chưa làm.
Nhánh hoàn thành chỉ thông báo tối đa một lần cho mỗi task/ngày, không lặp khi bấm
hoàn tác rồi hoàn thành lại. Không có tác vụ tự động nhắc con “mẹ chưa làm”.

## Kiến trúc

1. Backend ghi `users/{recipientUid}/notifications/{stableId}` trước.
2. `notifyInbox` đọc token thiết bị mới trong 30 ngày và gửi FCM theo lô tối đa 500.
3. App đang mở: banner trong app, chống lặp theo ID trong phiên/tài khoản.
4. App nền/tắt bình thường: Android hiển thị notification payload; chạm mở qua
   `onMessageOpenedApp` hoặc `getInitialMessage`. App không tự mở màn khi chỉ nhận tin.
5. Hộp thông báo lấy Firestore, tối đa 100 tin gần nhất; tắt quyền OS vẫn xem được
   trong app khi có mạng. Có lọc Gia đình/Hệ thống, thời điểm và trạng thái chưa đọc.

`notification-events.cjs` tạo inbox bằng transaction/create-once, không ghi đè
`readAt` khi trigger chạy lại. Trigger Firestore có thể lặp và sai thứ tự; không
cam kết FCM exactly-once. Android dùng `tag=notification_id`, app foreground giữ
200 ID gần nhất trong phiên để hạn chế banner trùng. Sau khởi động lại có thể nhận
lại một push; inbox vẫn dùng cùng ID nếu document còn tồn tại.

FCM lỗi tạm thời gây retry; chỉ xóa đăng ký khi token đã bị xác nhận không còn hợp
lệ. Push tray giữ nội dung chung, không đưa tên việc/thông tin sức khỏe lên màn
hình khóa. Chi tiết chỉ hiển thị trong inbox của tài khoản.

## Quyền và điều hướng

- Client không tạo thông báo, không sửa title/body/route/kind. Chủ tài khoản chỉ
  cập nhật `readAt` bằng server timestamp; người thân không đọc hộp thư của nhau.
- Thay đổi lịch chỉ thông báo nếu auth ID người ghi khác chủ lịch và còn grant.
  Không phát thông báo “người thân sửa” từ thay đổi của chính chủ hoặc Admin SDK
  không có danh tính người thân hợp lệ.
- Hoàn thành kiểm tra grant, `pairedMomUid` hiện tại và trạng thái completion còn
  là done ngay trong transaction; không gửi cho người đã ngưng ghép nối.
- Tin hoàn thành mang `parentUid`. Chạm tin cũ sau khi đổi cha/mẹ ghép nối sẽ về
  inbox, không mở nhầm lịch cha/mẹ mới. Áp dụng cả inbox và đường mở từ FCM.
- Route push có allowlist, ngày phải hợp lệ; URL ngoài, traversal và query lạ về inbox.
- Lỗi đánh dấu đã đọc được báo khi thao tác trực tiếp; mở nội dung không chờ mạng
  ghi readAt hoặc analytics. Ghi readAt có timeout để tránh khóa nút vô thời hạn.
- Quyền OS và đăng ký token là hai kết quả riêng: mạng lỗi không được báo thành
  quyền đã bị từ chối. Cấp quyền native ở onboarding cũng đồng bộ token; resume
  app thử đăng ký lại. Đăng xuất xóa token, pending push và banner theo tài khoản.

## Android

Kênh FCM `an_nhien_updates` (Gia đình và hệ thống) tách kênh local
`an_nhien_reminders`. Manifest có icon và channel mặc định. Kênh được tạo khi khởi
động native reminder runtime; Android có thể dùng fallback nếu push đến trước lần
khởi tạo đầu tiên. Không yêu cầu exact alarm cho push.

Lời nhắc đúng giờ của task vẫn dùng local notifications hiện có. Thay đổi lịch từ
con được đồng bộ/reschedule khi app cha/mẹ đang chạy hoặc resume; chưa có background
worker đảm bảo cập nhật các local alarm khi app cha/mẹ không được mở. Không hứa
nhận push khi app bị Force stop, thiết bị offline hoặc Android chặn thông báo.

## Hai luồng gợi ý trong repo

Màn F12 mẫu dùng contract riêng và chưa được nối đầy đủ với backend production.
Push thật hiện mở `/inbox/suggestions/{id}`, dùng `caregiverSuggestionServiceProvider`
và callable resolve, lọc đúng ID; không mở nhầm F12 Fake. Firebase adapter cũng chuyển route cũ
`/today/suggestions/{id}` trong lịch sử sang màn thật này. Nếu đã xử lý/hết tồn tại,
màn báo không còn gợi ý mới. Dữ liệu gợi ý mẫu tự động đã tắt ở provider mặc định,
chỉ bật trong `main_dev.dart` để không tạo tin gia đình giả trong production.

## Chạy local, deploy và kiểm tra thật

Các test Emulator gọi notification handlers trực tiếp với Firestore local; không
mô phỏng được giao nhận FCM thật. Phiên này chưa gửi tin cho người dùng thật.
Chưa deploy Functions/rules lên cloud trong đợt này.

Kiểm tra backend/rules:

```bash
npm run check --prefix firebase/functions
npm test --prefix firebase/tests
```

Sau khi review, operator có thể deploy vào dự án được cấu hình:

```bash
firebase deploy --project prm393-145c9 --only functions:an-nhien,firestore:rules
```

Cần Firebase project hỗ trợ Cloud Functions/Blaze, quyền deploy và các API liên
quan. Các trigger mới là `notifyScheduleChanged`, `notifyTaskCompleted`,
`notifyPairingChanged`; `notifyInbox` tiếp tục làm đầu gửi duy nhất.

Gửi thông báo hệ thống theo UID (thao tác thật, chỉ chạy khi muốn gửi):

```json
{
  "id": "system-example-unique-id",
  "recipientUid": "REAL_RECIPIENT_UID",
  "title": "Thông báo từ An Nhiên",
  "body": "Nội dung operator muốn gửi.",
  "route": "/inbox"
}
```

```bash
node firebase/scripts/send-notification.cjs prm393-145c9 /path/to/payload.json --send
```

CLI chỉ tạo inbox mới, không gửi FCM lần hai; ID đã tồn tại sẽ không bị ghi đè.
Đừng dùng CLI cũ gửi trực tiếp đồng thời với trigger, vì sẽ bị push đôi. CLI không
đọc token ra log và không có API tương ứng trong app cho người dùng tự gửi hệ thống.

Checklist hai thiết bị Android có Google Play Services:

1. Đăng nhập hai vai trò, ghép nối, cấp quyền thông báo ở cả hai máy.
2. Con gửi gợi ý; mẹ thử foreground/nền/tắt bình thường; chạm vào đúng gợi ý thật.
3. Con thêm/sửa lịch trực tiếp; mẹ nhận cập nhật. Mẹ tự sửa không nhận tin giả từ con.
4. Mẹ hoàn thành; con nhận một tin, mở đúng ngày. Hoàn tác/làm lại không spam.
5. Bỏ qua gợi ý/việc không gửi phản hồi cho con. Ngưng ghép nối rồi hoàn thành
   không gửi tin mới tới con cũ.
6. Đổi tài khoản/ghép nối, chạm tin cũ: không đọc dữ liệu hay mở nhầm cha/mẹ mới.
7. Gửi một tin hệ thống bằng operator; thấy nhóm Hệ thống, cập nhật readAt đúng UID.
8. Từ chối quyền, offline rồi mở lại, token refresh, thông báo đến lặp; inbox vẫn là
   nguồn đối chiếu. Không đưa token/credentials vào ảnh nghiệm thu.

## Tài liệu chính thức đã đối chiếu

- [FCM Flutter: receive messages](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
- [Firestore triggers: auth context, retries và ordering](https://firebase.google.com/docs/functions/firestore-events)

## Kết quả kiểm chứng

- Flutter: **619/619 test qua**, gồm 8 test mới về push/inbox. Nhóm kiểm tra cuối
  push/F10/local-reminder: **18/18 qua**.
- Backend + Firestore/Storage rules Emulator: **25/25 qua**, gồm event idempotency,
  revoke grant, completion, pairing, phân lô FCM, invalid token và transient retry.
- Android debug APK build thành công (`flutter build apk --debug --no-pub`).
- Analyzer: chỉ còn 2 info style có sẵn ở `main_emulator.dart:29,52`; không error/warning mới.
- Native build còn cảnh báo toolchain/Kotlin plugin có sẵn, không chặn build.
- Giao nhận FCM trên hai thiết bị, auth-context trigger được triển khai cloud,
  background/cold-start thật và hệ thống operator gửi thật: **chưa kiểm chứng**.

