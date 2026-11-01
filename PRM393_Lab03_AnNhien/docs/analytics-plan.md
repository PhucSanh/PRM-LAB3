# Analytics event plan

Chủ file: Hiếu. Không gửi tên, e-mail, số điện thoại trong tham số.

| Event | Trigger (màn / flow) | Tham số (kiểu) | Câu hỏi sản phẩm |
| --- | --- | --- | --- |
| `login` | Đăng nhập Google xong (F1) | `method` (string) | Bao nhiêu người quay lại mỗi tuần? |
| `logout` | Bấm Đăng xuất (F8) | — | Phiên dùng kéo dài bao lâu? |
| `tutorial_complete` | Xong onboarding (F2) | `font_size` (string), `notifications_on` (bool) | Bao nhiêu người hoàn tất thiết lập, cỡ chữ nào phổ biến? |
| `add_task` | Lưu việc mới (F4) | `habit_key` (string), `repeat` (string), `source` (string: tap/voice) | Thói quen nào được thêm nhiều; giọng nói có được dùng không? |
| `complete_task` | Đánh dấu Đã xong (F3, F6) | `task_id` (string), `habit_key` (string), `on_time` (bool) | Bác có làm việc đúng giờ (tiêu chí thành công Lab 2)? |
| `skip_task` / `postpone_task` | Bỏ qua / Dời (F3, F6) | `task_id` (string), `reason` (string) | Việc nào hay bị bỏ, vì sao? |
| `view_habit` | Mở S16 (F9) | `habit_key` (string) | Thói quen nào được tìm hiểu mà chưa thêm thành việc? |
| `voice_add_task` | Lưu ở V03 (F5) | `success` (bool), `attempts` (int) | Nhập giọng nói có hiểu đúng ngay lần đầu? |
| `export_report` | Upload PDF xong (F7) | `week` (string), `file_size_kb` (int) | Ai xuất lịch tuần để gửi con cháu? |
| `accept_suggestion` | Nhận gợi ý (F12) | `count` (int), `changed_time` (bool) | Gợi ý của con cháu có được nhận? |

Bằng chứng: ảnh DebugView từng sự kiện → `evidence/analytics/`.
