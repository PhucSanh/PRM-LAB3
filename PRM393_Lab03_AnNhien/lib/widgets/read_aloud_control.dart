import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/device_access_view_model.dart';
import 'read_aloud_button.dart';
import 'form_parts.dart';

class ReadAloudControl extends ConsumerWidget {
  const ReadAloudControl({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(speechViewModelProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ReadAloudButton(
          speaking: state.speaking,
          onPressed: () =>
              ref.read(speechViewModelProvider.notifier).toggle(text)),
      if (state.error != null) FieldMessage.error(state.error!),
    ]);
  }
}
