# Design traceability – Lab 2 Figma → Flutter

Figma: https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled  ·  Chủ file: Sanh

Trạng thái: `todo` → `doing` → `done` (khớp Figma) / `changed` (lệch Figma, ghi lý do ở bảng cuối).

## Tóm tắt feature

| Feature | Người làm | Route | Số màn |
| --- | --- | --- | ---: |
| F0 Nền tảng: theme, widget dùng chung, điều hướng | Sanh | `(toàn app)` | 2 |
| F1 Tài khoản + chọn vai trò (Bác / Con cháu) | Hiếu | `/sign-in, /role` | 6 |
| F2 Onboarding của Bác (Flow 1) | Hương | `/welcome, /setup, /setup/notifications` | 14 |
| F3 Hôm nay: làm xong / dời / bỏ qua (Flow 3) | Khang | `/today, /today/task/:id` | 14 |
| F4 Thêm, sửa, xoá việc (Flow 2, Flow 7) | Khang | `/today/add, /today/add/time, /today/task/:id/edit` | 20 |
| F5 Thêm việc bằng giọng nói | Khang | `/today/voice` | 6 |
| F6 Lời nhắc đến giờ (Flow 6) | Khang | `/reminder/:taskId` | 3 |
| F7 Lịch tuần + xuất PDF (Flow 4) | Hương | `/week, /week/:date` | 5 |
| F8 Cài đặt hiển thị & hồ sơ | Sanh | `/settings, /settings/profile` | 5 |
| F9 9 thói quen Power 9 (Flow 8 – Flow chính 1) | Hương | `/habits, /habits/:key` | 3 |
| F10 Firebase: thông báo, Remote Config, Crashlytics, khu demo | Hiếu | `/inbox, /settings/profile` | 1 |
| F11 Gia đình: thêm người thân, nhắn tin (Flow 5, Flow 9) | Hương | `/family, /family/add, /family/:personId/share` | 13 |
| F12 Gợi ý lịch: Con cháu gửi ↔ Bác nhận | Sanh | `/today/suggestions/:id, /caregiver/suggest` | 19 |
| F13 Ghép nối máy con cháu với máy mẹ (Flow 10) | Hiếu | `/caregiver/pair` | 2 |
| F14 Con cháu lập lịch cho mẹ (Flow 11, 12 – Flow chính 3) | Sanh | `/caregiver/schedule, /caregiver/task/…` | 11 |

## F0 · Nền tảng: theme, widget dùng chung, điều hướng — Sanh

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| Components · Màn mới (Giọng nói & Tài khoản) | [138:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=138-2) | `(toàn app)` | | | todo |
| S03 Hôm nay | [1:270](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-270) | `(toàn app)` | | | todo |

## F1 · Tài khoản + chọn vai trò (Bác / Con cháu) — Hiếu

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| A01 Tạo tài khoản – Số điện thoại (Bước 1/3) | [139:6](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-6) | `/sign-in, /role` | | | todo |
| A02 Nhập mã xác nhận (Bước 2/3) | [139:43](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-43) | `/sign-in, /role` | | | todo |
| A02e Mã chưa đúng | [139:89](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-89) | `/sign-in, /role` | | | todo |
| A03 Mở app bằng vân tay (Bước 3/3) | [139:136](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-136) | `/sign-in, /role` | | | todo |
| A04 Đã tạo tài khoản | [139:178](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-178) | `/sign-in, /role` | | | todo |
| C01 Chọn vai trò | [1:3870](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-3870) | `/sign-in, /role` | | | todo |

## F2 · Onboarding của Bác (Flow 1) — Hương

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| S01 Chào mừng – chọn cỡ chữ | [1:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2) | `/welcome, /setup, /setup/notifications` | | | todo |
| S02 · Xác nhận tên (trước S02) | [1:58](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-58) | `/welcome, /setup, /setup/notifications` | | | todo |
| S02 Thiết lập hồ sơ (Bước 1/2) | [1:103](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-103) | `/welcome, /setup, /setup/notifications` | | | todo |
| S02 · Nhập lại tên | [1:176](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-176) | `/welcome, /setup, /setup/notifications` | | | todo |
| DLG-WakeTime Chọn giờ thức dậy | [31:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-2) | `/welcome, /setup, /setup/notifications` | | | todo |
| S13 Cho phép nhắc việc (Bước 2/2) | [1:217](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-217) | `/welcome, /setup, /setup/notifications` | | | todo |
| S13d Nhắc việc đang tắt | [14:284](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=14-284) | `/welcome, /setup, /setup/notifications` | | | todo |
| N01 Thử lời nhắc | [31:68](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-68) | `/welcome, /setup, /setup/notifications` | | | todo |
| N02 Đã nhận lời nhắc | [31:170](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-170) | `/welcome, /setup, /setup/notifications` | | | todo |
| N03 Chưa nhận lời nhắc | [31:218](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-218) | `/welcome, /setup, /setup/notifications` | | | todo |
| N04 Chọn việc đầu tiên | [38:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-2) | `/welcome, /setup, /setup/notifications` | | | todo |
| N05 Xem lại việc đầu tiên | [38:108](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-108) | `/welcome, /setup, /setup/notifications` | | | todo |
| N18 Đã lưu việc đầu tiên | [47:170](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=47-170) | `/welcome, /setup, /setup/notifications` | | | todo |
| N19 Hôm nay · việc đầu tiên | [47:225](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=47-225) | `/welcome, /setup, /setup/notifications` | | | todo |

