import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/models/voice_task_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceTaskDraft Schedule Completion Unit Tests', () {
    test('1. scheduleComplete is false when hour or minute is missing', () {
      final draft = VoiceTaskDraft(
        title: 'Đi bộ công viên',
        date: DateTime(2026, 11, 13),
        hour: null,
        minute: null,
        repeat: RepeatRule.daily,
        weekdays: const [],
        habitKey: 'move',
      );
      expect(draft.scheduleComplete, isFalse);
      expect(draft.complete, isFalse);
    });

    test('2. complete requires durationMinutes in addition to complete schedule', () {
      final draftWithoutDuration = VoiceTaskDraft(
        title: 'Uống thuốc sáng',
        date: DateTime(2026, 11, 13),
        hour: 8,
        minute: 0,
        durationMinutes: null,
        repeat: RepeatRule.daily,
        weekdays: const [],
        habitKey: 'downshift',
      );
      expect(draftWithoutDuration.scheduleComplete, isTrue);
      expect(draftWithoutDuration.complete, isFalse);
    });

    test('3. withDuration returns updated instance with complete set to true', () {
      final draft = VoiceTaskDraft(
        title: 'Đo huyết áp',
        date: DateTime(2026, 11, 13),
        hour: 9,
        minute: 30,
        repeat: RepeatRule.daily,
        weekdays: const [],
        habitKey: 'downshift',
      );
      final completedDraft = draft.withDuration(15);
      expect(completedDraft.durationMinutes, 15);
      expect(completedDraft.complete, isTrue);
    });
  });
}\n