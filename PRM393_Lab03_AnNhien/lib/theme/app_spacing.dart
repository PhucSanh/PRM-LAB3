import 'package:flutter/widgets.dart';

/// Khoảng cách (DESIGN.md › spacing). Lề màn 20, khoảng cách khối 16.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double screen = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Khoảng cách tối thiểu giữa 2 nút kề nhau (≈ 3.17 mm, slide Canva). rule.md R-TAP-03.
  static const double betweenTargets = 20;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: screen);
}

/// Bo góc (DESIGN.md › rounded).
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double button = 20;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999; // chip trạng thái, avatar (Bảng 1: StadiumBorder)

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius buttonAll = BorderRadius.all(Radius.circular(button));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius dialogAll = BorderRadius.all(Radius.circular(xl));
}

/// Kích thước (Figma đã sửa theo Canva, rule.md R-TAP-01/02; DESIGN.md › components).
abstract final class AppSizes {
  /// Nút, ô nhập, mục danh sách: ≥ 72 dp (≈ 11.43 mm).
  static const double minTarget = 72;

  /// Nút micro lớn ở luồng giọng nói (V01, V02): 152 dp (≈ 24 mm).
  static const double micButton = 152;

  static const double icon = 32;
  static const double iconInChip = 24;

  /// Ô icon thói quen 48 × 48 (DESIGN.md › habit-icon-*).
  static const double habitIcon = 48;

  /// Vạch màu thói quen bên trái thẻ việc (DESIGN.md › card-accent-bar).
  static const double accentBar = 6;

  /// Viền nút phụ, ô nhập, ô lựa chọn: 2 dp (DESIGN.md › option-card-outline, Bảng 2 Secondary).
  static const double border = 2;

  /// Icon minh hoạ của màn Trống / Lỗi.
  static const double stateIcon = 64;

  /// Logo trên màn đăng nhập / chào mừng.
  static const double logo = 96;

  /// Thanh "Quay lại": cao 88 (chứa nút 72 + lề), rộng phần nút 180 để đủ chữ "Quay lại" ở cỡ chữ lớn.
  static const double appBar = 88;
  static const double backButtonWidth = 180;

  /// Bottom nav: cao 96 (vùng chạm 72 + nhãn 20 sp).
  static const double navBar = 96;

  /// Vòng xoay trong nút đang bận và nét vòng xoay.
  static const double spinnerInButton = 28;
  static const double spinnerStroke = 3;
  static const double spinnerStrokeLarge = 6;
}
