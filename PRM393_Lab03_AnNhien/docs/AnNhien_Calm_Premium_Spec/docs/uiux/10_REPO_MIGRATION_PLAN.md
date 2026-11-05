# 10 — Source-grounded migration plan (Flutter ZIP audit)

## Baseline provenance
Input ZIP: **`PRM-LAB3-feat-noti-demo.zip`**, repo folder `PRM393_Lab03_AnNhien/`, snapshot date shown in ZIP: **2026-11-04**. This is **read-only analysis**; no Flutter source is changed in this spec bundle. If Codex checkout differs from this snapshot, re-audit before editing.

### Existing architecture observed
- Flutter, `go_router: ^18.1.2`, `flutter_riverpod: ^3.4.3`; Firebase Core/Auth/Firestore/Messaging/RemoteConfig/Functions etc. in `pubspec.yaml`.
- Be Vietnam Pro is bundled under `assets/fonts/` and configured in `pubspec.yaml`; theme currently `lib/theme/app_theme.dart`.
- `lib/theme/app_colors.dart` already has ivory/green surfaces and high-contrast design; **evolve rather than throw away**.
- `lib/theme/app_icons.dart` uses `Icons.*_rounded` and `AppIcons` dictionary; standardize semantics and selection states, do not blindly install another library.
- `lib/theme/app_spacing.dart`: `AppSizes.minTarget=72`, `navBar=96`, `AppSpacing.betweenTargets=20`, and large defaults; migrate thoughtfully to role-specific density, not arbitrary blanket shrink.
- `lib/widgets/app_shell.dart`: 4 tabs: `Hôm nay`, `Lịch tuần`, `Thói quen`, `Gia đình`, hardcoded 2-line labels and `FittedBox.scaleDown`. Proposed 3-tab IA requires architecture change plus regression tests.
- `lib/router/app_router.dart`: `StatefulShellRoute.indexedStack` with four elderly branches `/today`, `/week`, `/habits`, `/family`; caregiver routes mostly outside shell. `authGuardEnabledProvider` default `false`; `initialRouteProvider` defaults `/today`.
- Reminder/notification listeners depend on current routing and `SuggestionPopupListener` active when branch index 0 (today). Migrating indices must NOT silently trigger suggestion popups in calendar; audit listener's intended placement and UX.
- Many paths currently use `FeaturePlaceholder` (task editor/date/repeat/scope, reminder detail, week/habits/family and other child routes). Do not label these production complete.
- `lib/screens/caregiver/` includes schedule/form/detail/pairing screens. Suggestion compose/review and inbox code exists. Keep services/providers/VM contracts.

## Current feature map (audit target)
| Current location | Current type | Target UX | Risk |
|---|---|---|---|
| `screens/today/today_screen.dart` | Real screen | **OUT OF SCOPE** (no redesign) | high if route accidentally removed |
| `screens/onboarding/{welcome,setup_profile,notifications,try_reminder,first_task}_screen.dart` | Real | E01–E05 | low-medium |
| `screens/sign_in/sign_in_screen.dart` | Real | S01 | auth-sensitive |
| `screens/account/{account,role,session}_screen.dart` | Real | S02–S04 | auth-sensitive |
| `screens/settings/{settings,profile,help,data}_screen.dart` | Real | S05–S08 | settings persistence |
| `screens/caregiver/{pairing,caregiver_schedule,caregiver_form,caregiver_detail}_screen.dart` | Real | C02–C06 | business transactions |
| `screens/suggestion/{suggestion_compose,suggestion_review}_screen.dart` | Real | C07/E13 | accept/reject semantics |
| `screens/firebase_demo/inbox_screen.dart` | Real | S09 | notification routing |
| `widgets/{task_widgets,habit_widgets,read_aloud_button,...}.dart` | Existing reusable UI | Component library | preserve input contracts |
| `router/app_router.dart` `/week` | Placeholder branch | E06 | new real screen needed |
| `router/app_router.dart` `/habits` | Placeholder branch | E08/E11 | new real screen needed |
| `router/app_router.dart` `/family` | Placeholder branch | E12/C08 | new real screen needed |
| `router/app_router.dart` `/today/add*` / `/today/task/:id*` | Placeholder descendants | E07/E14 | cannot promise create/edit without real backend glue |
| `router/app_router.dart` `/today/voice` | Placeholder | E15 | speech recognition feature gap |
| `router/app_router.dart` `/reminder/:taskId` | Placeholder | E15 | notification flow |

**Careful:** Some real underlying repositories/models/viewmodels exist even if a route is placeholder; Codex must inspect their interfaces before deciding a feature is missing.

