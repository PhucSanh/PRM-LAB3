import '../screens/calm/guided_activity_screen.dart';
import '../viewmodels/task_form_view_model.dart';
import '../screens/calm/weekly_report_screen.dart';
import '../screens/voice/voice_input_screen.dart';
import '../screens/settings/reminder_settings_screen.dart';
import '../services/local_reminder_service.dart';
import '../viewmodels/caregiver_schedule_view_model.dart';
import '../screens/firebase_demo/suggestion_demo_screen.dart';
import '../screens/caregiver/pairing_screen.dart';
import '../screens/caregiver/caregiver_schedule_screen.dart';
import '../screens/caregiver/caregiver_form_screen.dart';
import '../screens/caregiver/caregiver_detail_screen.dart';
import '../screens/caregiver/demo_hub_screen.dart';
import '../models/user_profile.dart';
import '../screens/firebase_demo/inbox_screen.dart';
import '../screens/firebase_demo/firebase_demo_screen.dart';
import '../models/app_notification.dart';
import '../models/task_item.dart';
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
import '../screens/suggestion/suggestion_compose_screen.dart';
import '../screens/suggestion/suggestion_review_screen.dart';
import '../viewmodels/suggestion_review_view_model.dart' show SuggestionEntry;
import '../screens/today/today_screen.dart';
import '../screens/today/task_detail_screen.dart';
import '../viewmodels/session_view_model.dart';
import '../widgets/app_shell.dart';
import '../widgets/dev/widget_gallery.dart';
import '../screens/tasks/task_form_screens.dart';
import '../screens/calm/calendar_screen.dart';
import '../screens/calm/activities_screen.dart';
import '../screens/calm/activity_flashcards_screen.dart';
import '../screens/calm/family_screen.dart';

/// Route map theo architecture.md mục 7.2 (gốc: flutter-handoff.md Lab 2). Chủ file: A – Sanh.
/// Ai làm màn nào: thay `FeaturePlaceholder` bằng màn thật của mình.
final notificationOpenedProvider = StreamProvider<AppNotification>(
    (ref) => ref.watch(messagingServiceProvider).onOpened);

/// Đăng nhập bật mặc định. Chỉ tắt tường minh trong fixture / UI preview.
final authGuardEnabledProvider = Provider<bool>(
    (ref) => const bool.fromEnvironment('AUTH_GUARD', defaultValue: true));

