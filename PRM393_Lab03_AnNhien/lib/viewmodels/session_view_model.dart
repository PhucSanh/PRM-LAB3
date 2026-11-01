import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/providers.dart';

/// Người đang đăng nhập (null = chưa đăng nhập). Router dùng để chặn màn.
final sessionProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});
