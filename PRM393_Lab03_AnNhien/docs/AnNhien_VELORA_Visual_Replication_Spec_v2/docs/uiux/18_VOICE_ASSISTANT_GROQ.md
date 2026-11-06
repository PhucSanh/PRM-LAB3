# 18 — Nói để thêm lịch với Groq (06/11/2026)

Theo yêu cầu trực tiếp của người dùng: bổ sung LLM để hiểu tên việc, ngày, giờ và cách lặp từ câu nói tiếng Việt. Giữ phong cách VELORA và typography tại 15/16/17.

- Route `/today/voice`: Android nhận giọng nói; Bác có thể sửa phần chữ. Chỉ gọi Groq khi bấm **Hiểu lời Bác nói**; có câu giải thích phần chữ được gửi ra dịch vụ.
- Mơ hồ/thiếu thông tin: hỏi và đọc câu hỏi, hỗ trợ nói hoặc gõ câu trả lời bổ sung. Không tự gán “8 giờ” thành 08:00 nếu chưa rõ sáng/tối. Không tự suy ngày khi Bác chưa chỉ ngày.
- Đủ thông tin: hiển thị và đọc bản nháp gồm tên/ngày/giờ/lặp. **Dùng lịch này** chỉ điền form F4; Bác còn kiểm tra và bấm Lưu. LLM không tự ghi, sửa hoặc xoá lịch.
- Đang xử lý: giữ nhãn trạng thái, khóa gửi lặp và chỉnh nội dung; kết quả về sau khi đăng xuất/dispose bị bỏ. Sửa câu ban đầu vô hiệu bản nháp AI cũ.
- Lỗi mạng/chưa key/chưa backend: thông báo trung thực, giữ câu nói và cho nhập tay. Không dùng Fake thay production. Key chỉ ở server Secret Manager, không nằm trong APK.
- Form/name giới hạn 80 ký tự; transcript/câu bổ sung tối đa 500 ký tự/lượt và 4 lượt. Nếu nhập tay từ câu dài, yêu cầu rút gọn tên để Bác tự chọn ngày giờ trong form.
- Tương lai được tính theo múi giờ Việt Nam UTC+07. Bác nói nhiều việc hoặc yêu cầu sửa/xoá phải được hướng dẫn nói một việc mới.

Hướng dẫn cấu hình và bằng chứng: `docs/groq-voice-setup.md` ở gốc project. Code và test fixture đã hoàn thành; chưa có key/chưa deploy Functions, nên chưa nghiệm thu chất lượng hiểu tiếng Việt của Groq thật. Project hiện còn điều kiện Blaze cho Functions. Không đánh dấu production-ready chỉ từ mock/widget tests.
