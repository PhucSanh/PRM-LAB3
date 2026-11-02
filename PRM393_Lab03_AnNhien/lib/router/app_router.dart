import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../screens/sign_in/sign_in_screen.dart';
import '../screens/today/today_screen.dart';
import '../viewmodels/session_view_model.dart';
import '../widgets/app_shell.dart';
import '../widgets/feature_placeholder.dart';

/// Route map theo flutter-handoff.md (Lab 2). Chủ file: A – Sanh.
/// Ai làm màn nào: thay `FeaturePlaceholder` bằng màn thật của mình.
final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<AppUser?>(null);
  ref.onDispose(session.dispose);
  ref.listen(
    sessionProvider,
    (_, next) => session.value = next.when(data: (u) => u, loading: () => null, error: (_, __) => null),
    fireImmediately: true,
  );

  FeaturePlaceholder ph(String code, String title, String owner, {bool back = true}) =>
      FeaturePlaceholder(code: code, title: title, owner: owner, showBack: back);

  return GoRouter(
    initialLocation: '/today',
    refreshListenable: session,
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
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      // F2 Onboarding – Hiếu
      GoRoute(path: '/welcome', builder: (_, __) => ph('S01 · F2', 'Chào mừng – chọn cỡ chữ', 'Hiếu', back: false)),
      GoRoute(path: '/setup', builder: (_, __) => ph('S02 · F2', 'Thiết lập hồ sơ', 'Hiếu')),
      GoRoute(path: '/setup/notifications', builder: (_, __) => ph('S13 · F2', 'Cho phép nhắc việc', 'Hiếu')),
      // F6 Lời nhắc – Khang
      GoRoute(path: '/reminder/:taskId', builder: (_, __) => ph('S14 · F6', 'Lời nhắc đến giờ', 'Khang')),
      // F8 Cài đặt & hồ sơ – Sanh (khu demo Firebase F10 – Hiếu)
      GoRoute(path: '/settings', builder: (_, __) => ph('S10 · F8', 'Cài đặt hiển thị', 'Sanh')),
      GoRoute(path: '/settings/profile', builder: (_, __) => ph('N06 · F8/F10', 'Hồ sơ + khu demo Firebase', 'Sanh, Hiếu')),
      GoRoute(path: '/inbox', builder: (_, __) => ph('F10', 'Hộp thông báo', 'Hiếu')),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/today', builder: (_, __) => const TodayScreen(), routes: [
              GoRoute(path: 'task/:id', builder: (_, __) => ph('S04 · F3', 'Chi tiết hoạt động', 'Khang')),
              GoRoute(path: 'task/:id/edit', builder: (_, __) => ph('S15 · F4', 'Sửa việc', 'Khang')),
              GoRoute(path: 'add', builder: (_, __) => ph('S05 · F4', 'Thêm việc – chọn hoạt động', 'Khang')),
              GoRoute(path: 'add/time', builder: (_, __) => ph('S06 · F4', 'Thêm việc – thiết lập', 'Khang')),
              GoRoute(path: 'voice', builder: (_, __) => ph('V01 · F5', 'Nói để thêm việc', 'Khang')),
              GoRoute(path: 'suggestions/:id', builder: (_, __) => ph('G03 · F12', 'Lịch Mai gợi ý', 'Hương')),
            ]),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/week', builder: (_, __) => ph('S07 · F7', 'Lịch tuần', 'Hương', back: false), routes: [
              GoRoute(path: ':date', builder: (_, __) => ph('S11 · F7', 'Chi tiết ngày', 'Hương')),
            ]),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/habits', builder: (_, __) => ph('S08 · F9', '9 thói quen', 'Hương', back: false), routes: [
              GoRoute(path: ':key', builder: (_, __) => ph('S16 · F9', 'Chi tiết thói quen', 'Hương')),
            ]),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/family', builder: (_, __) => ph('S09 · F11', 'Gia đình', 'Hương', back: false), routes: [
              GoRoute(path: 'add', builder: (_, __) => ph('S12 · F11', 'Thêm người thân', 'Hương')),
              GoRoute(path: ':personId/share', builder: (_, __) => ph('S17 · F11', 'Nhắn tin cho người thân', 'Hương')),
            ]),
          ]),
        ],
      ),
    ],
    debugLogDiagnostics: kDebugMode,
  );
});
