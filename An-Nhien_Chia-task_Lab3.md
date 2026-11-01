# An Nhiên – Chia task Lab 3 (bản theo đề)

PRM393 · Flutter + Firebase · mỗi feature kèm danh sách màn Figma (bấm mã node để mở đúng khung trong Figma)

Figma: [figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled) · Bản ngày 02/11/2026 (chia lại)

| Mã | Feature | Người làm | Số màn |
|---|---|---|---|
| F0 | Nền tảng: theme, widget dùng chung, điều hướng | Sanh | 2 |
| F1 | Tài khoản + chọn vai trò (Bác / Con cháu) | Hiếu | 6 |
| F2 | Onboarding của Bác (Flow 1) | Hương | 14 |
| F3 | Hôm nay: làm xong / dời / bỏ qua (Flow 3) | Khang | 14 |
| F4 | Thêm, sửa, xoá việc (Flow 2, Flow 7) | Khang | 20 |
| F5 | Thêm việc bằng giọng nói | Khang | 6 |
| F6 | Lời nhắc đến giờ (Flow 6) | Khang | 3 |
| F7 | Lịch tuần + xuất PDF (Flow 4) | Hương | 5 |
| F8 | Cài đặt hiển thị & hồ sơ | Sanh | 5 |
| F9 | 9 thói quen Power 9 (Flow 8 – Flow chính 1) | Hương | 3 |
| F10 | Firebase: thông báo, Remote Config, Crashlytics, khu demo | Hiếu | 1 |
| F11 | Gia đình: thêm người thân, nhắn tin (Flow 5, Flow 9) | Hương | 13 |
| F12 | Gợi ý lịch: Con cháu gửi ↔ Bác nhận | Sanh | 19 |
| F13 | Ghép nối máy con cháu với máy mẹ (Flow 10) | Hiếu | 2 |
| F14 | Con cháu lập lịch cho mẹ (Flow 11, 12 – Flow chính 3) | Hiếu | 11 |

**Tóm tắt theo người:**

| Người | Feature | Số màn | Bước chung (xem bảng 8 bước) |
|---|---|---|---|
| Sanh | F0, F8, F12 (code UI + ViewModel bằng AI agent, không đụng Firebase / hạ tầng) | 26 | 1, 2, 7 (điều phối AI code review), 8 (report + slides) |
| Hiếu | F1, F10, F13, F14 + toàn bộ Firebase / hạ tầng | 20 | 0 (setup project), 3, 5 |
| Hương | F2, F7, F9, F11 | 35 | 6 (điều phối), 8 (video) |
| Khang | F3, F4, F5, F6 | 43 | 8 (video) |

> **Thay đổi so với bản 02/11 trước:**
> - **Chia theo kiểu việc:** Sanh làm phần chạy AI agent (sinh màn + ViewModel từ Figma, AI code review, viết docs/report). Hiếu làm toàn bộ Firebase và hạ tầng.
> - **Mọi việc tạo Firebase / setup hạ tầng thuộc về Hiếu** (Hiếu đã sở hữu `android/`, `firebase/`, `lib/services/`): cài đặt project lần đầu (`flutter create` sinh `android/`, `flutter pub get`), đổi `github-templates/` → `.github/` + điền `CODEOWNERS`, cấu hình AI review chạy trên PR, tạo project Firebase + `flutterfire configure`, chặn route khi chưa đăng nhập, security rules, FCM, và bản Firebase của mọi service (kể cả `SettingsService` cho F8, `SuggestionService` cho F12). Sanh chỉ code UI + ViewModel trên interface service (dùng bản Fake cho tới khi Hiếu nối Firebase).
> - **F14 Con cháu lập lịch** chuyển từ Sanh sang **Hiếu**, đi liền với F13 ghép nối (cùng quyền `users/{momUid}/tasks` qua rules ghép nối).
> - **F12 Gợi ý lịch** vẫn là của **Sanh** (phần màn + ViewModel). Firestore `suggestions` và FCM báo gợi ý mới do Hiếu viết trong service.
> - **Slides** (bước 8) chuyển từ Hiếu sang **Sanh** để bù việc cho Hiếu.
> - **Hương và Khang giữ nguyên**: feature, màn, flow, bước chung không đổi. Thẻ gợi ý G12 trên Hôm nay dùng widget dùng chung ở `lib/widgets/` (F0), Khang không phải sửa code F3.
> - Sanh giữ **F0** (phần UI: theme, widget, route map) vì là nền cho mọi người, phải xong trước khi ai code màn (đề chấm thứ tự commit).
>
> Đã sửa so với bản trước nữa (đúng ý đề): chế độ Con cháu (C01–C12) và gợi ý lịch (G) phải làm trong Lab 3, vì đây là Flow chính 3 trong prototype Lab 2 và đề chấm "mọi flow Lab 2 chạy hết đầu tới cuối". Màn chưa có trong Figma cần thiết kế thêm: nút "Xuất PDF" ở S07, Hộp thông báo, Khu demo Firebase; A01 đổi sang Google. Mọi thay đổi ghi vào `docs/design-traceability.md` và sửa Figma.

