# Design traceability – Lab 2 Figma → Flutter

Figma: https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled · fileKey `K3JczHkChbUWoDBkXZYMhR` · Chủ file: **Sanh**

File này nối **từng khung Figma** với **route, ViewModel, nguồn dữ liệu và trạng thái code**. Người và AI agent tra file này trước khi làm một màn (thứ tự đọc docs: `README.md`).

## Cách dùng

- **Trạng thái**: `todo` → `doing` (đang làm) → `done` (khớp Figma) / `changed` (lệch Figma, phải có dòng DT-xx ở cuối file).
- **Loại**: `Màn` = route riêng · `State` = trạng thái của màn khác (cùng route, cùng ViewModel) · `Dialog` = hộp thoại / popup · `Màn con` = trả kết quả bằng `pop(result)` · `Thư viện` = khung component, không phải màn.
- **Biến thể** (S03-later, S03-skip, G08b…) **không** làm thành màn mới: làm thành state của màn gốc.
- **Node**: bấm để mở đúng khung. Khi gọi Figma MCP đổi `52-161` → `52:161`.
- **ViewModel / Nguồn dữ liệu**: tên **đề xuất** theo `architecture.md`. Đổi tên khi code thì sửa cả hai file.
- **Đặc tả chi tiết** (layout, states, interactions, navigation, ràng buộc UI): `lab2/flutter-handoff.md`, tìm theo mã màn.
- **Stitch (Lab 2)**: bản HTML tốt nhất trong repo `prm393-lab2-an-nhien/`. Chỉ tham khảo khi không mở được Figma; lệch thì Figma thắng.

## Tóm tắt feature

| Feature | Người làm | Route chính | Số khung | Flow Lab 2 |
| --- | --- | --- | ---: | --- |
| F0 Nền tảng: theme, widget dùng chung, điều hướng | Sanh | (toàn app) | 2 | — |
| F1 Tài khoản + chọn vai trò (Bác / Con cháu) | Hiếu | `/sign-in`, `/role` | 6 | Đăng nhập (đề), Flow 10 (C01) |
| F2 Onboarding của Bác (Flow 1) | Hương | `/welcome`, `/setup`, `/setup/notifications`, `/setup/try-reminder` | 14 | Flow 1 |
| F3 Hôm nay: làm xong / dời / bỏ qua (Flow 3) | Khang | `/today`, `/today/task/:id` | 14 | Flow 3, Main flow |
| F4 Thêm, sửa, xoá việc (Flow 2, Flow 7) | Khang | `/today/add`, `/today/add/time`, `/task/date`, `/task/repeat` | 20 | Flow 2, Flow 7 |
| F5 Thêm việc bằng giọng nói | Khang | `/today/voice` | 6 | Mới (Lab 3) |
| F6 Lời nhắc đến giờ (Flow 6) | Khang | `/reminder/:taskId`, `/today`, `/settings/reminders` | 3 | Flow 6 – Flow chính 2 |
| F7 Lịch tuần + xuất PDF (Flow 4) | Hương | `/week`, `/week/:date` | 5 | Flow 4 |
| F8 Cài đặt hiển thị & hồ sơ | Sanh | `/settings`, `/settings/profile`, `/settings/help`, `/settings/data` | 5 | Main flow (S10), Hồ sơ (đề) |
| F9 9 thói quen Power 9 (Flow 8 – Flow chính 1) | Hương | `/habits`, `/habits/:key` | 3 | Flow 8 – Flow chính 1 |
| F10 Firebase: thông báo, Remote Config, Crashlytics, khu demo | Hiếu | `/settings/profile`, `/inbox` | 1 | Firebase demo (đề) |
| F11 Gia đình: thêm người thân, nhắn tin (Flow 5, Flow 9) | Hương | `/family`, `/family/add`, `/family/:personId/edit`, `/family/:personId/share` | 13 | Flow 5, Flow 9 |
| F12 Gợi ý lịch: Con cháu gửi ↔ Bác nhận | Sanh | `/caregiver/suggest`, `/today/suggestions/:id`, `/week/:date`, `/today` | 19 | Gợi ý lịch (G) |
| F13 Ghép nối máy con cháu với máy mẹ (Flow 10) | Hiếu | `/caregiver/pair` | 2 | Flow 10 |
| F14 Con cháu lập lịch cho mẹ (Flow 11, 12 – Flow chính 3) | Hiếu | `/caregiver/schedule`, `/caregiver/task/new`, `/caregiver/task/new/repeat`, `/caregiver/task/new/review` | 11 | Flow 11, 12 – Flow chính 3 |

## Flow Lab 2 → người chịu trách nhiệm chạy hết đầu tới cuối

