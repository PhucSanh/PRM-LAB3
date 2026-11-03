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
              ('Hôm nay', '/today', Icons.today),
              ('Chọn vai trò', '/role', Icons.people),
              ('Onboarding của Bác', '/welcome', Icons.waving_hand),
              ('Mã ghép nối của Bác', '/pairing/code', Icons.phonelink_setup),
              ('Nhập mã từ máy mẹ', '/caregiver/pair', Icons.phonelink),
              ('Lịch của mẹ', '/caregiver/schedule', Icons.calendar_month),
              ('Tài khoản', '/account', Icons.account_circle),
              (
                'Nhận lịch gợi ý',
                '/settings/firebase-demo/suggestions',
                Icons.inbox
              ),
              ('Khu thử Firebase', '/settings/firebase-demo', Icons.science),
            ])
              AppButton(
                  label: item.$1,
                  icon: item.$3,
                  kind: AppButtonKind.secondary,
                  wrapLabel: true,
                  onPressed: () => context.push(item.$2)),
          ]);
}