## Migration plan — safe incremental PRs
### M0 · Baseline & compatibility audit (no production behavioral changes)
1. Enumerate routes, callsites `go`, `push`, `pop`, notification route strings, auth guard/session triggers, test references.
2. Confirm expected role, route inputs, providers for each spec screen; capture baseline screenshots/goldens.
3. Record blockers: absent real catalogue/saved backend, lack of voice recognition, unknown task-edit backend, Firebase security restrictions.
4. Define mapping table for old → canonical route, preserving external links.
**Deliverable:** audit report + approved migration plan; no mass edits.

### M1 · Foundations
1. Create semantic tokens (theme + elderly/caregiver density as defined) keeping `AppColors` backward-compatible during transition.
2. Apply TYPE-01 v1.1.0 from `02_VISUAL_TOKENS.md` as the only typography source; retain or increase accessible existing sizes rather than shrinking to the obsolete v1.0.0 table. Verify local 600/700 assets, shared/unknown-role elderly defaults, component fallback styles and wrapping at 200%. Align the icon dictionary; avoid font network dependency.
3. Update primitive button/input/list/dialog/status/voice styling + add gallery states.
4. Screenshot & contrast tests, no route behavior changes.
**Exit:** tokens used by new components; existing screens still compile.

### M2 · Shared screens
Update onboarding, login, roles, settings, profile, help/data, inbox/read-aloud. Preserve providers, form models, permissions and auth state. Capture a11y and golden tests.

### M3 · Navigation IA
1. Implement role-aware shell **separately** for elderly/caregiver with 3 top-level tabs.
2. Create elderly `/calendar`, `/activities`, `/family` screens/branches; caregiver `/caregiver/schedule`, `/caregiver/suggest`, caregiver family root.
3. Add legacy aliases `/week`, `/habits`, `/today` **after detailed reference audit**. `/today` UI remains untouched; legacy handling may redirect safely but must not force branch-index assumption.
4. Preserve branch child state and back behavior, notification deep links and `SuggestionPopupListener` intended behavior.
5. If auth guard disabled in demo, ensure navigation remains demonstrable without erroneous loops.
**Exit:** all shell and links open correct authorized root; no lost old notification links.

### M4 · Elderly features
Implement E06–E15 UI with real repositories. Prioritize calendar and activity taxonomy, then family, suggestion-review and task details. For feature gaps, show honest unavailable state and open issue; never fake database writes. Exclude `/today` dashboard changes.

### M5 · Caregiver features
Migrate C01–C09 using existing form/viewmodels, pairing and notification contracts. Caregiver calendar views/query params maintained. Add role coverage tests.

### M6 · QA, cleanup & merge
All P0 tests, screenreader, text-scale, navigation smoke, static analysis; remove obsolete **presentation** duplicates only after validating route aliases and imports; do not remove legacy Firebase functionality. Regression check no dashboard UI file changed.

## Compatibility hotspots & required tests
| Hotspot | Risk | Test |
|---|---|---|
| Branch indices `currentIndex == 0` | SuggestionPopupListener appears on wrong tab | Open each tab, notification arrival, assert desired behavior |
| Initial `/today` & `AUTH_GUARD` | Blank/root invalid when demo starts | Launch with guard true/false, with each role |
| `notificationTarget()` | Cold-start notification broken | Test every supported target string + invalid target |
| Firebase auth/session changes | stale user state across accounts | sign out/in as different user |
| `date/view` query caregiver | wrong day/month after navigation | open deep link, go detail and Back |
| `/habits/:key` | broken old links | test all habit keys |
| Task recurrence scope | editing too many instances | test single/series supported scenarios |
| Suggestion approve/reject | violates preference or false approval status | state transition tests |
| UI switching from 4 → 3 tabs | overflow and lost scroll | 320–430 width, 200% text, branch return |
| High-contrast settings | theme regression | widget golden light/high contrast |

## Scope boundaries / implementation restrictions
- This package supplies **design specification**, not source files to merge or a new architecture implementation.
- Change routing only after test inventory. Preserve all models (`task_item.dart`, `habit.dart`, `suggestion.dart`, etc.), Riverpod APIs, Firebase security/service calls.
- Do not “improve” by moving business logic from viewmodels into screens.
- If a new route requires a real backend feature absent, add a clearly named issue + safe affordance or defer; never substitute fake state.
- Preserve voice, notification, caregiver feature behavior, and privacy safeguards.
- No `/today` dashboard redesign. Test source diff for this file.
