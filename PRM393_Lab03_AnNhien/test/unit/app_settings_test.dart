import 'package:an_nhien/models/app_settings.dart';
import 'package:an_nhien/theme/display_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings Model Unit Tests', () {
    test('1. default constructor initializes with large font and vibration enabled', () {
      const settings = AppSettings();
      expect(settings.fontScale, AppFontScale.lon);
      expect(settings.highContrast, isFalse);
      expect(settings.readAloud, isFalse);
      expect(settings.vibrate, isTrue);
    });

    test('2. copyWith selectively updates highContrast and readAloud flags', () {
      const settings = AppSettings();
      final updated = settings.copyWith(highContrast: true, readAloud: true);
      expect(updated.highContrast, isTrue);
      expect(updated.readAloud, isTrue);
      expect(updated.fontScale, settings.fontScale);
      expect(updated.vibrate, settings.vibrate);
    });

    test('3. toMap serializes fontScale factor to expected double representation', () {
      const standardSettings = AppSettings(fontScale: AppFontScale.vua);
      expect(standardSettings.toMap()['fontScale'], AppFontScale.vua.factor);

      const extraLargeSettings = AppSettings(fontScale: AppFontScale.ratLon);
      expect(extraLargeSettings.toMap()['fontScale'], AppFontScale.ratLon.factor);
    });
  });
}\n