// Firebase Emulator thật (Auth/Firestore/Functions), project demo, không dùng cloud.
// Hai máy: --dart-define=DEMO_ROLE=elder hoặc caregiver.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'models/app_user.dart';
import 'models/user_profile.dart';
import 'router/app_router.dart';
import 'services/analytics_service.dart';
import 'services/crash_service.dart';
import 'services/firebase_profile_service.dart';
import 'services/messaging_service.dart';
import 'services/providers.dart';
import 'services/remote_config_service.dart';
import 'services/report_service.dart';
import 'services/session_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    const host =
        String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');
    const roleName = String.fromEnvironment('DEMO_ROLE', defaultValue: 'elder');
    if (!['elder', 'caregiver'].contains(roleName))
      throw const FormatException('DEMO_ROLE phải là elder hoặc caregiver.');
    final app = await Firebase.initializeApp(
        name: 'local-emulator',
        options: const FirebaseOptions(
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
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
    final profile = FirebaseProfileService(db, auth);
    await profile.ensureProfile(AppUser(
        uid: user.uid,
        displayName: roleName == 'elder' ? 'Bác thử' : 'Con thử'));
    final existing = await profile.watch(user.uid).first;
    final role = UserRole.values.byName(roleName);
    if (existing.role != null && existing.role != role)
      throw StateError(
          'Máy này đang có vai trò khác. Xoá dữ liệu app local hoặc dùng máy thứ hai.');
    await profile.setRole(user.uid, role);
    if (role == UserRole.elder) await profile.markOnboarded(user.uid);
    runApp(ProviderScope(overrides: [
      firestoreSdkProvider.overrideWithValue(db),
      authSdkProvider.overrideWithValue(auth),
      functionsSdkProvider.overrideWithValue(functions),
      initialRouteProvider.overrideWithValue(
          role == UserRole.elder ? '/account' : '/caregiver/pair'),
      sessionDataServiceProvider
          .overrideWithValue(FirebaseSessionDataService(db)),
      messagingServiceProvider.overrideWithValue(FakeMessagingService()),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
      remoteConfigServiceProvider.overrideWithValue(FakeRemoteConfigService()),
      reportServiceProvider.overrideWithValue(FakeReportService()),
      demoReportServiceProvider.overrideWithValue(FakeReportService()),
    ], child: const AnNhienApp()));
  } catch (e) {
    runApp(MaterialApp(
        home: Scaffold(
            body: SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                        'Chưa kết nối được môi trường local.\nKiểm tra emulator server và EMULATOR_HOST.\n$e'))))));
  }
}
