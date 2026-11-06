import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/relative.dart';
import '../services/family_repository.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'calm_feature_providers.dart';
import 'session_view_model.dart';

class FavoriteChange {
  const FavoriteChange(this.uid, this.person);
  final String uid;
  final Relative person;
}

class FamilyActionsViewModel extends Notifier<bool> {
  @override
  bool build() => false;
  Future<void> call(Relative person) =>
      ref.read(contactLauncherServiceProvider).openDialer(person.phone);
  Future<FavoriteChange?> toggleFavorite(Relative person) async {
    if (state) return null;
    final uid = ref.read(sessionProvider).value?.uid;
    if (uid == null) throw const AppException('Bác đăng nhập lại nhé.');
    state = true;
    try {
      await _setFavorite(person, !person.favorite);
      ref.invalidate(familyListProvider);
      return FavoriteChange(uid, person);
    } finally {
      if (ref.mounted) state = false;
    }
  }

  Future<void> _setFavorite(Relative person, bool value) async {
    final repository = ref.read(familyRepositoryProvider);
    if (repository is FavoriteFamilyRepository) {
      await (repository as FavoriteFamilyRepository)
          .setFavorite(person.id, value);
    } else {
      await repository.save(person.copyWith(favorite: value));
    }
  }

  Future<void> undo(FavoriteChange change) async {
    if (ref.read(sessionProvider).value?.uid != change.uid)
      throw const AppException(
          'Tài khoản đã thay đổi. Bác mở lại Gia đình nhé.');
    await _setFavorite(change.person, change.person.favorite);
    ref.invalidate(familyListProvider);
  }
}

final familyActionsProvider =
    NotifierProvider<FamilyActionsViewModel, bool>(FamilyActionsViewModel.new);
