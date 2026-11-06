import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'form_parts.dart';

/// Keep legacy relationship labels available while new contacts use choices.
class RelationshipDropdown extends StatelessWidget {
  const RelationshipDropdown(
      {super.key,
      required this.value,
      required this.onChanged,
      this.enabled = true});
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  static const options = [
    'Con',
    'Cháu',
    'Anh/chị/em',
    'Vợ/chồng',
    'Bạn bè',
    'Khác'
  ];

  @override
  Widget build(BuildContext context) {
    final choices = [
      ...options,
      if (value != null && !options.contains(value)) value!,
    ];
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const FieldLabel('Mối quan hệ'),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            itemHeight: null,
            hint: const Text('Chọn mối quan hệ'),
            decoration: const InputDecoration(),
            items: [
              for (final choice in choices)
                DropdownMenuItem(
                    value: choice,
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            minHeight: AppSizes.assistanceTarget),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(choice))))
            ],
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: enabled ? onChanged : null,
          ),
        ]);
  }
}
