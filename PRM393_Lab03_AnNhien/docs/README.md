# docs/ – Tài liệu dự án An Nhiên (Lab 3)

Thư mục này là **nguồn chuẩn** của dự án: thầy chấm theo các file ở đây (8 bước của đề), cả nhóm tra cứu, và AI agent đọc làm context trước khi code (thứ tự đọc ở cuối file này).

## File Lab 3 (cả nhóm cập nhật trong lúc làm)

| File | Trả lời câu hỏi | Bước đề | Chủ | Khi nào sửa |
| --- | --- | --- | --- | --- |
| `design-traceability.md` | Khung Figma nào → route, ViewModel, nguồn dữ liệu nào? Làm tới đâu? Lệch Figma chỗ nào? | 1 | Sanh | Bắt đầu / xong mỗi màn; khi lệch Figma (DT-xx) |
| `architecture.md` | Code tổ chức thế nào? Route map, service, dữ liệu Firestore, widget dùng chung, luật bị chấm | 2 | Sanh (Firebase: Hiếu) | Thêm ViewModel / service / route / trường dữ liệu |
| `analytics-plan.md` | Ghi event gì, tham số gì, đo chỉ số thành công nào? | 5 | Hiếu | Thêm event; có ảnh DebugView |
| `test-plan.md` | Test ca nào, ai test, kết quả 3 lần chạy? | 6 | Hương | Thêm ca; sau mỗi lần chạy |
| `code-review.md` | AI review ra gì, sửa hay bỏ, vì sao? | 7 | Sanh | Mỗi PR |

## Tài liệu Lab 2 (`lab2/`, bản chép nguyên văn, **chỉ đọc**)

Chép từ repo `prm393-lab2-an-nhien` để repo này tự đủ. Muốn đổi thiết kế: sửa Figma + ghi DT-xx trong `design-traceability.md`, **không** sửa file trong `lab2/`.

| File | Dùng khi | Nguồn gốc |
| --- | --- | --- |
| `lab2/flutter-handoff.md` | Code một màn: layout, component, states, interactions, navigation, ràng buộc UI; Bảng 1 token → Flutter, Bảng 2 component → widget | `flutter-handoff.md` |
| `lab2/user-flow.md` | Hiểu một flow đầu tới cuối (mermaid, nhánh lỗi, nhánh phụ), IA 2 chế độ | `ux/user-flow.md` |
| `lab2/rule.md` | Tự chấm màn vừa làm (11 luật cho người 65+) | `rule.md` |
| `lab2/accessibility.md` | Contrast, vùng chạm, cỡ chữ, 360 / 412 dp, vấn đề còn mở | `accessibility.md` |
| `lab2/design-tokens.md` | Token màu / chữ / spacing / bo góc, 9 màu thói quen, từ điển icon | `assets/stitch/DESIGN.md` (đổi tên để không nhầm với `DESIGN.md` gốc là prompt lịch sử) |
| `lab2/AppStyleGuide.md` | Viết câu chữ: giọng văn, xưng hô, nhãn nút, câu mẫu lỗi / xác nhận / thành công | `assets/stitch/AppStyleGuide.md` |
| `lab2/vocabulary.md` | Tên 9 thói quen, từ nên dùng / từ cấm | `assets/stitch/vocabulary.md` |
| `lab2/PRD.md` | Phạm vi, user story, FR / NFR có tiêu chí chấp nhận, chỉ số M1–M8 | `assets/stitch/PRD.md` |
| `lab2/persona.md` | Bà Lan, chị Mai, chỉ số thành công, Power 9 → việc hằng ngày | `ux/persona.md` |
| `lab2/design-decisions.md` | Vì sao thiết kế như vậy (D1, D23…), các vòng rà soát | `design-decisions.md` |
| `lab2/bang_mau.png`, `lab2/power9.png` | Ảnh bảng màu và 9 thói quen | `assets/stitch/` |

Trong các file `lab2/`, chỗ nào nhắc `DESIGN.md` (trong `assets/stitch/`) thì xem `lab2/design-tokens.md`.

Bản HTML Stitch từng màn (cột "Stitch" trong `design-traceability.md`) **không** chép sang vì nặng: xem trong repo Lab 2 ở `codex-runs/` và `stitch-runs/`.

## Agent đọc theo thứ tự nào

1. `../../An-Nhien_Chia-task_Lab3.md` → feature của mình, "Xong khi".
2. `design-traceability.md` → dòng của màn: node Figma, route, ViewModel, nguồn dữ liệu.
3. `architecture.md` → service, widget dùng chung, dữ liệu, luật.
4. `lab2/flutter-handoff.md` → đặc tả màn (tìm theo mã).
5. `lab2/AppStyleGuide.md` + `lab2/vocabulary.md` → câu chữ.
6. `analytics-plan.md` → event của màn.
7. Sau khi làm: tự chấm theo `lab2/rule.md`, test theo `test-plan.md`, cập nhật `design-traceability.md` + `architecture.md`.