| Flow | Màn chính | Người |
| --- | --- | --- |
| ★ Main flow – Một ngày của bà Lan | S01 → … → S14 | Cả nhóm |
| Flow 1 Onboarding | S01, S02, S13 | Hương |
| Flow 2 Thêm việc (có lỗi + phục hồi) | S05, S06, ST-* | Khang |
| Flow 3 Xong / dời / bỏ qua | S03, S04, DLG-* | Khang |
| Flow 4 Xem lịch một ngày | S07, S11 | Hương |
| Flow 5 Thêm người thân (có lỗi) | S09, S12a, S12e | Hương |
| Flow 6 Lời nhắc – Flow chính 2 | S14 | Khang |
| Flow 7 Sửa & xoá việc | S04, S15, DLG-Delete | Khang |
| Flow 8 Thói quen – Flow chính 1 | S08, S16 | Hương |
| Flow 9 Nhắn tin cho con cháu | S09, S17 | Hương |
| Flow 10 Ghép nối | C01, C02, C02e | Hiếu |
| Flow 11 Lập lịch cho mẹ – Flow chính 3 | C03 … C09 | Hiếu |
| Flow 12 Sửa / ngưng lịch lặp | C10, C11, C12 | Hiếu |
| Gợi ý lịch (G) | G01 – G12 | Sanh |
| Đăng nhập + Hồ sơ (đề bắt buộc thêm) | A01 (Google), N06 | Hiếu (A01), Sanh (N06) |
| Thêm việc bằng giọng nói (mới) | V00 – V05 | Khang |

Sơ đồ từng flow (nhánh chính, nhánh lỗi, nhánh phụ): `lab2/user-flow.md`.


## F0 · Nền tảng: theme, widget dùng chung, điều hướng — Sanh

**Xong khi:** Màn của mọi người chỉ dùng widget trong `lib/widgets/`; không còn màu/cỡ chữ cứng; `flutter analyze` sạch.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Components Màn mới (Giọng nói & Tài khoản) | [138:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=138-2) | Thư viện | `(toàn app)` | — | — | — | todo |
| S03 Hôm nay | [1:270](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-270) | Màn (tab 0) | `/today` | TodayViewModel | TaskRepository | `stitch-runs/S03/v3.html` | todo |

## F1 · Tài khoản + chọn vai trò (Bác / Con cháu) — Hiếu

**Xong khi:** Chưa đăng nhập không vào app được; huỷ có thông báo; đổi A01 thành nút Google: ghi design-traceability + sửa Figma. A02–A04 (SĐT + mã) làm sau nếu kịp, nếu bỏ thì ghi lý do.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A01 Tạo tài khoản – Số điện thoại (Bước 1/3) | [139:6](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-6) | Màn | `/sign-in` | SignInViewModel | AuthService | — | todo |
| A02 Nhập mã xác nhận (Bước 2/3) | [139:43](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-43) | Màn | `/sign-in (làm sau)` | SignInViewModel | AuthService | — | todo |
| A02e Mã chưa đúng | [139:89](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-89) | State | `/sign-in (làm sau)` | SignInViewModel | AuthService | — | todo |
| A03 Mở app bằng vân tay (Bước 3/3) | [139:136](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-136) | Màn | `/sign-in (làm sau)` | SignInViewModel | AuthService | — | todo |
| A04 Đã tạo tài khoản | [139:178](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-178) | State | `/sign-in (làm sau)` | SignInViewModel | AuthService | — | todo |
| C01 Chọn vai trò | [1:3870](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-3870) | Màn | `/role` | RoleViewModel | ProfileService | `codex-runs/C01/v0.html` | todo |

## F2 · Onboarding của Bác (Flow 1) — Hương

