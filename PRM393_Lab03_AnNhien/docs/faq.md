# Câu hỏi thường gặp (FAQ)

**Vì sao chữ nhỏ nhất là 20 sp?**
Người dùng chính trên 65 tuổi; chữ nhỏ hơn khó đọc. Toàn bộ `TextTheme` được điền để widget Material cũng không dưới 20 sp.

**Test có cần mạng / Firebase không?**
Không. Test ViewModel override service bằng bản `Fake…`.

**Thêm một trường mới vào Firestore thì làm sao?**
Đề xuất trong PR; người phụ trách Firebase chốt và cập nhật `docs/architecture.md` mục 10.

**Muốn làm khác thiết kế Figma?**
Ghi một dòng `DT-xx` cuối `docs/design-traceability.md` và sửa Figma.

**Con cháu có xem được lịch của Bác không?**
Chỉ khi đã ghép nối bằng mã (hết hạn sau 10 phút) và chỉ được đọc `tasks` / `completions`.

**Bật / tắt nhập giọng nói mà không build lại?**
Đổi khoá Remote Config `voice_input_enabled`.

**Gặp lỗi khi chạy?**
Xem `docs/troubleshooting-runbook.md`.
