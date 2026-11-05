import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Thẻ người thân ở Gia đình (Figma S09 `1:2009`, S09b `26:26`, N21 `52:48`).
/// F11 bước 02 đề xuất, F0 – Sanh duyệt.
///
/// Đầu thẻ: avatar **chữ cái đầu** trong ô tròn 48 nền `primaryContainer`, tên (`titleMedium`), quan hệ.
/// [onOpen] (tuỳ chọn) làm cả đầu thẻ chạm được (cao ≥ 72) – mở N09 Sửa người thân (DT-34).
/// Dưới: 2 nút viền "Gọi điện" / "Nhắn tin" **nằm ngang** khi đủ chỗ, chữ lớn không vừa thì **xếp dọc**
/// (không cắt chữ). [highlighted] = viền `primary` 2 dp cho người vừa thêm (S09b).
class RelativeCard extends StatelessWidget {
  const RelativeCard({
    super.key,
    required this.name,
    required this.relation,
    required this.onCall,
    required this.onMessage,
    this.onOpen,
    this.openHint,
    this.highlighted = false,
    this.callLabel = 'Gọi điện',
    this.messageLabel = 'Nhắn tin',
  });

  final String name;
  final String relation;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onOpen;

  /// Câu TalkBack đọc cho đầu thẻ, vd. "Sửa thông tin Mai".
  final String? openHint;
  final bool highlighted;
  final String callLabel;
  final String messageLabel;

  /// Chữ cái đầu của **tên gọi** – từ cuối cùng, như Figma S12 `1:2146` ("Mai" → "M", "Cô Tám" → "T",
  /// "Chị Hoa" → "H").
  static String initial(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.isEmpty ? '?' : words.last.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final header = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
      child: Row(children: [
        ExcludeSemantics(
          child: Container(
            width: AppSizes.habitIcon,
            height: AppSizes.habitIcon,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: scheme.primaryContainer, shape: BoxShape.circle),
            child: Text(
              initial(name),
              style:
                  theme.textTheme.titleMedium?.copyWith(color: scheme.primary),
              textScaler: TextScaler
                  .noScaling, // chữ trong ô cố định 48 – tên đầy đủ ở bên cạnh vẫn phóng to
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: theme.textTheme.titleMedium),
            Text(relation,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ]),
        ),
      ]),
    );

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: highlighted
            ? BorderSide(color: scheme.primary, width: AppSizes.border)
            : BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (onOpen == null)
            Semantics(container: true, child: header)
          else
            Semantics(
              button: true,
              label: '$name, $relation',
              hint: openHint,
              excludeSemantics: true,
              onTap: onOpen,
              child: InkWell(
                  onTap: onOpen, borderRadius: AppRadius.mdAll, child: header),
            ),
          const SizedBox(height: AppSpacing.base),
          _Actions(
            name: name,
            callLabel: callLabel,
            messageLabel: messageLabel,
            onCall: onCall,
            onMessage: onMessage,
          ),
        ]),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.name,
    required this.callLabel,
    required this.messageLabel,
    required this.onCall,
    required this.onMessage,
  });

  final String name;
  final String callLabel;
  final String messageLabel;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  /// Chữ nút thẻ: 20 đậm (Figma S09 `136:15`), nhỏ hơn nút chính 22 để 2 nút vừa một hàng ở 360 dp.
  static TextStyle? _labelStyle(ThemeData theme) =>
      theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _labelStyle(theme);
    final scaler = MediaQuery.textScalerOf(context);

    double needed(String label) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width +
          AppSizes.icon +
          AppSpacing.xs +
          2 *
              AppSpacing
                  .xs; // lề trong 4 + 4; viền vẽ đè lên mép, không chiếm chỗ
    }

    final call = _CardButton(
      label: callLabel,
      semanticLabel: '$callLabel cho $name',
      icon: AppIcons.phone,
      style: style,
      onPressed: onCall,
    );
    final message = _CardButton(
      label: messageLabel,
      semanticLabel: '$messageLabel cho $name',
      icon: AppIcons.message,
      style: style,
      onPressed: onMessage,
    );

    return LayoutBuilder(builder: (context, constraints) {
      final half = (constraints.maxWidth - AppSpacing.betweenTargets) / 2;
      final fits = needed(callLabel) <= half && needed(messageLabel) <= half;
      if (fits) {
        return Row(children: [
          Expanded(child: call),
          const SizedBox(width: AppSpacing.betweenTargets),
          Expanded(child: message),
        ]);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        call,
        const SizedBox(height: AppSpacing.betweenTargets),
        message,
      ]);
    });
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.style,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;
  final TextStyle? style;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          textStyle: style,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.icon),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ]),
      ),
    );
  }
}
