# AI code review

Chủ file: **Sanh** (điều phối bước 7). Review theo từng PR. Đề yêu cầu: **ít nhất 5 phát hiện (≥ 2 loại), sửa ít nhất 3**, mỗi bản sửa một commit `fix(CR-xx): …`. **Mỗi người ≥ 1 bản sửa trong PR của mình** và giải thích được vì sao nhận / sửa / bỏ.

## Cách chạy

1. Mở PR (nhánh `feat/<mã-feature>-<mô-tả>`).
2. Chạy AI review trên diff của PR với prompt mẫu bên dưới.
3. Ghi **mọi** phát hiện vào bảng, kể cả cái bỏ qua (ghi lý do).
4. Sửa cái nhận → commit `fix(CR-xx): <mô tả ngắn>` → điền cột "Commit sửa".

### Prompt mẫu

```text
Review diff của PR này cho dự án An Nhiên (Flutter, MVVM + Riverpod, Firebase).
Đọc trước: PRM393_Lab03_AnNhien/docs/architecture.md (mục 15 Luật),
docs/lab2/rule.md, docs/lab2/vocabulary.md.
Chỉ báo phát hiện có thật, mỗi phát hiện: file:dòng, loại (theo bảng Loại),
mô tả, vì sao sai (dẫn luật / đề / số đo), cách sửa đề xuất. Không sửa code.
```

## Loại phát hiện và điều cần kiểm

| Loại | Kiểm gì | Dựa vào |
| --- | --- | --- |
| Kiến trúc | Widget gọi Firebase / `http` trực tiếp; logic trong `build()`; không có `UiState`; service không tiêm qua `providers.dart` | `architecture.md` mục 15 |
| Thiết kế / token | Màu, cỡ chữ, khoảng cách viết cứng; dùng widget riêng thay widget chung; lệch Figma mà không có DT-xx | `architecture.md` mục 12–13, `design-traceability.md` |
| Trợ năng | Chữ < 20 sp, nút < 60 dp, vùng chạm < 48 dp, trạng thái chỉ bằng màu, thiếu `Semantics`, tràn chữ ở `textScaler` 2.0 | `lab2/rule.md`, `lab2/accessibility.md` |
| Câu chữ | Từ cấm ("task", "sync", "streak", "bạn chưa hoàn thành"…), xưng hô sai, câu > 15 tiếng, nút > 5 tiếng | `lab2/AppStyleGuide.md`, `lab2/vocabulary.md` |
| Đúng sai | Thiếu nhánh lỗi / Thử lại; Hoàn tác không trả đúng trạng thái; bỏ qua gợi ý vẫn báo cho con cháu; S17 báo "Đã gửi" | "Xong khi" từng feature, FR08, FR09 |
| Bảo mật / riêng tư | Lộ key, tài khoản test; analytics gửi tên / số điện thoại; rules cho người lạ đọc | `analytics-plan.md` Luật, `firebase/*.rules` |
| Test | ViewModel thiếu test nhánh Empty / Error; test phụ thuộc mạng | `architecture.md` mục 15 luật 4 |
| Hiệu năng | Gọi Firestore trong vòng lặp, không huỷ stream, rebuild cả màn khi chỉ đổi 1 dòng | — |

## Phát hiện

| ID | PR | Công cụ | File:dòng | Loại | Phát hiện | Quyết định (nhận / sửa / bỏ) | Lý do (dựa vào đề / luật / số đo / ràng buộc) | Người | Commit sửa |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CR-01 | | | | | | | | | |

## Công cụ AI đã dùng

| Công cụ | Dùng để làm gì | Ai dùng |
| --- | --- | --- |
| Claude | Chia việc, khung project, viết docs, sinh màn + ViewModel từ Figma, AI review | Sanh |
| Google Stitch | Sinh thiết kế v0 cho Lab 2 (`lab2/design-decisions.md`) | Sanh |
| Codex | Vòng Stitch tự phản biện cho C / G / N (Lab 2) | Sanh |
| _(thêm khi dùng)_ | | |

## F10 — rà soát cục bộ bằng Codex (02/11/2026)

Đây là tự rà soát implementation trong working tree, chưa phải review trên PR;
không thay bằng chứng commit `fix(CR-xx)` của đề. Chưa tạo PR/commit trong lượt này.

| ID | File | Loại | Phát hiện | Sửa và kiểm chứng | Commit sửa |
| --- | --- | --- | --- | --- | --- |
| CR-F10-01 | firebase_messaging_service.dart | Đúng sai | Inbox RAM mất khi process chết; cold-start push không tạo lịch sử bền vững | Inbox Firestore do trusted sender ghi trước push; rules tests owner/stranger | Chưa commit |
| CR-F10-02 | notification_target.dart / app_router.dart | Bảo mật | Payload mới cần được kiểm tra trước khi thành route | Allowlist local target + recipient_uid + auth/profile guards; target/routing tests | Chưa commit |
| CR-F10-03 | app_button.dart | Trợ năng | Nhãn ellipsis bị cắt ở chữ 200% | wrapLabel opt-in F10; widget tests 360/412 dp, 200% | Chưa commit |
| CR-F10-04 | firebase_demo_view_model.dart | Đúng sai | RC realtime thay UiData có thể xóa busy, cho bấm upload lần hai | Giữ busy/message/progress/url khi đọc RC | Chưa commit |
| CR-F10-05 | session_data_service.dart | Bảo mật | Callback xóa token lỗi có thể bỏ qua xóa cache | terminate/clearPersistence trong finally; còn cần native runtime | Chưa commit |
| CR-F10-06 | firebase_messaging_service.dart / sender | Riêng tư | Đăng ký máy cũ có thể còn khi logout offline | Invalidate token, xóa đăng ký; sender giới hạn 30 ngày, system tray chung và recipient guard | Chưa commit |

Chưa có adapter/native E2E do không có Android device. Không suy diễn Fake tests
thành xác nhận FCM/Storage/Crashlytics production đã chạy.

## Tự review của Hiếu — 04/11/2026

Đây là AI tự review diff local, **chưa phải review trên PR**. Không có link PR hoặc
GitHub Actions run để ghi nhận yêu cầu review trên PR đã đạt.

| Mã | Phát hiện có trigger cụ thể | Sửa và kiểm chứng |
|---|---|---|
| CR-H01 | Gửi lại cùng request ID nhưng đổi nội dung: backend từng trả success cho bản cũ, khiến UI báo lịch mới đã gửi dù dữ liệu không khớp | So sánh sender/tasks/message trước khi trả idempotent success; payload khác trả already-exists. Test transaction Emulator có case đổi message |
| CR-H02 | Client đặt schema v1 rồi thêm startDate/weekday sai có thể đi qua nhánh validate legacy | Nhánh legacy chỉ nhận các field v1, test Emulator chặn v2 fields giả dạng legacy |

Không ghi nhận các kiểm tra local này là bằng chứng chạy AI review trên GitHub.