## Flow Lab 2 → người chịu trách nhiệm chạy hết đầu tới cuối

| Flow (prototype Lab 2) | Màn chính | Người |
|---|---|---|
| ★ Main flow – Một ngày của bà Lan | S01 → … → S14 | Cả nhóm (mỗi người phần mình) |
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
| Đăng nhập + Hồ sơ (đề bắt buộc thêm) | A01 (Google), N06 | Hiếu |
| Thêm việc bằng giọng nói (mới) | V00 – V05 | Khang |

## Việc MỖI NGƯỜI đều phải tự làm (thầy hỏi riêng từng người)

- Ít nhất 1 ViewModel của chính mình, giải thích được (state Loading/Empty/Error/Data, service nào được tiêm).
- Viết và chạy test ARTEMIS cho flow của mình, mỗi test ≥ 3 lần; biết chạy lại 1 test trước mặt thầy.
- Ghi analytics event cho màn của mình theo `docs/analytics-plan.md`; biết đổi 1 giá trị Remote Config trên console.
- Sửa ít nhất 1 phát hiện AI code review trong PR của mình, commit ghi mã CR-xx; giải thích được vì sao nhận/sửa/bỏ.
- Commit mỗi ngày bằng tài khoản GitHub của mình; cập nhật trạng thái màn trong `docs/design-traceability.md`.

## 8 bước của đề (git history phải theo đúng thứ tự)

| # | Bước | Đầu ra | Chủ trì |
|---|---|---|---|
| 0 | Setup project: `flutter create` (android/), `.github/` + CODEOWNERS, AI review trên PR | Repo chạy được `flutter run` / `flutter test` với service giả | Hiếu |
| 1 | Design traceability | `docs/design-traceability.md` | Sanh |
| 2 | Architecture + theme | `docs/architecture.md`, `lib/theme`, `lib/widgets` | Sanh |
| 3 | Firebase + đăng nhập | `firebase/` rules, sign-in chạy được | Hiếu |
| 4 | Features: mọi flow + state, export & upload | Màn chạy đủ trạng thái | Cả nhóm |
| 5 | Instrumentation | `docs/analytics-plan.md`, ảnh console | Hiếu (mỗi người gắn event màn mình) |
| 6 | Test plan + ARTEMIS | `docs/test-plan.md`, `e2e_test/`, bằng chứng chạy | Hương điều phối, mỗi người test flow mình |
| 7 | AI code review + sửa | `docs/code-review.md`, commit sửa | Sanh điều phối, mỗi người ≥ 1 sửa |
| 8 | Report, slides, video | `report/`, `slides/`, link video | Sanh (report + slides), Khang + Hương (video) |


## F0 · Nền tảng: theme, widget dùng chung, điều hướng

**Người làm:** Sanh · **Số màn:** 2

**Làm gì:** Phần UI của nền tảng: hoàn thiện ThemeData từ token Lab 2, mọi component Lab 2 thành widget trong `lib/widgets/` (nút 72 dp, thanh Quay lại, thẻ việc, bottom nav 4 tab, hộp thoại, snackbar Hoàn tác, Loading/Empty/Error), go_router theo route map của flutter-handoff.md (chỉ khai báo route; chặn khi chưa đăng nhập do Hiếu gắn ở F1). Không làm setup project / Firebase: việc đó của Hiếu.

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| Components | Màn mới (Giọng nói & Tài khoản) | [node 138:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=138-2) |
| S03 | Hôm nay | [node 1:270](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-270) |

