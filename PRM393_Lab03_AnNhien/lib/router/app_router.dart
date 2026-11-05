import '../screens/firebase_demo/inbox_screen.dart';
import '../screens/firebase_demo/firebase_demo_screen.dart';
import '../models/app_notification.dart';
import '../models/notification_target.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/account/account_screen.dart';
import '../screens/account/role_screen.dart';
import '../screens/account/session_screen.dart';
import '../screens/onboarding/first_task_screen.dart';
import '../screens/onboarding/notifications_screen.dart';
import '../screens/onboarding/setup_profile_screen.dart';
import '../screens/onboarding/try_reminder_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/settings/data_screen.dart';
import '../screens/settings/help_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../viewmodels/account_view_model.dart';
import '../viewmodels/today_view_model.dart';
import '../services/providers.dart';
import '../screens/sign_in/sign_in_screen.dart';
import '../screens/family/family_screen.dart';
import '../screens/family/relative_form_screen.dart';
import '../screens/suggestion/suggestion_compose_screen.dart';
import '../screens/suggestion/suggestion_review_screen.dart';
import '../viewmodels/suggestion_review_view_model.dart' show SuggestionEntry;
import '../screens/today/today_screen.dart';
import '../viewmodels/session_view_model.dart';
import '../widgets/app_shell.dart';
import '../widgets/dev/widget_gallery.dart';
import '../widgets/feature_placeholder.dart';

