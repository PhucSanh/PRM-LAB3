import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/caregiver_parts.dart';
import '../../widgets/app_button.dart';

class DemoHubScreen extends StatelessWidget {
  const DemoHubScreen({super.key});
  @override
  Widget build(BuildContext context) => CaregiverPage(
          title: 'Xem thử An Nhiên',
          onBack: () => context.go('/today'),
          children: [
            const Text(
                'Bản demo dùng dữ liệu mẫu trên máy. Thay đổi tại đây không gửi cho người dùng thật.'),
            for (final item in const <(String, String, IconData)>[
              ('Hôm nay', '/today', Icons.today_rounded),
              ('Chọn vai trò', '/role', Icons.people_rounded),
              ('Onboarding của Bác', '/welcome', Icons.waving_hand_rounded),
              (
                'Mã ghép nối của Bác',
                '/pairing/code',
                Icons.phonelink_setup_rounded
              ),
              ('Nhập mã từ máy mẹ', '/caregiver/pair', Icons.phonelink_rounded),
              (
                'Lịch của mẹ',
                '/caregiver/schedule',
                Icons.calendar_month_rounded
              ),
              ('Tài khoản', '/account', Icons.account_circle_rounded),
              (
                'Nhận lịch gợi ý',
                '/settings/firebase-demo/suggestions',
                Icons.inbox_rounded
              ),
              (
                'Khu thử Firebase',
                '/settings/firebase-demo',
                Icons.science_rounded
              ),
            ])
              AppButton(
                  label: item.$1,
                  icon: item.$3,
                  kind: AppButtonKind.secondary,
                  wrapLabel: true,
                  onPressed: () => context.push(item.$2)),
          ]);
}
