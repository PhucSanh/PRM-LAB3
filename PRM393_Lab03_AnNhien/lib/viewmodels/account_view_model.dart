import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'session_view_model.dart';
import 'ui_state.dart';

class SessionActionState {
  const SessionActionState({this.busy = false, this.message});
  final bool busy;
  final String? message;
}

class SignOutViewModel extends Notifier<SessionActionState> {
  @override
  SessionActionState build() => const SessionActionState();

  Future<void> signOut() async {
    if (state.busy) return;
    state = const SessionActionState(busy: true);
    final auth = ref.read(authServiceProvider);
    final cache = ref.read(sessionDataServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final crash = ref.read(crashServiceProvider);
    String? message;
    // Let profileProvider detach its subscription before terminating Firestore.
    await Future<void>.delayed(Duration.zero);
    try {
      await cache.clearLocalData();
    } catch (error, stack) {
      message = error is AppException
          ? error.userMessage
          : AppException.unknown.userMessage;
      try {
        await crash.recordError(error, stack, reason: 'sign_out_cache');
      } catch (_) {}
    }
    try {
      await auth.signOut();
    } catch (error, stack) {
      message = error is AppException
          ? error.userMessage
          : AppException.unknown.userMessage;
      try {
        await crash.recordError(error, stack, reason: 'sign_out');
      } catch (_) {}
    }
    if (auth.currentUser == null) {
      try {
        await analytics.logEvent('logout');
        await analytics.setUserId(null);
        await crash.setUserId('');
      } catch (_) {/* Telemetry cannot block logout. */}
    }
    if (ref.mounted) state = SessionActionState(message: message);
  }
}

final signOutViewModelProvider =
    NotifierProvider<SignOutViewModel, SessionActionState>(
        SignOutViewModel.new);

final profileProvider = StreamProvider<UserProfile?>((ref) {
  final closing = ref.watch(signOutViewModelProvider).busy;
  final session = ref.watch(sessionProvider);
  if (closing) return Stream.value(null);
  return session.when(
    loading: () => const Stream.empty(),
    error: (error, stack) => Stream.error(error, stack),
    data: (user) {
      if (user == null) return Stream.value(null);
      final service = ref.watch(profileServiceProvider);
      return (() async* {
        await service.ensureProfile(user);
        if (!ref.mounted) return;
        yield* service.watch(user.uid);
      })();
    },
  );
});

class RoleSelection {
  const RoleSelection({this.role, this.busy = false, this.message});
  final UserRole? role;
  final bool busy;
  final String? message;
}

class RoleViewModel extends Notifier<UiState<RoleSelection>> {
  @override
  UiState<RoleSelection> build() => const UiData(RoleSelection());
  void select(UserRole role) {
    final current = state;
    if (current is UiData<RoleSelection> && !current.data.busy) {
      state = UiData(RoleSelection(role: role));
    }
  }

  Future<void> submit() async {
    final current = state;
    if (current is! UiData<RoleSelection> || current.data.busy) return;
    final role = current.data.role;
    if (role == null) return;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) {
      state = UiData(
          RoleSelection(role: role, message: 'Bác cần đăng nhập trước.'));
      return;
    }
    final profiles = ref.read(profileServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final crash = ref.read(crashServiceProvider);
    state = UiData(RoleSelection(role: role, busy: true));
    try {
      await profiles.setRole(uid, role);
      if (!ref.mounted ||
          ref.read(authServiceProvider).currentUser?.uid != uid) {
        return;
      }
      try {
        await analytics.logEvent('select_role', {'role': role.name});
      } catch (_) {/* Persisted role is still successful. */}
      if (ref.mounted) state = UiData(RoleSelection(role: role));
    } catch (error, stack) {
      if (!ref.mounted) return;
      try {
        await crash.recordError(error, stack, reason: 'select_role');
      } catch (_) {}
      if (ref.mounted) {
        state = UiData(RoleSelection(
            role: role,
            message: error is AppException
                ? error.userMessage
                : AppException.unknown.userMessage));
      }
    }
  }
}

final roleViewModelProvider =
    NotifierProvider<RoleViewModel, UiState<RoleSelection>>(RoleViewModel.new);
