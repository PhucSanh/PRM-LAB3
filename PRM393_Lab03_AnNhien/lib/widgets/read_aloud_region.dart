import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/device_access_view_model.dart';

/// Reads only the text inside this content block, using its latest values.
class ReadAloudRegion extends StatefulWidget {
  const ReadAloudRegion({super.key, required this.child});
  final Widget child;
  @override
  State<ReadAloudRegion> createState() => _ReadAloudRegionState();
}

class _ReadAloudRegionState extends State<ReadAloudRegion> {
  final _content = GlobalKey();
  bool _reading = false;
  String? _error;
  Future<void> _read() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final vm = container.read(speechViewModelProvider.notifier);
    if (_reading) {
      await vm.stop();
      return;
    }
    final parts = <String>[];
    void visit(Element e) {
      final w = e.widget;
      if (w is Offstage && w.offstage) return;
      if (w is Text) {
        final text = w.data ?? w.textSpan?.toPlainText() ?? '';
        if (text.trim().isNotEmpty) parts.add(text.trim());
      }
      if (w is EditableText && !w.obscureText && w.controller.text.isNotEmpty) {
        parts.add(w.controller.text);
      }
      e.visitChildren(visit);
    }

    (_content.currentContext as Element?)?.visitChildren(visit);
    if (parts.isEmpty) return;
    final keep = container.listen(speechViewModelProvider, (_, __) {});
    setState(() {
      _reading = true;
      _error = null;
    });
    try {
      await vm.read(parts.join('. '));
      if (mounted) {
        setState(() {
          _reading = false;
          _error = container.read(speechViewModelProvider).error;
        });
      }
    } finally {
      keep.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
                tooltip: _reading ? 'Dừng đọc khung này' : 'Đọc khung này',
                onPressed: _read,
                icon: Icon(_reading
                    ? Icons.stop_circle_outlined
                    : Icons.volume_up_rounded)),
          ]),
          KeyedSubtree(key: _content, child: widget.child),
          if (_error != null) Text(_error!),
        ]);
  }
}