## F3 · Hôm nay: làm xong / dời / bỏ qua (Flow 3) — Khang

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| S03 Hôm nay | [1:270](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-270) | `/today, /today/task/:id` | | | todo |
| S03 · Hôm nay – xem từng việc (bấm nút) | [1:487](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-487) | `/today, /today/task/:id` | | | todo |
| S03b Hôm nay sau khi xong 1 việc | [12:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=12-2) | `/today, /today/task/:id` | | | todo |
| S03-alldone Hôm nay · xong 6/6 | [7:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=7-2) | `/today, /today/task/:id` | | | todo |
| N17 Hôm nay · đã xử lý hết (5 xong · 1 bỏ qua) | [47:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=47-2) | `/today, /today/task/:id` | | | todo |
| ST-Empty Hôm nay chưa có việc | [15:39](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=15-39) | `/today, /today/task/:id` | | | todo |
| S04 Chi tiết hoạt động | [1:580](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-580) | `/today, /today/task/:id` | | | todo |
| DLG-Done Xác nhận đã xong | [29:125](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-125) | `/today, /today/task/:id` | | | todo |
| DLG-Later Dời việc | [29:156](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-156) | `/today, /today/task/:id` | | | todo |
| DLG-Skip Bỏ qua hôm nay | [29:211](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-211) | `/today, /today/task/:id` | | | todo |
| S03-later Hôm nay (đã dời 30 phút) | [8:189](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=8-189) | `/today, /today/task/:id` | | | todo |
| S03-later4 Hôm nay · dời chiều nay | [10:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=10-2) | `/today, /today/task/:id` | | | todo |
| S03-tomorrow Hôm nay · dời ngày mai | [11:189](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=11-189) | `/today, /today/task/:id` | | | todo |
| S03-skip Hôm nay · đã bỏ qua | [10:193](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=10-193) | `/today, /today/task/:id` | | | todo |

## F4 · Thêm, sửa, xoá việc (Flow 2, Flow 7) — Khang

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| S05 Thêm việc – chọn hoạt động | [1:688](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-688) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| S05 · Thêm việc – xem thêm (cuộn) | [1:758](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-758) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| S06 Thêm việc – thiết lập | [1:890](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-890) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| S06e Thêm việc · thiếu thông tin | [12:193](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=12-193) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| S06o Thêm việc · đã sửa lỗi | [13:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=13-2) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| ST-Validation Thêm việc · báo lỗi nhập | [29:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-2) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| DLG-TaskTime Chọn giờ làm | [29:256](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-256) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| N11 Chọn ngày | [43:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-2) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| N12 Lặp lại | [43:95](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-95) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| N13 Phạm vi thay đổi | [43:195](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-195) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| N14 Chưa lưu thay đổi | [43:239](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-239) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| ST-Loading Đang lưu việc | [26:191](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-191) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| ST-Loading-offline Đang lưu · mất mạng | [26:199](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-199) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| ST-Saved Đã lưu xong | [26:217](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-217) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| ST-Error Chưa lưu được | [26:159](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-159) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| N16 Đã lưu · nhắc cần kiểm tra | [43:290](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-290) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| S15 Sửa việc | [1:2624](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2624) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| DLG-Delete Xóa việc | [29:98](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-98) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| S03-edited Hôm nay · đã lưu thay đổi | [8:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=8-2) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |
| S03-deleted Hôm nay · đã xóa việc | [7:168](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=7-168) | `/today/add, /today/add/time, /today/task/:id/edit` | | | todo |

