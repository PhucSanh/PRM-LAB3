# Tra cứu: Widget dùng chung

Màn của mọi người **chỉ** dùng widget trong `lib/widgets/`. Thiếu widget → báo chủ F0, không tự làm bản riêng.

| Nhóm | Widget |
| --- | --- |
| Khung màn | `app_shell`, `app_back_bar`, `app_surface`, `section_card` |
| Nút & nhập liệu | `app_button`, `app_text_field`, `app_dropdown_field`, `time_field`, `choice_group`, `switch_row`, `form_parts`, `relationship_dropdown` |
| Trạng thái | `state_views` (Loading / Empty / Error + Thử lại), `undo_snackbar`, `confirm_dialog` |
| Việc & lịch | `task_widgets`, `task_detail_parts`, `quick_task_actions`, `upcoming_activity_card` |
| Thói quen | `habit_widgets`, `habit_photo_cards`, `activity_discovery_deck` |
| Gợi ý | `suggestion_card`, `suggestion_swipe_deck` |
| Gia đình & con cháu | `family_contact_card`, `caregiver_parts`, `caregiver_design_icon` |
| Đọc to & giọng nói | `read_aloud_button`, `read_aloud_control`, `read_aloud_region`, `voice_task_review`, `voice_example_art` |
| Trợ lý | `assistant_bubble`, `assistant_mascot`, `global_assistance` |
| Trang trí | `brand_mark`, `botanical_scene`, `icon_circle`, `nav_row`, `calm_parts`, `velora_parts`, `velora_home_parts` |
| Phát triển | `feature_placeholder`, `firebase_demo_entry`, `dev/` |

Xem trực quan tại route `/dev/widgets` khi chạy bản dev.
