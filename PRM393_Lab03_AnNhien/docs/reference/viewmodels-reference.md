# Tra cứu: ViewModel

Tất cả nằm trong `lib/viewmodels/`. Mỗi màn tải dữ liệu giữ một `UiState` (`ui_state.dart`).

| Nhóm | ViewModel |
| --- | --- |
| Đăng nhập & phiên | `sign_in_view_model`, `session_view_model`, `account_view_model` |
| Onboarding (F2) | `onboarding_view_model`, `first_task_view_model`, `try_reminder_view_model`, `device_access_view_model` |
| Hôm nay & việc (F3, F4) | `today_view_model`, `daily_actions_view_model`, `task_form_view_model`, `task_detail_view_model`, `schedule_conflict` |
| Giọng nói (F5) | `voice_command` |
| Lịch tuần & PDF (F7) | `weekly_report_view_model` |
| Cài đặt & hồ sơ (F8) | `settings_view_model`, `profile_view_model`, `display_settings_sync` |
| Thói quen & gia đình (F9, F11) | `calm_feature_providers`, `family_actions_view_model` |
| Gợi ý lịch (F12) | `suggestion_compose_view_model`, `suggestion_inbox_view_model`, `suggestion_review_view_model`, `suggestion_demo_view_model`, `inbox_view_model` |
| Ghép nối & con cháu (F13, F14) | `pairing_view_model`, `caregiver_form_view_model`, `caregiver_schedule_view_model` |
| Trợ lý | `assistant_view_model` |
| Demo Firebase | `firebase_demo_view_model` |

Mẫu để chép khi làm màn mới: `today_view_model.dart` + `test/today_view_model_test.dart`.
