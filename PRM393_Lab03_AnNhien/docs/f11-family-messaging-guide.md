# Hướng dẫn Kỹ thuật Tin nhắn Gia đình & Lời nhắn Âm thanh (Feature F11)

## 1. Khái niệm Thiết kế Tin nhắn Dành cho Người cao tuổi
Giao diện tin nhắn gia đình được tinh giản tối đa so với các ứng dụng chat thông thường:
- Không hiển thị bàn phím ảo phức tạp nếu người dùng muốn gửi phản hồi nhanh.
- Nút bấm to với các câu phản hồi mẫu sẵn: "Mẹ đã uống thuốc rồi", "Mẹ khỏe, con yên tâm", "Hôm nay mẹ vui lắm".
- Gửi tin nhắn giọng nói 1 chạm (Nhấn và giữ nút micro to ở giữa màn hình).

## 2. Tính năng Lời nhắn Động viên từ Con cháu
- Con cháu có thể gửi những lời nhắc nhở kèm file ghi âm giọng nói thật của mình (ví dụ: tiếng cháu gái nhắc "Bà ơi bà nhớ uống thuốc huyết áp nhé!").
- Ứng dụng sẽ phát trực tiếp âm thanh này khi đến giờ hẹn thay cho chuông báo thức mặc định.

## 3. Kiến trúc Đồng bộ Dữ liệu Firestore
- Collection: `conversations/{familyId}/messages`
- Document Fields:
  - `senderId`: ID người gửi
  - `senderRole`: vai trò ('elderly' | 'caregiver' | 'member')
  - `type`: kiểu tin nhắn ('text' | 'voice' | 'quick_reply' | 'sticker')
  - `content`: nội dung văn bản hoặc link audio storage
  - `timestamp`: thời gian gửi
  - `isRead`: cờ đánh dấu đã đọc\n