**Firebase / kỹ thuật:** Không gọi Firebase. Viết `docs/design-traceability.md`, `docs/architecture.md` TRƯỚC khi ai code màn (đề chấm thứ tự commit).

**Xong khi:** Màn của mọi người chỉ dùng widget trong `lib/widgets/`; không còn màu/cỡ chữ cứng; `flutter analyze` sạch.

## F1 · Tài khoản + chọn vai trò (Bác / Con cháu)

**Người làm:** Hiếu · **Số màn:** 6

**Làm gì:** Đăng nhập Google (đề bắt buộc), xử lý khi huỷ; đăng xuất xoá dữ liệu trên máy; tạo `users/{uid}` lần đầu; C01 chọn vai trò rồi đi vào nhánh Bác hoặc nhánh Con cháu.

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| A01 | Tạo tài khoản – Số điện thoại (Bước 1/3) | [node 139:6](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-6) |
| A02 | Nhập mã xác nhận (Bước 2/3) | [node 139:43](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-43) |
| A02e | Mã chưa đúng | [node 139:89](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-89) |
| A03 | Mở app bằng vân tay (Bước 3/3) | [node 139:136](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-136) |
| A04 | Đã tạo tài khoản | [node 139:178](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=139-178) |
| C01 | Chọn vai trò | [node 1:3870](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-3870) |

**Firebase / kỹ thuật:** Firebase Auth (Google), Firestore `users/{uid}.role`, Analytics login / logout + setUserId.

**Xong khi:** Chưa đăng nhập không vào app được; huỷ có thông báo; đổi A01 thành nút Google: ghi design-traceability + sửa Figma. A02–A04 (SĐT + mã) làm sau nếu kịp, nếu bỏ thì ghi lý do.

## F2 · Onboarding của Bác (Flow 1)

**Người làm:** Hương · **Số màn:** 14

**Làm gì:** Lần đầu mở app: chọn cỡ chữ, nhập tên + xưng hô + giờ thức dậy, xin quyền thông báo, thử lời nhắc, chọn việc đầu tiên.

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| S01 | Chào mừng – chọn cỡ chữ | [node 1:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2) |
| S02 | Xác nhận tên (trước S02) | [node 1:58](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-58) |
| S02 | Thiết lập hồ sơ (Bước 1/2) | [node 1:103](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-103) |
| S02 | Nhập lại tên | [node 1:176](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-176) |
| DLG-WakeTime | Chọn giờ thức dậy | [node 31:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-2) |
| S13 | Cho phép nhắc việc (Bước 2/2) | [node 1:217](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-217) |
| S13d | Nhắc việc đang tắt | [node 14:284](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=14-284) |
| N01 | Thử lời nhắc | [node 31:68](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-68) |
| N02 | Đã nhận lời nhắc | [node 31:170](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-170) |
| N03 | Chưa nhận lời nhắc | [node 31:218](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=31-218) |
| N04 | Chọn việc đầu tiên | [node 38:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-2) |
| N05 | Xem lại việc đầu tiên | [node 38:108](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-108) |
| N18 | Đã lưu việc đầu tiên | [node 47:170](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=47-170) |
| N19 | Hôm nay · việc đầu tiên | [node 47:225](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=47-225) |

**Firebase / kỹ thuật:** Firestore `users/{uid}/profile`, quyền POST_NOTIFICATIONS (Android 13+), local notification để thử.

**Xong khi:** Đi hết S01 → Hôm nay có việc đầu tiên; từ chối quyền thì hiện S13d; mở lại app không hỏi lại.

## F3 · Hôm nay: làm xong / dời / bỏ qua (Flow 3)

**Người làm:** Khang · **Số màn:** 14

