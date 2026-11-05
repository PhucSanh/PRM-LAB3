# Prompt F11 · Gia đình: thêm người thân, nhắn tin (Hương)

Chạy **lần lượt** từng file trong nhánh F11 (vd. `feat/F11-gia-dinh`), mỗi file một phiên agent mới (dán: "Đọc và thực hiện `docs/prompt/F11/0x-….md`"). Xong mỗi bước: đọc mục "Kết quả chạy" ở cuối file, trả lời câu agent hỏi, chạy thử trên máy, rồi commit **bằng tài khoản GitHub của Hương** trước khi sang bước sau.

| Bước | File | Màn | Commit gợi ý |
| --- | --- | --- | --- |
| 01 | `01-service-viewmodel.md` | Service danh bạ + gọi điện / nhắn tin (Fake), khung 3 ViewModel | `feat(F11): thêm service danh bạ, gọi điện, nhắn tin (Fake) và khung ViewModel` |
| 02 | `02-s09-gia-dinh.md` | S09, S09b | `feat(F11): màn S09 Gia đình, gọi điện và nhắn tin cho người thân` |
| 03 | `03-s12-them-nguoi-than.md` | S12 (3 khung), S12a, S12e | `feat(F11): thêm người thân từ danh bạ hoặc tự nhập, báo lỗi số có ví dụ` |
| 04 | `04-n09-sua-xoa.md` | N09, N15, N21 | `feat(F11): sửa, xoá người thân có hỏi lại và Hoàn tác` |
| 05 | `05-s17-nhan-tin.md` | S17, S17b, N10 | `feat(F11): nhắn tin qua Zalo / SMS, không báo đã gửi` |
| 06 | `06-kiem-tra-pr.md` | Test cả luồng, đối chiếu Figma, docs, `PR-F11.md` | `test(F11): test cả luồng Gia đình, chốt docs và PR-F11` |

Mọi bước đều bắt agent **làm đúng Figma**: gọi `get_design_context` + `get_screenshot` từng node, chép nguyên văn chữ, không thêm / bớt khối, so ảnh màn Flutter với Figma; lệch chỉ khi người dùng đồng ý và phải có `DT-xx`. Mỗi file có bảng nội dung Figma đã đối chiếu (04/11/2026) và mục **"Điểm Figma cần hỏi"** – agent sẽ dừng lại hỏi, nên chuẩn bị câu trả lời trước. Chính:

- **Bước 01:** quan hệ chỉ có Con / Cháu / Bạn bè / Khác nhưng Figma hiện "Con gái", "Con trai", "Hàng xóm"…; repo **chưa có package** gọi điện / nhắn tin / danh bạ (`url_launcher`, `share_plus`, `flutter_contacts`) – đề xuất thêm hay chờ; Figma "chọn từ danh bạ" là danh sách trong app có ô tìm tên.
- **Bước 02:** nút "Gọi" (S09) hay "Gọi điện" (S09b, N21); avatar icon hay chữ cái; chạm thẻ để mở N09.
- **Bước 03:** S12 có 2 kiểu bố trí (màn chọn "Chọn từ danh bạ / Tự nhập" vs màn S12a có cả form); Figma chỉ vẽ lỗi **thiếu số**, chưa có câu lỗi **số sai**; từ chối quyền danh bạ hiện gì.
- **Bước 04:** N21 khác S09 (nút xếp dọc, "Về Hôm nay"); Hoàn tác sau khi sửa.
- **Bước 05:** **S17 trong Figma thiếu phần chọn nội dung tin** (chỉ có "Gửi bằng" + khoảng trống) – cần Sanh sửa Figma hay làm theo handoff; S17b và N10 dùng khi nào.

Phụ thuộc người khác: Sanh (widget F0 còn thiếu – thẻ người thân 2 nút, hàng danh bạ; sửa Figma theo DT-xx), Hiếu (package / bản thật service, trường mới của `Relative`). Hàng "Gợi ý từ Mai" dùng `suggestionInboxViewModelProvider` của F12 (đã có).