## F5 · Thêm việc bằng giọng nói — Khang

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| V00 Cho phép dùng micro | [140:112](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-112) | `/today/voice` | | | todo |
| V01 Nói để thêm việc – sẵn sàng | [140:147](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-147) | `/today/voice` | | | todo |
| V02 Đang nghe Bác nói | [140:176](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-176) | `/today/voice` | | | todo |
| V03 Bác xem lại việc vừa nói | [140:205](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-205) | `/today/voice` | | | todo |
| V04 Chưa nghe rõ | [140:256](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-256) | `/today/voice` | | | todo |
| V05 Đã thêm việc bằng giọng nói | [140:290](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-290) | `/today/voice` | | | todo |

## F6 · Lời nhắc đến giờ (Flow 6) — Khang

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| S14 Lời nhắc đến giờ | [1:635](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-635) | `/reminder/:taskId` | | | todo |
| S03-snooze Hôm nay · nhắc lại sau 10 phút | [11:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=11-2) | `/reminder/:taskId` | | | todo |
| N07 Cài đặt nhắc việc | [41:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=41-2) | `/reminder/:taskId` | | | todo |

## F7 · Lịch tuần + xuất PDF (Flow 4) — Hương

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| S07 Lịch tuần | [1:970](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-970) | `/week, /week/:date` | | | todo |
| S07 · Lịch tuần (cuộn xuống) | [1:1136](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1136) | `/week, /week/:date` | | | todo |
| S11 Chi tiết ngày | [1:1303](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1303) | `/week, /week/:date` | | | todo |
| S11 · Chi tiết ngày (cuộn xuống) | [1:1446](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1446) | `/week, /week/:date` | | | todo |
| S11b Chi tiết ngày · ngày khác | [14:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=14-2) | `/week, /week/:date` | | | todo |

## F8 · Cài đặt hiển thị & hồ sơ — Sanh

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| S10 Cài đặt hiển thị | [1:2325](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2325) | `/settings, /settings/profile` | | | todo |
| S10 · Cài đặt hiển thị (cuộn xuống) | [1:2474](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2474) | `/settings, /settings/profile` | | | todo |
| N06 Thông tin của Bác (Sửa hồ sơ) | [38:187](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-187) | `/settings, /settings/profile` | | | todo |
| N08 Cách dùng đơn giản | [41:85](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=41-85) | `/settings, /settings/profile` | | | todo |
| N20 Dữ liệu trên điện thoại | [52:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-2) | `/settings, /settings/profile` | | | todo |

## F9 · 9 thói quen Power 9 (Flow 8 – Flow chính 1) — Hương

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| S08 9 thói quen | [1:1590](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1590) | `/habits, /habits/:key` | | | todo |
| S08 · Tuần này (thống kê) | [1:1740](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1740) | `/habits, /habits/:key` | | | todo |
| S16 Chi tiết thói quen | [1:1934](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1934) | `/habits, /habits/:key` | | | todo |

## F10 · Firebase: thông báo, Remote Config, Crashlytics, khu demo — Hiếu

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| N06 Thông tin của Bác (Sửa hồ sơ) | [38:187](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-187) | `/inbox, /settings/profile` | | | todo |

## F11 · Gia đình: thêm người thân, nhắn tin (Flow 5, Flow 9) — Hương

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| S09 Gia đình | [1:1993](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1993) | `/family, /family/add, /family/:personId/share` | | | todo |
| S09b Gia đình · đã thêm người thân | [26:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-2) | `/family, /family/add, /family/:personId/share` | | | todo |
| S12 Thêm người thân | [1:2110](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2110) | `/family, /family/add, /family/:personId/share` | | | todo |
| S12 · Thêm người thân – chọn từ danh bạ | [1:2146](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2146) | `/family, /family/add, /family/:personId/share` | | | todo |
| S12 · Thêm người thân – tự nhập | [1:2215](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2215) | `/family, /family/add, /family/:personId/share` | | | todo |
| S12a Thêm người thân · chưa có số | [14:120](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=14-120) | `/family, /family/add, /family/:personId/share` | | | todo |
| S12e Thêm người thân · số sai | [14:196](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=14-196) | `/family, /family/add, /family/:personId/share` | | | todo |
| N09 Sửa người thân | [41:136](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=41-136) | `/family, /family/add, /family/:personId/share` | | | todo |
| N15 Xóa người thân | [43:263](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-263) | `/family, /family/add, /family/:personId/share` | | | todo |
| N21 Gia đình sau khi xóa người thân | [52:48](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-48) | `/family, /family/add, /family/:personId/share` | | | todo |
| S17 Nhắn tin cho người thân | [1:2278](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2278) | `/family, /family/add, /family/:personId/share` | | | todo |
| S17b Nhắn tin · đã mở chia sẻ | [26:122](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-122) | `/family, /family/add, /family/:personId/share` | | | todo |
| N10 Đã mở ứng dụng chia sẻ | [41:205](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=41-205) | `/family, /family/add, /family/:personId/share` | | | todo |

