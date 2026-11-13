# Tra cứu: Model

Lớp Dart thuần trong `lib/models/`, có `fromMap` / `toMap` để đọc ghi Firestore.

| File | Dùng cho |
| --- | --- |
| `app_user.dart` | Người dùng đăng nhập + vai trò |
| `user_profile.dart` | Hồ sơ (tên, cách xưng hô, giờ thức dậy) |
| `app_settings.dart` | Cỡ chữ, tương phản cao, đọc to, rung |
| `task_item.dart` | Một việc trong lịch (giờ, lặp lại, nhắc) |
| `voice_task_draft.dart` | Bản nháp việc tạo từ giọng nói |
| `habit.dart`, `habit_guide.dart`, `guided_activity.dart` | Thói quen Power 9 và hoạt động gợi ý |
| `relative.dart` | Người thân trong danh bạ gia đình |
| `suggestion.dart` | Gợi ý lịch từ con cháu |
| `app_notification.dart`, `notification_target.dart` | Thông báo và route đích khi bấm |
