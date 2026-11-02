import 'package:flutter/material.dart';
import 'app_button.dart';

/// Insert at the end of the F8 profile form when that feature is implemented.
class FirebaseDemoEntry extends StatelessWidget {
  const FirebaseDemoEntry({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => AppButton(
      wrapLabel: true,
      label: 'Khu thử tính năng',
      icon: Icons.science_outlined,
      kind: AppButtonKind.secondary,
      onPressed: onOpen);
}
