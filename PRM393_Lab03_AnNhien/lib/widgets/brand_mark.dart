import 'package:flutter/material.dart';
import 'botanical_scene.dart';

/// A quiet, code-native brand tile. Decorative next to the app's written name.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 112});
  final double size;
  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
        dimension: size, child: BotanicalScene(height: size, round: true));
  }
}
