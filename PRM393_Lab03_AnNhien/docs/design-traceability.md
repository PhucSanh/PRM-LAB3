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
| Components Màn mới (Giọng nói & Tài khoản) | [138:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=138-2) | Thư viện | `(toàn app)` | — | — | — | changed (DT-09 → DT-21) |
| S03 Hôm nay | [1:270](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-270) | Màn (tab 0) | `/today` | TodayViewModel | TaskRepository | `stitch-runs/S03/v3.html` | changed (DT-16, DT-17; màn của Khang – F0 chỉ giao widget) |

## F1 · Tài khoản + chọn vai trò (Bác / Con cháu) — Hiếu

**Xong khi:** Chưa đăng nhập không vào app được; huỷ có thông báo; đổi A01 thành nút Google: ghi design-traceability + sửa Figma. A02–A04 (SĐT + mã) làm sau nếu kịp, nếu bỏ thì ghi lý do.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A01 Tạo tài khoản – Số điện thoại (Bước 1/3) | [139:6](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-6) | Màn | `/sign-in` | SignInViewModel | AuthService | — | changed |
| A02 Nhập mã xác nhận (Bước 2/3) | [139:43](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-43) | Màn | `/sign-in (làm sau)` | SignInViewModel | AuthService | — | todo |
| A02e Mã chưa đúng | [139:89](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-89) | State | `/sign-in (làm sau)` | SignInViewModel | AuthService | — | todo |
| A03 Mở app bằng vân tay (Bước 3/3) | [139:136](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-136) | Màn | `/sign-in (làm sau)` | SignInViewModel | AuthService | — | todo |
| A04 Đã tạo tài khoản | [139:178](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-178) | State | `/sign-in (làm sau)` | SignInViewModel | AuthService | — | todo |
| C01 Chọn vai trò | [1:3870](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-3870) | Màn | `/role` | RoleViewModel | ProfileService | `codex-runs/C01/v0.html` | doing |

## F2 · Onboarding của Bác (Flow 1) — Hương

**Xong khi:** Đi hết S01 → Hôm nay có việc đầu tiên; từ chối quyền thì hiện S13d; mở lại app không hỏi lại.

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S01 Chào mừng – chọn cỡ chữ | [1:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2) | Màn | `/welcome` | OnboardingViewModel | SettingsService | `stitch-runs/S01/v2.html` | changed (DT-23) |
| S02 Xác nhận tên (trước S02) | [1:58](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-58) | Màn | `/setup` | OnboardingViewModel | ProfileService | `stitch-runs/S02/v0.html` | changed (DT-24) |
| S02 Thiết lập hồ sơ (Bước 1/2) | [1:103](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-103) | Màn | `/setup` | OnboardingViewModel | ProfileService | `stitch-runs/S02/v0.html` | changed (DT-24) |
| S02 Nhập lại tên | [1:176](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-176) | Màn | `/setup` | OnboardingViewModel | ProfileService | `stitch-runs/S02/v0.html` | changed (DT-24) |
| DLG-WakeTime Chọn giờ thức dậy | [31:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-2) | Dialog | `/setup (dialog)` | OnboardingViewModel | — | `stitch-runs/DLG-WakeTime/v1.html` | changed (DT-12) |
| S13 Cho phép nhắc việc (Bước 2/2) | [1:217](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-217) | Màn | `/setup/notifications` | OnboardingViewModel | ReminderService (quyền) | `stitch-runs/S13/v1.html` | changed (DT-25) |
| S13d Nhắc việc đang tắt | [14:284](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=14-284) | State | `/setup/notifications` | OnboardingViewModel | ReminderService (quyền) | `stitch-runs/S13d/v1.html` | changed (DT-25) |
| N01 Thử lời nhắc | [31:68](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-68) | Màn | `/setup/try-reminder` | TryReminderViewModel | ReminderService | `codex-runs/N01/v3.html` | changed (DT-26) |
| N02 Đã nhận lời nhắc | [31:170](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-170) | State | `/setup/try-reminder` | TryReminderViewModel | ReminderService | `codex-runs/N02/v3.html` | changed (DT-26) |
| N03 Chưa nhận lời nhắc | [31:218](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-218) | State | `/setup/try-reminder` | TryReminderViewModel | ReminderService | `codex-runs/N03/v2.html` | changed (DT-26) |
| N04 Chọn việc đầu tiên | [38:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-2) | Màn | `/setup/first-task` | FirstTaskViewModel | TaskRepository | `codex-runs/N04/v2.html` | changed (DT-27) |
| N05 Xem lại việc đầu tiên | [38:108](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-108) | Màn | `/setup/first-task` | FirstTaskViewModel | TaskRepository | `codex-runs/N05/v3.html` | changed (DT-27) |
| N18 Đã lưu việc đầu tiên | [47:170](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=47-170) | State | `/setup/first-task` | FirstTaskViewModel | TaskRepository | `stitch-runs/N18/v0.html` | changed (DT-27) |
| N19 Hôm nay · việc đầu tiên | [47:225](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=47-225) | State | `/today` | TodayViewModel | TaskRepository | `stitch-runs/N19/v1.html` | todo (chờ Khang – F3: state S03 có đúng 1 việc vừa thêm; F2 đã lưu việc qua cùng `TaskRepository`) |

## F3 · Hôm nay: làm xong / dời / bỏ qua (Flow 3) — Khang