final initialRouteProvider = Provider<String>((ref) =>
    const String.fromEnvironment('INITIAL_ROUTE', defaultValue: '/intro'));

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
  AppNotification? pendingNotification;
  ref.listen(localReminderOpenedProvider, (_, next) {
    next.whenData((item) {
      pendingNotification = item;
    });
    refresh.value++;
  });
  ref.listen(notificationOpenedProvider, (_, next) {
    next.whenData((item) {
      pendingNotification = item;
    });
    refresh.value++;
  });
  ref.listen(sessionProvider, (_, next) {
    next.whenData((user) {
      if (lastUid != user?.uid) {
        lastUid = user?.uid;
        ref.invalidate(todayViewModelProvider);
        ref.invalidate(taskFormViewModelProvider);
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

  router = GoRouter(
    initialLocation: ref.read(initialRouteProvider),
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      final role = ref.read(profileProvider).asData?.value?.role;
      if (role == UserRole.caregiver && path == '/calendar') {
        return state.uri.replace(path: '/caregiver/schedule').toString();
      }
      if (role == UserRole.caregiver && path == '/family') {
        return '/caregiver/family';
      }
      // Public introduction is shown once on launch; its CTA uses normal guards.
      if (path == '/intro' && pendingNotification == null) return null;
      // Auth, role và onboarding được kiểm tra trước khi vào dữ liệu ứng dụng.
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
              : '/calendar';
        }
      }
      final pending = pendingNotification;
      if (pending != null) {
        pendingNotification = null;
        final parent = pending.parentUid;
        final target = parent != null &&
                parent.isNotEmpty &&
                ref.read(profileProvider).asData?.value?.pairedMomUid != parent
            ? '/inbox'
            : notificationTarget(pending.route);
        return target == state.uri.toString() ? null : target;
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
      GoRoute(
          path: '/intro',
          builder: (_, __) => const WelcomeScreen(launch: true)),
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
      GoRoute(
          path: '/calendar/export',
          builder: (_, __) => const WeeklyReportScreen()),
      // F4 Thêm, sửa, xoá việc – Khang (màn con N11–N13, trả kết quả bằng pop(result))
      GoRoute(path: '/task/date', builder: (_, __) => const TaskDateScreen()),
      GoRoute(
          path: '/task/repeat', builder: (_, __) => const TaskRepeatScreen()),
      GoRoute(path: '/task/scope', builder: (_, __) => const TaskScopeRoute()),
      // F6 Lời nhắc – Khang
      GoRoute(
          path: '/reminder/:taskId',
          builder: (_, state) => state.pathParameters['taskId'] == 'preview'
              ? const CalmReminderPreviewScreen()
              : CalmTaskDetailScreen(
                  id: state.pathParameters['taskId']!,
                  date: parseDateKey(state.uri.queryParameters['date']),
                  autoRead: true)),
      GoRoute(
          path: '/settings/reminders',
          builder: (_, __) => const ReminderSettingsScreen()),
      // F8 Cài đặt & hồ sơ – Sanh (khu demo Firebase F10 – Hiếu)
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/settings/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(
          path: '/settings/firebase-demo',
          builder: (_, __) => const FirebaseDemoScreen()),
      GoRoute(path: '/settings/help', builder: (_, __) => const HelpScreen()),
      GoRoute(path: '/settings/data', builder: (_, __) => const DataScreen()),
      // F10 Firebase – Hiếu
      GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen()),
      GoRoute(
          path: '/inbox/suggestions/:id',
          builder: (_, state) => SuggestionReviewScreen(
              id: state.pathParameters['id']!, entry: SuggestionEntry.push)),
      // Chế độ Con cháu: editor/detail ở root, ba destination có shell riêng.
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
      // F0 Trang xem thử widget – chỉ có ở bản debug (cần đăng nhập như mọi route khác).
      if (kDebugMode)
        GoRoute(
            path: '/dev/widgets',
            builder: (_, __) => const WidgetGallery(animate: false)),
      // Legacy routes remain valid after the navigation migration.
      GoRoute(path: '/week', redirect: (_, __) => '/calendar/day'),
      GoRoute(
          path: '/week/:date',
          redirect: (_, state) =>
              '/calendar?date=${Uri.encodeComponent(state.pathParameters['date']!)}'),
      GoRoute(
          path: '/week/:date/task/:id',
          redirect: (_, state) =>
              '/calendar/task/${Uri.encodeComponent(state.pathParameters['id']!)}?date=${Uri.encodeComponent(state.pathParameters['date']!)}'),
      GoRoute(
          path: '/habits', redirect: (_, __) => '/activities?section=habits'),
      GoRoute(
          path: '/habits/:key',
          redirect: (_, state) =>
              '/activities/habits/${Uri.encodeComponent(state.pathParameters['key']!)}'),
      GoRoute(
          path: '/family/add', builder: (_, __) => const FamilyEditorScreen()),
      GoRoute(
          path: '/family/:personId/edit',
          builder: (_, state) =>
              FamilyEditorScreen(id: state.pathParameters['personId']!)),
      GoRoute(
          path: '/family/:personId/share',
          builder: (_, state) =>
              FamilyContactScreen(id: state.pathParameters['personId']!)),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) =>
            AppShell(navigationShell: shell, caregiver: true),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/caregiver/schedule',
                builder: (_, state) => CaregiverScheduleScreen(
                    date: parseDateKey(state.uri.queryParameters['date']),
                    view: switch (state.uri.queryParameters['view']) {
                      'week' => CalendarView.week,
                      'month' => CalendarView.month,
                      _ => state.uri.queryParameters.containsKey('date')
                          ? CalendarView.day
                          : null
                    }))
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/caregiver/suggest',
                builder: (_, __) => const SuggestionComposeScreen(root: true))
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/caregiver/family',
                builder: (_, __) => const FamilyScreen(caregiver: true))
          ]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, state, shell) => AppShell(
            navigationShell: shell, legacyToday: state.uri.path == '/today'),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/calendar',
                // Link cũ `/calendar?date=…` mở trang lịch đầy đủ của ngày đó.
                redirect: (_, state) => state.uri.path == '/calendar' &&
                        state.uri.queryParameters['date'] != null
                    ? '/calendar/day?date=${Uri.encodeComponent(state.uri.queryParameters['date']!)}'
                    : null,
                builder: (_, __) => const CalendarScreen(),
                routes: [
                  GoRoute(
                      path: 'task/:id',
                      builder: (_, state) => CalmTaskDetailScreen(
                          id: state.pathParameters['id']!,
                          date:
                              parseDateKey(state.uri.queryParameters['date'])))
                ]),
            // Tab "Lịch": toàn bộ lịch theo ngày. Ngang hàng với /calendar để
            // là gốc của tab (không chồng lên Trang chủ, không có Quay lại).
            GoRoute(
                path: '/calendar/day',
                builder: (_, state) => CalendarDayScreen(
                    date: parseDateKey(state.uri.queryParameters['date']))),
            // F3 Hôm nay – Khang
            GoRoute(
                path: '/today',
                builder: (_, state) => TodayScreen(
                    forceMainView: state.uri.queryParameters['view'] == 'main'),
                routes: [
                  GoRoute(
                      path: 'task/:id',
                      builder: (_, state) => TaskDetailScreen(
                          taskId: state.pathParameters['id']!)),
                  // F4 Thêm, sửa, xoá việc – Khang (add/result mở bằng go, thay thế, không chồng)
                  GoRoute(
                      path: 'task/:id/edit',
                      builder: (_, state) => TaskConfigureScreen(
                          editId: state.pathParameters['id']!,
                          day:
                              parseDateKey(state.uri.queryParameters['date']))),
                  GoRoute(
                      path: 'add',
                      builder: (_, state) => ActivitySelectionScreen(
                          initialDate:
                              parseDateKey(state.uri.queryParameters['date']))),
                  GoRoute(
                      path: 'add/time',
                      builder: (_, __) => const TaskConfigureScreen()),
                  GoRoute(
                      path: 'add/result',
                      builder: (_, __) => const TaskSavedScreen()),
                  // F5 Giọng nói – Khang
                  GoRoute(
                      path: 'voice',
                      builder: (_, __) => const VoiceInputScreen()),
                  // F7 Lịch tuần – Hương
                  GoRoute(
                      path: 'all',
                      builder: (_, __) => const CalendarDayScreen()),
                  // F12 Gợi ý lịch (phía Bác) – Sanh
                  GoRoute(
                      path: 'suggestions/:id',
                      builder: (_, state) => SuggestionReviewScreen(
                          id: state.pathParameters['id']!,
                          entry: SuggestionEntry.fromQuery(
                              state.uri.queryParameters['from']))),
                ]),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/activities',
                builder: (_, state) => ActivitiesScreen(
                    section: state.uri.queryParameters['section'] ?? 'explore'),
                routes: [
                  GoRoute(
                      path: 'discover',
                      builder: (_, __) => const ActivityFlashcardsScreen()),
                  GoRoute(
                      path: 'guides/:id',
                      builder: (_, state) => GuidedActivityScreen(
                          id: state.pathParameters['id']!)),
                  GoRoute(
                      path: 'habits/:key',
                      builder: (_, state) => HabitDetailScreen(
                          habitKey: state.pathParameters['key']!))
                ]),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/family', builder: (_, __) => const FamilyScreen()),
          ]),
        ],
      ),
    ],
    debugLogDiagnostics: kDebugMode,
  );
  ref.onDispose(router.dispose);
  return router;
});
