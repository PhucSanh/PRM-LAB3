# Analytics event plan

Chủ file: **Hiếu** (bước 5). Mỗi người gắn event cho màn của mình, gọi qua `AnalyticsService.logEvent` **trong ViewModel**, không gọi trong widget.

Nguồn: chỉ số thành công M1–M8 (`lab2/PRD.md` mục 10, `lab2/persona.md`), FR / NFR (`lab2/PRD.md` mục 8–9), "Firebase / kỹ thuật" từng feature trong `../../An-Nhien_Chia-task_Lab3.md`.

## Luật

- **Không** gửi tên, e-mail, số điện thoại, nội dung tin nhắn, tên việc tự gõ trong tham số (NFR10 riêng tư). Chỉ gửi khoá (`habit_key`), số, cờ đúng / sai.
- Tên event `snake_case`, ≤ 40 ký tự; dùng event có sẵn của Firebase khi có (`login`, `tutorial_complete`, `share`).
- Đề yêu cầu ≥ 7 event có bằng chứng; bảng dưới có 22, bằng chứng tối thiểu là 7 event đánh dấu ★.
- Không đo "số lần mở app" làm thước đo thành công: đo việc làm thật (`lab2/PRD.md` I10).

## User property

| Property | Giá trị | Đặt ở |
| --- | --- | --- |
| `role` | `elder` / `caregiver` | C01 (F1) |
| `font_size` | `vua` / `lon` / `rat_lon` | S01 (F2), S10 (F8) |
| `notifications_on` | `true` / `false` | S13 / S13d (F2), N07 (F6) |
| `high_contrast` | `true` / `false` | S10 (F8) |

## Event