**Xong khi:** Đi hết S01 → Hôm nay có việc đầu tiên; từ chối quyền thì hiện S13d; mở lại app không hỏi lại.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S01 Chào mừng – chọn cỡ chữ | [1:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2) | Màn | `/welcome` | OnboardingViewModel | SettingsService | `stitch-runs/S01/v2.html` | todo |
| S02 Xác nhận tên (trước S02) | [1:58](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-58) | Màn | `/setup` | OnboardingViewModel | ProfileService | `stitch-runs/S02/v0.html` | todo |
| S02 Thiết lập hồ sơ (Bước 1/2) | [1:103](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-103) | Màn | `/setup` | OnboardingViewModel | ProfileService | `stitch-runs/S02/v0.html` | todo |
| S02 Nhập lại tên | [1:176](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-176) | Màn | `/setup` | OnboardingViewModel | ProfileService | `stitch-runs/S02/v0.html` | todo |
| DLG-WakeTime Chọn giờ thức dậy | [31:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-2) | Dialog | `/setup (dialog)` | OnboardingViewModel | — | `stitch-runs/DLG-WakeTime/v1.html` | todo |
| S13 Cho phép nhắc việc (Bước 2/2) | [1:217](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-217) | Màn | `/setup/notifications` | OnboardingViewModel | ReminderService (quyền) | `stitch-runs/S13/v1.html` | todo |
| S13d Nhắc việc đang tắt | [14:284](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=14-284) | State | `/setup/notifications` | OnboardingViewModel | ReminderService (quyền) | `stitch-runs/S13d/v1.html` | todo |
| N01 Thử lời nhắc | [31:68](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-68) | Màn | `/setup/try-reminder` | TryReminderViewModel | ReminderService | `codex-runs/N01/v3.html` | todo |
| N02 Đã nhận lời nhắc | [31:170](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-170) | State | `/setup/try-reminder` | TryReminderViewModel | ReminderService | `codex-runs/N02/v3.html` | todo |
| N03 Chưa nhận lời nhắc | [31:218](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-218) | State | `/setup/try-reminder` | TryReminderViewModel | ReminderService | `codex-runs/N03/v2.html` | todo |
| N04 Chọn việc đầu tiên | [38:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-2) | Màn | `/setup/first-task` | FirstTaskViewModel | TaskRepository | `codex-runs/N04/v2.html` | todo |
| N05 Xem lại việc đầu tiên | [38:108](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-108) | Màn | `/setup/first-task` | FirstTaskViewModel | TaskRepository | `codex-runs/N05/v3.html` | todo |
| N18 Đã lưu việc đầu tiên | [47:170](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=47-170) | State | `/setup/first-task` | FirstTaskViewModel | TaskRepository | `stitch-runs/N18/v0.html` | todo |
| N19 Hôm nay · việc đầu tiên | [47:225](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=47-225) | State | `/today` | TodayViewModel | TaskRepository | `stitch-runs/N19/v1.html` | todo |

## F3 · Hôm nay: làm xong / dời / bỏ qua (Flow 3) — Khang

