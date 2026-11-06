import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// A small, calm sprout companion, drawn with the app's semantic palette.
class AssistantMascot extends StatelessWidget {
  const AssistantMascot({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
        child: SizedBox.square(
      dimension: AppSizes.stateIcon,
      child: CustomPaint(
          painter: _SproutPainter(
              ink: colors.primary,
              face: colors.surface,
              leaf: colors.onPrimaryContainer,
              soft: colors.primaryContainer)),
    ));
  }
}

class _SproutPainter extends CustomPainter {
  const _SproutPainter(
      {required this.ink,
      required this.face,
      required this.leaf,
      required this.soft});
  final Color ink, face, leaf, soft;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height);
    canvas.save();
    canvas.translate((size.width - unit) / 2, (size.height - unit) / 2);
    canvas.scale(unit);
    final outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = .025
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Two rounded leaves and a gently bending stem.
    final left = Path()
      ..moveTo(.50, .33)
      ..cubicTo(.29, .35, .19, .20, .19, .11)
      ..cubicTo(.38, .08, .52, .17, .50, .33)
      ..close();
    final right = Path()
      ..moveTo(.49, .27)
      ..cubicTo(.48, .10, .65, .05, .81, .09)
      ..cubicTo(.78, .25, .63, .34, .49, .27)
      ..close();
    canvas.drawPath(left, Paint()..color = leaf.withValues(alpha: .72));
    canvas.drawPath(right, Paint()..color = ink);
    canvas.drawPath(
        Path()
          ..moveTo(.50, .45)
          ..quadraticBezierTo(.47, .30, .57, .20),
        outline);

    // An ivory seed face, with relaxed eyes and a quiet smile.
    const head = Rect.fromLTWH(.18, .36, .64, .54);
    canvas.drawOval(head, Paint()..color = face);
    canvas.drawOval(head, outline);
    canvas.drawOval(
        const Rect.fromLTWH(.25, .64, .12, .065), Paint()..color = soft);
    canvas.drawOval(
        const Rect.fromLTWH(.63, .64, .12, .065), Paint()..color = soft);
    canvas.drawPath(
        Path()
          ..moveTo(.33, .59)
          ..quadraticBezierTo(.37, .55, .41, .59),
        outline);
    canvas.drawPath(
        Path()
          ..moveTo(.59, .59)
          ..quadraticBezierTo(.63, .55, .67, .59),
        outline);
    canvas.drawPath(
        Path()
          ..moveTo(.43, .70)
          ..quadraticBezierTo(.50, .77, .57, .70),
        outline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SproutPainter old) =>
      old.ink != ink ||
      old.face != face ||
      old.leaf != leaf ||
      old.soft != soft;
}
