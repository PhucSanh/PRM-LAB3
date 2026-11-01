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
  static const double button = 14;
  static const double lg = 16;
  static const double xl = 24;

  static const BorderRadius buttonAll = BorderRadius.all(Radius.circular(button));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(lg));
}

/// Kích thước vùng chạm (Figma đã sửa theo Canva, rule.md R-TAP-01/02).
abstract final class AppSizes {
  /// Nút, ô nhập, mục danh sách: ≥ 72 dp (≈ 11.43 mm).
  static const double minTarget = 72;

  /// Nút micro lớn ở luồng giọng nói (V01, V02): 152 dp (≈ 24 mm).
  static const double micButton = 152;

  static const double icon = 32;
  static const double iconInChip = 24;
}