**Xong khi:** Đủ loading / trống / lỗi + Thử lại; Hoàn tác trả lại trạng thái cũ; đánh dấu xong ≤ 2 lần chạm (chỉ số thành công #1).

| Khung Figma | Node | Loại | Route | ViewModel | Nguồn dữ liệu | Stitch (Lab 2) | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S03 Hôm nay | [1:270](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-270) | Màn (tab 0) | `/today` | TodayViewModel | TaskRepository | `stitch-runs/S03/v3.html` | done (DT-34) |
| S03 Hôm nay – xem từng việc (bấm nút) | [1:487](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-487) | Màn (tab 0) | `/today` | TodayViewModel | TaskRepository | `stitch-runs/S03/v3.html` | done (DT-34) |
| S03b Hôm nay sau khi xong 1 việc | [12:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=12-2) | State | `/today` | TodayViewModel | TaskRepository | `stitch-runs/S03b/v2.html` | done (DT-34) |
| S03-alldone Hôm nay · xong 6/6 | [7:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=7-2) | State | `/today` | TodayViewModel | TaskRepository | `stitch-runs/S03-alldone/v2.html` | done (DT-34) |
| N17 Hôm nay · đã xử lý hết (5 xong · 1 bỏ qua) | [47:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=47-2) | State | `/today` | TodayViewModel | TaskRepository | `stitch-runs/N17/v0.html` | done (DT-34) |
| ST-Empty Hôm nay chưa có việc | [15:39](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=15-39) | State | `/today` | TodayViewModel | TaskRepository | `stitch-runs/ST-Empty/v1.html` | done (DT-34) |
| S04 Chi tiết hoạt động | [1:580](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-580) | Màn | `/today/task/:id · /week/:date/task/:id` | TaskDetailViewModel | TaskRepository | `stitch-runs/S04/v0.html` | done (DT-34) |
| DLG-Done Xác nhận đã xong | [29:125](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-125) | Dialog | `/today (dialog)` | TodayViewModel | TaskRepository | `stitch-runs/DLG-Done/v2.html` | done (DT-34) |
| DLG-Later Dời việc | [29:156](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-156) | Dialog | `/today (dialog)` | TodayViewModel | TaskRepository | `stitch-runs/DLG-Later/v1.html` | changed (DT-34) |
| DLG-Skip Bỏ qua hôm nay | [29:211](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-211) | Dialog | `/today (dialog)` | TodayViewModel | TaskRepository | `stitch-runs/DLG-Skip/v1.html` | done (DT-34) |
| S03-later Hôm nay (đã dời 30 phút) | [8:189](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=8-189) | State | `/today (snackbar)` | TodayViewModel | TaskRepository | `stitch-runs/S03-later/v2.html` | done (DT-34) |
| S03-later4 Hôm nay · dời chiều nay | [10:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=10-2) | State | `/today (snackbar)` | TodayViewModel | TaskRepository | `stitch-runs/S03-later4/v0.html` | done (DT-34) |
| S03-tomorrow Hôm nay · dời ngày mai | [11:189](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=11-189) | State | `/today (snackbar)` | TodayViewModel | TaskRepository | `stitch-runs/S03-tomorrow/v2.html` | changed (DT-34) |
| S03-skip Hôm nay · đã bỏ qua | [10:193](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=10-193) | State | `/today (snackbar)` | TodayViewModel | TaskRepository | `stitch-runs/S03-skip/v1.html` | done (DT-34) |

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
| S10 Cài đặt hiển thị | [1:2325](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2325) | Màn | `/settings` | SettingsViewModel | SettingsService (+ `SignOutViewModel` của F1 cho Đăng xuất) | `stitch-runs/S10/v1.html` | changed (DT-28) |
| S10 Cài đặt hiển thị (cuộn xuống) | [1:2474](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2474) | Màn | `/settings` | SettingsViewModel | SettingsService (+ `SignOutViewModel` của F1 cho Đăng xuất) | `stitch-runs/S10/v1.html` | changed (DT-28) |
| N06 Thông tin của Bác (Sửa hồ sơ) | [38:187](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-187) | Màn | `/settings/profile` | ProfileViewModel | ProfileService, ProfileSetupService (`watchSetup` / `saveSetup`) | `stitch-runs/N06/v2.html` | changed (DT-29) |
| N08 Cách dùng đơn giản | [41:85](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=41-85) | Màn | `/settings/help` | — (tĩnh) | — | `codex-runs/N08/v2.html` | changed (DT-31) |
| N20 Dữ liệu trên điện thoại | [52:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-2) | Màn | `/settings/data` | — (tĩnh) | — | `codex-runs/N20/v1.html` | changed (DT-30) |

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
| N06 Thông tin của Bác (Sửa hồ sơ) | [38:187](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-187) | Màn | `/settings/profile` | ProfileViewModel | ProfileService | `stitch-runs/N06/v2.html` | F8 form xong (DT-29); lối vào khu demo F10 (`FirebaseDemoEntry`) ở cuối N06 |

F10 cập nhật 02/11/2026: `/inbox` → InboxViewModel → MessagingService
(Firestore owner inbox + FCM); `/settings/firebase-demo` → FirebaseDemoViewModel →
RemoteConfig/Crash/Analytics + demoReportService. Đã code và có Fake/widget/rules
tests; chờ thiết bị và Console evidence. Xem [f10-verification.md](f10-verification.md).
Thiết kế mới: [demo 153:224](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=153-224),
[inbox 153:264](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=153-264).

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
| G01 Con cháu soạn lịch gợi ý | [52:161](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-161) | Màn (máy con cháu) | `/caregiver/suggest` | SuggestionComposeViewModel | SuggestionService | `codex-runs/G01/v2.html` | changed (DT-29) |
| G01b Soạn gợi ý · chọn giờ | [52:230](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-230) | State | `/caregiver/suggest` | SuggestionComposeViewModel | SuggestionService | `codex-runs/G01b/v2.html` | changed (DT-29) |
| G02 Đã gửi gợi ý | [56:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=56-2) | State | `/caregiver/suggest` | SuggestionComposeViewModel | SuggestionService | `codex-runs/G02/v1.html` | changed (DT-30) |
| G03 Lịch Mai gợi ý | [56:107](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=56-107) | Màn | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService | `codex-runs/G03/v3.html` | changed (DT-31) |
| G03b Lịch Mai gợi ý · đã đổi giờ | [56:201](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=56-201) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService | `codex-runs/G03b/v2.html` | changed (DT-31) |
| G04 Đổi giờ đi bộ | [57:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=57-2) | State (toàn trang) | `/today/suggestions/:id` | SuggestionReviewViewModel | — | `codex-runs/G04/v2.html` | changed (DT-31) |
| G05 Đã nhận gợi ý | [57:128](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=57-128) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService, TaskRepository | `codex-runs/G05/v3.html` | changed (DT-31) |
| G05b Đã nhận · đổi giờ | [58:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=58-2) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService, TaskRepository | `codex-runs/G05b/v1.html` | changed (DT-31) |
| G06 Chọn từng việc | [58:117](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=58-117) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService | `codex-runs/G06/v5.html` | changed (DT-32) |
| G07 Đã nhận một việc | [61:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=61-2) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService, TaskRepository | `codex-runs/G07/v1.html` | changed (DT-32) |
| G07b Đã nhận một việc · nhánh B | [61:118](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=61-118) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService, TaskRepository | `codex-runs/G07b/v1.html` | changed (DT-32) |
| G08 Lịch ngày mai | [61:233](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=61-233) | State | `/week/:date (ngày mai)` | DayDetailViewModel | TaskRepository | `codex-runs/G08/v2.html` | todo (chờ Hương – F7 S11) |
| G08b Lịch ngày mai | [63:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=63-2) | State | `/week/:date (ngày mai)` | DayDetailViewModel | TaskRepository | `codex-runs/G08b/v0.html` | todo (chờ Hương – F7 S11) |
| G08c Lịch ngày mai | [63:102](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=63-102) | State | `/week/:date (ngày mai)` | DayDetailViewModel | TaskRepository | `codex-runs/G08c/v3.html` | todo (chờ Hương – F7 S11) |
| G08d Lịch ngày mai | [63:179](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=63-179) | State | `/week/:date (ngày mai)` | DayDetailViewModel | TaskRepository | `codex-runs/G08d/v0.html` | todo (chờ Hương – F7 S11) |
| G09 Đã bỏ qua gợi ý | [66:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=66-2) | State | `/today/suggestions/:id` | SuggestionReviewViewModel | SuggestionService | `codex-runs/G09/v2.html` | changed (DT-32) |
| G10 Có gợi ý mới (tự hiện) | [66:119](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=66-119) | Dialog | `/today (popup)` | SuggestionInboxViewModel | SuggestionService | `stitch-runs/G10/v1.html` | changed (DT-33) |
| G11 Popup Mai gửi lịch cho Bác | [71:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=71-2) | Dialog | `/today (popup)` | SuggestionInboxViewModel | SuggestionService | `stitch-runs/G11/v2.html` | changed (DT-33) |
| G12 Hôm nay · thẻ gợi ý của Mai | [71:209](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=71-209) | State | `/today (thẻ đầu trang)` | SuggestionInboxViewModel | SuggestionService | `stitch-runs/G12/v1.html` | changed (DT-33) – chờ Khang đặt thẻ trên S03 |

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
| Hộp thông báo | Danh sách thông báo FCM, route `/inbox` | F10 – Hiếu | Đã thêm thiết kế DT-03; xem phần F10 |
| Khu demo Firebase | Trên N06 | F10 – Hiếu | Đã thêm thiết kế DT-03; xem phần F10 |

## Thay đổi so với Figma (bắt buộc ghi, đề Lab 3 › "Changes to the design")

| # | Màn | Thay đổi | Lý do | Đã sửa Figma? |
| --- | --- | --- | --- | --- |
| DT-01 | A01 | Nút chính "Tiếp tục với Google" thay cho nhập số điện thoại; A02–A04 làm sau nếu kịp | Đề Lab 3 bắt buộc Google Sign-In | ☐ |
| DT-02 | S07 | Thêm nút "Xuất PDF" + thanh tiến độ + link tải | Đề Lab 3 bắt buộc sinh 1 file và upload | ☐ |
| DT-03 | N06 | Thêm nút mở khu thử tính năng + demo / inbox riêng; tệp thử PDF ghi rõ không phải lịch tuần | Đề Lab 3 bắt buộc Firebase demo area | ☑ N06 + 153:224 + 153:264; chưa nối prototype |
| DT-04 | S05, V00–V05 | Nút "Nói việc" ở S05 mở luồng giọng nói, bật/tắt bằng Remote Config `voice_input_enabled` | Tính năng mới Lab 3 | ☐ |
| DT-05 | N20 | Câu "Chưa đồng bộ sang máy khác" không còn đúng khi dùng Firestore: đổi thành "Lưu trên tài khoản Google của Bác, vẫn dùng được khi mất mạng" (**câu chốt ở DT-30**) | Lab 3 có backend Firebase | ☐ |
| DT-06 | G03–G09 | Route `/today/suggestions/:id` thay cho `/family/suggestions/:id` của handoff | Gợi ý mở chủ yếu từ S03 (G11 / G12); router Lab 3 đã đặt như vậy | — (chỉ route) |
| DT-07 | C06–C08 | Giữ state form 3 bước bằng Riverpod `Notifier` thay cho `Cubit` của handoff | Kiến trúc Lab 3 là MVVM + Riverpod | — (chỉ code) |
| DT-08 | S01, S10 | Cỡ chữ / tương phản lưu qua `SettingsService` (Firestore + cache máy) thay cho chỉ `SharedPreferences` | Đổi máy vẫn giữ cài đặt | — (chỉ code) |
| DT-09 | Components `138:2`, mọi màn | Icon Lucide trong Figma được thay bằng icon Material gần nhất (`lib/theme/app_icons.dart`), hình nét hơi khác | Không thêm package icon ở F0; nghĩa từng icon giữ đúng Từ điển icon của DESIGN.md | — (chỉ code) |
| DT-10 | S03b, S03-skip, G09 (snackbar Hoàn tác) | Câu chữ ở tầng trên, hàng nút ở tầng dưới (Figma S03b đặt chữ và "Hoàn tác" cùng một hàng); thêm nút "Đóng"; nút "Hoàn tác" cao 72 thay vì 48 | Theo handoff › Snackbar (2 tầng) và prompt F0-03 (có nút đóng vì snackbar không tự tắt); vùng chạm 72 theo rule.md R-TAP-01 | ☐ |
| DT-11 | DLG-*, N13, N14, ST-Loading / Empty / Error | Icon đầu hộp thoại / màn trạng thái 64 dp trong vòng tròn 112 (Figma ≈ 44 trong vòng 80); nút trong hộp thoại cao 72 (Figma 60) | Handoff ghi "icon 64"; dùng chung `IconCircle` cho hộp thoại và ST-*; vùng chạm 72 toàn app | ☐ |
| DT-12 | DLG-TaskTime `29:256`, DLG-WakeTime `31:2` | Làm theo Figma (lưới nút chạm), **không** theo handoff / prompt F0-04 (3 cột `ListWheelScrollView`, phút bước 5, "Xong"). Lệch Figma: ô cao 72 (Figma 48); hàng Sáng / Chiều đưa lên ngay dưới lưới giờ, phút xuống cuối; dòng "Bác chọn: …" + "Lưu giờ" / "Hủy" ghim ở đáy hộp, phần lưới cuộn (thanh cuộn luôn hiện); nút "Hủy" có icon ✕; giờ đã lưu có phút lẻ (vd. 9:40) thì thêm ô phút đó. Hàm vẫn tên `showTimeWheel()` | Nhóm chốt theo Figma (không bắt vuốt, hợp người 65+). Ô 72 theo rule.md R-TAP-01; lưới cao hơn màn 800 dp ở cỡ chữ lớn nên ghim phần quan trọng ở đáy và để buổi (đổi nghĩa giờ) trước phút (thường để 00) | ☐ |
| DT-13 | S02, S06, S12 (ô nhập, ô giờ) | Ô nhập / ô giờ cao ≥ 72 (Figma 60); giờ viết "6:00 sáng" (Figma "6 : 00 sáng"); ô giờ luôn có chữ "Đổi giờ ⌄" (S02 Figma chỉ có ⌄); khi lỗi, câu "Ví dụ…" thụt vào thẳng hàng câu lỗi ở mọi màn (giống S12e) | rule.md R-TAP-01; AppStyleGuide SG-10 (giờ "9:30 sáng"); ô giờ là nút nên cần chữ chỉ hành động | ☐ |
| DT-14 | S10 `1:2325` / `1:2474`, N07 `41:2` (hàng công tắc) | Chữ "Đang bật / Đang tắt" đặt dưới câu phụ (N07 đặt dưới công tắc, S10 không có); công tắc dùng kích thước Material mặc định (Figma 64 × 48), cả hàng 72 là vùng chạm | Thêm dấu hiệu không chỉ bằng màu cho mọi hàng; đặt dưới câu phụ để cột chữ không bị bóp ở 360 dp × 1.3 | ☐ |
| DT-15 | S01 `1:2`, S10, S12, N12 `43:95`, C07 `1:2764` (nhóm chọn một) | Một kiểu chung cho mọi khung: dấu tích tròn bên trái (S10 Figma đặt bên phải, N12 / S12 / C07 dùng chấm radio) + chữ "Đang chọn" bên phải (S01, S10 Figma không có); ô cao ≥ 72 (Figma 60), cách nhau 20 | Prompt F0-04: đang chọn phải có dấu tích, không chỉ dựa vào màu; một widget `ChoiceGroup` cho mọi màn; rule.md R-TAP-01 / R-TAP-03 | ☐ |
| DT-16 | S03 `1:270`, S03b `12:2`, S03-skip `10:193`, S03-later `8:189`, G12 `71:209` (thẻ Việc tiếp theo) | Theo bản mới (S03b / G12: nền trắng viền `primary`, "🔔 Việc tiếp theo · 9:30 sáng", dòng "20 phút · Vận động tự nhiên"), không theo S03 `1:270` cũ (nền vàng, "Dời lại" cạnh giờ, chip "Đang chờ"). Nút "Đã xong" đặt **trong thẻ** (Figma đặt "Đã xong việc …" ở thanh đáy cố định), thêm nút chữ "Hôm nay bỏ qua"; nút cao 72 (Figma 60) | Prompt F0-05: `NextTaskCard` có `onDone` / `onLater` / `onSkip`, "Đã xong" là `AppButton` primary trong thẻ. Nếu S03 cần giữ nút ở thanh đáy như Figma, Khang báo để thêm tuỳ chọn ẩn nút trong thẻ | ☐ |
| DT-17 | S03, S03-skip, S03-later (TaskRow) | Chip việc chưa làm ghi "Chưa làm" (S03 `1:270` ghi "Đang chờ") theo G12 + Từ điển icon; chip "Đã dời" dùng icon `redo-2` (Từ điển icon), chip "Bỏ qua" icon `circle-minus`; nền thẻ luôn trắng (S03 cũ tô vàng việc chưa làm); giờ chẵn "3 giờ chiều", giờ lẻ "9:30 sáng"; mũi tên › chỉ khi `showChevron` (S16) | Thống nhất theo khung mới + DESIGN.md › `status-*`; SG-10 | ☐ |
| DT-18 | S05 `1:688`, S08 `1:1590` (HabitTile) | S05: chữ "Đã chọn / Chọn" nằm dưới tên việc (Figma: dưới dấu chọn ở cột phải); dấu chọn là ✓ tròn đặc (`AppIcons.radioOn`) như Figma S05, trong khi Từ điển icon ghi "Đang chọn" = `circle-dot`. Icon 9 thói quen là icon Material gần nhất (footprints → đi bộ, salad → bát cơm…, xem DT-09) | Cột phải hẹp, chữ lớn 2.0 bị tràn; mâu thuẫn Figma ↔ Từ điển icon cần nhóm chốt | ☐ |
| DT-19 | S04 `1:580`, S14 `1:635`, S16 `1:1934` (Đọc to) | Đang đọc: dòng "🔊 Đang đọc…" (S14 ghi "Đang đọc to") + nút "Dừng đọc" full-width icon `circle-stop` (S14: nút nhỏ ở giữa, icon ô vuông) | Câu theo prompt F0-05; nút chính cùng một kiểu, cao 72, đúng Từ điển icon | ☐ |
| DT-20 | G12 `71:209` (SuggestionCard) | Thêm danh sách tên việc gợi ý (tối đa 3, quá thì "và n việc khác") và nút chữ "Bỏ qua gợi ý" tuỳ chọn (ViewModel phải hiện Hoàn tác như G09); nút "Xem gợi ý" cao 72 (Figma 56) | Prompt F0-05 (`previewTitles`, `onDismiss`); Bác biết trước có việc gì mà không phải mở G03 | ☐ |
| DT-21 | Thanh "Quay lại + Bước x/y" `138:111`, S04 Back + "Sửa" `1:580` | Chữ "Bước x/y" và nút "Sửa" đặt ở ô co giãn của thanh; khi chữ ×2.0 ở 360 dp không đủ chỗ thì thu nhỏ vừa ô (có thể dưới 20 sp / nút "Sửa" dưới 72 dp trong trường hợp cực hạn này) | Trước đây đặt ở `actions` rộng cố định nên tràn 24 dp ở ×2.0 (bắt được nhờ `gallery_overflow_test`); chỉ thu nhỏ khi thật sự thiếu chỗ (đủ chỗ thì giữ nguyên cỡ) | — (chỉ code) |
| DT-22 | Bottom nav S03 › Nav `1:451` (mọi tab) | Làm theo Figma: nhãn luôn 2 dòng ("Hôm / nay", "Lịch / tuần", "Thói / quen", "Gia / đình"), **không** theo CLAUDE.md / accessibility.md (`maxLines: 1`); bỏ `NavigationBar` Material (nền chỉ bọc icon) để ô đang chọn bọc cả icon + nhãn như Figma. Ô rộng đều theo màn (Figma cố định 72), chữ ×2.0 thiếu chỗ thì nhãn thu nhỏ vừa ô | `maxLines: 1` ở cỡ 20 × 1.15 không đủ chỗ cho "Hôm nay" / "Lịch tuần" trong 4 ô ở 360 dp (phải cắt "…" – cấm theo SG-13); 2 dòng đều nhau đúng Figma, trước đây nhãn xuống dòng lộn xộn | — (chỉ code) |
| DT-23 | S01 `1:2` | Logo dùng `IconCircle` nền `primary`: vòng 112, icon 64 (Figma vòng 72, icon 40), icon lá `spa` như A01 (Figma: lá trong vòng tròn); tiêu đề "Cỡ chữ" dùng icon Material `text_fields` (Figma Lucide `type`, chưa có trong `AppIcons`); nút "Bắt đầu" icon mũi tên bên **trái** chữ (Figma bên phải); "Xem thử" là nhãn, không bấm được (Figma là thẻ `<a>`); câu mẫu xuống 2 dòng vì cả app đã phóng theo cỡ đang chọn (mặc định ×1.15). Vì logo cao hơn nên ở 360 × 800 cỡ "Lớn" ô "Rất lớn" bị thanh nút đáy che một phần, phải cuộn (Figma thấy đủ 3 ô) | Chỉ dùng widget trong `lib/widgets/`: `IconCircle` cố định 112 / 64, `AppButton` luôn đặt icon trước chữ. Nhờ Sanh (F0): thêm tham số cỡ cho `IconCircle` + icon `type` vào `AppIcons` thì làm khớp Figma | ☐ |
| DT-24 | S02 `1:58`, `1:103`, `1:176` | Câu dưới tên ở `1:58` đổi thành "Tên này lấy từ tài khoản Google của Bác." (Figma: "Con cháu đã nhập tên này cho Bác.") và tên gợi ý lấy từ `displayName` Google (giữ nguyên họ tên); lỗi tên trống / quá dài (Figma `1:176` không vẽ) theo AppStyleGuide: ⓘ "Bác chưa nhập tên gọi." + "Ví dụ: Lan, Sáu, Tư", giới hạn 40 ký tự; lưu lỗi thì hiện câu lỗi trên nút, nút đổi thành "Thử lại"; không có ô số điện thoại người thân (handoff có, Figma không); cách gọi chỉ Ông / Bà, chọn sẵn "Ông", giờ thức dậy mặc định 6:00 sáng (handoff: 5:00) – theo Figma; thanh trên không có icon lịch cạnh "Bước 1/2" (`AppBackBar`); ô tên chỉ xem nền `secondaryContainer` #E7F2EB (Figma #EFF4F1, chưa có token); nút "Nhập lại tên" viền + chữ màu `primary` (`AppButton` secondary; Figma viền xám, chữ đen); icon "cách gọi" / "giờ thức dậy" là Material `favorite_border` / `alarm`; mũi tên "Tiếp tục" bên trái chữ (như DT-23) | Lab 3 đăng nhập Google nên tên đến từ tài khoản, không phải con cháu nhập; chỉ dùng widget + token có sẵn | ☐ |
| DT-25 | S13 `1:217`, S13d `14:284` | Hộp gợi ý nền vàng ("Khi điện thoại hỏi, Bác bấm Cho phép.", "Muốn bật lại, Bác vào: Hôm nay › Cài đặt › Nhắc việc") vẽ bằng `FieldMessage.hint` (ⓘ + chữ xám, không nền, "Cho phép" không gạch chân); ở S13 câu dặn đưa lên **trước** thẻ ví dụ (Figma: sau); vòng icon `IconCircle` 112 / 64 (Figma S13 80 / 56); S13d vòng nền `errorContainer`, icon đỏ (Figma nền vàng `warning`, theo handoff "error-container"); thẻ ví dụ dùng `HabitAccentCard` + `HabitBadge` (nền trắng, Figma nền `background`); nút "Để sau" icon `alarm-clock-plus` (Figma đồng hồ), "Vẫn để sau" thêm icon mũi tên (`AppButton` luôn có icon), 2 nút cao 72 (S13d Figma 60); nút "Bật nhắc việc" ở S13d **hỏi lại quyền**, không mở cài đặt hệ thống (handoff: `openAppSettings()`) | Chưa có widget `InlineHint` và màu `warning` trong `ColorScheme` (người dùng chọn `FieldMessage.hint`, nhờ Sanh thêm `InlineHint`); câu dặn phải thấy trước khi hệ thống hỏi quyền (handoff S13 › priming) mà vòng icon lớn hơn đẩy nó xuống dưới nút; không thêm package `permission_handler` / `app_settings` (người dùng chọn hỏi lại quyền) – Android chặn hỏi lại sau 2 lần từ chối, cần bản thật của `ReminderService` mở cài đặt | ☐ |
| DT-26 | N01 `31:68`, N02 `31:170`, N03 `31:218` | N02 là state **hỏi lại** sau khi gửi thử (`waitingAnswer`), không phải màn "đã nhận": tiêu đề đổi "Đã nhận lời nhắc" → "Đã gửi lời nhắc thử" (câu phụ giữ "Bác đã nhận được chưa?"); nút "Tôi đã nhận được" đổi thành "Đã nhận được" (rule.md R-LANG-02: xưng hô thống nhất "Bác", không "Tôi") và đi thẳng `/setup/first-task` (không có màn xác nhận riêng). N01 không có thanh tab dưới (onboarding nằm ngoài `AppShell`); chip "Lời nhắc thử" vẽ thành icon + chữ (chưa có widget chip); thẻ mẫu dùng `TaskRow` (thêm dòng "Vận động tự nhiên", viền nhạt); ô ghi chú xanh ("Bác thử chuông…", "Bác có thể xem lại sau.") dùng `FieldMessage.hint` như DT-25; N02 / N03 không có chữ "An Nhiên" bên phải thanh trên; dòng kiểm tra N02 và bước N03 dùng `FieldLabel` (icon 32 không có ô nền 48; N03 bước 3 icon `retry` thay số "3"); nút "Để sau" có icon (`AppButton.text`), nút cao 72 (Figma 60), icon nút theo `AppIcons`; lỗi gửi thử (Figma không vẽ): câu lỗi trên nút, nút đổi thành "Thử lại" | Theo luồng: lời nhắc thử vừa gửi nên chưa thể "đã nhận"; chỉ dùng widget có sẵn (`TaskRow`, `FieldLabel`, `FieldMessage`, `AppButton`) | ☐ |
| DT-27 | N04 `38:2`, N05 `38:108`, N18 `47:170` | N04 liệt kê **9 thói quen** từ `HabitRepository` (tên + mô tả, `HabitTile`), không phải việc cụ thể ("Đi bộ nhẹ nhàng", "Chăm cây"…); tên việc lưu = tên thói quen; không có thẻ "Tự đặt tên việc" (để S05 / F4); thói quen đầu danh sách chọn sẵn; không có thanh tab. N05 chỉ đổi được **giờ** (`TimeField`, mặc định 9:00 sáng theo Figma); "Ngày bắt đầu: Hôm nay" và "Nhịp nhắc: Mỗi ngày" chỉ xem, không có nút "Đổi ngày" / "Đổi nhịp" (Figma N05 ghi "Một lần", N18 ghi "Mỗi ngày" – chọn "Mỗi ngày"); thẻ việc bằng `TaskRow` (dòng phụ "Mỗi ngày"); ô ghi chú dùng `FieldMessage.hint`. N18: vòng icon 112 / 64 (Figma 128 / 72); không có dòng "Nhắc trước 10 phút" (`TaskItem` chưa có trường); "Thêm việc khác" đi `/today/add`. Lỗi lưu / lỗi hoàn tất (Figma không vẽ): câu lỗi trên nút, nút "Thử lại" | Người dùng chọn (02/11): `Habit` chưa có `suggestions[]`, đề cấm hard-code; `TaskItem` chưa có ngày bắt đầu / nhắc trước, màn con N11 / N12 thuộc F4 (Khang) chưa làm. Đề xuất Hiếu thêm `Habit.suggestions` (Firestore `habits/{key}.suggestions[]` đã có trong architecture mục 10) để N04 khớp Figma | ☐ |
| DT-28 | S10 `1:2325`, `1:2474` | Thanh trên dùng `AppBackBar` "Quay lại" (Figma "‹ Hôm nay"); tiêu đề "⚙ Cài đặt hiển thị" (Figma "⚙ Cài đặt") đặt thành dòng tiêu đề lớn ở đầu nội dung, không nằm bên phải thanh trên. Khung "Xem thử" viền liền màu `outline` (Figma viền đứt `#A0ACA3`), TalkBack đọc "Xem thử: Đi bộ 20 phút lúc 9:30 sáng". Thẻ cỡ chữ dùng `ChoiceGroup` (theo DT-15), thẻ công tắc dùng `SwitchRow` (theo DT-14). 4 hàng điều hướng dùng widget F0 mới `NavRow`, thẻ dùng `SectionCard`. Icon mới trong `AppIcons`: `settings`, `textSize`, `contrast`, `vibrate`, `bellRing`, `bookOpen`, `smartphone`, `logout`. **Thêm nút "Đăng xuất"** (`dangerOutline`) ở cuối màn, Figma không vẽ. Bấm → hộp hỏi lại (`showConfirmDialog`): "Bác muốn đăng xuất?" · "Bác sẽ cần đăng nhập lại. Lịch đã lưu vẫn còn." · ⓘ "Việc chưa kịp lưu lên mạng sẽ bị xoá.", nút "Ở lại" (chính, trên) / "Đăng xuất" (viền đỏ, dưới). Đăng xuất xong thì tự về `/sign-in`, vì `redirect` của router đang tạm tắt. "Xem thử lời nhắc" → `/reminder/preview?preview=true` (S14 của Khang, còn placeholder) | Người dùng chọn (03/11): làm theo prompt bước 02 ("Quay lại" + "Cài đặt hiển thị"); tiêu đề trong thanh trên sẽ bị `FittedBox` thu nhỏ dưới 20 sp khi chữ ×2.0. Đề bắt buộc có đăng xuất. Flutter không có viền đứt sẵn, không thêm package. Hộp hỏi lại theo SG-19: hậu quả khó lấy lại nên nút an toàn đứng trên | ☐ |
| DT-29 | N06 `38:187` | Cách gọi chỉ có **Ông / Bà** (`ChoiceGroup` segmented, theo S02; Figma có thêm "Bác"), dưới nhóm vẫn có dòng "Đang chọn: …" như Figma. Ô lưu ý nền xanh "Việc đã lưu vẫn giữ giờ cũ." và dòng "Để nhắc việc đúng giờ cho Bác." (Figma icon chuông) vẽ bằng `FieldMessage.hint` (ⓘ chữ xám, không nền – như DT-25). Ô tên dùng `AppTextField` (nhãn "Tên Bác", gợi ý "Ví dụ: Lan"), ô giờ dùng `TimeField` ("5:30 sáng · Đổi giờ ⌄"; Figma "5 : 30 sáng" + ⌄); nút cao 72 (Figma 60). Thanh nút cố định ở đáy có "Lưu thông tin" + "Hủy"; nút "Khu thử tính năng" (F10) đặt ở **cuối phần cuộn** (Figma đặt dưới thanh nút). Icon mới `AppIcons.smile`, `AppIcons.sunrise`. Lưu xong: Snackbar "Đã lưu thông tin của Bác." + Hoàn tác rồi về màn trước. Rời màn khi chưa lưu (Quay lại / Hủy / back hệ thống) → hộp hỏi "Bác chưa lưu thay đổi" · "Ở lại sửa" (chính, trên) / "Bỏ thay đổi" (viền đỏ, dưới); lỗi lưu (Figma không vẽ): câu lỗi trên nút "Lưu thông tin" | Người dùng chọn (04/11): giữ Ông / Bà vì enum `Honorific` + dữ liệu Firestore (`ong` / `ba`) dùng chung với S02, thêm "Bác" sẽ đổi S02 của Hương; nhãn nút theo Figma "Lưu thông tin" (handoff ghi "Lưu hồ sơ"); chưa có widget hộp lưu ý có nền (`InlineHint`) nên dùng `FieldMessage.hint`. Thanh nút cố định để nút Lưu luôn thấy kể cả khi bàn phím mở; Khu thử đặt trong phần cuộn để thanh đáy không quá cao ở chữ ×2.0 | ☐ |
| DT-30 | N20 `52:2` | **Đổi câu chữ cho đúng Lab 3** (người dùng duyệt 04/11): câu dưới tiêu đề "Lịch việc lưu gọn gàng trên chính chiếc điện thoại này." → "Lịch của Bác được lưu trên tài khoản Google của Bác."; thẻ 1 giữ tiêu đề "Dùng được khi mất mạng", câu → "Mất mạng, Bác vẫn xem được lịch đã tải về máy."; thẻ 2 "Lịch chỉ ở điện thoại này · Lịch chưa chuyển sang máy khác." → "Đổi điện thoại vẫn còn lịch · Bác đăng nhập lại là thấy lịch cũ."; thẻ 3 giữ "Chia sẻ do Bác quyết định", câu → "Chỉ người thân Bác đã ghép nối mới xem được lịch.". Thẻ dùng `SectionCard` (icon 32 trơn, Figma ô icon 48 nền xanh); nút "Về Cài đặt" icon `chevronLeft`, cao 72 (Figma 60), ghim đáy. Thay cho câu DT-05 | Lab 3 lưu lịch trên Firestore `users/{uid}` theo tài khoản Google (đăng nhập máy khác là thấy), bật offline persistence (chỉ xem được phần đã tải), `firestore.rules` cho người thân đã ghép nối (`caregivers/{uid}`) **đọc** `tasks` – câu Lab 2 "chỉ ở điện thoại này" sai sự thật. **Cần sửa Figma `52:2`** | ☐ |
| DT-31 | N08 `41:85` | Ba bước vẽ bằng `SectionCard` + số thứ tự trong vòng tròn 48 (Figma 36); bỏ ô icon chuông nền cam chỉ có ở bước 2 (3 bước cùng một kiểu); thẻ trấn an "Bác tự chọn nhận gợi ý lịch." dùng `SectionCard` (icon ⓘ + tiêu đề, nền trắng – Figma nền xanh viền đậm); không có chữ "An Nhiên" bên phải thanh trên (như DT-26); nút "Mở cài đặt" thêm icon `settings` (`AppButton` luôn có icon), 2 nút cao 72 (Figma 60), ghim đáy; không có `ReadAloudButton` (Figma không vẽ). "Mở cài đặt" quay về S10 (`pop`), "Thử lời nhắc" → `/reminder/preview?preview=true` như S10 | Chỉ dùng widget có sẵn; ô icon cam ở bước 2 không có ở 2 bước kia và màu `warningStrong` không có trong `ColorScheme` (tương phản cao không đổi được); chưa có widget hộp lưu ý có nền (`InlineHint`, xem DT-25 / DT-29) | ☐ |
| DT-28 | G10 `66:119`, G11 `71:2` (lời nhắn trong popup) | Lời nhắn trong popup dùng đúng câu G03: "“Mẹ ơi, mai mình đi bộ với cô Tám nhé?”" (Figma popup ghi "Mẹ ơi 3 giờ chiều mẹ đi bộ với cô Tám nh…"). Lời nhắn là dữ liệu con cháu gõ (`Suggestion.message`), popup và G03 hiện cùng một câu | Figma tự mâu thuẫn: popup ghi "3 giờ chiều" trong khi gợi ý là 8:00 / 9:00 sáng ngày mai; người dùng chọn câu G03 (04/11) | ☐ |
| DT-29 | G01 `52:161`, G01b `52:230` | Cả màn gọi người nhận là **"mẹ"** (G01b Figma ghi "Bác": "Gợi ý lịch cho Bác", "Gửi gợi ý cho Bác?", "Lịch của Bác…"). Nút back ghi **"Quay lại"** (Figma "Gia đình"), quay về màn trước hoặc `/caregiver/schedule`. 2 việc lấy từ mẫu trong `SuggestionComposeViewModel` (tên thói quen nạp từ `HabitRepository`). Nút giờ là `ChoiceGroup` **xếp dọc ở mọi state** (G01 Figma xếp ngang), ô cao 72 (Figma 52 / 48), dấu tích bên trái + chữ "Đang chọn" (Figma vòng radio bên phải – như DT-15); một việc chọn đúng một giờ (G01b Figma tô nền 8:00 nhưng viền + chấm ở 9:00 – hiểu là đã đổi sang 9:00). Ở G01b nút giờ chỉ xem, bấm "Sửa lại" mới đổi. Nhãn ô lời nhắn gộp thành "Lời nhắn gửi kèm (không bắt buộc)" (Figma: "Không bắt buộc" ở cột phải); ô **để trống**, câu Figma thành gợi ý "Ví dụ: Mẹ ơi, mai mình đi bộ nhé?" dưới ô. Khối "Lịch của mẹ chỉ thay đổi khi mẹ bấm nhận." vẽ bằng `FieldMessage.hint` (không viền, không chữ đậm – như DT-25). Nút "Gửi gợi ý cho mẹ" / "Gửi gợi ý" dùng icon mũi tên (Figma message-square, `AppIcons` chưa có), "Sửa lại" thêm icon bút, nút cao 72 (Figma 60 / 50). Thanh đáy G01b: phần chữ cuộn được, 2 nút luôn ghim. Lỗi gửi (Figma không vẽ): câu lỗi đỏ trên nút, nút chính đổi thành "Thử lại", dữ liệu giữ nguyên | Người dùng chọn (04/11): màn chạy trên máy con cháu; không hard-code danh sách thói quen; 2 ô ngang có "Đang chọn" tràn ở 360 dp × 2.0; không gửi câu con cháu chưa gõ; chỉ ghép widget F0, không thêm widget / icon | ☐ |
| DT-30 | G02 `56:2`, chưa ghép nối (Figma không vẽ) | **Không có bottom nav** của Bác; nút chính **"Về lịch của mẹ"** → `/caregiver/schedule` (Figma "Về Gia đình" + 4 tab); back "Quay lại" về màn trước. Chip "Mai · Con gái" thành dòng chữ thường **chỉ có tên** (hồ sơ con cháu chưa có quan hệ với mẹ, `Suggestion.fromRelation = null`). Vòng icon ✓ 112 / 64 (Figma 80 / 40, như DT-11). Khối "Lịch của mẹ chưa thay đổi. Việc chỉ vào lịch khi mẹ bấm nhận." bằng `FieldMessage.hint` (không viền, không chữ đậm). 2 thẻ việc bằng `TaskRow`: giờ ở trên tên việc ("9 giờ sáng"), chip "Chưa làm", dòng phụ "20 phút" (Figma: icon đồng hồ + "8:00 sáng · 20 phút" dưới tên, ô icon nền nhạt). Chưa ghép nối: `EmptyView` "Chưa ghép nối với máy của mẹ" · "Ghép nối trước, rồi mới gửi gợi ý cho mẹ được." + nút "Ghép nối máy" → `/caregiver/pair` | Người dùng chọn (04/11): điều hướng theo chế độ Con cháu (`/caregiver/*` ngoài shell của Bác); TODO(Hiếu): lưu quan hệ khi ghép nối (F13) để hiện "Mai · Con gái"; chỉ dùng widget F0 | ☐ |
| DT-31 | G03 `56:107`, G03b `56:201`, G04 `57:2`, G05 `57:128`, G05b `58:2` | Nút đổi giờ cho **việc chưa nhận đầu tiên có ≥ 2 giờ để chọn**, nhãn = "Đổi giờ " + tên việc viết thường ("Đổi giờ đi bộ nhẹ nhàng"; Figma "Đổi giờ đi bộ"), G04 tiêu đề cùng câu, "Chọn giờ đi bộ nhẹ nhàng:"; G03b câu "Bác đã chọn giờ đi bộ nhẹ nhàng. Chưa thêm vào lịch." và thẻ việc hiện **giờ đã đổi** (Figma G03b vẫn ghi 8:00). Nút back theo nơi mở: mở từ Gia đình (`?from=family`) giữ chữ Figma ("Gia đình", G05 "Quay lại Gia đình" + "Về Gia đình" → `/family`); mở từ popup / thẻ / thông báo: "Quay lại" → `/today`, G05 nút phụ "Về Hôm nay". **Luôn có bottom nav** (route trong shell; Figma G03 không có nav, tab sáng là Hôm nay thay vì Gia đình). "Đọc to" giữ đúng chỗ nhưng **tắt tạm** (chưa có `SpeechService` – F5). Thẻ trích dẫn ghép từ F0: icon người + tên (`FieldLabel`), quan hệ, lời nhắn nghiêng (Figma: avatar chữ "M", bong bóng nền). Khối trạng thái ("Chưa thêm vào lịch. Bác tự chọn.", G04 "Chưa đổi trên máy của Bác…", G05b "Bác có thể đổi giờ hoặc ngưng nhắc.") bằng `FieldMessage.hint` (không nền xanh, không viền). Thẻ việc bằng `TaskRow`: giờ ở trên tên ("8 giờ sáng"), chip "Chưa làm", dòng phụ "20 phút" (G05: "Vận động tự nhiên · 20 phút"; Figma: "8:00 sáng · 20 phút" dưới chip, G05b có icon đồng hồ). G04 lựa chọn giờ bằng `ChoiceGroup` ("8:00 sáng" + "Đang chọn" tách riêng – như DT-15; Figma "8:00 sáng (Đang chọn)"). Icon: "Thêm vào lịch" dùng ✓ (Figma +, `AppIcons` chưa có), "Chọn từng việc" ô vuông, "Về Hôm nay" mặt trời. Nút cao 72 (Figma 60 / 52 / 48). Thanh đáy: nút chính luôn thấy, nút phụ cuộn khi chữ lớn (360 dp × 1.3 thanh đáy chiếm ~60% vùng nội dung). Figma không vẽ: gợi ý không còn / đã nhận hết → `EmptyView` "Gợi ý này không còn" + "Về Hôm nay"; lỗi lưu → câu lỗi đỏ trên nút, nút chính thành "Thử lại" (các việc vừa lưu được xoá, lịch không nửa vời). "ngày mai" trong "Xem lịch ngày mai" / "… đã vào lịch ngày mai." tính theo ngày của việc (hôm nay / ngày mai / ngày d/m) | Người dùng chọn (04/11): gợi ý thật có thể có việc khác đi bộ; Lab 3 mở G03 chủ yếu từ Hôm nay; route nằm trong shell; chưa có TTS; chỉ ghép widget F0; dữ liệu đúng hơn Figma ở G03b | ☐ |
| DT-32 | G06 `58:117`, G07 `61:2`, G07b `61:118`, G09 `66:2` | G06 **chọn nhiều, mặc định chọn hết** (như Figma); mỗi thẻ là `HabitTile` (dấu ✓ bên phải + chữ "Đã chọn" / "Chọn", dòng giờ "8:00 sáng" không có icon đồng hồ); chọn hết + "Tiếp tục" = nhận hết → G05. "Tiếp tục" **lưu luôn** (Figma không vẽ bước xác nhận) nên câu phụ đổi thành "Chưa thêm vào lịch của Bác. Lịch chỉ thay đổi khi Bác bấm Tiếp tục." (Figma "…sau khi Bác xác nhận ở bước tiếp theo.", câu đầu không đậm); nút "Tiếp tục" ghim đáy, icon mũi tên đặt trước chữ. Chưa chọn việc nào (Figma không vẽ): câu lỗi "Bác chưa chọn việc nào." + "Ví dụ: chạm vào “Đi bộ nhẹ nhàng” ở trên." trên nút, không lưu gì. G07 / G07b: việc chưa nhận vẽ bằng `HabitAccentCard` + ô icon + tên + dòng "Gợi ý của Mai · 9:00 sáng · 15 phút" (Figma: chip "Gợi ý của Mai" + dòng giờ, viền nét đứt); câu "Chưa thêm vào lịch. Bác có thể thêm sau trong Gia đình." dùng cho cả G07b (Figma G07b chỉ "Chưa thêm vào lịch."); việc đã nhận bằng `TaskRow`; khối "Bác có thể đổi giờ hoặc ngưng nhắc." bằng `FieldMessage.hint`. G09: "Hoàn tác" là **nút chính trên màn, không có `UndoSnackbar`** (lệch `CLAUDE.md` – nút luôn thấy, không tự mất, đạt ý luật); chip "Bỏ qua" kiểu F0 (viền xám, icon ⊖; Figma nền đỏ nhạt, ✕), không viền nét đứt; "Bỏ qua gợi ý" ở G03 **không hỏi lại** (Figma không vẽ hộp thoại). Nhãn back / nút "Về …" theo nơi mở như DT-31; Figma G06 không có, G07 / G09 có tab Gia đình sáng. Nhận tiếp việc còn lại: mở lại G03 từ Gia đình (`?from=family`) – TODO(Hương, S09) liệt kê gợi ý `partial` / `dismissed`; thẻ G12 chỉ hiện gợi ý `pending` | Người dùng chọn (04/11): Figma G06 vẽ 2 thẻ cùng chọn; câu Figma nhắc tới bước không có; Figma không vẽ trạng thái chưa chọn; chỉ ghép widget F0 (chưa có chip "Gợi ý của …", viền nét đứt) | ☐ |
| DT-33 | G10 `66:119`, G11 `71:2`, G12 `71:209` | G10 / G11 là **một popup**: dòng "Mai vừa gửi lúc 4:20 chiều" chỉ hiện khi gợi ý gửi **hôm nay** (G10), gửi từ hôm trước thì không có dòng này (G11). Popup ghép từ `ConfirmDialog` (F0): vòng icon thư 112 / 64 (Figma 80 / 64, như DT-11), nút cao 72 (Figma 60); lời nhắn lấy `Suggestion.message` thật (dữ liệu mẫu dùng câu G03 – DT-28), bong bóng nền màu nền màn; chạm ra ngoài / Back không đóng (chỉ "Xem gợi ý" / "Để sau"); ở chữ ×1.3 trở lên hai nút nằm dưới, cuộn trong popup. Popup gắn ở `AppShell` (`SuggestionPopupListener`), chỉ hiện ở tab Hôm nay, đánh dấu `popupShown` ngay khi hiện. G12: `SuggestionCard` **không** truyền `previewTitles` / `onDismiss` (khớp Figma: không tên việc, không "Bỏ qua gợi ý"; DT-20 không dùng trên S03), nút "Xem gợi ý" cao 72 (Figma 56); thẻ chỉ hiện gợi ý `pending` | Người dùng chọn (04/11): "vừa gửi" chỉ đúng khi gửi trong ngày; chỉ dùng widget F0; không sửa code F3 của Khang (popup đặt ở `AppShell` – F0 của Sanh) | ☐ |
| DT-34 | S03, S04, DLG-Done/Later/Skip, S03-* | F3 dùng `TaskRow`, `NextTaskCard`, `AppBackBar`, `SectionCard`, `ConfirmDialog` và `showUndoSnackbar` có `persist: true`; trạng thái S03b / all-done / N17 được suy ra từ `TaskStatus`. Event được chuẩn hoá theo analytics-plan (`complete_task`, `postpone_task`, `skip_task`, `undo_action`). Dời 30 phút/chiều lưu giờ mới; dời ngày mai hiện là trạng thái occurrence hôm nay vì `TaskRepository` chưa có API `postpone(id, to)` / trường `postponedTo`. | Giữ phạm vi F3 không sửa Firebase/service của Hiếu; cần Hiếu bổ sung API occurrence-specific trước khi production có thể lưu chính xác mốc “ngày mai”. | — |

## Ghi chú từ Lab 2 cần nhớ khi code

- Mọi màn: chữ ≥ 20 sp, nội dung 24 sp, nút chính 60 dp, vùng chạm ≥ 48 dp, cách nhau ≥ 8 dp, `textScaler` tới 2.0 không tràn, contrast ≥ 4.5 : 1, không cử chỉ vuốt bắt buộc (`lab2/rule.md`, `lab2/accessibility.md`).
- Bottom nav: nhãn "Lịch tuần" / "Thói quen" xuống 2 dòng ở cỡ 20 → `maxLines: 1` hoặc rút nhãn (`lab2/accessibility.md` mục 7).
- S17 **không bao giờ** báo "Đã gửi" (app không biết kết quả Zalo / SMS).
- G: lịch chỉ đổi khi Bác bấm nhận; không tự báo cho con cháu là Bác đã bỏ qua.
- S14: không có cử chỉ vuốt để tắt; chuông lặp tối đa 1 phút rồi thành thông báo thường.
- Xoá việc là xoá mềm, giữ 7 ngày để Hoàn tác.
- Chế độ Người thân dùng cùng design system, được dùng cỡ chữ "Vừa"; không có màn theo dõi vị trí hay sức khỏe.


F1 cập nhật 02/11/2026: A01 giữ Google theo DT-01; báo huỷ/mất mạng và provider
đang tạm tắt. C01 đã có UI/RoleViewModel, Firestore profile, guard và widget tests.
Chưa đối chiếu hình ảnh hoặc sửa Figma nên C01 không đánh dấu done; DT-01 vẫn ☐.
A02/A02e/A03/A04 hoãn: luồng số điện thoại/OTP/sinh trắc học không thuộc phương thức
Google bắt buộc của Lab 3; không triển khai giả các màn xác thực này.
`/session` và `/account` là màn hỗ trợ F1; không thay màn hồ sơ N06 của F8.

## Cập nhật Hiếu — 04/11/2026

Các mục dưới cập nhật trạng thái code local, không phải bằng chứng nghiệm thu cloud/Figma prototype.

| Màn | Figma nguồn đã đọc | Route/state | Trạng thái code |
|---|---|---|---|
| C02/C02e | 1:3382 (C02); lỗi giữ mã đang nhập | /caregiver/pair, PairingViewModel | implemented; test Fake và backend Emulator |
| Mã phía Bác | bổ sung điểm vào tài khoản cho F13 | /pairing/code | implemented; xác nhận, TTL, revoke |
| C03/C04/C05 | 1:3148 và mô tả handoff | /caregiver/schedule + view | implemented; live data, ngày/tuần/tháng |
| C06/C06e | 1:3036 | /caregiver/task/new | implemented; validation và thói quen từ catalog |
| C07/C07m | 1:2764 và handoff | /caregiver/task/new/repeat | implemented; weekly/monthly/cuối tháng |
| C08/C08w | 1:2960 | /caregiver/task/new/review + dialog | implemented; consent và xung đột giờ |
| C09 | handoff Flow 11 | /caregiver/task/sent | implemented; phân biệt chờ nhận/đã thêm/đã sửa |
| C10/C11/C12 | 75:2 và handoff | /caregiver/task/:id + scope/stop dialog | implemented; lịch sử và undo |

Điều chỉnh responsive local cần Sanh đối chiếu/cập nhật Figma khi chốt UI: ô mã có nhãn thay sáu ô riêng; tháng hiện danh sách ngày có số việc để giữ vùng chạm; nút chế độ wrap khi chữ lớn; bốn thẻ thói quen dùng SVG gốc và widget F0. Chưa đánh dấu design parity done. Không sửa các frame Figma trong phiên này.

## Cập nhật TYPE-01 — 05/11/2026

| ID | Phạm vi | Điều chỉnh | Căn cứ / kiểm chứng | Trạng thái |
|---|---|---|---|---|
| DT-34 | Typography toàn app và shared layout, không sửa file dashboard | TYPE-01 v1.1.0: elderly body 24/600, secondary 22/600, nút 22/700, tab 20/700, sàn 20/600; caregiver body 20/600, sàn 18/600. Màn chưa có role dùng elderly. Nhãn wrap; back bar đo chiều cao; time grid thích ứng; lịch caregiver cuộn ngang; chỉ ghim CTA chính trên profile/review. Điều hướng vẫn giữ nguyên cho milestone này. | Người dùng duyệt spec chữ lớn/đậm và yêu cầu code; 701 tests + analyze pass, 4 goldens được xem và so sánh lại. Chi tiết tại `typography-v1.1-verification.md`. | implemented / widget+golden QA; device accessibility và full redesign chưa nghiệm thu |

| DT-VELORA-REF | Yêu cầu người dùng mới nhất: clone anatomy intro/home trước, bỏ font quá lớn/đậm của lượt trước | `/intro` và main `/calendar`; welcome pager, greeting/feature/categories/task cards, 5 đích nav của Bác; serif Regular + sans Regular; primary target 56dp | `docs/AnNhien_VELORA_Visual_Replication_Spec_v2/docs/uiux/15_ACCESSIBLE_TYPOGRAPHY_OVERRIDE.md` và `16_REFERENCE_FIRST_LAYOUT.md` thay bảng chữ 24/600 cũ; không sửa `/today` source/backend |


## Cập nhật luồng local — 06/11/2026

Các hàng `todo` ở bảng Lab 2 phía trên là trạng thái lịch sử. Yêu cầu giao diện mới của người dùng và triển khai hiện tại được ghi tại đây; chưa đánh dấu nghiệm thu Figma/thiết bị thật.

| Phạm vi | Route | ViewModel/service hiện tại | Trạng thái |
| --- | --- | --- | --- |
| Giọng nói V00–V04 | `/today/voice` | VoiceInputViewModel / DeviceAccessService / Android RecognizerIntent | implemented local; nhận tiếng Việt, sửa/xác nhận; quyền/nghe do hệ thống Android trình bày |
| Lưu việc sau giọng nói V05 | `/today/add/time` → `/today/add/result` | TaskFormViewModel | dùng chung bước chọn giờ và lưu thật, không tự lưu sau nhận giọng |
| N07 | `/settings/reminders` | ReminderSettingsViewModel / ReminderService / DeviceAccessService | implemented local; quyền, gửi thử, mở settings, refresh khi resume |
| Đọc to màn gợi ý | `/today/suggestions/:id`, `/inbox/suggestions/:id` | SpeechViewModel / Android TTS | implemented local; đọc/dừng/lỗi, cùng backend Firebase |
| Xuất lịch tuần | `/calendar/export` | WeeklyReportViewModel / WeeklyReportService | implemented local; lấy lịch thật theo tuần, lưu PDF trên máy; không phải link PDF mẫu |
| Sửa/dời/bỏ qua trên UI mới | `/calendar/task/:id` | TodayViewModel / TaskFormViewModel / ScopedTaskRepository | implemented local; đúng ngày, scope, xác nhận và Undo |

Chi tiết và giới hạn nghiệm thu: `flow-completion-implementation.md`.
