import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO(B – Hiếu, ngày 1): sau `flutterfire configure`:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  runApp(const ProviderScope(child: AnNhienApp()));
}
