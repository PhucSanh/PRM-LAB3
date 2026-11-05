# 08 — Shared screens, settings, voice, system states

## S01 · Sign-in `/sign-in`
- Hierarchy: brand mark small, confident title, one sentence purpose, existing real provider sign-in choices, privacy help, troubleshooting.
- No forced decorative multi-card. Inputs and buttons use existing auth service; no fake Social login.
- States: session loading, authenticated redirect, wrong credentials, network error, canceled external Google OAuth, locked/permission denied where applicable.
- A11y: fields label+hint, password show/hide semantic state; keyboard focus order; no disappearing text when keyboard opens.

## S02 · Session `/session`
- Display short neutral loading/sync state, optional retry only if real retry supported. No endless spinner without an explanation when error has occurred.
- Routing based on role/profile/onboarding/pairing, respecting `AUTH_GUARD` demo flag; no redirect loop.

## S03 · Role `/role`
- Two clear options: người cao tuổi / người thân; each option uses one consistent outlined selection component, description of what role does.
- Selected state via icon + outline/fill + semantics, not color alone. `Tiếp tục` only when selected; persist through existing role service.
- Confirmation if role change has data-access implications; no invented role-switch.

## S04 · Account `/account`
- Header with avatar/initial and account email/name if present; list grouping `Thông tin tài khoản`, `Quyền riêng tư`, `Đăng xuất` etc. as supported.
- Destructive sign-out confirmed if necessary; session cleanup, permission/data isolation. No fake account-deletion button.

## S05 · Settings `/settings`
- List sections: `Hiển thị` (cỡ chữ, tương phản), `Thông báo` (if implemented), `Giọng đọc` where available, `Thông tin`, `Trợ giúp`, `Dữ liệu`, `Tài khoản`.
- Use `SwitchListTile` semantics/accessible switches, avoid interactive entire row and child control both triggering duplicate update.
- Current code has `display_settings.dart` and viewmodel: preserve persisted settings and existing high-contrast mode.
- Text size control must provide immediate readable preview and restore default; don't block OS accessibility scaling.

## S06 · Profile `/settings/profile`
- Existing profile data only; editable fields clearly labeled, visible save state and error feedback; no new data fields added solely for a prettier mockup.
- High contrast support and validation; avoid showing raw UID as the main title.

## S07 · Help `/settings/help`
- Simple searchable? Only if actual search exists; otherwise sectioned FAQ with heading and plain text.
- Show contact channel only if real supported destination. `Đọc nội dung` optional for long help text.

## S08 · Data/privacy `/settings/data`
- Explain storage and user control accurately based on implementation, no invented guarantees (e.g. 'everything only on device' if Firebase used).
- Clear destructive confirmation for remove/clear only if implemented and authorized.

## S09 · Inbox `/inbox` and suggestion detail `/inbox/suggestions/:id`
- Group notifications by meaningful date, title + concise preview + timestamp + unread indicator; color never sole unread signal.
- Tapping an item marks seen only according to actual repository behavior. Route to correct item; expired references show an informative state with way back.
- No automatic popup on every app open. User controls when to review, except critical system alerts if product explicitly requires.
- Distinguish notification (message) from suggestion decision state (pending/accepted/rejected).

## S10 · Read aloud reusable component `lib/widgets/read_aloud_button.dart`
- Trigger label `Đọc nội dung` or accessible icon+tooltip; when playing show `Dừng đọc` or `Tạm dừng` if API supports it.
- Text remains visible; voice never prerequisite to navigate/complete a task.
- Audio interruptions (call/background/new playback) handled by actual audio service or explicitly documented as feature gap.
- No automatic speech output on page mount; respect reduced motion even if play icon animates.

## S11 · System permission states
- Notifications permission: request after explanation, distinguish not requested/allowed/denied/permanently denied; give settings route if platform supports.
- Microphone: request at moment of voice feature use; explicit recording indicator; ability to stop/cancel.
- Any external device/system service unavailable: show next step, not a hanging loader.

## Shared state taxonomy
| State | UI | CTA | What NOT to do |
|---|---|---|---|
| Initial load | Skeleton matching expected shape or progress label | None by default | Flash fake content |
| Refreshing with data | Existing content + unobtrusive progress | Optional refresh | Clear everything to white |
| Empty (first-time) | Soft small illustration/icon, title, single sentence | One relevant action | Treat as error |
| Empty (filtered) | `Không tìm thấy kết quả phù hợp` | `Xóa bộ lọc` | Show unrelated results |
| Error (network) | Short explanation, preserve data where safe | `Thử lại` | Generic “Something went wrong” |
| Error (permission) | Why access unavailable | Back / request access if allowed | Leak protected data |
| Not found | `Nội dung này không còn khả dụng` | Back to parent | Crash on null ID |
| Saved/sent success | Explicit accurate status | Return or view details | Equate sent = accepted |
| Offline | If detected, offline message; cached state labeled | Retry when online | Promise changes synced without confirmation |
| Disabled | Explanation if relevant | None | Poor contrast for essential info |
| Unsaved changes | Confirm sheet/dialog | `Tiếp tục chỉnh sửa` / `Bỏ thay đổi` | Silent loss |

## Shared UI pattern: empty state
```
[Small decorative botanical graphic or meaningful simple icon]
[Headline: Chưa có hoạt động trong ngày này]
[One sentence: Các hoạt động đã lên lịch sẽ xuất hiện ở đây.]
[Optional CTA: Khám phá hoạt động]  // only if route exists
```
No inspirational slogans consuming full screens; no empty success confetti loop.

## Shared UI pattern: dialogs
- Confirm destructive: clear item and impact, primary/destructive label explicit (`Xóa hoạt động`), `Giữ lại` option. Focus correct in screen reader.
- For validation, prefer inline error to a modal.
- For permission, explain and use OS dialog; no coercive copy.

## Shared UX quality checklist
- Layout respects safe area, keyboard, device rotation, dynamic type.
- All forms preserve valid entries on save failure; Back from dirty form asks before discard.
- Touch targets sized independently from glyph size.
- Every list has loading/empty/error path; no TODO-only blank panel.
- Copy is vi-VN, friendly but adult and non-patronizing.

## Typography dependency — TYPE-01
Mọi chữ UI trên các màn/component thuộc tài liệu này phải dùng semantic tokens tại `02_VISUAL_TOKENS.md` → TYPE-01 (v1.1.0), gồm cả nhãn navigation, form, hint/error, dialog, loading/empty/placeholder và metadata. Không định nghĩa lại cỡ chữ/weight tại đây hoặc giảm chữ vì density. Shared chưa xác định vai trò dùng bộ elderly; layout phải wrap/scroll và tự tăng chiều cao theo chữ.
