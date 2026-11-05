# TYPE-01 v1.1.0 — implementation and verification

Date: 2026-11-05. Scope: typography and layouts needed to retain readable text; this is not completion of the full Calm & Premium UI migration.

## Implementation

- `lib/theme/app_typography.dart` contains the two role text themes. Elderly: page title 30/700, task title 24/700, body 24/600, secondary 22/600, button 22/700, tab 20/700, caption 20/600. Caregiver: body 20/600, minimum 18/600. Existing local Regular/SemiBold/Bold assets retained; no dependencies added.
- `AppTheme` maps all 15 TextTheme slots, inputs/helper/error/counter, lists, chips, tabs, tooltip, dialogs, date/time pickers and navigation labels to the role themes. Shared/unknown-role UI defaults elderly; `AnNhienApp` derives caregiver styling from the resolved session profile, not the route. Sign-out returns to elderly defaults.
- Essential button and navigation labels wrap at their intended size. AppShell keeps its existing four branches for this typography milestone; it no longer scales labels down. Navigation migration to three tabs remains separate.
- `AppBackBar.adaptive(context, ...)` measures text to reserve its preferred height before Scaffold layout. It stacks Back and the step/action when they do not fit side by side. Production callers and gallery previews use this constructor; future callers should too.
- Time grids reduce column count when the rendered digits/labels need more room; cells grow vertically. Caregiver calendar uses horizontal scrolling when seven readable date columns cannot fit. No `FittedBox` remains in `lib/`.
- Suggestion review and profile pin the primary action while supporting text scroll for content, errors and secondary actions. This avoids a footer of multiple large buttons consuming the reading area, including with the keyboard open.
- Debug widget gallery now previews both roles and supports the existing scale/high-contrast controls. Sample data stays in the existing debug/test context.

## Compatibility

No route, notification payload, Firebase/service/model/provider semantics or reminder behavior changed. No edits to `lib/screens/today/today_screen.dart`; shared text/button/navigation presentation changes affect it indirectly and its regression tests pass. No Figma file changed.

The pre-existing app text-scale ceiling of 2.0 in `app.dart` remains; this work does not claim support for larger effective scales. Existing user font-size and high-contrast preferences are preserved. Compact caregiver control targets have not been globally reduced; existing 72dp controls remain accessible.

## Verification

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub --update-goldens --reporter expanded`: **701 tests passed**. Four new golden references were created, not treated as a comparison against an earlier design.
- `flutter test --no-pub test/typography_test.dart --plain-name 'typography golden' --reporter expanded`: **4 tests passed** against those references without updates.
- New tests check actual rendered styles/input styles for both roles, light/high contrast, widths 320/360/390/430dp and scales 1.0/1.3/1.6/2.0. They also check shared unknown-role fallback, resolved caregiver profile and reset on sign-out.
- Four golden PNGs under `test/goldens/`: both roles at 390dp and scales 1.0/2.0, loading the actual local Be Vietnam Pro and Material Icons fonts. Visually reviewed for legibility and wrapping; at 2.0 the remaining content is below the viewport and scrollable, not shrunk.
- Existing tests needing interaction with content now below the viewport scroll it into view and settle before tapping.
- `git diff --check`: passed.
- Android smoke: `flutter run --no-pub -d emulator-5554 -t lib/main_dev.dart --dart-define=INITIAL_ROUTE=/dev/widgets` built and launched successfully on Android 17 / API 37 x86_64. Reviewed the real gallery at its default size and ×2.0, scrolled the content, and observed no Flutter overflow/error in that smoke session. Dart DEV providers use existing Fake services; this is not verification of production Firebase flows.
- Android screenshots: `docs/evidence/typography/android-gallery-default.png` and `android-gallery-2x.png`. Flutter CLI detached after inspection, leaving the gallery available on the emulator.

## Remaining validation

TalkBack/VoiceOver, physical-device testing, production Firebase smoke flows and formative testing with older adults have not been performed. Do not mark these complete from widget/golden tests. Full navigation/screen redesign from the spec remains outside this typography milestone.

References consulted: [Flutter UI design and styling](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling) and [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing).
