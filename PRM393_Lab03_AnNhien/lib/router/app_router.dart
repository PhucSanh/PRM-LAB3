import '../services/local_reminder_service.dart';
import '../viewmodels/caregiver_schedule_view_model.dart';
import '../screens/firebase_demo/suggestion_demo_screen.dart';
import '../screens/caregiver/pairing_screen.dart';
import '../screens/caregiver/caregiver_schedule_screen.dart';
import '../screens/caregiver/caregiver_form_screen.dart';
import '../screens/caregiver/caregiver_detail_screen.dart';
import '../screens/caregiver/demo_hub_screen.dart';
import '../models/user_profile.dart';
import '../screens/firebase_demo/profile_demo_entry_screen.dart';
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
import '../viewmodels/account_view_model.dart';
import '../viewmodels/today_view_model.dart';
import '../services/providers.dart';
import '../screens/sign_in/sign_in_screen.dart';
import '../screens/today/today_screen.dart';
import '../viewmodels/session_view_model.dart';
import '../widgets/app_shell.dart';
import '../widgets/dev/widget_gallery.dart';
import '../widgets/feature_placeholder.dart';

/// Route map theo architecture.md mục 7.2 (gốc: flutter-handoff.md Lab 2). Chủ file: A – Sanh.
/// Ai làm màn nào: thay `FeaturePlaceholder` bằng màn thật của mình.
final notificationOpenedProvider = StreamProvider<AppNotification>(
    (ref) => ref.watch(messagingServiceProvider).onOpened);

/// Demo mặc định mở tự do. Chỉ bật chủ động bằng --dart-define=AUTH_GUARD=true.
final authGuardEnabledProvider = Provider<bool>(
    (ref) => const bool.fromEnvironment('AUTH_GUARD', defaultValue: false));

final initialRouteProvider = Provider<String>((ref) =>
    const String.fromEnvironment('INITIAL_ROUTE', defaultValue: '/today'));

