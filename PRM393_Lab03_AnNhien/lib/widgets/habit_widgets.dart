import 'read_aloud_region.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Icon, tên và câu mô tả **mặc định** của 9 thói quen (vocabulary.md mục 1 và 1.1). Màu ở `HabitPalette`.
/// Danh sách thói quen thật nạp từ Firestore `habits/{key}` (model `Habit`): màn truyền `habit.name` /
/// `habit.description` vào widget; bảng này chỉ là giá trị dự phòng khi chưa nạp xong.
abstract final class HabitStyle {
  static const _icons = <String, IconData>{
    'move': AppIcons.walk,
    'purpose': AppIcons.habitPurpose,
    'downshift': AppIcons.habitDownshift,
    'eighty': AppIcons.habitEighty,
    'plant': AppIcons.habitPlant,
    'tea': AppIcons.habitTea,
    'belong': AppIcons.habitBelong,
    'family': AppIcons.home,
    'tribe': AppIcons.habitTribe,
  };

  static const _names = <String, String>{
    'move': 'Vận động tự nhiên',
    'purpose': 'Sống có mục đích',
    'downshift': 'Thư giãn mỗi ngày',
    'eighty': 'Ăn vừa đủ',
    'plant': 'Ăn nhiều rau, đậu',
    'tea': 'Trà chiều cùng bạn',
    'belong': 'Gắn kết cộng đồng',
    'family': 'Gia đình trên hết',
    'tribe': 'Bạn bè tích cực',
  };

  static const _descriptions = <String, String>{
    'move': 'Đi bộ, làm vườn, tự làm việc nhà',
    'purpose': 'Mỗi sáng có một việc mình mong làm',
    'downshift': 'Ngủ trưa, ngồi tĩnh lặng, thắp hương ông bà',
    'eighty': 'Ăn chậm, thấy vừa đủ thì dừng',
    'plant': 'Bữa nào cũng có rau và đậu',
    'tea': 'Uống trà, trò chuyện với bạn lúc chiều',
    'belong': 'Đi chùa, nhà thờ, sinh hoạt hội, câu lạc bộ',
    'family': 'Gọi điện, ăn cơm cùng con cháu',
    'tribe': 'Đi bộ, tập cùng nhóm bạn quen',
  };

  /// Khoá lạ thì rơi về `move` (giống `HabitPalette.of`).
  static IconData iconOf(String key) => _icons[key] ?? _icons['move']!;
  static String nameOf(String key) => _names[key] ?? _names['move']!;
  static String descriptionOf(String key) => _descriptions[key] ?? '';
}

/// Ô icon thói quen (đã cập nhật màu dịu + icon đậm; thiết kế gốc DESIGN.md › `habit-icon-*`; Figma S04 `1:580`, S08 `1:1590`, S16 `1:1934`): nền màu nhấn,
/// icon đậm tương phản, bo mềm theo kích thước. Mặc định 48 × 48 (icon 32); S16 dùng `size: AppSizes.minTarget` (icon 48).
/// Luôn đặt cạnh tên thói quen / tên việc (R-ICON-01); TalkBack đọc tên thói quen.
class HabitBadge extends StatelessWidget {
  const HabitBadge({
    super.key,
    required this.habitKey,
    this.size = AppSizes.habitIcon,
    this.semanticLabel,
    this.icon,
  });

  final String habitKey;
  final double size;

  /// Thay icon thói quen, giữ màu thói quen (S05: ☎ "Gọi người thân" mang màu Gia đình trên hết).
  final IconData? icon;

  /// Mặc định tên thói quen theo vocabulary.md.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = HabitPalette.of(habitKey);
    return Semantics(
      image: true,
      label: semanticLabel ?? HabitStyle.nameOf(habitKey),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(
          icon ?? HabitStyle.iconOf(habitKey),
          size: size * AppSizes.icon / AppSizes.habitIcon,
          color: Theme.of(context).colorScheme.brightness == Brightness.dark
              ? Theme.of(context).colorScheme.onSurface
              : colors.fg,
        ),
      ),
    );
  }
}

/// Thẻ thói quen / hoạt động (Figma S08 `1:1590` hàng thói quen, S05 `1:688` thẻ chọn việc): vạch màu bên trái,
/// ô icon, tên (+ câu mô tả). Cả thẻ bấm được, cao ≥ 72.
/// - [selected] `null` (S08): cuối thẻ có mũi tên › mở chi tiết.
/// - [selected] `true / false` (S05, chọn một): cuối thẻ là dấu chọn, dưới tên có chữ "Đã chọn" / "Chọn"
///   (không chỉ dựa vào màu; S05 Figma đặt chữ dưới dấu chọn – chuyển vào cột chữ để không tràn khi chữ lớn).
class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habitKey,
    this.name,
    this.description,
    this.selected,
    required this.onTap,
    this.icon,
  });

  final String habitKey;

  /// Mặc định tên theo vocabulary.md. S05 truyền tên việc ("Đi bộ nhẹ nhàng").
  final String? name;
  final String? description;
  final bool? selected;
  final VoidCallback? onTap;

  /// Xem [HabitBadge.icon].
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSelected = selected ?? false;
    final title = name ?? HabitStyle.nameOf(habitKey);

    final trailing = selected == null
        ? Icon(AppIcons.chevronRight,
            size: AppSizes.icon, color: scheme.onSurfaceVariant)
        : Icon(
            isSelected ? AppIcons.radioOn : AppIcons.radioOff,
            size: AppSizes.icon,
            color: isSelected ? scheme.primary : scheme.outline,
          );

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: selected != null ? true : null,
      checked: selected,
      label: title,
      hint: description,
      excludeSemantics: true,
      onTap: onTap,
      child: HabitAccentCard(
        habitKey: habitKey,
        selected: isSelected,
        onTap: onTap,
        child: Row(children: [
          HabitBadge(habitKey: habitKey, icon: icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (description != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(description!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
              if (selected != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isSelected ? 'Đã chọn' : 'Chọn',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ]),
          ),
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ]),
      ),
    );
  }
}

/// Khung thẻ trắng, viền nhạt, vạch màu thói quen 6 dp bên trái (DESIGN.md › `card-accent-bar`), cả thẻ bấm được,
/// cao ≥ 72. [selected]: nền `primaryContainer`, viền `primary` 2 dp. Dùng chung cho [HabitTile] và `TaskRow`.
class HabitAccentCard extends StatelessWidget {
  const HabitAccentCard(
      {super.key,
      required this.habitKey,
      required this.child,
      this.onTap,
      this.selected = false});

  final String habitKey;
  final Widget child;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: selected
            ? BorderSide(color: scheme.primary, width: AppSizes.border)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(minHeight: AppSizes.minTarget),
                child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    // Keep the read-aloud control in the card's content row.
                    // The stacked layout reserved a full row above TaskRow,
                    // leaving a conspicuous empty area in schedule previews.
                    child: ReadAloudRegion(inline: true, child: child)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
