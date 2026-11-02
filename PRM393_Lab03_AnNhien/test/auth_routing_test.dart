import 'package:an_nhien/app.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('session changes preserve sign-in and sign-out redirects',
      (tester) async {
    final auth = FakeAuthService();
    final container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(auth),
      taskRepositoryProvider.overrideWithValue(FakeTaskRepository([])),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const AnNhienApp()));
    await tester.pumpAndSettle();
    final router = container.read(routerProvider);
    expect(router.routeInformationProvider.value.uri.path, '/sign-in');

    // runAsync allows the fake service's timer to complete outside fake time.
    await tester.runAsync(auth.signInWithGoogle);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    expect(router.routeInformationProvider.value.uri.path, '/today');

    await auth.signOut();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/sign-in');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 400));
  });
}
