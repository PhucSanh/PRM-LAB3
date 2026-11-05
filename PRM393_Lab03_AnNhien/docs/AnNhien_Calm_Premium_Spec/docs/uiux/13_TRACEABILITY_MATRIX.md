# 13 — Requirement traceability & sign-off matrix

**Legend:** DOC = specified; CODE = requires implementation; QA = must verify; BLOCKED = requires real feature/decision. This bundle supplies **DOC only**. Do not mark CODE/QA passed based on spec alone.

| ID | Requirement | Spec | Source hot spot | Acceptance signal | Priority |
|---|---|---|---|---|---|
| DS-01 | Calm Premium single brand all roles | 01,02 | `lib/theme/*` | screenshot color/hierarchy + semantic tokens | P0 |
| DS-02 / TYPE-01 | Be Vietnam Pro v1.1.0 accessible typography; elderly body 24/600, floor 20/600; caregiver body 20/600, floor 18/600; shared defaults elderly | 02 TYPE-01, 09 typography gate | `app_theme.dart`, `pubspec.yaml`, all text consumers | computed size/weight + local 600/700 + Material fallbacks + wrap at scale ×2 pass; CODE/QA pending | P0 |
| DS-03 | Rounded icon system, dictionary | 03 | `app_icons.dart`, widgets | no mixed icon families | P0 |
| DS-04 | Botanical illustration restrained | 03 | onboarding/empty assets | licensed, not intrusive, clear | P1 |
| DS-05 | Subtle accessible motion | 03 | animations across widgets | reduced motion pass | P1 |
| IA-01 | Elderly Lịch/Hoạt động/Gia đình | 04,06 | `app_router.dart`, `app_shell.dart` | 3 tabs + branch preservation | P0 |
| IA-02 | Activity Explore/Saved/Habits hierarchy | 04,06 | `/habits`, activity screens | segments correct; no tab duplicates | P0 |
| IA-03 | Caregiver Lịch/Gợi ý/Gia đình | 04,07 | caregiver routes/shell | role-specific 3 tabs | P0 |
| IA-04 | Legacy URLs and notifications | 04,10 | router, notificationTarget | deep link regression passes | P0 |
| IA-05 | Dashboard untouched | README,10,11 | `today_screen.dart` | no changes to dashboard | P0 |
| CMP-01 | Button/input/navigation standard | 05 | `lib/widgets/*` | gallery + tests | P0 |
| CMP-02 | List-first / minimal cards | 01,05,06,07 | feature screens | visual review | P1 |
| CMP-03 | Loading/empty/error/feedback | 05,08 | state_views etc. | each screen tested | P0 |
| CMP-04 | Voice controls explicit + real behavior | 03,06,08 | `read_aloud_button.dart` | play/stop/retry tested | P1 |
| E-01 | Onboarding cohesive | 06 | `screens/onboarding/*` | flow end-to-end | P1 |
| E-02 | Calendar chronological + meaningful states | 06 | `/week` placeholder, task widgets | real data, day state preserved | P0 |
| E-03 | Explore + Saved available truthfully | 06 | new screens/repo gap | no fake catalog or sync | P1 / BLOCKED if no backend |
| E-04 | Habits migration same keys | 06,10 | `/habits`, HabitPalette | 9 keys, all legacy links work | P0 |
| E-05 | Family pairing and member states | 06,07 | `/family`, pairing service | no unauthorized user data | P0 |
| E-06 | Suggestion review + strong rejection logic | 06,07 | suggestion services/screens | reject doesn't reappear as forced suggestion | P0 |
| C-01 | Caregiver calendar/day/week/month | 07 | caregiver_schedule | date/view query preserved | P0 |
| C-02 | Create/review/sent task real status | 07 | caregiver_form/detail | no double submit | P0 |
| C-03 | Suggestion compose sends accurately | 07 | suggestion_compose | sent ≠ accepted | P0 |
| SH-01 | Settings/profile/account integrity | 08 | settings/account | persisted prefs, auth safe | P0 |
| SH-02 | Inbox deep link and unavailable state | 08 | inbox + router | cold/warm start tested | P0 |
| A11Y-01 | Accessible tap/text/contrast | 09 | all UI | AA-aligned audit, device testing | P0 |
| A11Y-02 | Semantics + TalkBack/VoiceOver | 09 | all controls | manual test pass | P0 |
| QA-01 | Flutter analyze/test/golden/integration | 09,11 | test/ | CI and screenshots | P0 |
| OPS-01 | Small PRs, explicit deviations | 10,11 | repo workflow | milestone reports | P0 |

## Sign-off checklist
- [ ] Product owner approved route migration / unresolved backend gaps.
- [ ] Designer/FE accepted semantic tokens and visual gallery.
- [ ] QA tested elder and caregiver critical flows.
- [ ] Legacy routes and notifications validated.
- [ ] Accessibility tested at scale=2 and with screen readers.
- [ ] Dashboard unchanged.
- [ ] Documented unresolved issues tracked explicitly rather than replaced with fake functionality.

## Out-of-scope change detection
Run diff against baseline for `lib/screens/today/today_screen.dart`. If touched, revert unless purely necessary compile fix independently approved; no visual/layout redesign. Do not delete `/today` route without full alias migration and deep-link tests.
