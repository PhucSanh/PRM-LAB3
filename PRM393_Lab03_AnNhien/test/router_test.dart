import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mọi route placeholder trong architecture.md mục 7.2: path mẫu → mã màn hiện trên `FeaturePlaceholder`.
const _placeholders = {
  '/role': 'C01 · F1',
  '/welcome': 'S01 · F2',
  '/setup': 'S02 · F2',
  '/setup/notifications': 'S13 · F2',
  '/setup/try-reminder': 'N01 · F2',
  '/setup/first-task': 'N04 · F2',
  '/today/task/t1': 'S04 · F3',
  '/today/task/t1/edit': 'S15 · F4',
  '/today/add': 'S05 · F4',
  '/today/add/time': 'S06 · F4',
  '/today/add/result': 'ST-Saved · F4',
  '/task/date': 'N11 · F4',
  '/task/repeat': 'N12 · F4',
  '/task/scope': 'N13 · F4',
  '/today/voice': 'V01 · F5',
  '/today/all': 'S11 · F7',
  '/today/suggestions/g1': 'G03 · F12',
  '/reminder/t1': 'S14 · F6',
  '/week': 'S07 · F7',
  '/week/2026-11-02': 'S11 · F7',
  '/week/2026-11-02/task/t1': 'S04 · F3',
  '/habits': 'S08 · F9',
  '/habits/move': 'S16 · F9',
  '/family': 'S09 · F11',
  '/family/add': 'S12 · F11',
  '/family/p1/edit': 'N09 · F11',
  '/family/p1/share': 'S17 · F11',
  '/settings': 'S10 · F8',
  '/settings/profile': 'N06 · F8/F10',
  '/settings/reminders': 'N07 · F6',
  '/settings/help': 'N08 · F8',
  '/settings/data': 'N20 · F8',
  '/inbox': 'F10',
  '/caregiver/pair': 'C02 · F13',
  '/caregiver/schedule': 'C03 · F14',
  '/caregiver/schedule?view=day': 'C03 · F14',
  '/caregiver/schedule?view=week': 'C04 · F14',
  '/caregiver/schedule?view=month': 'C05 · F14',
  '/caregiver/task/new': 'C06 · F14',
  '/caregiver/task/new/repeat': 'C07 · F14',
  '/caregiver/task/new/review': 'C08 · F14',
  '/caregiver/task/sent': 'C09 · F14',
  '/caregiver/task/t1': 'C10 · F14',
  '/caregiver/suggest': 'G01 · F12',
};

void main() {
  for (final MapEntry(key: path, value: code) in _placeholders.entries) {
    testWidgets('$path → $code', (tester) async {
      final container = ProviderContainer(overrides: [
        authServiceProvider.overrideWithValue(
          FakeAuthService(signedIn: const AppUser(uid: 'test-uid', displayName: 'Bác Lan')),
        ),
        taskRepositoryProvider.overrideWithValue(FakeTaskRepository([])),
        analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
        crashServiceProvider.overrideWithValue(FakeCrashService()),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AnNhienApp()));
      await tester.pumpAndSettle();

      container.read(routerProvider).go(path);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(code), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));
    });
  }
}
