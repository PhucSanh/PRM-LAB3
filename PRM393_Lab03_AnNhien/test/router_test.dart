import 'support/demo_container.dart';
import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mọi route placeholder trong architecture.md mục 7.2: path mẫu → mã màn hiện trên `FeaturePlaceholder`.
const _placeholders = {
  '/today/voice': 'V01 · F5',
  '/today/all': 'S11 · F7',
  '/week': 'S07 · F7',
  '/week/2026-11-02': 'S11 · F7',
  '/habits': 'S08 · F9',
  '/habits/move': 'S16 · F9',
  '/family': 'S09 · F11',
  '/family/add': 'S12 · F11',
  '/family/p1/edit': 'N09 · F11',
  '/family/p1/share': 'S17 · F11',
  // '/settings' (S10) đã là màn thật – xem test/settings_screen_test.dart.
  // '/settings/profile' (N06) đã là màn thật – xem test/profile_screen_test.dart.
  // '/settings/help' (N08), '/settings/data' (N20) đã là màn thật – xem test/settings_static_screens_test.dart.
};

/// F4 không còn là placeholder: mỗi route phải xác nhận nội dung thực tế.
const _f4Routes = <String, String>{
  '/today/add': 'Bác muốn làm gì?',
  '/today/add/time': 'Tên việc',
  '/today/add/result': 'Đã lưu xong!',
  '/task/date': 'Chọn ngày',
  '/task/repeat': 'Chọn ngày trong tuần',
  '/task/scope': 'Thay đổi lần nào?',
  '/today/task/t1/edit': 'Sửa việc',
};

/// F3 không còn là placeholder: S04 phải lấy được task từ repository dùng chung.
const _f3Routes = <String, String>{
  '/today/task/t1': 'Việc của Bác',
  '/week/2026-11-02/task/t1': 'Việc của Bác',
};

/// F6 không còn là placeholder: S14 cần task thật, N07 cần cài đặt thật.
const _f6Routes = <String, String>{
  '/reminder/t1': 'Lời nhắc',
  '/settings/reminders': 'Cài đặt nhắc việc',
};

const _editTask = TaskItem(
  id: 't1',
  title: 'Tưới rau ngoài vườn',
  habitKey: 'plant',
  hour: 6,
  minute: 30,
);

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

  for (final MapEntry(key: path, value: content) in _f4Routes.entries) {
    testWidgets('$path → màn F4 thật', (tester) async {
      final container = demoContainer(
          tasks: path == '/today/task/t1/edit' ? [_editTask] : null);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container, child: const AnNhienApp()));
      await tester.pumpAndSettle();

      container.read(routerProvider).go(path);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(content), findsOneWidget);
      if (path == '/today/task/t1/edit') {
        expect(find.text(_editTask.title), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));
    });
  }

  for (final MapEntry(key: path, value: content) in _f6Routes.entries) {
    testWidgets('$path → màn F6 thật', (tester) async {
      final container = demoContainer(tasks: [_editTask]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container, child: const AnNhienApp()));
      await tester.pumpAndSettle();

      container.read(routerProvider).go(path);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(content), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));
    });
  }

  for (final MapEntry(key: path, value: content) in _f3Routes.entries) {
    testWidgets('$path → màn F3 thật', (tester) async {
      final container = demoContainer(tasks: [_editTask]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container, child: const AnNhienApp()));
      await tester.pumpAndSettle();

      container.read(routerProvider).go(path);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(content), findsOneWidget);
      expect(find.text(_editTask.title), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));
    });
  }
}
