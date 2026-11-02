import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/theme/display_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Khung 360 và 412 dp, cỡ chữ "Rất lớn" (1.3) và trần 2.0 (hệ thống phóng to): không tràn.
void main() {
  for (final width in [360.0, 412.0]) {
    for (final systemScale in [1.0, 2.0]) {
      for (final path in ['/today', '/week', '/settings', '/role']) {
        testWidgets('$path · $width dp · hệ thống ×$systemScale', (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = systemScale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          final container = ProviderContainer(overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(signedIn: const AppUser(uid: 'test-uid'))),
            taskRepositoryProvider.overrideWithValue(FakeTaskRepository([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            crashServiceProvider.overrideWithValue(FakeCrashService()),
          ]);
          addTearDown(container.dispose);
          container.read(fontScaleProvider.notifier).set(AppFontScale.ratLon);
          await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AnNhienApp()));
          await tester.pumpAndSettle();
          container.read(routerProvider).go(path);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 400));
        });
      }
    }
  }
}
