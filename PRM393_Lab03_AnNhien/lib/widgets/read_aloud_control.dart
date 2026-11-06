import '../services/providers.dart';
import '../viewmodels/session_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/device_access_view_model.dart';
import 'form_parts.dart';

class ReadAloudControl extends ConsumerWidget {
  const ReadAloudControl({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(speechViewModelProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(
          alignment: Alignment.centerRight,
          child: IconButton(
              tooltip:
                  state.speaking ? 'Dừng đọc nội dung này' : 'Đọc nội dung này',
              icon: Icon(state.speaking
                  ? Icons.stop_circle_outlined
                  : Icons.volume_up_rounded),
              onPressed: () =>
                  ref.read(speechViewModelProvider.notifier).toggle(text))),
      if (state.error != null) FieldMessage.error(state.error!),
    ]);
  }
}

final reminderReadPreferenceProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(sessionProvider).value?.uid;
  if (uid == null) return Stream.value(false);
  return ref.watch(settingsServiceProvider).watch().map((s) => s.readAloud);
});

/// The saved read-aloud preference applies when the user opens a reminder.
/// Manual reading remains available even if automatic reading is off.
class ReminderReadAloudControl extends ConsumerStatefulWidget {
  const ReminderReadAloudControl(
      {super.key, required this.text, required this.identity});
  final String text, identity;
  @override
  ConsumerState<ReminderReadAloudControl> createState() =>
      _ReminderReadAloudControlState();
}

class _ReminderReadAloudControlState
    extends ConsumerState<ReminderReadAloudControl> {
  String? _readIdentity;
  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(reminderReadPreferenceProvider).value ?? false;
    if (enabled && _readIdentity != widget.identity) {
      _readIdentity = widget.identity;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(speechViewModelProvider.notifier).read(widget.text);
        }
      });
    }
    return ReadAloudControl(text: widget.text);
  }
}
