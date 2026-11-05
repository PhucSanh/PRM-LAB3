# 05 — Component architecture & component specification

## Nguyên tắc kiến trúc
**Layer 1 foundations:** color/typography/spacing/radius/motion/icon/semantic labels → **Layer 2 reusable primitives:** button, field, tile, badge, top bar, bottom bar, dialogs → **Layer 3 feature patterns:** schedule row, activity preview, saved row, caregiver task editor, suggestion status, family member, voice controller. Không implement business logic trong primitive theme components. Component accessibility là contract, không là optional decoration.

## Component variants
| Component / tên khuyến nghị | Visual spec | States & interactions | Accessibility contract |
|---|---|---|---|
| `AnPrimaryButton` | Forest filled, radius 16–20, height elderly ≥56, caregiver ≥48–56 | default/pressed/focused/loading/disabled/success | Label là động từ cụ thể; spinner có status; no double tap |
| `AnSecondaryButton` | Sage-soft filled hoặc restrained outline, **không** chiếm visual weight CTA | default/pressed/focused/disabled | contrast check, full label |
| `AnTextButton` | Chỉ cho tertiary action | focus/pressed/disabled | target ≥48 |
| `AnIconButton` | Tonal hoặc clear background | selected, badge, disabled | semantic/tooltip; target ≥48 |
| `AnAppBar` | Single title, max 2 actions, no noisy decorative line | root/child/scroll | back label, correct header hierarchy |
| `AnNavBar` | 3 evenly sized items, active pill, labels always | active/inactive/focus/badge | `selected`, current tab, spoken label |
| `AnSegmentedTabs` | Khám phá / Đã lưu / Thói quen: light selected pill/underline, accessible | selected, focus, loading | 3 items; can scroll horizontally with labels at 200% if needed, not clipped |
| `AnActivityRow` | Icon tint in small rounded tile; title, caption, action/status | scheduled/done/skipped/postponed | icon & state label combined, stable hit target |
| `AnScheduleSection` | Day/date group + list; dividers; no nested cards | empty/partial/complete | semantic group header |
| `AnSuggestionTile` | Title, sender, purpose, status + actions when eligible | unread/pending/accepted/rejected/expired | statuses explicitly named |
| `AnFamilyMemberTile` | Avatar/initial, name, relationship, primary action | connected/invited/offline/unavailable | no fabricated online presence |
| `AnTextField` | Persistent label, soft outline, help/error below | idle/focus/filled/error/disabled | input hint, correct keyboard & autofill |
| `AnTimeField` | Readable time + clock icon, opens native/picker | valid/invalid/readonly | verbal date/time, 24h localization |
| `AnSelectionCard` | One choice per row, radio/check semantics | selected/unselected/disabled | `RadioGroup` if exclusive, not fake buttons |
| `AnChip` | Subtle tinted filter, compact, scroll when needed | active/inactive/disabled | selected semantics, label not just color |
| `AnDialog` | Title + one concise description + clear CTAs | confirm/cancel/error | modal focus, explicit consequences |
| `AnBottomSheet` | Short contextual options, large targets | open/close/scroll | drag affordance not only dismiss |
| `AnFeedbackBar` | Short message + optional Undo | success/error/action | announcement; error not transient only |
| `AnEmptyState` | Small consistent illustration/icon, message, 0–1 CTA | empty catalog/no schedule/no family | readable, no no-op CTA |
| `AnErrorState` | Human description + Try again if possible | network/permission/not-found | error described, screen reader |
| `AnLoadingState` | Skeleton for lists or progress + label | loading/refreshing | accessible busy/status |
| `AnVoiceControl` | Clear play/pause/replay and speed only if supported | idle/playing/paused/error | text equivalent, no autoplay, stop control |
| `AnStatusBadge` | Faint background + fg icon + short label | pending/done/rejected/etc | distinguish without color |

## Screen anatomy
```
SafeArea
 ├─ AppBar(title, optional 1–2 actions)
 ├─ Optional sticky secondary control (date selector / segment)
 ├─ Scrollable main content (headers → list or form)
 ├─ Optional bottom primary action (safe area, sticky only where useful)
 └─ Role-specific adaptive shell navigation (only at top-level roots)
```

## Component design rules
1. At most one visually dominant filled CTA in a task context. If dangerous/destructive: confirmation and error styling distinct.
2. `ListTile` or custom list row for repeating items; card only when context is grouped/independent. No card-in-card-in-card.
3. Space creates hierarchy before borders/shadows. Limit display illustrations to onboarding/empty/success.
4. Button labels: `Lưu hoạt động`, `Gửi gợi ý`, `Thử lại`, not `OK`, `Xác nhận` everywhere.
5. Loading on buttons disables rapid re-submit but never suppresses errors. For long operations show cancellable action only if backend can cancel.
6. Interactive control has >=48dp hitbox and semantic label; text content adapts to 200% scaling.
7. Dates/times localized `vi-VN`; colors via semantic tokens; no theme-specific literal hex in component consumers.
8. Non-decorative SVG assets accessible semantics; decorative images excluded.

## Flutter integration with existing repo
Existing primitives to **review and migrate**, not blindly replace:
`lib/widgets/app_button.dart`, `app_text_field.dart`, `app_back_bar.dart`, `app_shell.dart`, `choice_group.dart`, `confirm_dialog.dart`, `form_parts.dart`, `habit_widgets.dart`, `icon_circle.dart`, `nav_row.dart`, `read_aloud_button.dart`, `section_card.dart`, `state_views.dart`, `suggestion_card.dart`, `switch_row.dart`, `task_widgets.dart`, `time_field.dart`, `undo_snackbar.dart`; design sources `lib/theme/app_colors.dart`, `app_spacing.dart`, `app_icons.dart`, `app_theme.dart`, `display_settings.dart`.

Prefer evolving these components to avoid duplicate design systems. `lib/widgets/dev/widget_gallery.dart` should showcase each primitive + variants + elderly/caregiver density + high contrast/text scale; debug-only.

## State matrix for high-risk actions
| Flow | Idle | In progress | Success | Failure |
|---|---|---|---|---|
| Save scheduled activity | `Lưu hoạt động` | disabled button + progress | route back/result, optional Undo if supported | inline validation / retry, form preserved |
| Send suggestion | `Gửi gợi ý` | progress, no duplicate | `Đã gửi` (**not** `Đã thêm vào lịch`) | retry, draft preserved |
| Accept suggestion | `Đồng ý` | saving | precise accepted state | retry and no false optimistic success |
| Mark done | `Đã hoàn thành` action | updating | explicit status + undo if supported | restore prior state + actionable error |
| Pair member | `Kết nối` | validating | identity visible | expired/invalid code guidance |
| Read aloud | `Đọc nội dung` | loading playback | playing/pause/stop state | text remains available |

## Anti-patterns MUST NOT introduce
- `Container` elevation and border wrapping every list item.
- Fake search bar or fake filters without actions.
- Using no-op `onPressed: () {}` / dummy lorem data in production.
- Replacing semantic radio/switch with visually painted `GestureDetector` lacking semantics.
- Text `maxLines: 1` on essential titles/actions, `FittedBox` hiding overflow, disabling scaling.
- 72dp icon size inside 72dp target; icon is visually ~24–32dp.
