import 'support/demo_container.dart';
import 'package:an_nhien/app.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mọi route placeholder trong architecture.md mục 7.2: path mẫu → mã màn hiện trên `FeaturePlaceholder`.
const _placeholders = {
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
  // '/settings' (S10) đã là màn thật – xem test/settings_screen_test.dart.
  // '/settings/profile' (N06) đã là màn thật – xem test/profile_screen_test.dart.
  '/settings/reminders': 'N07 · F6',
  // '/settings/help' (N08), '/settings/data' (N20) đã là màn thật – xem test/settings_static_screens_test.dart.
};

void main() {
  for (final MapEntry(key: path, value: code) in _placeholders.entries) {
    testWidgets('$path → $code', (tester) async {
      final container = demoContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container, child: const AnNhienApp()));
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
