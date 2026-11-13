# Tra cứu: Service

Mọi service được chọn bản dùng tại **một nơi duy nhất**: `lib/services/providers.dart`. Test ViewModel override bằng bản `Fake…`.

| Nhóm | Interface / dùng chung | Bản Firebase / nền tảng |
| --- | --- | --- |
| Đăng nhập | `auth_service.dart` | `firebase_auth_service.dart` |
| Hồ sơ & cài đặt | `profile_service.dart`, `settings_service.dart`, `profile_setup_service.dart` | `firebase_profile_service.dart`, `firebase_settings_service.dart` |
| Việc | `task_repository.dart`, `schedule_limits.dart` | `firebase_repositories.dart` |
| Thói quen | `habit_repository.dart` | `firebase_repositories.dart` |
| Gia đình | `family_repository.dart`, `contact_launcher_service.dart` | `firebase_repositories.dart` |
| Nhắc việc | `reminder_service.dart`, `reminder_runtime.dart` | `local_reminder_service.dart` |
| Giọng nói | `voice_task_service.dart` | `firebase_voice_task_service.dart`, `gemini_voice_task_service.dart`, `local_voice_task_service.dart` |
| Gợi ý lịch | `suggestion_service.dart`, `caregiver_suggestion_service.dart` | `firebase_suggestion_service.dart`, `firebase_family_suggestion_service.dart` |
| Ghép nối | `pairing_service.dart` | `firebase_pairing_service.dart` |
| Con cháu lập lịch | `caregiver_schedule_service.dart` | `firebase_caregiver_schedule_service.dart` |
| Báo cáo PDF | `report_service.dart`, `weekly_report_service.dart` | `firebase_report_service.dart` |
| Thông báo đẩy | `messaging_service.dart` | `firebase_messaging_service.dart` |
| Telemetry | `analytics_service.dart`, `crash_service.dart`, `remote_config_service.dart` | `firebase_telemetry_services.dart` |
| Trợ lý | `assistant_service.dart`, `assistant_contact_filter.dart` | — |

Quy tắc: widget / screen **không** gọi SDK Firebase trực tiếp; service bắt lỗi SDK rồi ném `AppException`.
