import 'support/demo_container.dart';
import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mọi route placeholder trong architecture.md mục 7.2: path mẫu → mã màn hiện trên `FeaturePlaceholder`.
const _placeholders = {
  '/today/voice': 'Lên lịch bằng giọng nói',
  '/settings/reminders': 'Lời nhắc',
};

const _migratedRoutes = {
  '/today/all': 'Lịch của Bác',
  '/week': 'Lịch của Bác',
  '/week/2026-11-02': 'Lịch của Bác',
  '/week/2026-11-02/task/t1': 'Tưới rau ngoài vườn',
  '/habits': 'Vận động tự nhiên',
  '/habits/move': 'Vận động tự nhiên',
  '/family': 'Danh bạ gia đình',
  '/family/add': 'Tên người thân',
  '/family/p1/edit': 'Người thân này không còn trong danh bạ.',
  '/family/p1/share': 'Người thân này không còn trong danh bạ.',
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
};

const _editTask = TaskItem(
  id: 't1',
  title: 'Tưới rau ngoài vườn',
  habitKey: 'plant',
  hour: 6,
  minute: 30,
);

void main() {
  for (final MapEntry(key: path, value: code)
      in {..._placeholders, ..._migratedRoutes}.entries) {
    testWidgets('$path → $code', (tester) async {
      final container = demoContainer(tasks: const [_editTask]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container, child: const AnNhienApp()));
      await tester.pumpAndSettle();

      container.read(routerProvider).go(path);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      if (code == 'Lịch của Bác' || path == '/habits') {
        final screenScroll = find
            .byWidgetPredicate(
              (widget) => widget is Scrollable,
            )
            .evaluate()
            .firstWhere(
              (element) =>
                  element.findAncestorWidgetOfExactType<NavigationRail>() ==
                  null,
            );
        await tester.scrollUntilVisible(find.textContaining(code), 250,
            scrollable: find.byWidget(screenScroll.widget));
      }
      expect(find.textContaining(code), findsWidgets);

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
