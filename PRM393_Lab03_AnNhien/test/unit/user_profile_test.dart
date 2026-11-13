import 'package:an_nhien/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile Model Unit Tests', () {
    test('1. fromMap parses valid elder and caregiver roles correctly', () {
      final elderProfile = UserProfile.fromMap('uid_01', {
        'displayName': 'Bác Lan',
        'role': 'elder',
        'onboarded': true,
      });
      expect(elderProfile.uid, 'uid_01');
      expect(elderProfile.displayName, 'Bác Lan');
      expect(elderProfile.role, UserRole.elder);
      expect(elderProfile.onboarded, isTrue);

      final caregiverProfile = UserProfile.fromMap('uid_02', {
        'displayName': 'Chị Hoa',
        'role': 'caregiver',
        'onboarded': false,
      });
      expect(caregiverProfile.role, UserRole.caregiver);
      expect(caregiverProfile.onboarded, isFalse);
    });

    test('2. fromMap throws FormatException when unrecognized role is provided', () {
      expect(
        () => UserProfile.fromMap('uid_03', {'role': 'administrator'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('3. copyWith updates role and onboarded status while preserving uid', () {
      const original = UserProfile(
        uid: 'uid_04',
        displayName: 'Bác Hùng',
        role: UserRole.elder,
        onboarded: false,
      );
      final updated = original.copyWith(onboarded: true);
      expect(updated.uid, 'uid_04');
      expect(updated.displayName, 'Bác Hùng');
      expect(updated.onboarded, isTrue);
    });
  });
}\n