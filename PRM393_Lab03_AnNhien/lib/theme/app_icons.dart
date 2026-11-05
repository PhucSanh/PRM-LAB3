import 'package:flutter/material.dart';

/// Icon Material Rounded 32 dp: hình quen thuộc, nét rõ và cùng phong cách.
/// Không thêm package icon. Nghĩa của từng icon theo DESIGN.md › Từ điển icon: mỗi icon một nghĩa,
/// luôn kèm chữ. Chủ file: A – Sanh.
abstract final class AppIcons {
  // Khung Components (theo thứ tự trên Figma).
  static const mic = Icons.mic_rounded; // mic – nói để thêm việc
  static const phone = Icons.call_rounded; // phone – chỉ cho hành động gọi
  static const lock = Icons.lock_rounded; // lock
  static const fingerprint = Icons.fingerprint; // fingerprint
  static const check =
      Icons.check; // check – chốt lựa chọn ("Xong", "Đúng rồi")
  static const checkCircle =
      Icons.task_alt_rounded; // circle-check – chỉ cho "Đã xong"
  static const refresh = Icons.sync; // refresh-cw
  static const volume = Icons.volume_up_rounded; // volume-2 – Đọc to
  static const list = Icons.checklist_rounded; // file-text / list
  static const chevronLeft =
      Icons.chevron_left; // chevron-left – luôn kèm chữ "Quay lại"
  static const alert = Icons.error_rounded; // circle-alert – lỗi nhập, lỗi lưu
  static const clock = Icons.access_time_filled_rounded; // clock – giờ của việc
  static const repeat = Icons.repeat; // repeat – lặp lại
  static const bell = Icons.notifications_rounded; // bell – lời nhắc
  static const arrowRight =
      Icons.arrow_forward; // arrow-right – Tiếp tục, Bắt đầu
  static const x = Icons.close; // x – không đổi, đóng hộp thoại (luôn kèm chữ)
  static const square =
      Icons.check_box_outline_blank; // square – ô chọn chưa chọn
  static const shield = Icons.verified_user_rounded; // shield-check
  static const pencil = Icons.edit_rounded; // pencil – Sửa
  static const user = Icons.account_circle_rounded; // user – tên Bác, hồ sơ
  static const home =
      Icons.family_restroom_rounded; // house – thói quen Gia đình trên hết
  static const walk =
      Icons.directions_walk_rounded; // footprints / walk – thói quen Vận động

  // Form (widget F0-04).
  static const info =
      Icons.info_rounded; // info – câu gợi ý "Ví dụ…" dưới ô nhập
  static const chevronDown =
      Icons.keyboard_arrow_down; // chevron-down – ô giờ "Đổi giờ ⌄"
  static const save =
      Icons.save_rounded; // save – Lưu giờ, Lưu việc này, Lưu người thân
  static const radioOn =
      Icons.check_circle; // lựa chọn đang chọn (khác circle-check "Đã xong")
  static const radioOff = Icons.radio_button_unchecked; // lựa chọn chưa chọn

  // 9 thói quen (vocabulary.md mục 1; Move dùng [walk], Gia đình trên hết dùng [home]).
  static const habitPurpose =
      Icons.emoji_objects_rounded; // bóng đèn – việc có ý nghĩa
  static const habitDownshift =
      Icons.self_improvement_rounded; // người ngồi thư giãn
  static const habitEighty = Icons.restaurant_rounded; // utensils – Ăn vừa đủ
  static const habitPlant =
      Icons.eco_rounded; // cây – bữa ăn nhiều thực vật
  static const habitTea =
      Icons.emoji_food_beverage_rounded; // coffee – Trà chiều cùng bạn
  static const habitBelong = Icons.groups_rounded; // users – Gắn kết cộng đồng
  static const habitTribe =
      Icons.handshake_rounded; // handshake – Bạn bè tích cực

  // Trạng thái việc + hành động trên thẻ việc (widget F0-05; DESIGN.md › Từ điển icon).
  static const statusSkipped =
      Icons.remove_circle_outline; // circle-minus – "Bỏ qua"
  static const statusPostponed = Icons.redo; // redo-2 – "Đã dời"
  static const later =
      Icons.alarm_add_rounded; // alarm-clock-plus – "Dời lại", "Nhắc lại sau"
  static const skipToday =
      Icons.event_busy_rounded; // skip-forward – "Hôm nay bỏ qua"
  static const stopReading =
      Icons.stop_circle_outlined; // circle-stop – "Dừng đọc"
  static const suggestion = Icons
      .mark_email_unread_rounded; // mail – chỉ cho thẻ "Mai gửi Bác …" (G12)
  static const view = Icons.visibility_rounded; // eye – "Xem thử", "Xem gợi ý"
  static const chevronRight =
      Icons.chevron_right; // chevron-right – mở chi tiết, cuối thẻ bấm được

  // Tab bottom nav (DESIGN.md › Từ điển icon › Điều hướng).
  static const tabToday = Icons.wb_sunny_rounded; // sun
  static const tabWeek = Icons.calendar_month_rounded; // calendar-days
  static const tabHabits = Icons.spa_rounded; // leaf
  static const tabFamily =
      Icons.family_restroom_rounded; // hand-heart (không dùng users)

  // Trạng thái chung (state_views).
  static const retry = Icons.rotate_left; // rotate-ccw – Thử lại

  // Cài đặt S10 (Figma `1:2325` / `1:2474`; F8 bước 02 đề xuất, F0 duyệt).
  static const settings =
      Icons.settings_rounded; // settings – tiêu đề "Cài đặt"
  static const textSize = Icons.text_increase_rounded; // type – thẻ "Cỡ chữ"
  static const contrast = Icons.contrast; // contrast – "Chữ và nền rõ hơn"
  static const vibrate =
      Icons.vibration; // smartphone-vibrate – "Rung khi có lời nhắc"
  static const bellRing =
      Icons.notifications_active_rounded; // bell-ring – "Xem thử lời nhắc"
  static const bookOpen =
      Icons.menu_book_rounded; // book-open – "Cách dùng đơn giản"
  static const smartphone =
      Icons.smartphone; // smartphone – "Dữ liệu trên điện thoại"
  static const logout = Icons.logout; // log-out – "Đăng xuất"

  // Hồ sơ N06 (Figma `38:187`; F8 bước 03 đề xuất, F0 duyệt).
  static const smile =
      Icons.sentiment_satisfied_alt_rounded; // smile – "An Nhiên gọi Bác là"
  static const sunrise =
      Icons.wb_twilight_rounded; // sunrise – "Bác thức dậy lúc"
}
