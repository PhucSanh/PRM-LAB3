# Test plan – Google ARTEMIS

Chủ file: **Hương** (điều phối bước 6). **Mỗi người viết và chạy test cho flow của mình**, mỗi test ≥ 3 lần, ghi pass rate. Tài khoản Google test và API key để trong biến môi trường, **không commit**.

Nguồn: flow + nhánh lỗi trong `lab2/user-flow.md`, tiêu chí chấp nhận FR01–FR13 trong `lab2/PRD.md`, chỉ số M1–M8, mục "Xong khi" từng feature trong `../../An-Nhien_Chia-task_Lab3.md`.

## Flow quan trọng → màn → người

| Flow | Màn | Người |
| --- | --- | --- |
| Đăng nhập / chọn vai trò | A01 (Google), C01 | Hiếu |
| Đăng xuất | S10 | Sanh |
| Onboarding (Flow 1) | S01, S02, S13 / S13d, N01–N05, N18, N19 | Hương |
| Làm xong / dời / bỏ qua (Flow 3) | S03, S04, DLG-Done / Later / Skip | Khang |
| Thêm việc có lỗi (Flow 2) | S05, S06, S06e, ST-Validation, ST-Loading(-offline), ST-Saved, ST-Error | Khang |
| Sửa & xoá (Flow 7) | S04, S15, N13, DLG-Delete | Khang |
| Giọng nói | V00–V05 | Khang |
| Lời nhắc (Flow 6 – Flow chính 2) | S14, S03-snooze, N07 | Khang |
| Lịch tuần + PDF (Flow 4) | S07, S11, S11b | Hương |
| Thói quen (Flow 8 – Flow chính 1) | S08, S16 → S06 → ST-Saved | Hương |
| Gia đình (Flow 5, 9) | S09, S12, S12e, N09, N15, S17, S17b | Hương |
| Cài đặt & hồ sơ | S10, N06, N08, N20 | Sanh |
| Gợi ý lịch (G) | G01–G12 (2 máy) | Sanh |
| Ghép nối (Flow 10) | C02, C02e (2 máy) | Hiếu |
| Lập lịch cho mẹ (Flow 11, 12 – Flow chính 3) | C03–C10 | Hiếu |
| Firebase (FCM, Remote Config, Crashlytics, rules) | S14, N06 khu demo, Hộp thông báo | Hiếu |

## Ca test

Loại: `Chính` (happy path) · `Lỗi` (nhánh lỗi + phục hồi) · `Native` (quyền, thông báo, app bên ngoài) · `RC` (Remote Config) · `Export` · `Analytics` · `Bảo mật` · `Exploratory`.

