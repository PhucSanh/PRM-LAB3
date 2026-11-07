import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Original vector artwork, drawn locally. Never a copy of the reference asset.
class BotanicalScene extends StatelessWidget {
  const BotanicalScene(
      {super.key,
      this.height = 200,
      this.round = false,
      this.branch = true,
      this.welcome = false,
      this.edgeToEdge = false});
  final double height;
  final bool round, branch, welcome, edgeToEdge;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
              painter: _BotanicalPainter(round, branch, welcome, edgeToEdge))));
}

class _BotanicalPainter extends CustomPainter {
  const _BotanicalPainter(
      this.round, this.branch, this.welcome, this.edgeToEdge);
  final bool round, branch, welcome, edgeToEdge;
  static const fog = Color(0xFFDCE2D7),
      sage = Color(0xFFADBBA9),
      moss = Color(0xFF788D7C),
      pine = Color(0xFF243D32);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final diameter = math.min(w * (welcome ? .78 : 1), h * (welcome ? .88 : 1));
    // Keep the entire circle inside the painted background, including its top.
    final centerY = math.max(h * .47, diameter / 2);
    final circle = Rect.fromCenter(
        center: Offset(w * .5, centerY), width: diameter, height: diameter);
    canvas.save();
    if (round || welcome) {
      canvas.clipPath(Path()..addOval(circle));
    } else if (!edgeToEdge) {
      canvas.clipRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(22)));
    }
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [fog, Color(0xFFC7D0BF), Color(0xFFE8E9DA)])
              .createShader(Offset.zero & size));
    if (!welcome) {
      canvas.drawCircle(Offset(w * .69, h * .35), h * .105,
          Paint()..color = const Color(0xFFF0E8D5));
    }
    final paths = [
      Path()
        ..moveTo(0, h * .61)
        ..cubicTo(w * .2, h * .48, w * .32, h * .83, w * .55, h * .67)
        ..cubicTo(w * .76, h * .52, w * .84, h * .35, w, h * .4),
      Path()
        ..moveTo(0, h * .62)
        ..cubicTo(w * .18, h * .63, w * .4, h * .93, w * .63, h * .75)
        ..cubicTo(w * .8, h * .62, w * .9, h * .54, w, h * .6),
      Path()
        ..moveTo(0, h * .73)
        ..cubicTo(w * .23, h * .68, w * .41, h * 1.02, w * .65, h * .87)
        ..cubicTo(w * .81, h * .76, w * .91, h * .67, w, h * .7),
      Path()
        ..moveTo(0, h * .87)
        ..cubicTo(w * .2, h * .83, w * .4, h * 1.08, w * .64, h * .96)
        ..cubicTo(w * .8, h * .85, w * .9, h * .79, w, h * .8),
    ];
    final fills = [
      sage,
      const Color(0xFF96A68F),
      moss,
      const Color(0xFF526D59)
    ];
    for (var i = 0; i < paths.length; i++) {
      paths[i]
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(paths[i], Paint()..color = fills[i]);
    }
    // Deterministic, very quiet paper grain confined to the artwork.
    final random = math.Random(34);
    for (var i = 0; i < 1200; i++) {
      canvas.drawCircle(
          Offset(random.nextDouble() * w, random.nextDouble() * h),
          .35,
          Paint()..color = Colors.white.withValues(alpha: .09));
    }
    canvas.restore();
    if (welcome) {
      canvas.drawCircle(Offset(w * .88, h * .13), h * .065,
          Paint()..color = const Color(0xFFF0E8D5));
      final wave = Path()
        ..moveTo(0, h * .78)
        ..cubicTo(w * .22, h * .56, w * .34, h * .95, w * .62, h * .78)
        ..cubicTo(w * .79, h * .67, w * .91, h * .63, w, h * .7)
        ..lineTo(w, h * .88)
        ..cubicTo(w * .73, h * .76, w * .42, h * 1.04, 0, h)
        ..close();
      canvas.drawPath(wave, Paint()..color = sage.withValues(alpha: .87));
    }
    if (branch) {
      final stem = Path()
        ..moveTo(w * .4, h * .91)
        ..cubicTo(w * .49, h * .76, w * .61, h * .53, w * .63, h * .26);
      canvas.drawPath(
          stem,
          Paint()
            ..color = pine
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
      const leaves = [
        [.44, .84, .32, .65, .35, .77],
        [.47, .78, .67, .68, .58, .76],
        [.49, .72, .41, .49, .41, .63],
        [.52, .65, .72, .53, .64, .61],
        [.55, .57, .49, .36, .48, .48],
        [.58, .49, .72, .37, .66, .47],
        [.60, .41, .58, .21, .54, .32],
        [.62, .34, .67, .14, .68, .25],
      ];
      for (final (i, p) in leaves.indexed) {
        final base = Offset(w * p[0], h * p[1]),
            tip = Offset(w * p[2], h * p[3]);
        final delta = tip - base;
        final normal = Offset(-delta.dy, delta.dx) / delta.distance;
        final breadth = math.min(w * .027, delta.distance * .18);
        final c1 = base + delta * .3, c2 = base + delta * .72;
        final upper1 = c1 + normal * breadth, upper2 = c2 + normal * breadth;
        final lower1 = c1 - normal * breadth * .55,
            lower2 = c2 - normal * breadth * .65;
        final leaf = Path()
          ..moveTo(base.dx, base.dy)
          ..cubicTo(upper1.dx, upper1.dy, upper2.dx, upper2.dy, tip.dx, tip.dy)
          ..cubicTo(
              lower2.dx, lower2.dy, lower1.dx, lower1.dy, base.dx, base.dy);
        canvas.drawPath(leaf,
            Paint()..color = i.isEven ? pine : Color.lerp(pine, moss, .2)!);
      }
    }
  }

  @override
  bool shouldRepaint(_BotanicalPainter old) =>
      old.round != round ||
      old.branch != branch ||
      old.welcome != welcome ||
      old.edgeToEdge != edgeToEdge;
}
