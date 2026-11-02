import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/providers.dart';
import '../utils/app_error.dart';

/// F1 Tài khoản – chủ: B – Hiếu.
class SignInState {
  const SignInState({this.busy = false, this.message});
  final bool busy;
  final String? message; // câu báo khi huỷ / lỗi
}

class SignInViewModel extends Notifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  Future<void> signInWithGoogle() async {
    if (state.busy) return;
    state = const SignInState(busy: true);
    try {
      await ref.read(sessionDataServiceProvider).clearLocalData();
      if (!ref.mounted) return;
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (!ref.mounted) return;
      try {
        await ref.read(analyticsServiceProvider).setUserId(user.uid);
        await ref
            .read(analyticsServiceProvider)
            .logEvent('login', {'method': 'google'});
      } catch (_) {/* Telemetry must not undo authentication. */}
      if (!ref.mounted) return;
      state = const SignInState();
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = SignInState(message: e.userMessage);
    } catch (e, st) {
      if (!ref.mounted) return;
      try {
        await ref
            .read(crashServiceProvider)
            .recordError(e, st, reason: 'sign_in');
      } catch (_) {/* Telemetry cannot hide the sign-in error. */}
      if (!ref.mounted) return;
      state = SignInState(message: AppException.unknown.userMessage);
    }
  }
}

final signInViewModelProvider =
    NotifierProvider<SignInViewModel, SignInState>(SignInViewModel.new);
