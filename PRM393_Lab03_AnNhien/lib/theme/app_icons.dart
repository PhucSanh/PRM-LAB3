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

  // Tab bottom nav (DESIGN.md › Từ điển icon › Điều hướng).
  static const tabToday = Icons.wb_sunny_outlined; // sun
  static const tabWeek = Icons.calendar_month_outlined; // calendar-days
  static const tabHabits = Icons.eco_outlined; // leaf
  static const tabFamily = Icons.volunteer_activism_outlined; // hand-heart (không dùng users)

  // Trạng thái chung (state_views).
  static const retry = Icons.rotate_left; // rotate-ccw – Thử lại
}
