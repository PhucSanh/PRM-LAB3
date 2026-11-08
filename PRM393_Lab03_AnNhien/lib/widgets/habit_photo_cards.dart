import 'package:flutter/material.dart';

import '../models/habit_guide.dart';
import '../theme/app_spacing.dart';
import 'habit_widgets.dart';

/// Ảnh thói quen bo góc; chưa có ảnh thì nền nhạt + icon của thói quen.
class _HabitPhoto extends StatelessWidget {
  const _HabitPhoto({required this.habitKey});
  final String habitKey;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final photo = habitPhotosOf(habitKey).firstOrNull;
    final fallback = ColoredBox(
        color: colors.secondaryContainer,
        child: Center(
            child: Icon(HabitStyle.iconOf(habitKey),
                size: AppSizes.habitIcon, color: colors.primary)));
    if (photo == null) return fallback;
    return Image.asset(photo,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => fallback);
  }
}

/// Thẻ lớn đầu tab Khám phá: ảnh thật của thói quen, lớp tối mờ dưới đáy để
/// chữ trắng dễ đọc, nút "Xem" dạng viên thuốc.
class HabitPhotoFeature extends StatelessWidget {
  const HabitPhotoFeature(
      {super.key,
      required this.habitKey,
      required this.eyebrow,
      required this.title,
      required this.onTap,
      this.subtitle});
  final String habitKey, eyebrow, title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final onPhoto = colors.surface;
    return Semantics(
      button: true,
      label: '$title. ${subtitle ?? ''}',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: AppRadius.cardAll,
        child: Material(
          color: colors.primary,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 232),
              child: Stack(children: [
                Positioned.fill(child: _HabitPhoto(habitKey: habitKey)),
                // Lớp tối từ giữa xuống đáy: chữ luôn đủ tương phản trên ảnh.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, .35, 1],
                        colors: [
                          colors.primary.withValues(alpha: .05),
                          colors.primary.withValues(alpha: .25),
                          colors.primary.withValues(alpha: .92),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Chip(text: eyebrow),
                        const SizedBox(height: 88),
                        Text(title,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(color: onPhoto)),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: onPhoto.withValues(alpha: .92))),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Flexible(
                            child: Text('Xem cách bắt đầu',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(color: onPhoto)),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(Icons.arrow_forward_rounded,
                              color: onPhoto, size: AppSizes.icon),
                        ]),
                      ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Text(text,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: colors.primary, letterSpacing: .5)),
      ),
    );
  }
}

/// Ô thói quen trong lưới: ảnh bo góc, tên thói quen bên dưới.
class HabitPhotoTile extends StatelessWidget {
  const HabitPhotoTile(
      {super.key,
      required this.habitKey,
      required this.title,
      required this.onTap});
  final String habitKey, title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: AppRadius.cardAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AspectRatio(
                aspectRatio: 4 / 3, child: _HabitPhoto(habitKey: habitKey)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.base),
              child: Row(children: [
                Icon(HabitStyle.iconOf(habitKey),
                    size: AppSizes.icon, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
