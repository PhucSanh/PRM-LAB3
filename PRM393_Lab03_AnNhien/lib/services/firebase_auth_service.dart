import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import '../utils/app_error.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);
  final FirebaseAuth _auth;
  static Future<void>? _googleReady;

  AppUser? _map(User? user) => user == null
      ? null
      : AppUser(
          uid: user.uid,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );

  @override
  AppUser? get currentUser => _map(_auth.currentUser);
  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await (_googleReady ??= GoogleSignIn.instance.initialize());
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null) throw AppException.unknown;
      final result = await _auth
          .signInWithCredential(GoogleAuthProvider.credential(idToken: token));
      return _map(result.user)!;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AppException.cancelled;
      }
      if (e.description?.toLowerCase().contains('network') ?? false) {
        throw AppException.network;
      }
      throw AppException('Không thể đăng nhập Google. Bác thử lại nhé.',
          cause: e);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') throw AppException.network;
      if (e.code == 'operation-not-allowed') {
        throw const AppException(
            'Đăng nhập Google đang tạm tắt. Bác thử lại sau nhé.');
      }
      throw AppException('Không thể đăng nhập. Bác thử lại nhé.', cause: e);
    } on SocketException {
      throw AppException.network;
    } on PlatformException catch (e) {
      if (e.code == 'network_error') throw AppException.network;
      throw AppException('Không thể mở đăng nhập Google.', cause: e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // End Firebase session even if Google cleanup fails.
      await _auth.signOut();
      // Also clear Google state after a Firebase session restored on app launch.
      await (_googleReady ??= GoogleSignIn.instance.initialize());
      await GoogleSignIn.instance.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') throw AppException.network;
      throw AppException('Chưa thể đăng xuất. Bác thử lại nhé.', cause: e);
    } on GoogleSignInException catch (e) {
      throw AppException(
          'Đã đăng xuất, nhưng chưa thể xoá phiên Google trên máy.',
          cause: e);
    }
  }
}
