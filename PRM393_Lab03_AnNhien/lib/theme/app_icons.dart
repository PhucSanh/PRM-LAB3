import 'package:flutter/material.dart';

/// Bộ icon 32 dp (Figma › Components `138:2`, gốc Lucide) → `IconData` Material gần nhất.
/// Không thêm package icon. Nghĩa của từng icon theo DESIGN.md › Từ điển icon: mỗi icon một nghĩa,
/// luôn kèm chữ. Chủ file: A – Sanh.
abstract final class AppIcons {
  // Khung Components (theo thứ tự trên Figma).
  static const mic = Icons.mic_none_outlined; // mic – nói để thêm việc
  static const phone = Icons.phone_outlined; // phone – chỉ cho hành động gọi
  static const lock = Icons.lock_outline; // lock
  static const fingerprint = Icons.fingerprint; // fingerprint
  static const check = Icons.check; // check – chốt lựa chọn ("Xong", "Đúng rồi")
  static const checkCircle = Icons.check_circle_outline; // circle-check – chỉ cho "Đã xong"
  static const refresh = Icons.sync; // refresh-cw
  static const volume = Icons.volume_up_outlined; // volume-2 – Đọc to
  static const list = Icons.article_outlined; // file-text / list
  static const chevronLeft = Icons.chevron_left; // chevron-left – luôn kèm chữ "Quay lại"
  static const alert = Icons.error_outline; // circle-alert – lỗi nhập, lỗi lưu
  static const clock = Icons.schedule; // clock – giờ của việc
  static const repeat = Icons.repeat; // repeat – lặp lại
  static const bell = Icons.notifications_none; // bell – lời nhắc
  static const arrowRight = Icons.arrow_forward; // arrow-right – Tiếp tục, Bắt đầu
  static const x = Icons.close; // x – không đổi, đóng hộp thoại (luôn kèm chữ)
  static const square = Icons.check_box_outline_blank; // square – ô chọn chưa chọn
  static const shield = Icons.shield_outlined; // shield-check
  static const pencil = Icons.edit_outlined; // pencil – Sửa
  static const user = Icons.person_outline; // user – tên Bác, hồ sơ
  static const home = Icons.home_outlined; // house – thói quen Gia đình trên hết
  static const walk = Icons.directions_walk; // footprints / walk – thói quen Vận động

  // Form (widget F0-04).
  static const info = Icons.info_outline; // info – câu gợi ý "Ví dụ…" dưới ô nhập
  static const chevronDown = Icons.keyboard_arrow_down; // chevron-down – ô giờ "Đổi giờ ⌄"
  static const save = Icons.save_outlined; // save – Lưu giờ, Lưu việc này, Lưu người thân
  static const radioOn = Icons.check_circle; // lựa chọn đang chọn (khác circle-check "Đã xong")
  static const radioOff = Icons.radio_button_unchecked; // lựa chọn chưa chọn

  // 9 thói quen (vocabulary.md mục 1; Move dùng [walk], Gia đình trên hết dùng [home]).
  static const habitPurpose = Icons.explore_outlined; // compass – Sống có mục đích
  static const habitDownshift = Icons.air; // wind – Thư giãn mỗi ngày
  static const habitEighty = Icons.restaurant; // utensils – Ăn vừa đủ
  static const habitPlant = Icons.rice_bowl_outlined; // salad – Ăn nhiều rau, đậu
  static const habitTea = Icons.emoji_food_beverage_outlined; // coffee – Trà chiều cùng bạn
  static const habitBelong = Icons.groups_outlined; // users – Gắn kết cộng đồng
  static const habitTribe = Icons.handshake_outlined; // handshake – Bạn bè tích cực

  // Trạng thái việc + hành động trên thẻ việc (widget F0-05; DESIGN.md › Từ điển icon).
  static const statusSkipped = Icons.remove_circle_outline; // circle-minus – "Bỏ qua"
  static const statusPostponed = Icons.redo; // redo-2 – "Đã dời"
  static const later = Icons.alarm_add_outlined; // alarm-clock-plus – "Dời lại", "Nhắc lại sau"
  static const skipToday = Icons.skip_next_outlined; // skip-forward – "Hôm nay bỏ qua"
  static const stopReading = Icons.stop_circle_outlined; // circle-stop – "Dừng đọc"
  static const suggestion = Icons.mail_outline; // mail – chỉ cho thẻ "Mai gửi Bác …" (G12)
  static const view = Icons.visibility_outlined; // eye – "Xem thử", "Xem gợi ý"
  static const chevronRight = Icons.chevron_right; // chevron-right – mở chi tiết, cuối thẻ bấm được

  // Tab bottom nav (DESIGN.md › Từ điển icon › Điều hướng).
  static const tabToday = Icons.wb_sunny_outlined; // sun
  static const tabWeek = Icons.calendar_month_outlined; // calendar-days
  static const tabHabits = Icons.eco_outlined; // leaf
  static const tabFamily = Icons.volunteer_activism_outlined; // hand-heart (không dùng users)

  // Trạng thái chung (state_views).
  static const retry = Icons.rotate_left; // rotate-ccw – Thử lại

  // Cài đặt S10 (Figma `1:2325` / `1:2474`; F8 bước 02 đề xuất, F0 duyệt).
  static const settings = Icons.settings_outlined; // settings – tiêu đề "Cài đặt"
  static const textSize = Icons.title; // type – thẻ "Cỡ chữ"
  static const contrast = Icons.contrast; // contrast – "Chữ và nền rõ hơn"
  static const vibrate = Icons.vibration; // smartphone-vibrate – "Rung khi có lời nhắc"
  static const bellRing = Icons.notifications_active_outlined; // bell-ring – "Xem thử lời nhắc"
  static const bookOpen = Icons.menu_book_outlined; // book-open – "Cách dùng đơn giản"
  static const smartphone = Icons.smartphone; // smartphone – "Dữ liệu trên điện thoại"
  static const logout = Icons.logout; // log-out – "Đăng xuất"

  // Hồ sơ N06 (Figma `38:187`; F8 bước 03 đề xuất, F0 duyệt).
  static const smile = Icons.sentiment_satisfied_alt_outlined; // smile – "An Nhiên gọi Bác là"
  static const sunrise = Icons.wb_twilight; // sunrise – "Bác thức dậy lúc"

  // Gia đình S09 (Figma `1:1993` / `26:2`; F11 bước 02 đề xuất, F0 – Sanh duyệt).
  static const message = Icons.chat_bubble_outline; // message-square – "Nhắn tin"
  static const userPlus = Icons.person_add_alt; // user-plus – "Thêm người thân"

  // Thêm người thân S12 (Figma `14:120` / `1:2146`; F11 bước 03 đề xuất, F0 – Sanh duyệt).
  static const contact = Icons.contact_page_outlined; // contact – "Chọn từ danh bạ"
  static const search = Icons.search; // search – ô "Tìm tên"
}
