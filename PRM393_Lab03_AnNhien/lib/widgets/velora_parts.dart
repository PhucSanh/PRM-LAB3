import 'package:flutter/material.dart';
import 'botanical_scene.dart';

/// Reference home feature: pine canvas, ivory copy, circular landscape at right.
class VeloraFeaturedCard extends StatelessWidget {
  const VeloraFeaturedCard(
      {super.key,
      required this.eyebrow,
      required this.title,
      required this.label,
      required this.onPressed,
      this.metadata});
  final String eyebrow, title, label;
  final String? metadata;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, box) {
      final large = MediaQuery.textScalerOf(context).scale(20) > 28;
      final copy =
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: colors.onPrimary, letterSpacing: 1)),
        const SizedBox(height: 12),
        Text(title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: colors.onPrimary)),
        if (metadata != null) ...[
          const SizedBox(height: 8),
          Text(metadata!,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: colors.onPrimary)),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            style: FilledButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.primary,
                minimumSize: const Size(100, 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            label: Text(label)),
      ]);
      return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ColoredBox(
              color: colors.primary,
              child: Stack(children: [
                if (!large)
                  Positioned(
                      right: -24,
                      bottom: -32,
                      width: box.maxWidth * .56,
                      child: const BotanicalScene(
                          height: 210, round: true, branch: false)),
                Padding(
                    padding: const EdgeInsets.all(20),
                    child: large
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                const BotanicalScene(
                                    height: 140, round: true, branch: false),
                                const SizedBox(height: 16),
                                copy
                              ])
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Expanded(flex: 3, child: copy),
                                const Spacer(flex: 2)
                              ])),
              ])));
    });
  }
}

/// Continuous landscape behind an ivory sheet. Content remains fully scrollable.
class VeloraDetailBody extends StatelessWidget {
  const VeloraDetailBody(
      {super.key, required this.children, this.onBack, this.footer, this.hero});
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? footer;

  /// Thay phần minh hoạ đầu trang (tự vẽ nút Quay lại nếu cần).
  final Widget? hero;
  @override
  Widget build(BuildContext context) {
    final list = ListView(padding: EdgeInsets.zero, children: [
      if (hero != null)
        hero!
      else
        Stack(children: [
          const BotanicalScene(height: 290, branch: false, edgeToEdge: true),
          if (onBack != null)
            Positioned(
                top: 12,
                left: 16,
                child: IconButton.filledTonal(
                    tooltip: 'Quay lại',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded))),
        ]),
      Transform.translate(
          offset: const Offset(0, -28),
          child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28))),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children))),
    ]);
    return footer == null
        ? list
        : Column(children: [
            Expanded(child: list),
            Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: footer!),
          ]);
  }
}

class VeloraCategoryTile extends StatelessWidget {
  const VeloraCategoryTile(
      {super.key,
      required this.label,
      required this.icon,
      required this.tint,
      required this.onTap});
  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 136),
      child: Material(
          color: tint,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: .08),
                                shape: BoxShape.circle),
                            child: Icon(icon,
                                color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 12),
                        Text(label,
                            style: Theme.of(context).textTheme.titleSmall),
                      ])))));
}
