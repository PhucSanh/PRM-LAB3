import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pairing_service.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'session_view_model.dart';

class PairingState {
  const PairingState({this.busy = false, this.code, this.message, this.momUid});
  final bool busy;
  final PairingCode? code;
  final String? message, momUid;
}

class PairingViewModel extends Notifier<PairingState> {
  int _generation = 0;
  @override
  PairingState build() {
    ref.watch(sessionProvider.select((s) => s.value?.uid));
    _generation++;
    return const PairingState();
  }

  Future<bool> _perform(Future<PairingState> Function() run) async {
    if (state.busy) return false;
    final previous = state;
    final generation = _generation;
    state = PairingState(busy: true, code: previous.code);
    try {
      final next = await run();
      if (!ref.mounted || generation != _generation) return false;
      state = next;
      return true;
    } catch (e) {
      if (ref.mounted && generation == _generation) {
        state = PairingState(
            code: previous.code,
            message: e is AppException
                ? e.userMessage
                : 'Chưa ghép nối được. Thử lại nhé.');
      }
      return false;
    }
  }

  Future<bool> createCode() => _perform(() async =>
      PairingState(code: await ref.read(pairingServiceProvider).createCode()));
  Future<bool> redeem(String code) {
    if (state.busy) return Future.value(false);
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      state = const PairingState(message: 'Mã gồm 6 số. Ví dụ: 123456.');
      return Future.value(false);
    }
    return _perform(() async {
      final momUid = await ref.read(pairingServiceProvider).redeem(code);
      try {
        await ref.read(analyticsServiceProvider).logEvent('pair_device');
      } catch (_) {}
      return PairingState(momUid: momUid);
    });
  }

  Future<bool> revoke(String momUid, String childUid) => _perform(() async {
        await ref.read(pairingServiceProvider).revoke(momUid, childUid);
        return const PairingState(
            message:
                'Đã ngưng ghép nối. Người thân không còn xem hoặc sửa lịch được.');
      });
}

final pairingViewModelProvider =
    NotifierProvider<PairingViewModel, PairingState>(PairingViewModel.new);

final pairingLinksProvider = StreamProvider<List<PairingLink>>((ref) {
  ref.watch(sessionProvider);
  return ref.watch(pairingServiceProvider).watchCaregivers();
});
