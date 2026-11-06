import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/relative.dart';
import '../theme/app_spacing.dart';
import '../utils/app_error.dart';
import '../viewmodels/family_actions_view_model.dart';
import 'section_card.dart';
import 'app_button.dart';
import 'undo_snackbar.dart';

class FamilyContactCard extends ConsumerWidget {
  const FamilyContactCard(
      {super.key, required this.person, required this.onEdit});
  final Relative person;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(familyActionsProvider),
        vm = ref.read(familyActionsProvider.notifier);
    Future<void> favorite() async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        final change = await vm.toggleFavorite(person);
        if (change == null || !context.mounted) return;
        showUndoSnackbar(context,
            title: person.favorite
                ? 'Đã bỏ ghim người thân'
                : 'Đã ghim người thân lên đầu', onUndo: () async {
          try {
            await vm.undo(change);
          } catch (_) {
            if (messenger.mounted) {
              messenger.showSnackBar(const SnackBar(
                  content: Text('Chưa hoàn tác được. Bác thử lại nhé.')));
            }
          }
        });
      } catch (e) {
        if (context.mounted) {
          messenger.showSnackBar(SnackBar(
              content: Text(e is AppException
                  ? e.userMessage
                  : 'Chưa lưu được lựa chọn. Bác thử lại nhé.')));
        }
      }
    }

    return SectionCard(
        icon:
            person.favorite ? Icons.star_rounded : Icons.person_outline_rounded,
        title: person.name,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${person.relation} · ${person.phone}'),
          const SizedBox(height: AppSpacing.md),
          AppButton(
              label: 'Gọi ${person.name}',
              icon: Icons.call_rounded,
              kind: AppButtonKind.tonal,
              onPressed: () async {
                try {
                  await vm.call(person);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e is AppException
                            ? e.userMessage
                            : 'Chưa mở được màn hình gọi.')));
                  }
                }
              }),
          TextButton.icon(
              onPressed: busy ? null : favorite,
              icon: Icon(person.favorite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded),
              label: Text(person.favorite
                  ? 'Bỏ ghim người thân'
                  : 'Ghim người thân lên đầu')),
          TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Sửa thông tin')),
          TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: person.phone));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Đã sao chép số điện thoại.')));
                }
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Sao chép số')),
        ]));
  }
}