| ID | Flow | Điều kiện đầu | Bước | Kết quả mong đợi (giá trị agent phải báo lại) | Loại | Người | Kết quả |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TC-01 | Đăng nhập | Cài app, chưa đăng nhập | Mở app → "Tiếp tục với Google" → chọn tài khoản test | Vào C01 (lần đầu); tài khoản Bác đã onboarding vào Trang chủ, có lời chào và 5 mục Trang chủ / Khám phá / Thói quen / Gia đình / Cá nhân | Native | Hiếu | |
| TC-02 | Đăng nhập | Chưa đăng nhập | Bấm Google → huỷ | Thấy câu "Bác chưa đăng nhập…" | Lỗi | Hiếu | |
| TC-03 | Thêm việc | Đã đăng nhập | Thêm "Đi bộ" 6:00 mỗi ngày | Việc có trong Hôm nay; báo tổng số việc | Chính | Khang | |
| TC-04 | Thêm việc | Đã đăng nhập | Lưu khi chưa nhập tên → nhập tên → lưu | Thấy lỗi có ví dụ (S06e), sau đó ST-Saved | Lỗi | Khang | |
| TC-05 | Làm xong | Có việc chưa làm | Bấm Đã xong → Đúng, đã xong → Hoàn tác | Trạng thái quay về "Chưa làm"; báo số việc xong; đếm số chạm ≤ 2 (M1) | Chính | Khang | |
| TC-06 | Giọng nói | Quyền micro đã cho | V01 → nói "Đi bộ 6 giờ sáng mỗi ngày" → V03 → Lưu | V05 hiện tên việc + giờ | Chính | Khang | |
| TC-07 | Điều hướng | Đã đăng nhập | Mở lần lượt 5 mục điều hướng + màn chi tiết | Báo tiêu đề từng màn; nhãn đầy đủ, cỡ chữ lớn dùng menu Chuyển mục | Chính | Sanh | |
| TC-08 | Gia đình | Đã đăng nhập | Thêm người thân số sai → sửa → lưu | Thấy S12e có ví dụ, rồi người thân có trong danh sách (S09b) | Lỗi | Hương | |
| TC-09 | Xuất PDF | Có việc trong tuần | Trang chủ → Lưu lịch tuần PDF → Tạo và lưu PDF | Android mở chọn nơi lưu; PDF có đủ 7 ngày và trạng thái thật; hủy không báo thành công, đổi tài khoản thì dừng (luồng hiện hành thay Storage) | Export | Hương | |
| TC-10 | Remote Config | `snooze_minutes` = 15 trên console | Mở S14 | Báo số phút trên nút = 15 | RC | Khang | |
| TC-11 | Thông báo | App đã tắt | Gửi FCM từ console → bấm ở khay thông báo | Mở đúng màn lời nhắc S14 | Native | Hiếu | |
| TC-12 | Mất mạng | Tắt Wi-Fi + dữ liệu | Lưu việc | Thấy ST-Loading-offline rồi ST-Saved khi có mạng, hoặc ST-Error có "Thử lại"; nội dung không mất | Lỗi | Khang | |
| TC-13 | Đăng xuất | Đã đăng nhập | Cài đặt → Đăng xuất | Về màn đăng nhập, không thấy dữ liệu cũ | Chính | Sanh | |
| TC-14 | Analytics | Debug mode bật | Làm TC-03 | Logcat / DebugView có `add_task` | Analytics | Hiếu | |
| TC-15 | Onboarding | Tài khoản mới, vai trò Bác | S01 chọn "Lớn" → S02 nhập tên, giờ thức dậy → S13 cho phép → N04 chọn việc đầu tiên → lưu | Tới N19: Hôm nay có việc đầu tiên; mở lại app không hỏi lại | Chính | Hương | |
| TC-16 | Onboarding | Tài khoản mới | Tới S13 → "Để sau" / từ chối quyền | Thấy S13d "Nhắc việc đang tắt"; vẫn vào được Hôm nay | Lỗi | Hương | |
| TC-17 | Thói quen | Đã đăng nhập | S08 → "Vận động tự nhiên" → "Thêm việc cho thói quen này" → lưu | ST-Saved; S16 "Tuần này: x lần" tăng đúng | Chính | Hương | |
| TC-18 | Dời / bỏ qua | Có việc chưa làm | Dời "30 phút nữa" → Hoàn tác; Bỏ qua "Trời mưa" | Snackbar nói rõ giờ mới; Hoàn tác về giờ cũ; TaskRow "Bỏ qua · … (trời mưa)" | Chính | Khang | |
| TC-19 | Sửa & xoá | Có việc lặp mỗi ngày | S04 → Sửa → đổi giờ → "Chỉ lần này"; rồi Xoá → "Không xoá, giữ lại" | Chỉ hôm nay đổi giờ; việc không bị xoá | Lỗi | Khang | |
| TC-20 | Cỡ chữ | Đã đăng nhập | S10 → "Rất lớn" → về Hôm nay | Chữ toàn app lớn lên; không tràn ở 360 dp | Chính | Sanh | |
| TC-21 | Hồ sơ | Đã đăng nhập | S10 → Sửa hồ sơ (N06) → đổi tên → Lưu | Lời chào ở S03 đổi theo tên mới | Chính | Sanh | |
| TC-22 | Ghép nối | Máy A vai trò Bác, máy B vai trò Con cháu | Máy A lấy mã 6 số → máy B nhập mã | Máy B thấy C03 "Lịch của mẹ … Đã ghép nối" | Chính | Hiếu | |
| TC-23 | Ghép nối | Mã đã quá 10 phút | Máy B nhập mã cũ | Thấy C02e "Mã chưa đúng hoặc đã hết hạn"; số đã nhập giữ nguyên | Lỗi | Hiếu | |
| TC-24 | Lập lịch cho mẹ | Đã ghép nối | C03 → Tạo lịch → tên + giờ → Mỗi tuần T2, T4, T6 → Gửi | Tới C09 "Đang chờ mẹ nhận"; báo thời gian thao tác (≤ 90 giây, M5) | Chính | Hiếu | |
| TC-25 | Lập lịch cho mẹ | Mẹ đã có việc 8:00 | Tạo việc 8:00 cùng ngày → Gửi | Thấy C08w "Trùng giờ" với "Đổi giờ khác" / "Vẫn gửi" | Lỗi | Hiếu | |
| TC-26 | Gợi ý lịch | Đã ghép nối; máy B gửi 2 việc (G01) | Máy A mở app | Popup G11 hiện **một lần**; "Xem gợi ý" → G03 → "Thêm 2 việc vào lịch" → G05; đếm chạm ≤ 2 (M6) | Chính | Sanh | |
| TC-27 | Gợi ý lịch | Có gợi ý chờ | G03 → "Bỏ qua gợi ý" → Hoàn tác | G09 rồi quay lại G03; máy B **không** nhận báo bỏ qua | Lỗi | Sanh | |
| TC-28 | Gợi ý lịch | Có gợi ý chờ | G11 → "Để sau" | Thẻ G12 ở đầu Hôm nay; mở lại app popup không hiện lại | Chính | Sanh | |
| TC-29 | Bảo mật | Máy C đăng nhập tài khoản khác, chưa ghép nối | Thử đọc `users/{momUid}/tasks` | Bị rules chặn (permission-denied) | Bảo mật | Hiếu | |
| TC-30 | Crashlytics | Khu demo N06 | Bấm "Thử crash"; lưu việc khi Firestore lỗi | Console có 1 crash + 1 non-fatal có custom key | Native | Hiếu | |
| TC-31 | Nhắn tin | Có người thân | S09 → Nhắn tin → chọn chủ đề → Zalo | Mở app Zalo / chia sẻ; S17b ghi "chưa xác nhận đã gửi", **không** có chữ "Đã gửi" | Native | Hương | |
| EX-01 | Khám phá | Profile Pro, 15–30 phút | Không kịch bản | Danh sách lỗi tìm được | Exploratory | Hương | |

