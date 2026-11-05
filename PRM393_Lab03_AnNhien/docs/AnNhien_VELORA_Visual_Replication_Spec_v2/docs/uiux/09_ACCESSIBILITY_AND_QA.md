# 09 — Accessibility, responsive & QA acceptance

## Standards & interpretation
Target **WCAG 2.2 AA** as guideline, plus Flutter accessibility guidance and real-device testing. Note WCAG is authored for web; its principles adapt to mobile, and accessibility testing on Flutter widgets requires platform-specific checks. Recommended **Android tap target >=48×48 dp**; **iOS >=44×44 pt**; senior primary control target preferably >=56dp and retain larger existing limits if required by coursework. Normal text >=4.5:1 contrast, large text >=3:1; meaningful non-text UI indicator >=3:1 where applicable. Text resize to 200% without loss of essential information or functionality. Do not confuse these with “all icons must be giant”.

**Official references (read on implementation day):**
- Flutter accessibility: https://docs.flutter.dev/ui/accessibility
- Flutter accessibility UI design: https://docs.flutter.dev/ui/accessibility/ui-design-and-styling
- Flutter widget accessibility tests: https://docs.flutter.dev/ui/accessibility/accessibility-testing
- W3C WCAG 2.2: https://www.w3.org/TR/WCAG22/
- Android navigation patterns: https://developer.android.com/design/ui/mobile/guides/layout-and-content/layout-and-nav-patterns

## Mandatory scenarios
| ID | Check | Pass criteria |
|---|---|---|
| A11Y-01 | Text scale 1.0, 1.3, 1.6, 2.0 | No clipped heading, CTA, nav label; content scrollable |
| A11Y-02 | Android 48dp; iOS 44pt | All controls tappable within guidelines |
| A11Y-03 | TalkBack elder flow | Announces headings, tab selected, date, action results |
| A11Y-04 | VoiceOver iOS flow | Same content/order; dialog focus returns correctly |
| A11Y-05 | Color contrast | All normal text >=4.5; large text >=3; UI icons/indicator audit |
| A11Y-06 | Grayscale/color vision | No state identifiable by color alone |
| A11Y-07 | Reduced motion | No essential information hidden in animation, reduced movement |
| A11Y-08 | Keyboard/focus | Focus order correct, fields don't hide, input persistent on error |
| A11Y-09 | Screen size 320 / 360 / 390 / 430 logical width | No overflow, bottom nav labels visible |
| A11Y-10 | 600 / 800 / 1024 logical width | Adaptive nav, not giant stretched forms |
| A11Y-11 | Deep link cold start / warm start | Opens correct role-allowed route with Back recovery |
| A11Y-12 | Sign out → sign in another account | No stale member/task data shown |
| A11Y-13 | Airplane / offline / permission denied | Honest states, no stuck loading or false success |
| A11Y-14 | Long Vietnamese diacritics / real long titles | No silent ellipsis on essential content |
| A11Y-15 | Date/time locale vi-VN | Correct weekday, date and 24h time in UI/semantics |
| A11Y-16 | Voice interrupted / replay | State and text remain intelligible |

## Test architecture (Flutter)
- Widget tests: `meetsGuideline(androidTapTargetGuideline)`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` where supported; assert semantics using actual widgets.
- Golden tests: each major screen at representative phone widths, elderly/caregiver, standard vs large text, high contrast; use fixed seeded TEST state (not production fake backend).
- Integration tests: role redirects, tab stack preservation, notification route, add/edit success/failure, pairing, suggestion accept/reject where service mock/fake available.
- Device manual tests: Android TalkBack and iOS VoiceOver, keyboard, gesture navigation, system larger fonts, landscape, system permission prompts.
- `flutter analyze`, `flutter test` are minimum CI; `flutter test integration_test` if environment supports emulator.

## Design-level QA checklist
- No more than one dominant filled primary CTA per task context.
- Icons follow dictionary and visual family. No unexpected emoji icons.
- Brand color applied via theme tokens, no scattered `Color(0x...)` in screens.
- Background ivory, cards rare, shadows soft, white space coherent.
- Content and statuses correctly localized; `Đã gửi` not `Đã đồng ý`.
- No blank placeholder disguised as finished feature.
- Bottom navigation 3 tabs per role, labels visible at 200% scale.
- Legacy links not broken; dashboard untouched.

## User testing — required before claiming “UX đã tối ưu”
Recruit 5–8 representative older users with varied phone familiarity and 3–5 caregivers as *formative usability testing* if feasible; these numbers are planning guidance, not a validated statistical sample. Observe unaided attempts to locate today's planned task, find a habit, save/plan an activity, open family connection, send/review suggestion. Record task success, error points, time, comprehension, qualitative feedback; no invented satisfaction scores. Revisit icon metaphors, labels and font size based on results.

## Exit criteria
1. Every scope screen has a reviewed spec mapping and implementation state.
2. Zero P0 navigation bugs or lost-data flows; zero missing critical accessible labels.
3. All responsive baselines verified on emulator or device; text scale ×2 reviewed.
4. All new or changed components represented in widget gallery.
5. Route aliases and notification compatibility tests pass.
6. User-facing copy audited, errors actionable; no fictional backend behavior.