| Event | Trigger (màn / flow) | Tham số (kiểu) | Feature – người | Câu hỏi sản phẩm / chỉ số |
| --- | --- | --- | --- | --- |
| `login` ★ | Đăng nhập Google xong (A01) | `method` (string) | F1 – Hiếu | Bao nhiêu người quay lại mỗi tuần? |
| `logout` | Bấm Đăng xuất (S10) | — | F8 – Sanh | Phiên dùng kéo dài bao lâu? |
| `select_role` | Chọn vai trò (C01) | `role` (string) | F1 – Hiếu | Tỉ lệ Bác / Con cháu cài app? |
| `tutorial_complete` ★ | Xong onboarding (S13 → Hôm nay) | `font_size` (string), `notifications_on` (bool), `has_first_task` (bool) | F2 – Hương | Bao nhiêu người hoàn tất thiết lập, cỡ chữ nào phổ biến? (M7) |
| `test_reminder` | Kết quả thử lời nhắc (N02 / N03) | `received` (bool) | F2 – Hương | Bao nhiêu máy nhận được lời nhắc? |
| `complete_task` ★ | "Đúng, đã xong" (DLG-Done, S04, S14) | `habit_key` (string), `on_time` (bool), `taps` (int), `source` (string: today / detail / reminder) | F3 – Khang | Bác làm việc đúng giờ? Đánh dấu xong ≤ 2 chạm? (M1) |
| `postpone_task` | Chọn mốc dời (DLG-Later) | `habit_key` (string), `option` (string: 30m / afternoon / tomorrow) | F3 – Khang | Việc nào hay bị dời, dời tới đâu? |
| `skip_task` | Bỏ qua (DLG-Skip, S14) | `habit_key` (string), `reason` (string: rain / tired / busy / other / none) | F3 – Khang | Việc nào hay bị bỏ, vì sao? (FR11) |
| `undo_action` | Bấm "Hoàn tác" ở snackbar | `action` (string: done / postpone / skip / delete / dismiss_suggestion) | F3 – Khang | Bác có bấm nhầm không? (M3) |
| `add_task` ★ | Lưu việc mới (ST-Saved) | `habit_key` (string), `repeat` (string), `source` (string: tap / voice / habit / first_task), `duration_sec` (int) | F4 – Khang | Thêm việc ≤ 60 giây? Thói quen nào được thêm nhiều? (M2) |
| `edit_task` | Lưu thay đổi (S15) | `habit_key` (string), `scope` (string: this / following / all) | F4 – Khang | Bác sửa gì nhiều nhất? |
| `delete_task` | Xoá (DLG-Delete) | `habit_key` (string), `scope` (string) | F4 – Khang | Việc nào bị bỏ hẳn? |
| `voice_add_task` | Lưu ở V03 / V04 | `success` (bool), `attempts` (int) | F5 – Khang | Giọng nói hiểu đúng ngay lần đầu? |
| `reminder_action` | Bấm nút ở S14 | `action` (string: start / snooze / skip), `snooze_minutes` (int) | F6 – Khang | Lời nhắc có giúp Bác làm việc? Remote Config `snooze_minutes` có tác dụng? |
| `view_week` | Mở S07 | `tasks_count` (int) | F7 – Hương | Bác có xem trước lịch tuần? |
| `export_report` ★ | Upload PDF xong (S07) | `week` (string), `file_size_kb` (int) | F7 – Hương | Ai xuất lịch tuần để gửi con cháu? |
| `change_font_size` | Đổi cỡ chữ (S10) | `from` (string), `to` (string) | F8 – Sanh | Cỡ mặc định có đủ lớn? (M4) |
| `view_habit` | Mở S16 | `habit_key` (string), `has_tasks` (bool) | F9 – Hương | Thói quen nào được tìm hiểu mà chưa thêm thành việc? |
| `add_relative` | Lưu người thân (S12) | `relation` (string), `from_contacts` (bool), `had_error` (bool) | F11 – Hương | Danh bạ có giúp nhập nhanh hơn? |
| `share` ★ | Mở Zalo / SMS ở S17 | `method` (string: zalo / sms), `topic` (string) | F11 – Hương | Bác có chủ động kể cho con cháu? (M8) |
| `send_suggestion` | Gửi gợi ý (G02 / C09) | `items` (int), `source` (string: suggest / schedule) | F12 – Sanh | Con cháu gửi gợi ý bao nhiêu? |
| `accept_suggestion` ★ | Nhận gợi ý (G05 / G05b / G07 / G07b) | `count` (int), `changed_time` (bool), `partial` (bool), `taps` (int) | F12 – Sanh | Mẹ nhận gợi ý ≤ 2 chạm? (M6) |
| `dismiss_suggestion` | Bỏ qua gợi ý (G09) | `items` (int) | F12 – Sanh | Gợi ý nào không hợp? (không báo lại cho con – FR08) |
| `pair_device` | Ghép nối xong / lỗi (C02 / C02e) | `success` (bool), `error` (string: wrong / expired / none) | F13 – Hiếu | Ghép nối có khó không? |
| `create_recurring_task` | Gửi ở C08 → C09 | `repeat` (string: once / daily / weekly / monthly), `duration_sec` (int), `conflict` (bool) | F14 – Hiếu | Lập lịch lặp ≤ 90 giây, ≤ 3 bước? (M5) |

## Chỉ số thành công → event

| Chỉ số (Lab 2) | Mục tiêu | Event đo |
| --- | --- | --- |
| M1 Số chạm đánh dấu xong | ≤ 2 | `complete_task.taps` |
| M2 Thời gian thêm 1 việc | ≤ 60 giây | `add_task.duration_sec` |
| M3 Bấm nhầm | 0 | `undo_action` (gần đúng) |
| M4 Đọc được không cần kính | ≥ 4/5 | `change_font_size` + phỏng vấn |
| M5 Con cháu lập 1 lịch lặp | ≤ 90 giây, ≤ 3 bước | `create_recurring_task.duration_sec` |
| M6 Mẹ nhận gợi ý | ≤ 2 chạm | `accept_suggestion.taps` |
| M7 Hiểu không cần hướng dẫn | ≥ 4/5 | `tutorial_complete` |
| M8 Việc thực hiện / đã lên lịch | tăng sau 2 tuần | `complete_task` / `add_task`, `share` |

## Bằng chứng

