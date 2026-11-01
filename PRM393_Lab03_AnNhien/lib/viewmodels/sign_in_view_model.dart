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
    state = const SignInState(busy: true);
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      await ref.read(analyticsServiceProvider).setUserId(user.uid);
      await ref.read(analyticsServiceProvider).logEvent('login', {'method': 'google'});
      state = const SignInState();
    } on AppException catch (e) {
      state = SignInState(message: e.userMessage);
    } catch (e, st) {
      await ref.read(crashServiceProvider).recordError(e, st, reason: 'sign_in');
      state = SignInState(message: AppException.unknown.userMessage);
    }
  }
}

final signInViewModelProvider = NotifierProvider<SignInViewModel, SignInState>(SignInViewModel.new);
