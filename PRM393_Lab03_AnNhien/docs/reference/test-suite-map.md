# Bản đồ bộ test

Chạy: `flutter test` (unit + widget), `e2e_test/` (ARTEMIS, pytest), `firebase/functions/test` (Cloud Functions).

| Feature | File test tiêu biểu trong `test/` |
| --- | --- |
| F0 Nền tảng | `theme_test`, `typography_test`, `text_scale_overflow_test`, `router_test`, `ui_polish_test` |
| F1 Tài khoản | `auth_routing_test`, `account_view_model_test` |
| F2 Onboarding | `onboarding_flow_test`, `onboarding_overflow_test`, `f2_view_models_test`, `f2_services_test`, `welcome_screen_test`, `first_task_screen_test`, `try_reminder_screen_test`, `device_access_flow_test` |
| F3 Hôm nay | `today_screen_test`, `today_view_model_test` |
| F4 Việc | `task_form_screen_test`, `task_form_view_model_test`, `task_schedule_test`, `delete_scope_test`, `moved_occurrence_edit_test`, `reschedule_collision_test`, `schedule_limits_test` |
| F5 Giọng nói | `voice_task_test`, `voice_command_test`, `voice_schedule_test`, `voice_task_screen_test`, `gemini_voice_task_service_test` |
| F6 Nhắc việc | `local_reminder_test`, `reminder_preferences_test` |
| F7 Lịch tuần | `calendar_day_test`, `weekly_report_test` |
| F8 Cài đặt | `settings_*_test`, `profile_*_test`, `setup_profile_screen_test` |
| F10 Firebase | `f10_test`, `push_notification_flow_test`, `foreground_push_test`, `notifications_screen_test` |
| F11 Gia đình | `relationship_dropdown_test`, `firebase_family_suggestion_test` |
| F12 Gợi ý | `f12_*_test`, `suggestion_*_test` |
| F13/F14 Con cháu | `caregiver_flow_test` |
| Trợ lý | `assistant_test`, `assistant_contact_filter_test`, `read_aloud_region_test` |
| Model (unit) | `test/unit/` |

Ảnh golden: `test/goldens/` (cập nhật bằng `flutter test --update-goldens`).
