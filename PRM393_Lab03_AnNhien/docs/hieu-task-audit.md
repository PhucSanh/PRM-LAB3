# Kiểm tra phần việc của Hiếu – 02/11/2026

Nguồn yêu cầu: `../../An-Nhien_Chia-task_Lab3.md`, bản phân công ngày 02/11/2026. Phạm vi Hiếu: F1, F10, F13, F14 (20 màn theo bảng phân công), toàn bộ Firebase/hạ tầng; không bao gồm F2 của Hương hoặc slides của Sanh.

Đối chiếu code ở commit `430ff67` và working tree hiện tại. Đây là kiểm tra tiến độ/độ đầy đủ, không phải xác nhận mọi feature đã chạy được. Chỉ đọc code, tài liệu và bằng chứng kiểm chứng đã có; không chạy lại build/E2E hay thay đổi feature trong lần audit này.

## Kết luận

Hạ tầng Android/Firebase đã có cấu hình thật và APK build thành công. Chưa có feature nào trong F1/F10/F13/F14 đủ toàn bộ tiêu chí “Xong khi”. F1 và F10 có một phần implementation; F13 và F14 chưa có luồng ứng dụng. Không quy đổi tiến độ sang phần trăm vì số lượng adapter hoặc số dòng code không phản ánh số flow đã hoàn thành.

## Checklist theo phần việc

