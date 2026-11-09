import 'dart:async';
import 'package:an_nhien/app.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/voice_task_service.dart';
import 'package:an_nhien/models/voice_task_draft.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/viewmodels/device_access_view_model.dart';
import 'package:an_nhien/viewmodels/task_form_view_model.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/demo_container.dart';
import 'device_access_flow_test.dart' show TestDevice;
import 'voice_task_test.dart' show ready, ambiguous, ScriptedVoiceService;

Future<ProviderContainer> pumpVoice(
    WidgetTester tester, VoiceTaskService service,
    {double scale = 1, double width = 360}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final c = demoContainer(
      initialRoute: '/today/voice',
      voiceTasks: service,
      device: TestDevice(),
      taskRepository: FakeTaskRepository([]));
  addTearDown(c.dispose);
  await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const AnNhienApp()));
  await tester.pumpAndSettle();
  return c;
}

Future<void> tap(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader(AppTheme.fontFamily);
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final (width, scale) in [(360.0, 1.0), (360.0, 2.0), (412.0, 2.0)]) {
    testWidgets(
        'spoken clarification, review and explicit form confirmation $width x$scale',
        (tester) async {
      final service = ScriptedVoiceService(() async => ambiguous());
      final c = await pumpVoice(tester, service, width: width, scale: scale);
      final vm = c.read(voiceInputViewModelProvider.notifier);
      vm.edit('Ngày 3 tháng 2 năm 2030 lúc 8 giờ tưới cây');
      await tester.pumpAndSettle();
      await tap(tester, 'Tạo lịch từ câu nói');
      expect(find.text(ambiguous().question!).hitTestable(), findsOneWidget);
      expect(find.text('Xem và sửa trước khi lưu'), findsNothing);
      vm.editFollowUp('8 giờ rưỡi sáng thứ hai tư sáu');
      await tester.pumpAndSettle();
      service.next = () async => ready();
      await tap(tester, 'Gửi câu trả lời');
      expect(find.text('Lịch đề xuất cho Bác').hitTestable(), findsOneWidget);
      expect(find.text('Giờ: 08:30'), findsOneWidget);
      expect(
          await tester.runAsync(() =>
              c.read(taskRepositoryProvider).tasksForDay(DateTime(2030, 2, 3))),
          isEmpty);
      await expectLater(
          find.byType(AnNhienApp),
          matchesGoldenFile(
              'goldens/groq_review_${width.toInt()}_${scale.toInt()}x.png'));
      await tap(tester, 'Xem và sửa trước khi lưu');
      expect(find.text('Thêm việc'), findsOneWidget);
      expect(c.read(taskFormViewModelProvider).title, 'Tưới cây');
      expect(c.read(taskFormViewModelProvider).minute, 30);
      expect(
          await tester.runAsync(() =>
              c.read(taskRepositoryProvider).tasksForDay(DateTime(2030, 2, 3))),
          isEmpty);
      expect(tester.takeException(), isNull);
      await close(tester);
    });
  }
  testWidgets('no key retains sentence, offers retry and manual form',
      (tester) async {
    final c = await pumpVoice(
        tester,
        ScriptedVoiceService(() async =>
            throw const AppException('Hiểu lời nói chưa được bật.')));
    c.read(voiceInputViewModelProvider.notifier).edit('Gọi con');
    await tester.pumpAndSettle();
    await tap(tester, 'Tạo lịch từ câu nói');
    expect(find.text('Hiểu lời nói chưa được bật.'), findsOneWidget);
    expect(c.read(voiceInputViewModelProvider).text, 'Gọi con');
    await tap(tester, 'Nhập lịch bằng tay');
    expect(find.text('Thêm việc'), findsOneWidget);
    expect(c.read(taskFormViewModelProvider).title, 'Gọi con');
    await close(tester);
  });
  testWidgets('blank manual fallback opens a usable empty form',
      (tester) async {
    final c = await pumpVoice(tester, FakeVoiceTaskService());
    await tap(tester, 'Nhập lịch bằng tay');
    expect(find.text('Tên việc'), findsOneWidget);
    expect(c.read(taskFormViewModelProvider).title, isEmpty);
    await close(tester);
  });
  testWidgets('pending AI request disables editing and repeat submit',
      (tester) async {
    final pending = Completer<VoiceTaskInterpretation>();
    final service = ScriptedVoiceService(() => pending.future);
    final c = await pumpVoice(tester, service);
    c.read(voiceInputViewModelProvider.notifier).edit('Mai tưới cây');
    await tester.pumpAndSettle();
    final target = find.text('Tạo lịch từ câu nói');
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    expect(c.read(voiceInputViewModelProvider).busy, true);
    expect(
        tester.widget<TextField>(find.byType(TextField).first).enabled, false);
    expect(find.text('Đang sắp xếp lịch…'), findsOneWidget);
    pending.complete(ready());
    await tester.pumpAndSettle();
    expect(service.requests, hasLength(1));
    await close(tester);
  });
  testWidgets(
      'full transcript wraps; incorrect AI proposal can be spoken again without saving',
      (tester) async {
    final c =
        await pumpVoice(tester, ScriptedVoiceService(() async => ready()));
    final vm = c.read(voiceInputViewModelProvider.notifier);
    const sentence =
        'Ngày mai tôi muốn đi uống nước chè và trò chuyện với bà Lan lúc 5 giờ chiều trong 30 phút';
    vm.edit(sentence);
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.maxLines, isNull);
    expect(field.minLines, 3);
    expect(field.controller!.text, sentence);
    await expectLater(find.byType(AnNhienApp),
        matchesGoldenFile('goldens/voice_transcript_360_1x.png'));
    await tap(tester, 'Tạo lịch từ câu nói');
    expect(find.text('Đúng rồi, thêm vào lịch'), findsOneWidget);
    expect(find.text(sentence), findsOneWidget);
    expect(
        await tester.runAsync(() =>
            c.read(taskRepositoryProvider).tasksForDay(DateTime(2030, 2, 3))),
        isEmpty);
    await tap(tester, 'Chưa đúng, nói lại');
    expect(c.read(voiceInputViewModelProvider).interpretation, isNull);
    expect(c.read(voiceInputViewModelProvider).text, 'Tưới rau ngoài vườn');
    expect(
        await tester.runAsync(() =>
            c.read(taskRepositoryProvider).tasksForDay(DateTime(2030, 2, 3))),
        isEmpty);
    await close(tester);
  });

  testWidgets(
      'AI draft only saves after explicit confirmation and snackbar expires',
      (tester) async {
    final c =
        await pumpVoice(tester, ScriptedVoiceService(() async => ready()));
    c
        .read(voiceInputViewModelProvider.notifier)
        .edit('Ngày 3 tháng 2 năm 2030 lúc 8 giờ rưỡi tưới cây 20 phút');
    await tester.pumpAndSettle();
    await tap(tester, 'Tạo lịch từ câu nói');
    expect(
        await tester.runAsync(() =>
            c.read(taskRepositoryProvider).tasksForDay(DateTime(2030, 2, 4))),
        isEmpty);
    await tap(tester, 'Đúng rồi, thêm vào lịch');
    expect(
        await tester.runAsync(() =>
            c.read(taskRepositoryProvider).tasksForDay(DateTime(2030, 2, 4))),
        hasLength(1));
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    await close(tester);
  });
}