**Xong khi:** Đủ loading / trống / lỗi + Thử lại; Hoàn tác trả lại trạng thái cũ; đánh dấu xong ≤ 2 lần chạm (chỉ số thành công #1).

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S03 Hôm nay | [1:270](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-270) | Màn (tab 0) | `/today` | TodayViewModel | TaskRepository | `stitch-runs/S03/v3.html` | todo |
| S03 Hôm nay – xem từng việc (bấm nút) | [1:487](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-487) | Màn (tab 0) | `/today` | TodayViewModel | TaskRepository | `stitch-runs/S03/v3.html` | todo |
| S03b Hôm nay sau khi xong 1 việc | [12:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=12-2) | State | `/today` | TodayViewModel | TaskRepository | `stitch-runs/S03b/v2.html` | todo |
| S03-alldone Hôm nay · xong 6/6 | [7:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=7-2) | State | `/today` | TodayViewModel | TaskRepository | `stitch-runs/S03-alldone/v2.html` | todo |
| N17 Hôm nay · đã xử lý hết (5 xong · 1 bỏ qua) | [47:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=47-2) | State | `/today` | TodayViewModel | TaskRepository | `stitch-runs/N17/v0.html` | todo |
| ST-Empty Hôm nay chưa có việc | [15:39](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=15-39) | State | `/today` | TodayViewModel | TaskRepository | `stitch-runs/ST-Empty/v1.html` | todo |
| S04 Chi tiết hoạt động | [1:580](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-580) | Màn | `/today/task/:id · /week/:date/task/:id` | TaskDetailViewModel | TaskRepository | `stitch-runs/S04/v0.html` | todo |
| DLG-Done Xác nhận đã xong | [29:125](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-125) | Dialog | `/today (dialog)` | TodayViewModel | TaskRepository | `stitch-runs/DLG-Done/v2.html` | todo |
| DLG-Later Dời việc | [29:156](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-156) | Dialog | `/today (dialog)` | TodayViewModel | TaskRepository | `stitch-runs/DLG-Later/v1.html` | todo |
| DLG-Skip Bỏ qua hôm nay | [29:211](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-211) | Dialog | `/today (dialog)` | TodayViewModel | TaskRepository | `stitch-runs/DLG-Skip/v1.html` | todo |
| S03-later Hôm nay (đã dời 30 phút) | [8:189](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=8-189) | State | `/today (snackbar)` | TodayViewModel | TaskRepository | `stitch-runs/S03-later/v2.html` | todo |
| S03-later4 Hôm nay · dời chiều nay | [10:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=10-2) | State | `/today (snackbar)` | TodayViewModel | TaskRepository | `stitch-runs/S03-later4/v0.html` | todo |
| S03-tomorrow Hôm nay · dời ngày mai | [11:189](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=11-189) | State | `/today (snackbar)` | TodayViewModel | TaskRepository | `stitch-runs/S03-tomorrow/v2.html` | todo |
| S03-skip Hôm nay · đã bỏ qua | [10:193](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=10-193) | State | `/today (snackbar)` | TodayViewModel | TaskRepository | `stitch-runs/S03-skip/v1.html` | todo |

## F4 · Thêm, sửa, xoá việc (Flow 2, Flow 7) — Khang

**Xong khi:** Lỗi thiếu tên/giờ hiện S06e; mất mạng hiện ST-Loading-offline; xoá việc lặp hỏi "lần này / các lần sau"; thêm việc ≤ 60 giây (chỉ số #2).

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S05 Thêm việc – chọn hoạt động | [1:688](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-688) | Màn | `/today/add` | TaskFormViewModel | HabitRepository | `stitch-runs/S05/v2.html` | todo |
| S05 Thêm việc – xem thêm (cuộn) | [1:758](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-758) | Màn | `/today/add` | TaskFormViewModel | HabitRepository | `stitch-runs/S05/v2.html` | todo |
| S06 Thêm việc – thiết lập | [1:890](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-890) | Màn | `/today/add/time` | TaskFormViewModel | TaskRepository | `stitch-runs/S06/v0.html` | todo |
| S06e Thêm việc · thiếu thông tin | [12:193](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=12-193) | State | `/today/add/time` | TaskFormViewModel | — | `stitch-runs/S06e/v2.html` | todo |
| S06o Thêm việc · đã sửa lỗi | [13:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=13-2) | State | `/today/add/time` | TaskFormViewModel | TaskRepository | `stitch-runs/S06o/v0.html` | todo |
| ST-Validation Thêm việc · báo lỗi nhập | [29:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-2) | State | `/today/add/time` | TaskFormViewModel | — | `stitch-runs/ST-Validation/v1.html` | todo |
| DLG-TaskTime Chọn giờ làm | [29:256](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-256) | Dialog | `(dialog dùng chung)` | TaskFormViewModel | — | `stitch-runs/DLG-TaskTime/v0.html` | todo |
| N11 Chọn ngày | [43:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-2) | Màn con | `/task/date` | TaskFormViewModel | — | `stitch-runs/N11/v1.html` | todo |
| N12 Lặp lại | [43:95](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-95) | Màn con | `/task/repeat` | TaskFormViewModel | — | `stitch-runs/N12/v1.html` | todo |
| N13 Phạm vi thay đổi | [43:195](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-195) | Màn con | `/task/scope` | TaskFormViewModel | — | `stitch-runs/N13/v1.html` | todo |
| N14 Chưa lưu thay đổi | [43:239](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-239) | Dialog | `(dialog khi rời form)` | TaskFormViewModel | — | `stitch-runs/N14/v0.html` | todo |
| ST-Loading Đang lưu việc | [26:191](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-191) | State | `/today/add/result` | TaskFormViewModel | TaskRepository | `stitch-runs/ST-Loading/v0.html` | todo |
| ST-Loading-offline Đang lưu · mất mạng | [26:199](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-199) | State | `/today/add/result` | TaskFormViewModel | TaskRepository | `stitch-runs/ST-Loading-offline/v0.html` | todo |
| ST-Saved Đã lưu xong | [26:217](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-217) | State | `/today/add/result` | TaskFormViewModel | TaskRepository | `stitch-runs/ST-Saved/v1.html` | todo |
| ST-Error Chưa lưu được | [26:159](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-159) | State | `/today/add/result` | TaskFormViewModel | TaskRepository, CrashService | `stitch-runs/ST-Error/v0.html` | todo |
| N16 Đã lưu · nhắc cần kiểm tra | [43:290](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-290) | State | `/today/add/result` | TaskFormViewModel | ReminderService | `stitch-runs/N16/v1.html` | todo |
| S15 Sửa việc | [1:2624](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2624) | Màn | `/today/task/:id/edit` | TaskFormViewModel | TaskRepository | `stitch-runs/S15/v1.html` | todo |
| DLG-Delete Xóa việc | [29:98](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-98) | Dialog | `/today/task/:id/edit (dialog)` | TaskFormViewModel | TaskRepository | `stitch-runs/DLG-Delete/v1.html` | todo |
| S03-edited Hôm nay · đã lưu thay đổi | [8:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=8-2) | State | `/today (snackbar)` | TodayViewModel | TaskRepository | `stitch-runs/S03-edited/v1.html` | todo |
| S03-deleted Hôm nay · đã xóa việc | [7:168](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=7-168) | State | `/today (snackbar)` | TodayViewModel | TaskRepository | `stitch-runs/S03-deleted/v1.html` | todo |

## F5 · Thêm việc bằng giọng nói — Khang

**Xong khi:** Từ chối micro không crash; nói không rõ hiện V04; tắt cờ trên console thì nút "Nói việc" ở S05 biến mất, không cần build lại.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| V00 Cho phép dùng micro | [140:112](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-112) | State | `/today/voice` | VoiceAddViewModel | SpeechService | — | todo |
| V01 Nói để thêm việc – sẵn sàng | [140:147](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-147) | Màn | `/today/voice` | VoiceAddViewModel | SpeechService, RemoteConfigService | — | todo |
| V02 Đang nghe Bác nói | [140:176](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-176) | State | `/today/voice` | VoiceAddViewModel | SpeechService | — | todo |
| V03 Bác xem lại việc vừa nói | [140:205](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-205) | State | `/today/voice` | VoiceAddViewModel | SpeechService, TaskRepository | — | todo |
| V04 Chưa nghe rõ | [140:256](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-256) | State | `/today/voice` | VoiceAddViewModel | SpeechService | — | todo |
| V05 Đã thêm việc bằng giọng nói | [140:290](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-290) | State | `/today/voice` | VoiceAddViewModel | TaskRepository | — | todo |

## F6 · Lời nhắc đến giờ (Flow 6) — Khang

**Xong khi:** Đổi `snooze_minutes` 10 → 15 trên console thì nút S14 đổi theo; bấm thông báo mở đúng S14.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S14 Lời nhắc đến giờ | [1:635](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-635) | Màn | `/reminder/:taskId` | ReminderViewModel | ReminderService, RemoteConfigService | `stitch-runs/S14/v2.html` | todo |
| S03-snooze Hôm nay · nhắc lại sau 10 phút | [11:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=11-2) | State | `/today (snackbar)` | TodayViewModel | ReminderService | `stitch-runs/S03-snooze/v1.html` | todo |
| N07 Cài đặt nhắc việc | [41:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=41-2) | Màn | `/settings/reminders` | ReminderSettingsViewModel | ReminderService, SettingsService | `codex-runs/N07/v4.html` | todo |

## F7 · Lịch tuần + xuất PDF (Flow 4) — Hương

**Xong khi:** Thêm nút "Xuất PDF" vào S07 (ghi traceability + sửa Figma). PDF đúng tuần đang xem; có thanh tiến độ + link tải.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S07 Lịch tuần | [1:970](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-970) | Màn (tab 1) | `/week` | WeekViewModel | TaskRepository, ReportService | `stitch-runs/S07/v1.html` | todo |
| S07 Lịch tuần (cuộn xuống) | [1:1136](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1136) | Màn (tab 1) | `/week` | WeekViewModel | TaskRepository, ReportService | `stitch-runs/S07/v1.html` | todo |
| S11 Chi tiết ngày | [1:1303](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1303) | Màn | `/week/:date · /today/all` | DayDetailViewModel | TaskRepository | `stitch-runs/S11/v3.html` | todo |
| S11 Chi tiết ngày (cuộn xuống) | [1:1446](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1446) | Màn | `/week/:date · /today/all` | DayDetailViewModel | TaskRepository | `stitch-runs/S11/v3.html` | todo |
| S11b Chi tiết ngày · ngày khác | [14:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=14-2) | State | `/week/:date` | DayDetailViewModel | TaskRepository | `stitch-runs/S11b/v1.html` | todo |

## F8 · Cài đặt hiển thị & hồ sơ — Sanh

**Xong khi:** Đổi cỡ chữ áp dụng toàn app; đúng ở 360 và 412 dp, không tràn chữ.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S10 Cài đặt hiển thị | [1:2325](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2325) | Màn | `/settings` | SettingsViewModel | SettingsService, AuthService | `stitch-runs/S10/v1.html` | todo |
| S10 Cài đặt hiển thị (cuộn xuống) | [1:2474](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2474) | Màn | `/settings` | SettingsViewModel | SettingsService, AuthService | `stitch-runs/S10/v1.html` | todo |
| N06 Thông tin của Bác (Sửa hồ sơ) | [38:187](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-187) | Màn | `/settings/profile` | ProfileViewModel | ProfileService | `stitch-runs/N06/v2.html` | todo |
| N08 Cách dùng đơn giản | [41:85](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=41-85) | Màn | `/settings/help` | — (tĩnh) | — | `codex-runs/N08/v2.html` | todo |
| N20 Dữ liệu trên điện thoại | [52:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-2) | Màn | `/settings/data` | — (tĩnh) | — | `codex-runs/N20/v1.html` | todo |

## F9 · 9 thói quen Power 9 (Flow 8 – Flow chính 1) — Hương

**Xong khi:** Đi hết Flow chính 1: S08 → S16 → thêm việc → ST-Saved; "Tuần này: x lần" tính từ dữ liệu thật.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S08 9 thói quen | [1:1590](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1590) | Màn (tab 2) | `/habits` | HabitsViewModel | HabitRepository, TaskRepository | `stitch-runs/S08/v2.html` | todo |
| S08 Tuần này (thống kê) | [1:1740](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1740) | Màn (tab 2) | `/habits` | HabitsViewModel | HabitRepository, TaskRepository | `stitch-runs/S08/v2.html` | todo |
| S16 Chi tiết thói quen | [1:1934](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1934) | Màn | `/habits/:key` | HabitDetailViewModel | HabitRepository, TaskRepository | `stitch-runs/S16/v4.html` | todo |

## F10 · Firebase: thông báo, Remote Config, Crashlytics, khu demo — Hiếu

**Xong khi:** Hộp thông báo + khu demo chưa có trong Figma: thiết kế thêm trên N06. Mỗi dịch vụ có ảnh bằng chứng trong `evidence/`.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N06 Thông tin của Bác (Sửa hồ sơ) | [38:187](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-187) | Màn | `/settings/profile` | ProfileViewModel | ProfileService | `stitch-runs/N06/v2.html` | todo |

## F11 · Gia đình: thêm người thân, nhắn tin (Flow 5, Flow 9) — Hương

**Xong khi:** Số sai hiện S12e có ví dụ; từ chối quyền danh bạ vẫn tự nhập được; xoá người thân có xác nhận.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S09 Gia đình | [1:1993](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1993) | Màn (tab 3) | `/family` | FamilyViewModel | FamilyRepository, SuggestionService | `stitch-runs/S09/v0.html` | todo |
| S09b Gia đình · đã thêm người thân | [26:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-2) | State | `/family` | FamilyViewModel | FamilyRepository | `stitch-runs/S09b/v1.html` | todo |
| S12 Thêm người thân | [1:2110](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2110) | Màn | `/family/add` | RelativeFormViewModel | FamilyRepository | `stitch-runs/S12/v1.html` | todo |
| S12 Thêm người thân – chọn từ danh bạ | [1:2146](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2146) | Màn | `/family/add` | RelativeFormViewModel | FamilyRepository | `stitch-runs/S12/v1.html` | todo |
| S12 Thêm người thân – tự nhập | [1:2215](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2215) | Màn | `/family/add` | RelativeFormViewModel | FamilyRepository | `stitch-runs/S12/v1.html` | todo |
| S12a Thêm người thân · chưa có số | [14:120](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=14-120) | State | `/family/add` | RelativeFormViewModel | — | `stitch-runs/S12a/v0.html` | todo |
| S12e Thêm người thân · số sai | [14:196](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=14-196) | State | `/family/add` | RelativeFormViewModel | — | `stitch-runs/S12e/v1.html` | todo |
| N09 Sửa người thân | [41:136](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=41-136) | Màn | `/family/:personId/edit` | RelativeFormViewModel | FamilyRepository | `stitch-runs/N09/v0.html` | todo |
| N15 Xóa người thân | [43:263](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-263) | Dialog | `/family/:personId/edit (dialog)` | RelativeFormViewModel | FamilyRepository | `stitch-runs/N15/v0.html` | todo |
| N21 Gia đình sau khi xóa người thân | [52:48](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-48) | State | `/family` | FamilyViewModel | FamilyRepository | `stitch-runs/N21/v1.html` | todo |
| S17 Nhắn tin cho người thân | [1:2278](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2278) | Màn | `/family/:personId/share` | ShareMessageViewModel | FamilyRepository, TaskRepository | `stitch-runs/S17/v1.html` | todo |
| S17b Nhắn tin · đã mở chia sẻ | [26:122](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-122) | State | `/family/:personId/share` | ShareMessageViewModel | — | `stitch-runs/S17b/v1.html` | todo |
| N10 Đã mở ứng dụng chia sẻ | [41:205](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=41-205) | State | `/family/:personId/share` | ShareMessageViewModel | — | `stitch-runs/N10/v0.html` | todo |

## F12 · Gợi ý lịch: Con cháu gửi ↔ Bác nhận — Sanh

**Xong khi:** Mẹ nhận gợi ý ≤ 2 lần chạm (chỉ số #6); nhận tạo đúng việc trong lịch của mẹ; bỏ qua không báo lại cho con. Thẻ G12 đặt trên S03 qua widget dùng chung của F0, không sửa vào code F3 của Khang.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| G01 Con cháu soạn lịch gợi ý | [52:161](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-161) | Màn (máy con cháu) | `/caregiver/suggest` | SuggestionComposeViewModel | SuggestionService | `codex-runs/G01/v2.html` | todo |
| G01b Soạn gợi ý · chọn giờ | [52:230](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-230) | State | `/caregiver/suggest` | SuggestionComposeViewModel | — | `codex-runs/G01b/v2.html` | todo |
| G02 Đã gửi gợi ý | [56:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=56-2) | State | `/caregiver/suggest` | SuggestionComposeViewModel | SuggestionService | `codex-runs/G02/v1.html` | todo |
| G03 Lịch Mai gợi ý | [56:107](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=56-107) | Màn | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService | `codex-runs/G03/v3.html` | todo |
| G03b Lịch Mai gợi ý · đã đổi giờ | [56:201](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=56-201) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService | `codex-runs/G03b/v2.html` | todo |
| G04 Đổi giờ đi bộ | [57:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=57-2) | Dialog | `/today/suggestions/:id (dialog)` | SuggestionReviewViewModel | — | `codex-runs/G04/v2.html` | todo |
| G05 Đã nhận gợi ý | [57:128](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=57-128) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService, TaskRepository | `codex-runs/G05/v3.html` | todo |
| G05b Đã nhận · đổi giờ | [58:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=58-2) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService, TaskRepository | `codex-runs/G05b/v1.html` | todo |
| G06 Chọn từng việc | [58:117](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=58-117) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService | `codex-runs/G06/v5.html` | todo |
| G07 Đã nhận một việc | [61:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=61-2) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService, TaskRepository | `codex-runs/G07/v1.html` | todo |
| G07b Đã nhận một việc · nhánh B | [61:118](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=61-118) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService, TaskRepository | `codex-runs/G07b/v1.html` | todo |
| G08 Lịch ngày mai | [61:233](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=61-233) | State | `/week/:date (ngày mai)` | DayDetailViewModel | TaskRepository | `codex-runs/G08/v2.html` | todo |
| G08b Lịch ngày mai | [63:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=63-2) | State | `/week/:date (ngày mai)` | DayDetailViewModel | TaskRepository | `codex-runs/G08b/v0.html` | todo |
| G08c Lịch ngày mai | [63:102](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=63-102) | State | `/week/:date (ngày mai)` | DayDetailViewModel | TaskRepository | `codex-runs/G08c/v3.html` | todo |
| G08d Lịch ngày mai | [63:179](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=63-179) | State | `/week/:date (ngày mai)` | DayDetailViewModel | TaskRepository | `codex-runs/G08d/v0.html` | todo |
| G09 Đã bỏ qua gợi ý | [66:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=66-2) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService | `codex-runs/G09/v2.html` | todo |
| G10 Có gợi ý mới (tự hiện) | [66:119](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=66-119) | Dialog | `/today (popup)` | SuggestionInboxViewModel | SuggestionService | `stitch-runs/G10/v1.html` | todo |
| G11 Popup Mai gửi lịch cho Bác | [71:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=71-2) | Dialog | `/today (popup)` | SuggestionInboxViewModel | SuggestionService | `stitch-runs/G11/v2.html` | todo |
| G12 Hôm nay · thẻ gợi ý của Mai | [71:209](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=71-209) | State | `/today (thẻ đầu trang)` | SuggestionInboxViewModel | SuggestionService | `stitch-runs/G12/v1.html` | todo |

## F13 · Ghép nối máy con cháu với máy mẹ (Flow 10) — Hiếu

**Xong khi:** Ghép nối được giữa 2 máy thật; mã hết hạn hiện C02e; rules chặn người lạ đọc lịch của mẹ.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C02 Nhập mã ghép nối | [1:3382](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-3382) | Màn | `/caregiver/pair` | PairingViewModel | PairingService | `codex-runs/C02/v2.html` | todo |
| C02e Mã sai hoặc hết hạn | [71:402](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=71-402) | State | `/caregiver/pair` | PairingViewModel | PairingService | `codex-runs/C02e/v3.html` | todo |

## F14 · Con cháu lập lịch cho mẹ (Flow 11, 12 – Flow chính 3) — Hiếu

**Xong khi:** Đi hết Flow chính 3 từ C03 tới C09; lập 1 lịch lặp ≤ 90 giây, ≤ 3 bước (chỉ số #5).

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C03 Lịch của mẹ Lan (Hoàn thiện biểu tượng & Bố cục) | [1:3148](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-3148) | Màn | `/caregiver/schedule?view=day` | MomScheduleViewModel | CaregiverScheduleService | `codex-runs/C03/v3.html` | todo |
| C04 Lịch của mẹ · Tuần | [73:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=73-2) | State | `/caregiver/schedule?view=week` | MomScheduleViewModel | CaregiverScheduleService | `codex-runs/C04/v2.html` | todo |
| C05 Lịch của mẹ · Tháng | [73:105](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=73-105) | State | `/caregiver/schedule?view=month` | MomScheduleViewModel | CaregiverScheduleService | `codex-runs/C05/v2.html` | todo |
| C06 Tạo việc gợi ý (Bước 1/3) | [1:3036](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-3036) | Màn | `/caregiver/task/new` | CaregiverTaskFormViewModel | — | `codex-runs/C06/v1.html` | todo |
| C06e Thiếu tên hoặc giờ | [74:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=74-2) | State | `/caregiver/task/new` | CaregiverTaskFormViewModel | — | `codex-runs/C06e/v1.html` | todo |
| C07 Lặp lại việc gợi ý (Bước 2/3) | [1:2764](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2764) | Màn | `/caregiver/task/new/repeat` | CaregiverTaskFormViewModel | — | `codex-runs/C07/v4.html` | todo |
| C07m Lặp lại mỗi tháng (Bước 2/3) | [74:98](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=74-98) | State | `/caregiver/task/new/repeat` | CaregiverTaskFormViewModel | — | `codex-runs/C07m/v3.html` | todo |
| C08 Xem lại và gửi gợi ý (Bước 3/3) | [1:2960](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2960) | Màn | `/caregiver/task/new/review` | CaregiverTaskFormViewModel | CaregiverScheduleService, SuggestionService | `codex-runs/C08/v3.html` | todo |
| C08w Trùng giờ | [74:235](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=74-235) | Dialog | `/caregiver/task/new/review (dialog)` | CaregiverTaskFormViewModel | CaregiverScheduleService | `codex-runs/C08w/v2.html` | todo |
| C09 Đã gửi cho mẹ | [1:2717](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2717) | State | `/caregiver/task/sent` | CaregiverTaskFormViewModel | SuggestionService | `codex-runs/C09/v2.html` | todo |
| C10 Chi tiết việc lặp lại | [75:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=75-2) | Màn | `/caregiver/task/:id` | RecurringTaskViewModel | CaregiverScheduleService | `codex-runs/C10/v0.html` | todo |

## Khung có trong flow Lab 2 nhưng chưa có trong danh sách Figma ở trên

| Mã | Mô tả (theo `lab2/flutter-handoff.md`) | Thuộc | Ghi chú |
| --- | --- | --- | --- |
| C11 | Dialog "Áp dụng thay đổi cho" (chỉ lần này / từ lần này về sau / tất cả / hủy) | F14 – Hiếu | Flow 12; Stitch chưa chạy. Làm theo handoff, ghi DT nếu khác |
| C12 | Dialog "Ngưng lịch lặp" (Giữ lại / Ngưng lặp lại) | F14 – Hiếu | Flow 12; như trên |
| Hộp thông báo | Danh sách thông báo FCM, route `/inbox` | F10 – Hiếu | Cần thiết kế thêm (DT-03) |
| Khu demo Firebase | Trên N06 | F10 – Hiếu | Cần thiết kế thêm (DT-03) |

## Thay đổi so với Figma (bắt buộc ghi, đề Lab 3 › "Changes to the design")

| # | Màn | Thay đổi | Lý do | Đã sửa Figma? |
| --- | --- | --- | --- | --- |
| DT-01 | A01 | Nút chính "Tiếp tục với Google" thay cho nhập số điện thoại; A02–A04 làm sau nếu kịp | Đề Lab 3 bắt buộc Google Sign-In | ☐ |
| DT-02 | S07 | Thêm nút "Xuất PDF" + thanh tiến độ + link tải | Đề Lab 3 bắt buộc sinh 1 file và upload | ☐ |
| DT-03 | N06 | Thêm khu demo Firebase + Hộp thông báo | Đề Lab 3 bắt buộc Firebase demo area | ☐ |
| DT-04 | S05, V00–V05 | Nút "Nói việc" ở S05 mở luồng giọng nói, bật/tắt bằng Remote Config `voice_input_enabled` | Tính năng mới Lab 3 | ☐ |
| DT-05 | N20 | Câu "Chưa đồng bộ sang máy khác" không còn đúng khi dùng Firestore: đổi thành "Lưu trên tài khoản Google của Bác, vẫn dùng được khi mất mạng" | Lab 3 có backend Firebase | ☐ |
| DT-06 | G03–G09 | Route `/today/suggestions/:id` thay cho `/family/suggestions/:id` của handoff | Gợi ý mở chủ yếu từ S03 (G11 / G12); router Lab 3 đã đặt như vậy | — (chỉ route) |
| DT-07 | C06–C08 | Giữ state form 3 bước bằng Riverpod `Notifier` thay cho `Cubit` của handoff | Kiến trúc Lab 3 là MVVM + Riverpod | — (chỉ code) |
| DT-08 | S01, S10 | Cỡ chữ / tương phản lưu qua `SettingsService` (Firestore + cache máy) thay cho chỉ `SharedPreferences` | Đổi máy vẫn giữ cài đặt | — (chỉ code) |

## Ghi chú từ Lab 2 cần nhớ khi code

- Mọi màn: chữ ≥ 20 sp, nội dung 24 sp, nút chính 60 dp, vùng chạm ≥ 48 dp, cách nhau ≥ 8 dp, `textScaler` tới 2.0 không tràn, contrast ≥ 4.5 : 1, không cử chỉ vuốt bắt buộc (`lab2/rule.md`, `lab2/accessibility.md`).
- Bottom nav: nhãn "Lịch tuần" / "Thói quen" xuống 2 dòng ở cỡ 20 → `maxLines: 1` hoặc rút nhãn (`lab2/accessibility.md` mục 7).
- S17 **không bao giờ** báo "Đã gửi" (app không biết kết quả Zalo / SMS).
- G: lịch chỉ đổi khi Bác bấm nhận; không tự báo cho con cháu là Bác đã bỏ qua.
- S14: không có cử chỉ vuốt để tắt; chuông lặp tối đa 1 phút rồi thành thông báo thường.
- Xoá việc là xoá mềm, giữ 7 ngày để Hoàn tác.
- Chế độ Người thân dùng cùng design system, được dùng cỡ chữ "Vừa"; không có màn theo dõi vị trí hay sức khỏe.