| ID | Phần việc | Trạng thái | Bằng chứng hiện có | Còn thiếu để hoàn thành |
|---|---|---|---|---|
| H00 | Android, dependencies, Firebase Core config | ĐÃ CÓ + BUILD PASS | android/, pubspec.lock; firebase_options.dart + google-services.json; main dùng generated options; APK debug và chữ ký đã kiểm tra | Chạy app/Core trên Android thật hoặc emulator; build không chứng minh runtime |
| H01 | .github, CODEOWNERS, AI review trên PR | CHƯA CÓ CẤU HÌNH TRONG REPO | Không tìm thấy .github/, github-templates/, CODEOWNERS hay workflow trong working tree | Thêm CODEOWNERS với username thật và workflow/integration phù hợp. Chưa kiểm tra GitHub App/settings phía remote nên không kết luận mọi hình thức review bên GitHub đều chưa bật |
| H02 | F1 Google login/cancel/logout, auth routing | MỘT PHẦN | FirebaseAuthService triển khai interface; SignInScreen có nút Google; SignInViewModel có busy/error/login event; router chặn signed-out; widget routing test dùng Fake PASS | Thử Google login/cancel/network/logout thật trên Android, kiểm chứng session restore và sau khi key restrictions đổi |
| H03 | F1 tạo users/{uid}, chọn role C01, điều hướng Bác/Con cháu | ĐÃ CODE + KIỂM THỬ FAKE | UserProfile/ProfileService/FirebaseProfileService; RoleScreen/RoleViewModel; role/onboarded/paired guard | Chờ Google provider bật lại và thiết bị Android để xác minh Auth/Firestore thật; chưa kiểm chứng Figma |
| H04 | F1 đăng xuất/xóa dữ liệu phiên trên máy | ĐÃ CODE + KIỂM THỬ FAKE | AccountScreen xác nhận, SignOutViewModel, Firestore terminate/clearPersistence; reset state theo UID; lỗi cache vẫn kết thúc auth | Cần runtime Android để kiểm chứng cache native và đổi tài khoản thật |
| H05 | F10 Analytics/Crashlytics/Remote Config | CÓ ADAPTER, CHƯA ĐỦ NGHIỆM THU | firebase_telemetry_services.dart; main init và error hooks; giữ 3 Remote Config keys; logEvent thực sự ở app mới có login và complete_task | Chưa đủ ≥7 events có ảnh DebugView; thiếu event select_role/pair_device/create_recurring_task; chưa có non-fatal thật/test crash/custom-key evidence; chưa chứng minh đổi Remote Config Console tác động UI |
| H06 | F10 FCM/inbox/mở đúng màn | MỘT PHẦN | Nhận onMessage/onMessageOpenedApp/getInitialMessage, xin quyền, stream inbox/onOpened | Inbox chỉ RAM; AppNotification.route không được map; router chưa consume onOpened; chưa có inbox UI, lưu bền vững, test 3 trạng thái, token lifecycle hoặc ảnh bằng chứng |
| H07 | F10 khu demo Firebase ở N06 | CHƯA LÀM | /settings/profile và /inbox vẫn FeaturePlaceholder | Demo UI/ViewModel, điều khiển RC/crash/upload/inbox, cập nhật thiết kế và bằng chứng Console |
| H08 | F13 ghép nối C02/C02e | CHƯA LÀM | Rules có kiểm tra caregiver grant do backend tin cậy cấp; không có pairing service/screen/ViewModel/route | Mã 6 số, TTL 10 phút, consume mã, mã sai/hết hạn, owner consent, cấp/revoke grant an toàn và thử giữa 2 máy. pairings/{code} chưa có rule/implementation nên đang bị deny mặc định |
| H09 | F14 lịch mẹ C03–C10 và dialog C11/C12 | CHƯA LÀM + BỊ CHẶN SCHEMA | Không có routes /caregiver/..., screens, ViewModels hoặc CaregiverScheduleService | Lịch ngày/tuần/tháng; form 3 bước; lặp tuần/tháng; conflict; sửa/ngưng theo phạm vi; cross-device realtime; hoàn thành Flow 11/12; đo ≤90 giây/≤3 bước |
| H10 | Firebase TaskRepository dùng chung | BỊ CHẶN SCHEMA | firebase_repositories.dart: tasksForDay/save/setStatus luôn throw schemaPending; chỉ delete gọi Firestore | TaskItem thiếu date, timezone, weekdays, weekly/monthly recurrence và per-occurrence status. Phải thống nhất contract/migration với nhóm trước khi thay model và rules |
| H11 | Firebase FamilyRepository/HabitRepository | CÓ IMPLEMENTATION, THIẾU E2E | Có read/save/delete family, read habits, family watchAll; đã seed 9 habit documents | Thử đọc/ghi bằng app-user thật. Interface hiện là Future nên UI chưa nhận realtime qua stream; cần thống nhất với chủ ViewModel |
| H12 | SettingsService cho F8 | CHƯA LÀM | Không tìm thấy interface hoặc adapter SettingsService trong lib/ | Thống nhất contract với Sanh; lưu settings Firestore/cache và quyền đúng UID |
| H13 | SuggestionService cho F12 | CHƯA LÀM | Có rules cho transport suggestion tối thiểu, chưa có service/model/UI integration | Contract với Sanh; gửi/nhận theo hai UID đã ghép nối, accept/partial/dismiss/undo, tạo occurrence đúng ngày, realtime và FCM qua backend an toàn |
| H14 | Upload PDF F7 | ĐÃ CHUẨN BỊ, BỊ CHẶN | FirebaseReportService giữ interface, có progress/upload và URL sau thành công; renderer mặc định null | Renderer PDF của Hương chưa được inject; chưa xử lý bucket/Blaze hoặc phương án thay thế được chấp nhận; chưa upload thật. Storage rules chưa deploy |
| H15 | Rules và bảo mật | MỘT PHẦN ĐÃ KIỂM CHỨNG | Firestore rules đã deploy; 6 nhóm Emulator tests PASS; denied anonymous cloud read; API key restrictions có REST tests PASS | Pairing/recurrence/suggestion payload đầy đủ còn chưa có; caregiver hiện chỉ được đọc task/gửi suggestion, chưa được ghi trực tiếp lịch mẹ. Chưa có App Check/runtime SDK verification sau siết key |
| H16 | Trách nhiệm cá nhân: ViewModel, ARTEMIS, CR fix, commit và traceability | MỘT PHẦN, THIẾU BẰNG CHỨNG | Có SignInViewModel; git log có commit Firebase của tài khoản Hiếu; có analytics plan | ARTEMIS fixture luôn pytest.skip, chưa khởi tạo client; test auth còn mẫu/TODO; chưa có ≥3 lần chạy flow của Hiếu; evidence/ chỉ có .gitkeep; bảng CR còn trống, không thấy commit fix(CR-xx) trong lịch sử hiện có; chưa chứng minh commit mỗi ngày hoặc traceability screen hoàn tất |