- Bật DebugView: `adb shell setprop debug.firebase.analytics.app com.annhien.an_nhien` (applicationId tạo bởi `flutter create --org com.annhien`).
- Ảnh DebugView từng event ★ → `evidence/analytics/<event>.png`; ghi ngày chụp vào bảng dưới.

| Event | Ảnh | Ngày | Người |
| --- | --- | --- | --- |
| `login` | | | |
| `tutorial_complete` | | | |
| `complete_task` | | | |
| `add_task` | | | |
| `export_report` | | | |
| `share` | | | |
| `accept_suggestion` | | | |

Cách lấy bằng chứng event F2 (Hương): bật DebugView như trên, xoá dữ liệu app (hoặc tài khoản Bác mới chưa `onboarded`), đi Flow 1 `/welcome` → `/setup` → `/setup/notifications` → `/setup/try-reminder` → `/setup/first-task`:
- `test_reminder`: N01 bấm "Gửi thử" → N02 bấm "Tôi đã nhận được" (`received: true`) hoặc "Chưa nhận được" (`received: false`).
- `add_task`: N05 bấm "Lưu việc" → tham số `source: first_task`, `habit_key`, `repeat`, `duration_sec`.
- `tutorial_complete`: N18 bấm "Xem lịch" (hoặc "Để sau" ở N04 → `has_first_task: false`) → `font_size`, `notifications_on`, `has_first_task`.
- Kiểm tra trên DebugView: không có tên Bác / tên việc trong tham số. Lưu ý: `add_task` chỉ có khi `TaskRepository` lưu được (bản Firebase đang chờ chốt schema – xem `docs/prompt/F2/06-n04-viec-dau-tien.md`).

Cách lấy bằng chứng event F12 (Sanh) – **cần 2 máy** (máy B con cháu đã ghép nối, máy A của Bác), bật DebugView trên máy đang thao tác:
- `send_suggestion` (máy B): `/caregiver/suggest` → "Gửi gợi ý cho mẹ" → "Gửi gợi ý" → `items: 2`, `source: suggest`.
- `accept_suggestion` ★ (máy A): mở Hôm nay → popup G10 / G11 "Xem gợi ý" → G03 "Thêm vào lịch" → `count: 2`, `changed_time: false`, `partial: false`, `taps: 2` (M6). Đổi giờ (G04) → `changed_time: true`; "Chọn từng việc" bỏ 1 việc → `partial: true`.
- `dismiss_suggestion` (máy A): G03 "Bỏ qua gợi ý" → `items: 2`; `undo_action` khi bấm "Hoàn tác" ở G09 → `action: dismiss_suggestion`.
- Kiểm tra trên DebugView: không có tên người gửi, lời nhắn, tên việc trong tham số. Máy B **không** nhận gì khi máy A bỏ qua (FR08). Lưu ý: hiện `SuggestionService` mới có bản Fake (cùng máy) – chụp DebugView 2 máy khi Hiếu xong bản Firebase; trước đó dùng 1 máy với dữ liệu mẫu (popup tự hiện ở Hôm nay).

## Event F10 bổ sung (02/11/2026)

Ghi trong ViewModel/provider, không ghi token, UID người nhận, route ID, URL tệp
hay nội dung thông báo. Business events ★ ở trên vẫn cần bằng chứng riêng.

| Event | Trigger | Tham số |
| --- | --- | --- |
| view_firebase_demo | Mở khu thử tính năng | — |
| refresh_remote_config | Đọc RC/defaults/cache xong; không chứng minh đã fetch mạng | — |
| view_inbox | Subscribe inbox theo phiên / thử lại | — |
| notification_permission | Kết quả xin quyền | allowed (int 0/1) |
| receive_notification | Nhận FCM foreground đúng tài khoản | — |
| open_notification | Bấm Xem từ banner hoặc mục inbox | — |
| upload_demo_file | Có URL thật sau upload tệp thử | source=firebase_demo |
| upload_demo_failed | Tạo/upload tệp thử lỗi | source=firebase_demo |
| test_crash | Xác nhận thử đóng ứng dụng | source=firebase_demo |

Chưa có ảnh DebugView F10; các test Fake không phải bằng chứng Console.
