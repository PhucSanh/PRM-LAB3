import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG gốc từ Figma; giữ kích thước root (32px hoặc 24px) của từng asset.
class CaregiverDesignIcon extends StatelessWidget {
  const CaregiverDesignIcon(this.asset, {super.key});
  final String asset;
  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/caregiver/$asset');
}