## Các điểm đang chặn người khác

1. Task schema chưa thống nhất và repository đang chủ động trả lỗi: chặn lịch/ngày, task management, completion và dữ liệu đầu vào PDF của Khang/Hương. Có cấu hình Firestore không đồng nghĩa Today/tasks đã hoạt động.
2. SettingsService chưa tồn tại: Sanh chưa có service contract/adapter để nối F8 theo tài liệu.
3. SuggestionService và pairing chưa tồn tại: Sanh chưa thể nối F12 và F14 cũng chưa có quyền ghép nối hoàn chỉnh.
4. F1 đã khai báo /role và điểm vào /caregiver/pair, /caregiver/schedule; nội dung F13/F14 vẫn placeholder.

## Trình tự ưu tiên đề nghị

1. Chốt schema lịch/occurrence và các interface Settings/Suggestion/Pairing với nhóm; giữ thay đổi có thỏa thuận, không tự sửa model dùng chung.
2. Hoàn thành F1: lưu user, chọn role, route theo role, sign-out/reset phiên; thử Google login thật trên Android.
3. Hoàn thành F13: pairing an toàn và kiểm thử rules/cross-account.
4. Hoàn thành F14 và backend Task/Suggestion/realtime theo contract đã chốt.
5. Hoàn thiện F10: inbox/deep link, demo UI, instrumentation và ảnh Console; phần PDF phối hợp Hương và chốt yêu cầu Storage với thầy nếu không dùng billing.
6. Làm song song CODEOWNERS/AI review CI, test ViewModel/service, ARTEMIS ≥3 lần mỗi test, CR fix và cập nhật traceability.

## Bằng chứng đã có và giới hạn

- [firebase-verification.md](firebase-verification.md): analyzer PASS, 3 Flutter tests PASS, APK debug PASS, 6 nhóm rules tests PASS. Đây là kết quả đã chạy trước audit, không phải E2E mới chạy trong lần audit này.
- [firebase-key-review.md](firebase-key-review.md): thay restrictions theo phê duyệt; đúng package/SHA được gọi Auth config, thiếu/sai bị chặn; Firestore vẫn chặn request không có user token. Không có kết luận đã kiểm tra đầy đủ security logs hoặc không từng bị lạm dụng.
- [design-traceability.md](design-traceability.md): mô tả màn và services dự kiến; nhiều hàng vẫn todo. Tên ViewModel/service trong bảng không phải bằng chứng class đó đã được implement.
- [analytics-plan.md](analytics-plan.md): kế hoạch event, bảng ảnh bằng chứng còn trống; kế hoạch không phải dữ liệu đã thấy trên Console.

Không sửa feature screens, ViewModels, router, rules, cloud configuration hoặc phân công của thành viên khác trong lần kiểm tra này.

Cập nhật F1 sau audit: xem [f1-verification.md](f1-verification.md). Những hàng còn lại giữ kết quả audit trước đó.

Cập nhật F10 sau audit: xem [f10-verification.md](f10-verification.md).
H06/H07 đã có inbox Firestore, route consumer, token lifecycle, foreground banner
và demo UI/ViewModel; H05 có instrumentation F10 và lỗi upload thật được báo cáo.
Chưa có thiết bị, Console evidence hoặc cloud deployment mới nên không đánh dấu
F10 nghiệm thu done. Các blocker dùng chung ngoài phần này giữ nguyên.

Cập nhật cloud F10 sau phê duyệt 02/11: publish RC version 1 và deploy Firestore
rules đã thành công, đọc lại xác minh PASS. Storage/thiết bị/evidence vẫn còn chờ.
