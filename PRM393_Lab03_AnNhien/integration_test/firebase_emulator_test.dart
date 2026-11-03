import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/services/firebase_caregiver_schedule_service.dart';
import 'package:an_nhien/services/firebase_pairing_service.dart';
import 'package:an_nhien/services/firebase_profile_service.dart';
import 'package:an_nhien/services/firebase_repositories.dart';
import 'package:an_nhien/services/firebase_settings_service.dart';
import 'package:an_nhien/services/firebase_suggestion_service.dart';
import 'package:an_nhien/services/caregiver_schedule_service.dart';
import 'package:an_nhien/services/profile_setup_service.dart';
import 'package:an_nhien/theme/display_settings.dart';
import 'package:an_nhien/utils/app_error.dart';

class LocalAccount {
  LocalAccount(this.app, this.auth, this.db, this.client);
  final FirebaseApp app;
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseCallableClient client;
  String get uid => auth.currentUser!.uid;
  FirebaseUserData get data => FirebaseUserData(db, auth);
  FirebasePairingService get pairing => FirebasePairingService(client, data);
  static Future<LocalAccount> create(String name, UserRole role) async {
    const host =
        String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');
    final app = await Firebase.initializeApp(
        name: name,
        options: const FirebaseOptions(
            // Synthetic format-only key: usable exclusively with local emulators.
            apiKey: 'AIzaSy000000000000000000000000000000000',
            appId: '1:123456789:android:0123456789abcdef',
            messagingSenderId: '123456789',
            projectId: 'demo-an-nhien'));
    final auth = FirebaseAuth.instanceFor(app: app),
        db = FirebaseFirestore.instanceFor(app: app);
    final functions =
        FirebaseFunctions.instanceFor(app: app, region: 'asia-southeast1');
    await auth.useAuthEmulator(host, 9099);
    db.useFirestoreEmulator(host, 8080);
    functions.useFunctionsEmulator(host, 5001);
    // Emulator-only anonymous account. Never reaches a real Firebase project.
    await auth.signOut();
    await auth.signInAnonymously();
    final profile = FirebaseProfileService(db, auth);
    await profile.ensureProfile(
        AppUser(uid: auth.currentUser!.uid, displayName: 'Tài khoản local'));
    await profile.setRole(auth.currentUser!.uid, role);
    return LocalAccount(app, auth, db, FirebaseCallableClient(functions));
  }

  Future<void> close() async {
    await db.terminate();
    await app.delete();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'native Firebase: two accounts pair, schedule, accept, status per day, revoke',
      (tester) async {
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final mom = await LocalAccount.create('mom-$suffix', UserRole.elder);
    final child =
        await LocalAccount.create('child-$suffix', UserRole.caregiver);
    final stranger =
        await LocalAccount.create('stranger-$suffix', UserRole.caregiver);
    try {
      final code = await mom.pairing.createCode();
      expect(code.code, hasLength(6));
      await expectLater(
          child.pairing.redeem('000000'), throwsA(isA<AppException>()));
      expect(await child.pairing.redeem(code.code), mom.uid);
      await expectLater(
          child.pairing.redeem(code.code), throwsA(isA<AppException>()));
      final profile = await FirebaseProfileService(child.db, child.auth)
          .watch(child.uid)
          .firstWhere((p) => p.pairedMomUid != null);
      expect(profile.pairedMomUid, mom.uid);
      final settings = FirebaseSettingsService(mom.data);
      await settings.setFontScale(AppFontScale.ratLon);
      await settings.setHighContrast(true);
      expect(
          (await settings.watch().firstWhere((s) => s.highContrast)).fontScale,
          AppFontScale.ratLon);
      await FirebaseProfileSetupService(mom.data).saveSetup(
          mom.uid,
          const ProfileSetup(
              displayName: 'Bác thử',
              honorific: Honorific.ba,
              wakeHour: 6,
              wakeMinute: 30));
      final today = DateTime.now().toUtc().add(const Duration(hours: 7));
      final task = TaskItem(
          id: 'native-walk',
          title: 'Đi bộ native',
          habitKey: 'move',
          hour: 8,
          minute: 0,
          startDate: dateKey(today));
      final schedule = FirebaseCaregiverScheduleService(child.data);
      await schedule.create(mom.uid, task);
      expect(
          (await schedule.watch(mom.uid, today, today).first).single.task.title,
          'Đi bộ native');
      await expectLater(
          FirebaseCaregiverScheduleService(stranger.data).templates(mom.uid),
          throwsA(isA<AppException>()));
      final repo = FirebaseTaskRepository(mom.data);
      await repo.setStatus(task.id, TaskStatus.done);
      expect((await repo.tasksForDay(today)).single.status, TaskStatus.done);
      expect(
          (await repo.tasksForDay(today.add(const Duration(days: 1))))
              .single
              .status,
          TaskStatus.pending);
      final sender = FirebaseSuggestionService(child.data, child.client),
          receiver = FirebaseSuggestionService(mom.data, mom.client);
      await sender.send(mom.uid, 'native-suggestion',
          [task.copyWith(id: 'a', hour: 10), task.copyWith(id: 'b', hour: 15)]);
      final pending = await receiver
          .watchPending()
          .firstWhere((list) => list.any((s) => s.id == 'native-suggestion'));
      expect(pending.single.tasks.length, 2);
      await receiver.resolve('native-suggestion', [1],
          times: {1: (hour: 16, minute: 30)});
      final received = (await repo.tasksForDay(today))
          .where((t) => t.id == 'suggestion-native-suggestion-1')
          .single;
      expect(received.hour, 16);
      expect(received.minute, 30);
      await expectLater(receiver.resolve('native-suggestion', [1]),
          throwsA(isA<AppException>()));
      final edit = await schedule.change(
          mom.uid, task, today, task.copyWith(hour: 7), ChangeScope.future);
      expect(
          (await schedule.templates(mom.uid))
              .where((t) => t.id == task.id)
              .single
              .endDate,
          isNotNull);
      expect(
          (await repo.tasksForDay(today))
              .where((t) => t.completionSourceId == task.id && t.hour == 7)
              .single
              .status,
          TaskStatus.done,
          reason: 'Splitting a series must preserve the completed occurrence.');
      await schedule.undo(edit);
      await mom.pairing.revoke(mom.uid, child.uid);
      await expectLater(
          schedule.templates(mom.uid), throwsA(isA<AppException>()));
    } finally {
      await mom.close();
      await child.close();
      await stranger.close();
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