/// Route map theo architecture.md mục 7.2 (gốc: flutter-handoff.md Lab 2). Chủ file: A – Sanh.
/// Ai làm màn nào: thay `FeaturePlaceholder` bằng màn thật của mình.
final notificationOpenedProvider = StreamProvider<AppNotification>(
    (ref) => ref.watch(messagingServiceProvider).onOpened);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  String? lastUid;
  String? pendingNotification;
  ref.listen(notificationOpenedProvider, (_, next) {
    next.whenData((item) {
      pendingNotification = notificationTarget(item.route);
    });
    refresh.value++;
  });
  ref.listen(sessionProvider, (_, next) {
    next.whenData((user) {
      if (lastUid != user?.uid) {
        lastUid = user?.uid;
        ref.invalidate(todayViewModelProvider);
        ref.invalidate(roleViewModelProvider);
        ref.invalidate(taskRepositoryProvider);
        ref.invalidate(familyRepositoryProvider);
        ref.invalidate(habitRepositoryProvider);
      }
    });
    refresh.value++;
  }, fireImmediately: true);
  ref.listen(profileProvider, (_, __) => refresh.value++,
      fireImmediately: true);
  ref.listen(signOutViewModelProvider, (_, __) => refresh.value++);
  late final GoRouter router;

  FeaturePlaceholder ph(String code, String title, String owner,
          {bool back = true}) =>
      FeaturePlaceholder(
          code: code,
          title: title,
          owner: owner,
          showBack: back,
          onAccount: () => router.push('/account'));

  router = GoRouter(
    initialLocation: '/today',
    refreshListenable: refresh,
    // TẠM TẮT chặn đăng nhập Google để build / test UI trước.
    // Bỏ comment khối dưới trước khi commit / nộp.
    // redirect: (context, state) {
    //   final signedIn = session.value != null;
    //   final atSignIn = state.matchedLocation == '/sign-in';
    //   if (!signedIn) return atSignIn ? null : '/sign-in';
    //   if (atSignIn) return '/today';
    //   return null;
    // },
    routes: [
      // F1 Tài khoản + vai trò – Hiếu
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/session', builder: (_, __) => const SessionScreen()),
      GoRoute(path: '/role', builder: (_, __) => const RoleScreen()),
      GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
      // F2 Onboarding – Hương
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/setup', builder: (_, __) => const SetupProfileScreen()),
      GoRoute(path: '/setup/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/setup/try-reminder', builder: (_, __) => const TryReminderScreen()),
      GoRoute(path: '/setup/first-task', builder: (_, __) => const FirstTaskScreen()),
      // F4 Thêm, sửa, xoá việc – Khang (màn con N11–N13, trả kết quả bằng pop(result))
      GoRoute(path: '/task/date', builder: (_, __) => ph('N11 · F4', 'Chọn ngày', 'Khang')),
      GoRoute(path: '/task/repeat', builder: (_, __) => ph('N12 · F4', 'Lặp lại', 'Khang')),
      GoRoute(path: '/task/scope', builder: (_, __) => ph('N13 · F4', 'Phạm vi thay đổi', 'Khang')),
      // F6 Lời nhắc – Khang
      GoRoute(path: '/reminder/:taskId', builder: (_, __) => ph('S14 · F6', 'Lời nhắc đến giờ', 'Khang')),
      GoRoute(path: '/settings/reminders', builder: (_, __) => ph('N07 · F6', 'Cài đặt nhắc việc', 'Khang')),
      // F8 Cài đặt & hồ sơ – Sanh (khu demo Firebase F10 – Hiếu)
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/settings/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/settings/firebase-demo', builder: (_, __) => const FirebaseDemoScreen()),
      GoRoute(path: '/settings/help', builder: (_, __) => const HelpScreen()),
      GoRoute(path: '/settings/data', builder: (_, __) => const DataScreen()),
      // F10 Firebase – Hiếu
      GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen()),
      // Chế độ Con cháu: mọi route /caregiver/* nằm ngoài shell của Bác.
      // F13 Ghép nối – Hiếu
      GoRoute(path: '/caregiver/pair', builder: (_, __) => ph('C02 · F13', 'Nhập mã ghép nối', 'Hiếu')),
      // F14 Con cháu lập lịch – Hiếu
      GoRoute(
        path: '/caregiver/schedule',
        builder: (_, state) => switch (state.uri.queryParameters['view']) {
          'week' => ph('C04 · F14', 'Lịch của mẹ · Tuần', 'Hiếu', back: false),
          'month' => ph('C05 · F14', 'Lịch của mẹ · Tháng', 'Hiếu', back: false),
          _ => ph('C03 · F14', 'Lịch của mẹ · Ngày', 'Hiếu', back: false),
        },
      ),
      GoRoute(
        path: '/caregiver/task/new',
        builder: (_, __) => ph('C06 · F14', 'Tạo việc gợi ý (Bước 1/3)', 'Hiếu'),
        routes: [
          GoRoute(path: 'repeat', builder: (_, __) => ph('C07 · F14', 'Lặp lại việc gợi ý (Bước 2/3)', 'Hiếu')),
          GoRoute(path: 'review', builder: (_, __) => ph('C08 · F14', 'Xem lại và gửi gợi ý (Bước 3/3)', 'Hiếu')),
        ],
      ),
      GoRoute(path: '/caregiver/task/sent', builder: (_, __) => ph('C09 · F14', 'Đã gửi cho mẹ', 'Hiếu')),
      GoRoute(path: '/caregiver/task/:id', builder: (_, __) => ph('C10 · F14', 'Chi tiết việc lặp lại', 'Hiếu')),
      // F12 Gợi ý lịch (phía Con cháu) – Sanh
      GoRoute(path: '/caregiver/suggest', builder: (_, __) => const SuggestionComposeScreen()),
      // F0 Trang xem thử widget – chỉ có ở bản debug (cần đăng nhập như mọi route khác).
      if (kDebugMode) GoRoute(path: '/dev/widgets', builder: (_, __) => const WidgetGallery(animate: false)),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            // F3 Hôm nay – Khang
            GoRoute(path: '/today', builder: (_, __) => const TodayScreen(), routes: [
              GoRoute(path: 'task/:id', builder: (_, __) => ph('S04 · F3', 'Chi tiết hoạt động', 'Khang')),
              // F4 Thêm, sửa, xoá việc – Khang (add/result mở bằng go, thay thế, không chồng)
              GoRoute(path: 'task/:id/edit', builder: (_, __) => ph('S15 · F4', 'Sửa việc', 'Khang')),
              GoRoute(path: 'add', builder: (_, __) => ph('S05 · F4', 'Thêm việc – chọn hoạt động', 'Khang')),
              GoRoute(path: 'add/time', builder: (_, __) => ph('S06 · F4', 'Thêm việc – thiết lập', 'Khang')),
              GoRoute(path: 'add/result', builder: (_, __) => ph('ST-Saved · F4', 'Đã lưu xong', 'Khang')),
              // F5 Giọng nói – Khang
              GoRoute(path: 'voice', builder: (_, __) => ph('V01 · F5', 'Nói để thêm việc', 'Khang')),
              // F7 Lịch tuần – Hương
              GoRoute(path: 'all', builder: (_, __) => ph('S11 · F7', 'Chi tiết ngày – hôm nay', 'Hương')),
              // F12 Gợi ý lịch (phía Bác) – Sanh
              GoRoute(
                  path: 'suggestions/:id',
                  builder: (_, state) => SuggestionReviewScreen(
                      id: state.pathParameters['id']!,
                      entry: SuggestionEntry.fromQuery(state.uri.queryParameters['from']))),
            ]),
          ]),
          StatefulShellBranch(routes: [
            // F7 Lịch tuần – Hương
            GoRoute(path: '/week', builder: (_, __) => ph('S07 · F7', 'Lịch tuần', 'Hương', back: false), routes: [
              GoRoute(path: ':date', builder: (_, __) => ph('S11 · F7', 'Chi tiết ngày', 'Hương'), routes: [
                // F3 Chi tiết hoạt động (mở từ lịch tuần) – Khang
                GoRoute(path: 'task/:id', builder: (_, __) => ph('S04 · F3', 'Chi tiết hoạt động', 'Khang')),
              ]),
            ]),
          ]),
          StatefulShellBranch(routes: [
            // F9 9 thói quen – Hương
            GoRoute(path: '/habits', builder: (_, __) => ph('S08 · F9', '9 thói quen', 'Hương', back: false), routes: [
              GoRoute(path: ':key', builder: (_, __) => ph('S16 · F9', 'Chi tiết thói quen', 'Hương')),
            ]),
          ]),
          StatefulShellBranch(routes: [
            // F11 Gia đình – Hương
            GoRoute(path: '/family', builder: (_, __) => const FamilyScreen(), routes: [
              GoRoute(path: 'add', builder: (_, __) => const RelativeFormScreen()),
              GoRoute(path: ':personId/edit', builder: (_, __) => ph('N09 · F11', 'Sửa người thân', 'Hương')),
              GoRoute(path: ':personId/share', builder: (_, __) => ph('S17 · F11', 'Nhắn tin cho người thân', 'Hương')),
            ]),
          ]),
        ],
      ),
    ],
    debugLogDiagnostics: kDebugMode,
  );
  ref.onDispose(router.dispose);
  return router;
});
