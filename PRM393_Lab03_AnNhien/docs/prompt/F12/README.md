# Prompt F12 · Gợi ý lịch: Con cháu gửi ↔ Bác nhận (Sanh)

Chạy **lần lượt** từng file trong nhánh F12, mỗi file một phiên agent mới (dán: "Đọc và thực hiện `docs/prompt/F12/0x-….md`"). Xong mỗi bước: đọc mục "Kết quả chạy" ở cuối file, trả lời câu agent hỏi, chạy thử trên máy, rồi commit trước khi sang bước sau.

| Bước | File | Màn | Commit gợi ý |
| --- | --- | --- | --- |
| 01 | `01-service-viewmodel.md` | `SuggestionService` + Fake, model, khung 3 ViewModel | `feat(F12): thêm SuggestionService (Fake), model gợi ý và khung ViewModel` |
| 02 | `02-g01-con-chau-gui.md` | G01, G01b, G02 (máy con cháu) | `feat(F12): màn G01 con cháu soạn và gửi gợi ý lịch` |
| 03 | `03-g03-nhan-goi-y.md` | G03, G03b, G04, G05, G05b | `feat(F12): màn G03 Bác xem và nhận gợi ý, đổi giờ` |
| 04 | `04-g06-chon-tung-viec-bo-qua.md` | G06, G07, G07b, G09 | `feat(F12): chọn từng việc và bỏ qua gợi ý có Hoàn tác` |
| 05 | `05-g10-g12-popup-the.md` | G10, G11, G12 | `feat(F12): popup gợi ý mới hiện một lần và dữ liệu thẻ G12` |
| 06 | `06-g08-kiem-tra-pr.md` | G08–G08d (phối hợp Hương), test cả luồng, docs, `PR-F12.md` | `test(F12): test cả luồng 2 máy, chốt docs và PR-F12` |

Mọi bước đều bắt agent **làm đúng Figma**: gọi `get_design_context` + `get_screenshot` từng node, chép nguyên văn chữ, không thêm / bớt khối, so ảnh màn Flutter với Figma; lệch chỉ khi bạn đồng ý và phải có `DT-xx`. Mỗi file có bảng nội dung Figma đã đối chiếu (04/11/2026) và mục **"Điểm Figma cần hỏi"** – agent sẽ dừng lại hỏi các điểm đó, nên chuẩn bị câu trả lời trước. Chính:

- **Bước 01:** `TaskItem` chưa có trường ngày (gợi ý là việc ngày mai); thêm `fromRelation` ("Con gái") + `timeOptions` (8:00 / 9:00) vào model; lời nhắn mẫu G03 và popup khác nhau; nhận tiếp việc còn lại sau G07.
- **Bước 02:** G01 gọi "mẹ", G01b gọi "Bác"; 2 việc cố định trong Figma lấy từ đâu; G01 / G02 có back "Gia đình" + bottom nav của Bác dù chạy trên máy con cháu.
- **Bước 03:** "Đổi giờ đi bộ" khi gợi ý có việc khác; G03b thẻ vẫn ghi 8:00; nhãn back "Gia đình" khi mở từ Hôm nay; G03 không có bottom nav nhưng G03b / G04 / G05 có; nút "Đọc to".
- **Bước 04:** G06 chọn một hay nhiều việc; "Hoàn tác" ở G09 là nút trên màn (Figma) hay snackbar (`CLAUDE.md`).
- **Bước 05:** G10 và G11 dùng khi nào; thẻ G12 trong Figma không có tên việc / nút bỏ qua; gắn popup vào `AppShell`.
- **Bước 06:** G08–G08d nằm trên S11 của Hương – gửi đề xuất, không tự làm.

Phụ thuộc người khác: Hiếu (bản Firebase + FCM + rules ghép nối), Khang (dán thẻ G12 / popup lên S03), Hương (G08* trên S11, hàng "Gợi ý từ Mai" ở S09).