## F12 · Gợi ý lịch: Con cháu gửi ↔ Bác nhận — Sanh

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| G01 Con cháu soạn lịch gợi ý | [52:161](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-161) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G01b Soạn gợi ý · chọn giờ | [52:230](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-230) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G02 Đã gửi gợi ý | [56:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=56-2) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G03 Lịch Mai gợi ý | [56:107](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=56-107) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G03b Lịch Mai gợi ý · đã đổi giờ | [56:201](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=56-201) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G04 Đổi giờ đi bộ | [57:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=57-2) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G05 Đã nhận gợi ý | [57:128](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=57-128) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G05b Đã nhận · đổi giờ | [58:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=58-2) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G06 Chọn từng việc | [58:117](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=58-117) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G07 Đã nhận một việc | [61:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=61-2) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G07b Đã nhận một việc · nhánh B | [61:118](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=61-118) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G08 Lịch ngày mai | [61:233](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=61-233) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G08b Lịch ngày mai | [63:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=63-2) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G08c Lịch ngày mai | [63:102](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=63-102) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G08d Lịch ngày mai | [63:179](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=63-179) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G09 Đã bỏ qua gợi ý | [66:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=66-2) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G10 Có gợi ý mới (tự hiện) | [66:119](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=66-119) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G11 Popup Mai gửi lịch cho Bác | [71:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=71-2) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |
| G12 Hôm nay · thẻ gợi ý của Mai | [71:209](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=71-209) | `/today/suggestions/:id, /caregiver/suggest` | | | todo |

## F13 · Ghép nối máy con cháu với máy mẹ (Flow 10) — Hiếu

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| C02 Nhập mã ghép nối | [1:3382](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-3382) | `/caregiver/pair` | | | todo |
| C02e Mã sai hoặc hết hạn | [71:402](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=71-402) | `/caregiver/pair` | | | todo |

## F14 · Con cháu lập lịch cho mẹ (Flow 11, 12 – Flow chính 3) — Sanh

| Màn Figma | Node | Route | Widget / ViewModel | Nguồn dữ liệu | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| C03 Lịch của mẹ Lan (Hoàn thiện biểu tượng & Bố cục) | [1:3148](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-3148) | `/caregiver/schedule, /caregiver/task/…` | | | todo |
| C04 Lịch của mẹ · Tuần | [73:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=73-2) | `/caregiver/schedule, /caregiver/task/…` | | | todo |
| C05 Lịch của mẹ · Tháng | [73:105](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=73-105) | `/caregiver/schedule, /caregiver/task/…` | | | todo |
| C06 Tạo việc gợi ý (Bước 1/3) | [1:3036](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-3036) | `/caregiver/schedule, /caregiver/task/…` | | | todo |
| C06e Thiếu tên hoặc giờ | [74:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=74-2) | `/caregiver/schedule, /caregiver/task/…` | | | todo |
| C07 Lặp lại việc gợi ý (Bước 2/3) | [1:2764](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2764) | `/caregiver/schedule, /caregiver/task/…` | | | todo |
| C07m Lặp lại mỗi tháng (Bước 2/3) | [74:98](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=74-98) | `/caregiver/schedule, /caregiver/task/…` | | | todo |
| C08 Xem lại và gửi gợi ý (Bước 3/3) | [1:2960](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2960) | `/caregiver/schedule, /caregiver/task/…` | | | todo |
| C08w Trùng giờ | [74:235](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=74-235) | `/caregiver/schedule, /caregiver/task/…` | | | todo |
| C09 Đã gửi cho mẹ | [1:2717](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2717) | `/caregiver/schedule, /caregiver/task/…` | | | todo |
| C10 Chi tiết việc lặp lại | [75:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=75-2) | `/caregiver/schedule, /caregiver/task/…` | | | todo |

## Thay đổi so với Figma (bắt buộc ghi, đề Lab 3 › "Changes to the design")

| # | Màn | Thay đổi | Lý do | Đã sửa Figma? |
| --- | --- | --- | --- | --- |
| DT-01 | A01 | Nút chính "Tiếp tục với Google" thay cho nhập số điện thoại | Đề Lab 3 bắt buộc Google Sign-In | ☐ |
| DT-02 | S07 | Thêm nút "Xuất PDF" | Đề Lab 3 bắt buộc sinh 1 file và upload | ☐ |
| DT-03 | N06 | Thêm khu demo Firebase + Hộp thông báo | Đề Lab 3 bắt buộc Firebase demo area | ☐ |
