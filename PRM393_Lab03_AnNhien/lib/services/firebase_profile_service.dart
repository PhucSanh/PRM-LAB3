import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/user_profile.dart';
import '../utils/app_error.dart';
import 'profile_service.dart';

class FirebaseProfileService implements ProfileService {
  FirebaseProfileService(this.db, this.auth);
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  DocumentReference<Map<String, dynamic>> _document(String uid) {
    if (auth.currentUser?.uid != uid) {
      throw const AppException('Phiên đăng nhập đã thay đổi.');
    }
    return db.collection('users').doc(uid);
  }

  AppException _error(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseException &&
        ['unavailable', 'deadline-exceeded', 'network-request-failed']
            .contains(error.code)) {
      return AppException.network;
    }
    return AppException('Chưa tải được tài khoản. Bác thử lại nhé.',
        cause: error);
  }

  @override
  Future<void> ensureProfile(AppUser user) async {
    try {
      final doc = _document(user.uid);
      // Existing accounts remain usable offline. A missing account must be
      // created by a transaction so concurrent sign-ins cannot reset role/setup.
      try {
        final cached = await doc.get(const GetOptions(source: Source.cache));
        if (cached.exists) return;
      } on FirebaseException catch (error) {
        if (error.code != 'unavailable' && error.code != 'not-found') rethrow;
      }
      await db.runTransaction((transaction) async {
        final existing = await transaction.get(doc);
        if (!existing.exists) {
          transaction.set(doc, {
            'displayName': user.displayName,
            'photoUrl': user.photoUrl,
            'role': null,
            'onboarded': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (error) {
      throw _error(error);
    }
  }

  @override
  Stream<UserProfile> watch(String uid) async* {
    try {
      await for (final snapshot in _document(uid).snapshots()) {
        if (auth.currentUser?.uid != uid) return;
        final data = snapshot.data();
        if (data == null) throw const AppException('Chưa tìm thấy tài khoản.');
        yield UserProfile.fromMap(uid, data);
      }
    } catch (error) {
      throw _error(error);
    }
  }

  @override
  Future<void> setRole(String uid, UserRole role) async {
    try {
      final doc = _document(uid);
      await db.runTransaction((transaction) async {
        final snapshot = await transaction.get(doc);
        final data = snapshot.data();
        if (data == null) throw const AppException('Chưa tìm thấy tài khoản.');
        final current = UserProfile.fromMap(uid, data);
        if (current.role != null && current.role != role) {
          throw const AppException('Tài khoản đã chọn vai trò.');
        }
        transaction.update(doc, {'role': role.name});
      });
    } catch (error) {
      throw _error(error);
    }
  }

  @override
  Future<void> markOnboarded(String uid) async {
    try {
      final doc = _document(uid);
      await db.runTransaction((transaction) async {
        final snapshot = await transaction.get(doc);
        if (snapshot.data()?['role'] != UserRole.elder.name) {
          throw const AppException('Bác cần chọn vai trò trước.');
        }
        transaction.update(doc, {'onboarded': true});
      });
    } catch (error) {
      throw _error(error);
    }
  }
}
