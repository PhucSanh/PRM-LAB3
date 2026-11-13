# Tra cứu nhanh: Event Analytics

Bảng đầy đủ kèm tham số: `docs/analytics-plan.md`. Gọi `AnalyticsService.logEvent` **trong ViewModel**.

| Nhóm | Event |
| --- | --- |
| Tài khoản | `login`, `logout`, `select_role` |
| Onboarding | `tutorial_complete`, `test_reminder` |
| Việc hằng ngày | `complete_task`, `postpone_task`, `skip_task`, `undo_action` |
| Thêm / sửa việc | `add_task`, `edit_task`, `delete_task`, `create_recurring_task` |
| Giọng nói | `voice_add_task`, `voice_command` |
| Nhắc việc | `reminder_action` |
| Lịch tuần | `view_week`, `export_report` |
| Cài đặt | `change_font_size` |
| Thói quen & gia đình | `view_habit`, `add_relative`, `share` |
| Gợi ý & ghép nối | `send_suggestion`, `accept_suggestion`, `dismiss_suggestion`, `pair_device` |

User property: `role`, `font_size`, `notifications_on`, `high_contrast`.

**Không** gửi tên, e-mail, số điện thoại, nội dung tin nhắn hay tên việc tự gõ.