**Làm gì:** Trang chính: lời chào, "Đã xong 3/6 việc", việc tiếp theo, danh sách việc; xem chi tiết; Đã xong / Dời / Bỏ qua, có Hoàn tác.

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| S03 | Hôm nay | [node 1:270](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-270) |
| S03 | Hôm nay – xem từng việc (bấm nút) | [node 1:487](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-487) |
| S03b | Hôm nay sau khi xong 1 việc | [node 12:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=12-2) |
| S03-alldone | Hôm nay · xong 6/6 | [node 7:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=7-2) |
| N17 | Hôm nay · đã xử lý hết (5 xong · 1 bỏ qua) | [node 47:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=47-2) |
| ST-Empty | Hôm nay chưa có việc | [node 15:39](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=15-39) |
| S04 | Chi tiết hoạt động | [node 1:580](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-580) |
| DLG-Done | Xác nhận đã xong | [node 29:125](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-125) |
| DLG-Later | Dời việc | [node 29:156](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-156) |
| DLG-Skip | Bỏ qua hôm nay | [node 29:211](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-211) |
| S03-later | Hôm nay (đã dời 30 phút) | [node 8:189](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=8-189) |
| S03-later4 | Hôm nay · dời chiều nay | [node 10:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=10-2) |
| S03-tomorrow | Hôm nay · dời ngày mai | [node 11:189](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=11-189) |
| S03-skip | Hôm nay · đã bỏ qua | [node 10:193](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=10-193) |

**Firebase / kỹ thuật:** Firestore tasks + completions theo ngày, Analytics complete_task / postpone_task / skip_task.