## Kiểm tra thủ công cho mọi màn (theo `lab2/rule.md`, `lab2/accessibility.md`)

- [ ] 360 dp và 412 dp, `textScaler` 2.0: không tràn ngang, nút Lưu không bị bàn phím che.
- [ ] Chữ ≥ 20 sp; nút chính 60 dp; vùng chạm ≥ 48 dp, cách nhau ≥ 8 dp.
- [ ] Trạng thái có icon + chữ, không chỉ màu; TalkBack đọc được nút và lỗi (`liveRegion`).
- [ ] Không có thao tác chỉ làm được bằng vuốt / nhấn giữ.
- [ ] Câu chữ đúng `lab2/vocabulary.md` (không "task", "sync", "streak"…).

## Kết quả chạy

| ID | Lần 1 | Lần 2 | Lần 3 | Pass rate | Thời gian TB | Ghi chú (flaky vì sao) |
| --- | --- | --- | --- | --- | --- | --- |
| TC-01 | | | | | | |
| TC-03 | Chưa chạy | Chưa chạy | Chưa chạy | — | — | F4: tạo việc; chạy bằng `e2e_test/run_artemis.py` |
| TC-04 | Chưa chạy | Chưa chạy | Chưa chạy | — | — | F4: lỗi tên → gợi ý → lưu |
| TC-12 | Chưa chạy | Chưa chạy | Chưa chạy | — | — | F4: cần Android + điều kiện mất mạng thật |
| TC-19 | Chưa chạy | Chưa chạy | Chưa chạy | — | — | F4: sửa/xóa task lặp, kiểm tra scope |

## F10 bổ sung 02/11/2026

Tự động: `test/f10_test.dart`, push routing case trong `test/auth_routing_test.dart`,
2 ca F10 trong `firebase/tests/rules.test.mjs`. Kết quả và giới hạn xem
[f10-verification.md](f10-verification.md). Flutter PASS 25 tests; Emulator PASS 9 nhóm.
Các kết quả này không thay ARTEMIS hoặc kiểm tra thiết bị.

| Ca nghiệm thu Android/ARTEMIS | Lần 1 | Lần 2 | Lần 3 |
| --- | --- | --- | --- |
| Inbox: quyền/từ chối, trống/lỗi/thử lại | Chưa chạy | Chưa chạy | Chưa chạy |
| FCM foreground/background/cold start, mở đúng màn | Chưa chạy | Chưa chạy | Chưa chạy |
| Đổi tài khoản, không thấy inbox cũ; restart giữ inbox | Chưa chạy | Chưa chạy | Chưa chạy |
| RC Console thay giá trị → UI cập nhật | Chưa chạy | Chưa chạy | Chưa chạy |
| Tạo/upload PDF, tiến độ, URL thật, non-fatal khi lỗi | Chưa chạy | Chưa chạy | Chưa chạy |
| Hủy/xác nhận test crash, mở lại và thấy Console report | Chưa chạy | Chưa chạy | Chưa chạy |

Fixture ARTEMIS hiện còn skip/TODO; không sửa thay Hương hoặc ghi kết quả giả.

## Kiểm chứng bổ sung Hiếu — 04/11/2026

`test/caregiver_flow_test.dart`: gửi form 3 bước → demo mẹ chọn nhận → lịch cập nhật;
trùng giờ, lỗi/retry/idempotency; layout 360/412dp × chữ 1x/2x.
`test/task_schedule_test.dart`: weekly/monthly/cuối tháng/leap year, scope, Undo,
xung đột qua nửa đêm, completion ancestry.
`integration_test/firebase_emulator_test.dart`: ba Firebase SDK sessions trên AVD,
Auth/Firestore/Functions Emulator thật, phân quyền và split giữ completion.
`integration_test/local_reminder_test.dart`: NotificationManager thật, active/pending,
snooze không xoá ngày sau, cancel và dọn khi đổi phiên.

Chạy bằng scripts trong [hieu-implementation-guide.md](hieu-implementation-guide.md).
Các bài này **không phải ARTEMIS**. Fixture ARTEMIS hiện hành của Hương không bị
đổi thành pass hoặc gỡ skip để tạo bằng chứng. Console/thiết bị vật lý vẫn cần nghiệm thu.