final localReminderOpenedProvider = StreamProvider<AppNotification>((ref) {
  if (!ref.watch(nativeReminderEventsEnabledProvider)) {
    return const Stream.empty();
  }
  final service = ref.watch(reminderServiceProvider);
  return service is LocalReminderService
      ? service.onOpened
      : const Stream.empty();
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  String? lastUid;
  String? pendingNotification;
  ref.listen(localReminderOpenedProvider, (_, next) {
    next.whenData((item) {
      pendingNotification = notificationTarget(item.route);
    });
    refresh.value++;
  });
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
  if (ref.watch(authGuardEnabledProvider)) {
    ref.listen(profileProvider, (_, __) => refresh.value++,
        fireImmediately: true);
  }
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
    initialLocation: ref.read(initialRouteProvider),
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      // Giữ guard TẮT trong bản demo theo yêu cầu 03/11.
      if (ref.read(authGuardEnabledProvider)) {
        final session = ref.read(sessionProvider);
        final profile = ref.read(profileProvider);
        if (ref.read(signOutViewModelProvider).busy || session.isLoading) {
          return path == '/session' ? null : '/session';
        }
        if (session.value == null) {
          return path == '/sign-in' ? null : '/sign-in';
        }
        if (path == '/account') return null;
        if (profile.isLoading || profile.hasError || profile.value == null) {
          return path == '/session' ? null : '/session';
        }
        final user = profile.value!;
        if (user.role == null) return path == '/role' ? null : '/role';
        if (user.role == UserRole.elder && !user.onboarded) {
          if (path == '/welcome' || path.startsWith('/setup')) return null;
          return '/welcome';
        }
        if (user.role == UserRole.caregiver && user.pairedMomUid == null) {
          return path == '/caregiver/pair' ? null : '/caregiver/pair';
        }
        if (['/sign-in', '/session', '/role', '/welcome'].contains(path) ||
            path.startsWith('/setup')) {
          return user.role == UserRole.caregiver
              ? '/caregiver/schedule'
              : '/today';
        }
      }
      final target = pendingNotification;
      if (target != null) {
        pendingNotification = null;
        return target == path ? null : target;
      }
      return null;
    },
    routes: [
      // F1 Tài khoản + vai trò – Hiếu
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/session', builder: (_, __) => const SessionScreen()),
      GoRoute(path: '/role', builder: (_, __) => const RoleScreen()),
      GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
      // F2 Onboarding – Hương
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/setup', builder: (_, __) => const SetupProfileScreen()),
      GoRoute(
          path: '/setup/notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(
          path: '/setup/try-reminder',
          builder: (_, __) => const TryReminderScreen()),
      GoRoute(
          path: '/setup/first-task',
          builder: (_, __) => const FirstTaskScreen()),
      // F4 Thêm, sửa, xoá việc – Khang (màn con N11–N13, trả kết quả bằng pop(result))
      GoRoute(
          path: '/task/date',
          builder: (_, __) => ph('N11 · F4', 'Chọn ngày', 'Khang')),
      GoRoute(
          path: '/task/repeat',
          builder: (_, __) => ph('N12 · F4', 'Lặp lại', 'Khang')),
      GoRoute(
          path: '/task/scope',
          builder: (_, __) => ph('N13 · F4', 'Phạm vi thay đổi', 'Khang')),
      // F6 Lời nhắc – Khang
      GoRoute(
          path: '/reminder/:taskId',
          builder: (_, __) => ph('S14 · F6', 'Lời nhắc đến giờ', 'Khang')),
      GoRoute(
          path: '/settings/reminders',
          builder: (_, __) => ph('N07 · F6', 'Cài đặt nhắc việc', 'Khang')),
      // F8 Cài đặt & hồ sơ – Sanh (khu demo Firebase F10 – Hiếu)
      GoRoute(
          path: '/settings',
          builder: (_, __) => ph('S10 · F8', 'Cài đặt hiển thị', 'Sanh')),
      GoRoute(
          path: '/settings/profile',
          builder: (_, __) => const ProfileDemoEntryScreen()),
      GoRoute(
          path: '/settings/firebase-demo',
          builder: (_, __) => const FirebaseDemoScreen()),
      GoRoute(
          path: '/settings/help',
          builder: (_, __) => ph('N08 · F8', 'Cách dùng đơn giản', 'Sanh')),
      GoRoute(
          path: '/settings/data',
          builder: (_, __) =>
              ph('N20 · F8', 'Dữ liệu trên điện thoại', 'Sanh')),
      // F10 Firebase – Hiếu
      GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen()),
      // Chế độ Con cháu: mọi route /caregiver/* nằm ngoài shell của Bác.
      // F13/F14 – Hiếu. Guard demo vẫn mặc định tắt.
      GoRoute(
          path: '/settings/firebase-demo/suggestions',
          builder: (_, __) => const SuggestionDemoScreen()),
      GoRoute(path: '/demo', builder: (_, __) => const DemoHubScreen()),
      GoRoute(
          path: '/pairing/code',
          builder: (_, __) => const PairingScreen(showCode: true)),
      GoRoute(
          path: '/caregiver/pair', builder: (_, __) => const PairingScreen()),
      GoRoute(
          path: '/caregiver/schedule',
          builder: (_, state) => CaregiverScheduleScreen(
                  view: switch (state.uri.queryParameters['view']) {
                'week' => CalendarView.week,
                'month' => CalendarView.month,
                _ => CalendarView.day
              })),
      GoRoute(
          path: '/caregiver/task/new',
          builder: (_, __) => const CaregiverFormScreen(),
          routes: [
            GoRoute(
                path: 'repeat',
                builder: (_, __) => const CaregiverFormScreen(step: 2)),
            GoRoute(
                path: 'review',
                builder: (_, __) => const CaregiverFormScreen(step: 3)),
          ]),
      GoRoute(
          path: '/caregiver/task/sent',
          builder: (_, __) => const CaregiverSentScreen()),
      GoRoute(
          path: '/caregiver/task/:id',
          builder: (_, state) => CaregiverDetailScreen(
              id: state.pathParameters['id']!,
              day: state.uri.queryParameters['date'] ??
                  DateTime.now().toIso8601String().substring(0, 10))),
      // F12 Gợi ý lịch (phía Con cháu) – Sanh
      GoRoute(
          path: '/caregiver/suggest',
          builder: (_, __) =>
              ph('G01 · F12', 'Con cháu soạn lịch gợi ý', 'Sanh')),
      // F0 Trang xem thử widget – chỉ có ở bản debug (cần đăng nhập như mọi route khác).
      if (kDebugMode)
        GoRoute(
            path: '/dev/widgets',
            builder: (_, __) => const WidgetGallery(animate: false)),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            // F3 Hôm nay – Khang
            GoRoute(
                path: '/today',
                builder: (_, __) => const TodayScreen(),
                routes: [
                  GoRoute(
                      path: 'task/:id',
                      builder: (_, __) =>
                          ph('S04 · F3', 'Chi tiết hoạt động', 'Khang')),
                  // F4 Thêm, sửa, xoá việc – Khang (add/result mở bằng go, thay thế, không chồng)
                  GoRoute(
                      path: 'task/:id/edit',
                      builder: (_, __) => ph('S15 · F4', 'Sửa việc', 'Khang')),
                  GoRoute(
                      path: 'add',
                      builder: (_, __) => ph(
                          'S05 · F4', 'Thêm việc – chọn hoạt động', 'Khang')),
                  GoRoute(
                      path: 'add/time',
                      builder: (_, __) =>
                          ph('S06 · F4', 'Thêm việc – thiết lập', 'Khang')),
                  GoRoute(
                      path: 'add/result',
                      builder: (_, __) =>
                          ph('ST-Saved · F4', 'Đã lưu xong', 'Khang')),
                  // F5 Giọng nói – Khang
                  GoRoute(
                      path: 'voice',
                      builder: (_, __) =>
                          ph('V01 · F5', 'Nói để thêm việc', 'Khang')),
                  // F7 Lịch tuần – Hương
                  GoRoute(
                      path: 'all',
                      builder: (_, __) =>
                          ph('S11 · F7', 'Chi tiết ngày – hôm nay', 'Hương')),
                  // F12 Gợi ý lịch (phía Bác) – Sanh
                  GoRoute(
                      path: 'suggestions/:id',
                      builder: (_, __) =>
                          ph('G03 · F12', 'Lịch Mai gợi ý', 'Sanh')),
                ]),
          ]),
          StatefulShellBranch(routes: [
            // F7 Lịch tuần – Hương
            GoRoute(
                path: '/week',
                builder: (_, __) =>
                    ph('S07 · F7', 'Lịch tuần', 'Hương', back: false),
                routes: [
                  GoRoute(
                      path: ':date',
                      builder: (_, __) =>
                          ph('S11 · F7', 'Chi tiết ngày', 'Hương'),
                      routes: [
                        // F3 Chi tiết hoạt động (mở từ lịch tuần) – Khang
                        GoRoute(
                            path: 'task/:id',
                            builder: (_, __) =>
                                ph('S04 · F3', 'Chi tiết hoạt động', 'Khang')),
                      ]),
                ]),
          ]),
          StatefulShellBranch(routes: [
            // F9 9 thói quen – Hương
            GoRoute(
                path: '/habits',
                builder: (_, __) =>
                    ph('S08 · F9', '9 thói quen', 'Hương', back: false),
                routes: [
                  GoRoute(
                      path: ':key',
                      builder: (_, __) =>
                          ph('S16 · F9', 'Chi tiết thói quen', 'Hương')),
                ]),
          ]),
          StatefulShellBranch(routes: [
            // F11 Gia đình – Hương
            GoRoute(
                path: '/family',
                builder: (_, __) =>
                    ph('S09 · F11', 'Gia đình', 'Hương', back: false),
                routes: [
                  GoRoute(
                      path: 'add',
                      builder: (_, __) =>
                          ph('S12 · F11', 'Thêm người thân', 'Hương')),
                  GoRoute(
                      path: ':personId/edit',
                      builder: (_, __) =>
                          ph('N09 · F11', 'Sửa người thân', 'Hương')),
                  GoRoute(
                      path: ':personId/share',
                      builder: (_, __) =>
                          ph('S17 · F11', 'Nhắn tin cho người thân', 'Hương')),
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