**Xong khi:** Đủ loading / trống / lỗi + Thử lại; Hoàn tác trả lại trạng thái cũ; đánh dấu xong ≤ 2 lần chạm (chỉ số thành công #1).

## F4 · Thêm, sửa, xoá việc (Flow 2, Flow 7)

**Người làm:** Khang · **Số màn:** 20

**Làm gì:** Chọn hoạt động, đặt giờ, lặp lại, nhắc; báo lỗi nhập có ví dụ; đang lưu / lưu lỗi / mất mạng; sửa và xoá có hỏi phạm vi.

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| S05 | Thêm việc – chọn hoạt động | [node 1:688](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-688) |
| S05 | Thêm việc – xem thêm (cuộn) | [node 1:758](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-758) |
| S06 | Thêm việc – thiết lập | [node 1:890](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-890) |
| S06e | Thêm việc · thiếu thông tin | [node 12:193](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=12-193) |
| S06o | Thêm việc · đã sửa lỗi | [node 13:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=13-2) |
| ST-Validation | Thêm việc · báo lỗi nhập | [node 29:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-2) |
| DLG-TaskTime | Chọn giờ làm | [node 29:256](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-256) |
| N11 | Chọn ngày | [node 43:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-2) |
| N12 | Lặp lại | [node 43:95](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-95) |
| N13 | Phạm vi thay đổi | [node 43:195](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-195) |
| N14 | Chưa lưu thay đổi | [node 43:239](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-239) |
| ST-Loading | Đang lưu việc | [node 26:191](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-191) |
| ST-Loading-offline | Đang lưu · mất mạng | [node 26:199](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-199) |
| ST-Saved | Đã lưu xong | [node 26:217](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-217) |
| ST-Error | Chưa lưu được | [node 26:159](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-159) |
| N16 | Đã lưu · nhắc cần kiểm tra | [node 43:290](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-290) |
| S15 | Sửa việc | [node 1:2624](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2624) |
| DLG-Delete | Xóa việc | [node 29:98](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=29-98) |
| S03-edited | Hôm nay · đã lưu thay đổi | [node 8:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=8-2) |
| S03-deleted | Hôm nay · đã xóa việc | [node 7:168](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=7-168) |

**Firebase / kỹ thuật:** Firestore tasks (create/update/delete), Crashlytics non-fatal khi lưu lỗi (đường lỗi thật), Analytics add_task / edit_task / delete_task.

**Xong khi:** Lỗi thiếu tên/giờ hiện S06e; mất mạng hiện ST-Loading-offline; xoá việc lặp hỏi "lần này / các lần sau"; thêm việc ≤ 60 giây (chỉ số #2).

## F5 · Thêm việc bằng giọng nói

**Người làm:** Khang · **Số màn:** 6

**Làm gì:** Bác nói "Đi bộ 6 giờ sáng mỗi ngày", app hiện lại + đọc to để xác nhận rồi lưu. Bật/tắt bằng Remote Config.

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| V00 | Cho phép dùng micro | [node 140:112](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-112) |
| V01 | Nói để thêm việc – sẵn sàng | [node 140:147](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-147) |
| V02 | Đang nghe Bác nói | [node 140:176](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-176) |
| V03 | Bác xem lại việc vừa nói | [node 140:205](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-205) |
| V04 | Chưa nghe rõ | [node 140:256](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-256) |
| V05 | Đã thêm việc bằng giọng nói | [node 140:290](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=140-290) |

**Firebase / kỹ thuật:** speech_to_text, flutter_tts, quyền micro, Remote Config `voice_input_enabled`, Analytics voice_add_task.

**Xong khi:** Từ chối micro không crash; nói không rõ hiện V04; tắt cờ trên console thì nút "Nói việc" ở S05 biến mất, không cần build lại.

## F6 · Lời nhắc đến giờ (Flow 6)

**Người làm:** Khang · **Số màn:** 3

**Làm gì:** Màn lời nhắc toàn màn hình: Bắt đầu làm / Nhắc lại sau N phút / Bỏ qua, đọc to; cài đặt nhắc việc.

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| S14 | Lời nhắc đến giờ | [node 1:635](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-635) |
| S03-snooze | Hôm nay · nhắc lại sau 10 phút | [node 11:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=11-2) |
| N07 | Cài đặt nhắc việc | [node 41:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=41-2) |

**Firebase / kỹ thuật:** flutter_local_notifications (fullScreenIntent), Remote Config `snooze_minutes`, mở từ thông báo FCM.

**Xong khi:** Đổi `snooze_minutes` 10 → 15 trên console thì nút S14 đổi theo; bấm thông báo mở đúng S14.

## F7 · Lịch tuần + xuất PDF (Flow 4)

**Người làm:** Hương · **Số màn:** 5

**Làm gì:** Xem 7 ngày, chi tiết một ngày; tạo PDF "Lịch tuần của Bác" rồi upload lên Storage (file bắt buộc của đề).

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| S07 | Lịch tuần | [node 1:970](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-970) |
| S07 | Lịch tuần (cuộn xuống) | [node 1:1136](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1136) |
| S11 | Chi tiết ngày | [node 1:1303](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1303) |
| S11 | Chi tiết ngày (cuộn xuống) | [node 1:1446](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1446) |
| S11b | Chi tiết ngày · ngày khác | [node 14:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=14-2) |

**Firebase / kỹ thuật:** Firestore tasks theo khoảng ngày, package pdf, Cloud Storage `reports/{uid}/…`, Analytics view_week / export_report.

**Xong khi:** Thêm nút "Xuất PDF" vào S07 (ghi traceability + sửa Figma). PDF đúng tuần đang xem; có thanh tiến độ + link tải.

## F8 · Cài đặt hiển thị & hồ sơ

**Người làm:** Sanh · **Số màn:** 5

**Làm gì:** Đổi cỡ chữ, tương phản cao, xem thử lời nhắc; sửa hồ sơ; cách dùng đơn giản; dữ liệu trên điện thoại; nút đăng xuất (gọi `AuthService` của Hiếu); chừa chỗ cho khu demo Firebase (F10, Hiếu làm).

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| S10 | Cài đặt hiển thị | [node 1:2325](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2325) |
| S10 | Cài đặt hiển thị (cuộn xuống) | [node 1:2474](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2474) |
| N06 | Thông tin của Bác (Sửa hồ sơ) | [node 38:187](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-187) |
| N08 | Cách dùng đơn giản | [node 41:85](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=41-85) |
| N20 | Dữ liệu trên điện thoại | [node 52:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-2) |

**Firebase / kỹ thuật:** Sanh chỉ gọi `SettingsService` qua interface + gắn event Analytics change_font_size cho màn mình. Bản Firestore `users/{uid}/settings` do Hiếu viết trong `lib/services/`.

**Xong khi:** Đổi cỡ chữ áp dụng toàn app; đúng ở 360 và 412 dp, không tràn chữ.

## F9 · 9 thói quen Power 9 (Flow 8 – Flow chính 1)

**Người làm:** Hương · **Số màn:** 3

**Làm gì:** Danh sách 9 thói quen, thống kê tuần, chi tiết thói quen có Đọc to và nút Thêm việc nối sang F4.

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| S08 | 9 thói quen | [node 1:1590](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1590) |
| S08 | Tuần này (thống kê) | [node 1:1740](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1740) |
| S16 | Chi tiết thói quen | [node 1:1934](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1934) |

**Firebase / kỹ thuật:** Firestore habits (nạp 9 thói quen, không hard-code), Analytics view_habit.

**Xong khi:** Đi hết Flow chính 1: S08 → S16 → thêm việc → ST-Saved; "Tuần này: x lần" tính từ dữ liệu thật.

## F10 · Firebase: thông báo, Remote Config, Crashlytics, khu demo

**Người làm:** Hiếu · **Số màn:** 1

**Làm gì:** Tạo project Firebase, `flutterfire configure`, bọc mọi SDK trong service (bản Firebase cho mọi service, kể cả `SettingsService` của F8); FCM nhận ở 3 trạng thái, xin quyền, lưu danh sách thông báo, bấm mở đúng màn; khu demo Firebase ở Hồ sơ (hộp thông báo, xuất & upload file, giá trị Remote Config, nút thử Crashlytics); security rules.

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| N06 | Thông tin của Bác (Sửa hồ sơ) | [node 38:187](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=38-187) |

**Firebase / kỹ thuật:** FCM, Analytics (≥ 7 sự kiện, `docs/analytics-plan.md`), Crashlytics (1 non-fatal thật + 1 test crash, custom key), Remote Config (≥ 2 tham số), firestore.rules, storage.rules.

**Xong khi:** Hộp thông báo + khu demo chưa có trong Figma: thiết kế thêm trên N06. Mỗi dịch vụ có ảnh bằng chứng trong `evidence/`.

## F11 · Gia đình: thêm người thân, nhắn tin (Flow 5, Flow 9)

**Người làm:** Hương · **Số màn:** 13

**Làm gì:** Danh sách người thân; thêm (danh bạ hoặc tự nhập), báo số sai; sửa, xoá; gọi và nhắn tin qua Zalo/SMS.

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| S09 | Gia đình | [node 1:1993](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-1993) |
| S09b | Gia đình · đã thêm người thân | [node 26:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-2) |
| S12 | Thêm người thân | [node 1:2110](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2110) |
| S12 | Thêm người thân – chọn từ danh bạ | [node 1:2146](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2146) |
| S12 | Thêm người thân – tự nhập | [node 1:2215](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2215) |
| S12a | Thêm người thân · chưa có số | [node 14:120](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=14-120) |
| S12e | Thêm người thân · số sai | [node 14:196](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=14-196) |
| N09 | Sửa người thân | [node 41:136](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=41-136) |
| N15 | Xóa người thân | [node 43:263](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=43-263) |
| N21 | Gia đình sau khi xóa người thân | [node 52:48](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-48) |
| S17 | Nhắn tin cho người thân | [node 1:2278](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2278) |
| S17b | Nhắn tin · đã mở chia sẻ | [node 26:122](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=26-122) |
| N10 | Đã mở ứng dụng chia sẻ | [node 41:205](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=41-205) |

**Firebase / kỹ thuật:** Firestore family, url_launcher (gọi), share_plus (nhắn), quyền danh bạ, Analytics add_relative / share_message.

**Xong khi:** Số sai hiện S12e có ví dụ; từ chối quyền danh bạ vẫn tự nhập được; xoá người thân có xác nhận.

## F12 · Gợi ý lịch: Con cháu gửi ↔ Bác nhận

**Người làm:** Sanh · **Số màn:** 19

**Làm gì:** Con cháu soạn gợi ý (G01–G02) → máy Bác hiện popup / thẻ trên Hôm nay → nhận hết, đổi giờ, chọn từng việc, hoặc bỏ qua (có Hoàn tác).

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| G01 | Con cháu soạn lịch gợi ý | [node 52:161](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-161) |
| G01b | Soạn gợi ý · chọn giờ | [node 52:230](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=52-230) |
| G02 | Đã gửi gợi ý | [node 56:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=56-2) |
| G03 | Lịch Mai gợi ý | [node 56:107](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=56-107) |
| G03b | Lịch Mai gợi ý · đã đổi giờ | [node 56:201](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=56-201) |
| G04 | Đổi giờ đi bộ | [node 57:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=57-2) |
| G05 | Đã nhận gợi ý | [node 57:128](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=57-128) |
| G05b | Đã nhận · đổi giờ | [node 58:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=58-2) |
| G06 | Chọn từng việc | [node 58:117](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=58-117) |
| G07 | Đã nhận một việc | [node 61:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=61-2) |
| G07b | Đã nhận một việc · nhánh B | [node 61:118](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=61-118) |
| G08 | Lịch ngày mai | [node 61:233](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=61-233) |
| G08b | Lịch ngày mai | [node 63:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=63-2) |
| G08c | Lịch ngày mai | [node 63:102](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=63-102) |
| G08d | Lịch ngày mai | [node 63:179](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=63-179) |
| G09 | Đã bỏ qua gợi ý | [node 66:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=66-2) |
| G10 | Có gợi ý mới (tự hiện) | [node 66:119](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=66-119) |
| G11 | Popup Mai gửi lịch cho Bác | [node 71:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=71-2) |
| G12 | Hôm nay · thẻ gợi ý của Mai | [node 71:209](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=71-209) |

**Firebase / kỹ thuật:** Sanh làm màn + ViewModel trên interface `SuggestionService` và gắn Analytics send_suggestion / accept_suggestion. Bản Firestore `suggestions` (dữ liệu chung giữa 2 máy đã ghép nối) + FCM báo gợi ý mới do Hiếu viết (F10).

**Xong khi:** Mẹ nhận gợi ý ≤ 2 lần chạm (chỉ số #6); nhận tạo đúng việc trong lịch của mẹ; bỏ qua không báo lại cho con. Thẻ G12 đặt trên S03 qua widget dùng chung của F0, không sửa vào code F3 của Khang.

## F13 · Ghép nối máy con cháu với máy mẹ (Flow 10)

**Người làm:** Hiếu · **Số màn:** 2

**Làm gì:** Máy mẹ hiện mã 6 số; con cháu nhập mã để ghép nối; mã sai / hết hạn có đường phục hồi.

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| C02 | Nhập mã ghép nối | [node 1:3382](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-3382) |
| C02e | Mã sai hoặc hết hạn | [node 71:402](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=71-402) |

**Firebase / kỹ thuật:** Firestore `pairings/{code}` (hết hạn sau 10 phút), rules chỉ cho người đã ghép nối đọc/ghi lịch của mẹ.

**Xong khi:** Ghép nối được giữa 2 máy thật; mã hết hạn hiện C02e; rules chặn người lạ đọc lịch của mẹ.

## F14 · Con cháu lập lịch cho mẹ (Flow 11, 12 – Flow chính 3)

**Người làm:** Hiếu · **Số màn:** 11

**Làm gì:** Lịch của mẹ theo Ngày / Tuần / Tháng; form 3 bước tạo việc lặp (mỗi tuần / mỗi tháng), kiểm tra trùng giờ, gửi cho mẹ; sửa / ngưng lịch lặp có hỏi phạm vi.

| Mã màn | Tên khung trong Figma | Mở Figma |
|---|---|---|
| C03 | Lịch của mẹ Lan (Hoàn thiện biểu tượng & Bố cục) | [node 1:3148](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-3148) |
| C04 | Lịch của mẹ · Tuần | [node 73:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=73-2) |
| C05 | Lịch của mẹ · Tháng | [node 73:105](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=73-105) |
| C06 | Tạo việc gợi ý (Bước 1/3) | [node 1:3036](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-3036) |
| C06e | Thiếu tên hoặc giờ | [node 74:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=74-2) |
| C07 | Lặp lại việc gợi ý (Bước 2/3) | [node 1:2764](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2764) |
| C07m | Lặp lại mỗi tháng (Bước 2/3) | [node 74:98](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=74-98) |
| C08 | Xem lại và gửi gợi ý (Bước 3/3) | [node 1:2960](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2960) |
| C08w | Trùng giờ | [node 74:235](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=74-235) |
| C09 | Đã gửi cho mẹ | [node 1:2717](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=1-2717) |
| C10 | Chi tiết việc lặp lại | [node 75:2](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled?node-id=75-2) |

**Firebase / kỹ thuật:** Firestore `users/{momUid}/tasks` (quyền qua ghép nối), suggestions, Analytics create_recurring_task.

**Xong khi:** Đi hết Flow chính 3 từ C03 tới C09; lập 1 lịch lặp ≤ 90 giây, ≤ 3 bước (chỉ số #5).
