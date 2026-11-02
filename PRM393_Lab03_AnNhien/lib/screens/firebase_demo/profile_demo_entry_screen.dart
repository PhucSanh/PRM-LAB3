import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/firebase_demo_entry.dart';

/// F10 entry only. Does not implement or claim completion of F8 profile editing.
class ProfileDemoEntryScreen extends StatelessWidget {
  const ProfileDemoEntryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: const AppBackBar(),
      body: SafeArea(
          child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
            Text('Thông tin của Bác',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.base),
            const Text('Phần sửa hồ sơ đang được hoàn thiện.'),
            const SizedBox(height: AppSpacing.base),
            FirebaseDemoEntry(
                onOpen: () => context.push('/settings/firebase-demo')),
          ])));
}
