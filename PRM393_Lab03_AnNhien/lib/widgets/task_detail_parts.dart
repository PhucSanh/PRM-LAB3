import 'package:flutter/material.dart';

import '../models/habit_guide.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'botanical_scene.dart';
import 'habit_widgets.dart';

/// Ảnh minh hoạ đầu màn Chi tiết việc: phong cảnh + ô thói quen lớn.
class TaskHeroArt extends StatelessWidget {
  const TaskHeroArt({super.key, required this.habitKey, this.onBack});
  final String habitKey;
  final VoidCallback? onBack;
  static const double height = 280;

  @override
  Widget build(BuildContext context) {
    final photos = habitPhotosOf(habitKey);
    const fallback =
        BotanicalScene(height: height, branch: false, edgeToEdge: true);
    return Stack(children: [
      if (photos.isEmpty)
        fallback
      else
        ExcludeSemantics(
          child: Image.asset(photos.first,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback),
        ),
      // Lớp mờ dưới cùng để ô thói quen và nút Quay lại luôn rõ trên ảnh.
      Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .15),
                    Colors.transparent,
                    Colors.black.withValues(alpha: .25),
                  ]),
            ),
          ),
        ),
      ),
      Positioned(
        left: AppSpacing.lg,
        bottom: AppSpacing.xxl,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
              boxShadow: const [
                BoxShadow(blurRadius: 16, color: Color(0x22000000))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: HabitBadge(habitKey: habitKey, size: 64),
            ),
          ),
        ),
      ),
      if (onBack != null)
        Positioned(
            top: AppSpacing.md,
            left: AppSpacing.base,
            child: IconButton.filledTonal(
                tooltip: 'Quay lại',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded))),
    ]);
  }
}

/// Dải ảnh minh hoạ cuộn ngang (các ảnh sau ảnh lớn đầu trang).
class HabitPhotoStrip extends StatelessWidget {
  const HabitPhotoStrip({super.key, required this.photos, required this.label});
  final List<String> photos;

  /// Mô tả cho TalkBack, ví dụ "Ảnh minh hoạ Vận động".
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        image: true,
        excludeSemantics: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final photo in photos)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: ClipRRect(
                  borderRadius: AppRadius.cardAll,
                  child: Image.asset(photo,
                      width: 240,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox(width: 240, height: 160)),
                ),
              ),
          ]),
        ),
      );
}

/// Một ô thông tin: icon + nhãn nhỏ + giá trị.
class TaskInfoTile extends StatelessWidget {
  const TaskInfoTile(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: colors.secondaryContainer, borderRadius: AppRadius.cardAll),
        child: Row(children: [
          Icon(icon, color: colors.primary, size: AppSizes.icon + 4),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant)),
              Text(value, style: theme.textTheme.titleMedium),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Lưới ô thông tin: 2 cột khi đủ rộng, 1 cột khi chữ lớn / màn hẹp.
class TaskInfoGrid extends StatelessWidget {
  const TaskInfoGrid({super.key, required this.tiles});
  final List<TaskInfoTile> tiles;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final two = box.maxWidth >= 320 &&
            MediaQuery.textScalerOf(context).scale(20) <= 26;
        final width = two ? (box.maxWidth - AppSpacing.md) / 2 : box.maxWidth;
        return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final tile in tiles) SizedBox(width: width, child: tile)
            ]);
      });
}

IconData _prepareIcon(String key) => switch (key) {
      'shoes' => Icons.directions_walk_rounded,
      'water' => Icons.water_drop_rounded,
      'hat' => Icons.wb_sunny_rounded,
      'phone' => Icons.phone_iphone_rounded,
      'seat' => Icons.chair_rounded,
      'music' => Icons.music_note_rounded,
      'tea' => Icons.emoji_food_beverage_rounded,
      'note' => Icons.edit_note_rounded,
      'people' => Icons.groups_rounded,
      'veg' => Icons.eco_rounded,
      'fruit' => Icons.local_florist_rounded,
      'bowl' => Icons.rice_bowl_rounded,
      'calendar' => Icons.event_rounded,
      'game' => Icons.extension_rounded,
      'time' => Icons.schedule_rounded,
      _ => Icons.spa_rounded,
    };

/// Thẻ hình "Chuẩn bị": mỗi thứ một ô minh hoạ màu dịu, cuộn ngang.
class PrepareGallery extends StatelessWidget {
  const PrepareGallery({super.key, required this.items});
  final List<(String, String)> items;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final tints = AppColors.categoryTints;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final (i, (icon, label)) in items.indexed)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: SizedBox(
              width: 132,
              child: Semantics(
                label: label,
                image: true,
                excludeSemantics: true,
                child: Column(children: [
                  Container(
                    height: 112,
                    width: 132,
                    decoration: BoxDecoration(
                        color: tints[i % tints.length],
                        borderRadius: AppRadius.cardAll),
                    child: Stack(children: [
                      Positioned(
                        right: -12,
                        bottom: -12,
                        child: Icon(_prepareIcon(icon),
                            size: 88,
                            color: colors.primary.withValues(alpha: .08)),
                      ),
                      Center(
                          child: Icon(_prepareIcon(icon),
                              size: 48, color: colors.primary)),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Các bước làm có số thứ tự lớn, dễ nhìn.
class TaskStepList extends StatelessWidget {
  const TaskStepList({super.key, required this.steps});
  final List<String> steps;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final (i, step) in steps.indexed) ...[
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
              radius: 18,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              child: Text('${i + 1}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: colors.onPrimary))),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(step, style: theme.textTheme.bodyLarge)),
        ]),
        const SizedBox(height: AppSpacing.md),
      ],
    ]);
  }
}

/// Ô lưu ý nhẹ nhàng.
class TaskNoteCard extends StatelessWidget {
  const TaskNoteCard({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: const BoxDecoration(
          color: AppColors.warningContainer, borderRadius: AppRadius.cardAll),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, color: colors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
      ]),
    );
  }
}
