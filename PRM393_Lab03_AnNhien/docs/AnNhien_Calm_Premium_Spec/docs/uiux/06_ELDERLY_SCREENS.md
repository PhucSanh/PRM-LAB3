# 06 — Elderly screen-by-screen specification

> **Phase scope excludes `/today` dashboard**. Elderly entry after auth/onboarding should route into **Lịch** once compatibility is verified. No new dashboard proposed.

## Standard screen template
Every feature below must specify in implementation review: **route**, **purpose**, **app bar**, **content order**, **primary CTA**, **secondary actions**, **state handling** (loading/empty/error), **Back**, **a11y**, **backend availability**, **analytics** (only if existing instrumentation permits). No fake datasets.

## E01 · Welcome `/welcome`
- Purpose: 1 value proposition, reassuring introduction; illustration botanical/people age-respectful, no stereotypical frailty.
- Content order: brand mark → greeting title → one short explanatory paragraph → illustration (not cover entire viewport) → `Bắt đầu` CTA.
- Visual: ivory background, forest button, large warm title, one accent illustration, no competing CTA.
- Interaction: proceed to existing setup flow; back/exit as appropriate. Support compact height scrolling.
- Empty/error: not normally; if onboarding state load fails show retry rather than stuck splash.
- Accessibility: label for brand, image decorative unless conveys information; screen reader heading order correct.

## E02 · Setup profile `/setup`
- Purpose: nhập tên xưng hô, thói quen sinh hoạt có thật trong current model; không tự thu thêm thông tin nhạy cảm.
- Content: progress indicator (`Bước 1/…`), concise title, clearly labeled inputs, example/hint, single sticky `Tiếp tục` with safe area.
- Keyboard: form scrollIntoView; retain input on validation failure; avoid required fields not in business rules.
- Errors: field-level explanation; back retains draft; unsaved confirmation if necessary.

## E03 · Permissions `/setup/notifications`
- Purpose: giải thích **vì sao** cần notifications trước OS prompt; `Cho phép thông báo` and `Để sau` where backend permits.
- Do not falsely say notifications enabled if denied; show route to device settings for permanently denied.
- Inform: reminders may be affected by permission; do not force consent as condition unless requirement demands it.

## E04 · Try reminder `/setup/try-reminder`
- Purpose: walkthrough/test reminder with honest actual permission/status.
- Content: illustration small, explanation, `Thử lời nhắc` only when service works, actual status + retry.
- No fabricated reminder-fired confirmation. Voice optional; no auto TTS.

## E05 · First task `/setup/first-task`
- Purpose: first meaningful activity if current onboarding supports it.
- Choose existing activity options instead of blank complex form; if service unavailable explicit guided empty state.
- Success routes into Lịch showing corresponding scheduled item if backend recorded it; no fake success.

## E06 · Lịch root (proposed `/calendar`, legacy `/week`)
- Hero: compact page heading `Lịch` + optional Inbox/Settings icon buttons, no duplicate giant slogan.
- Date control: today shortcut, current selected date, previous/next day or week as supported; do not rely on swipe-only gestures.
- Information hierarchy: selected date → accessible day summary → grouped scheduled activities ordered by local time → one relevant creation action if feature implemented.
- Schedule row: time (e.g. `08:00`), semantic activity icon, title, optional duration, exact status (Chưa làm / Đã hoàn thành / Đã dời / Bỏ qua), chevron to detail.
- List-first: neutral page, subtle divider not individual giant shadows. Completed items less prominent but readable, never low contrast.
- States: `Chưa có hoạt động nào cho ngày này` + action to browse activities if route implemented; partial data and offline explicit; loading skeleton height stable.
- Behaviors: changing date keeps selected date when visit child and return; restored state on tab revisit; screen reader announces date selected.
- Privacy: do not expose unrelated caregiver data.

## E07 · Lịch detail `/calendar/task/:id` (legacy `/today/task/:id`, `/week/:date/task/:id`)
- Purpose: review scheduled instance, including date/time and repeat rule if present.
- Content: title, schedule metadata, activity description/notes, status, reminder, owner/sender when authorized; actual data only.
- Primary action context-dependent (`Hoàn thành` for pending), secondary `Dời`, `Bỏ qua`, `Sửa` based on permissions.
- Destructive/change operations confirm consequences and repeat scope; optimistic change needs rollback/Undo.
- Empty/not found: `Không tìm thấy hoạt động này` + `Quay lại Lịch`, avoid blank placeholder.

## E08 · Hoạt động root (proposed `/activities`)
- App bar `Hoạt động`, no dashboard summary.
- Secondary segmented nav: **Khám phá · Đã lưu · Thói quen**. Persist selected section when moving between tabs and details.
- Visual: contextual title short; optional search if truly implemented; list-first and simple category chips.
- If catalogue/saved repository unavailable: accessible, honest empty state and route to other working sections; do **not** generate mock content or invent API methods.
- Deep-link canonical section parameter optional; must support opening `/habits` legacy into `Thói quen`.

## E09 · Khám phá segment `/activities?section=explore`
- Purpose: browse relevant activities; show suggestions appropriate for older adults when user profile exists.
- Row: recognisable activity icon/thumbnail if licensed, title, brief benefit, duration if known, clear `Xem chi tiết` or row clickable.
- Filters: at most a few meaningful categories from actual model, no “AI suggested” label unless actually personalized.
- Detail: synopsis, suitability/effort details if known, two distinct actions `Lưu hoạt động` and `Đặt vào lịch` (only if supported).
- Personalization: previously **strongly rejected** activity should not reappear as positive recommendation; preserve existing preference/rejection semantics, don't fabricate scoring.
- No results: explain current filter, `Xóa bộ lọc` if applicable.

## E10 · Đã lưu segment `/activities?section=saved`
- Purpose: library/bookmarks, **not** scheduled or completed tasks.
- Row: same base component as Explore with saved status; remove saved with Undo if repository permits; date scheduling separate.
- Empty: `Chưa có hoạt động được lưu` + action `Khám phá hoạt động` (switch segment).
- Persistence: only claim saved after actual write success. If saved feature not implemented in repo, mark as feature gap; no local fake state represented as synced data.

## E11 · Thói quen segment `/activities?section=habits` (legacy `/habits`)
- Show actual **9 habit categories** from `HabitPalette`/habit model with consistent semantic icons and soft tint.
- Layout: high readability list or restrained two-column layout **only when** 200% scaling remains usable; default list strongly preferred.
- Each entry: category name, short explanation, chevron. Don't show invented streak/counters unless real.
- Detail legacy `/habits/:key`: overview, existing related activities if available, actionable next step; no loop of “card > card”.
- Remember: UI grouping does not mutate Habit keys/Firestore schema.

## E12 · Gia đình `/family`
- Purpose: who is connected, help/contact if existing functionality allows, invitation/pairing.
- Content: heading, summary of connection, list with name + relation + accessible action, invitation/pairing next step.
- States: not paired / paired / loading / failed / revoked; **never invent online presence**.
- Privacy/consent: do not expose private info or enable contact action without phone permission/service and verified data.
- Child routes (`/family/add`, member details) follow existing business capabilities and route inventory.

## E13 · Suggestion review (legacy `/today/suggestions/:id`)
- Purpose: see a caregiver-sent suggestion and choose using user autonomy.
- Content: sender identity where available, activity title, description, time, reason for suggestion if present, permissions and consequences.
- Primary `Đồng ý` or `Thêm vào lịch` only if backend action exact; secondary `Để sau`/`Từ chối` when supported.
- When **strong rejection** is stored, recommendation system must honor rejection; distinguish simple dismiss from explicit negative preference.
- States: pending, accepted, rejected, expired, deleted, already acted; no double submit, no misleading success.

## E14 · Add/edit activity (legacy `/today/add`, `/today/add/time`, `/today/task/:id/edit`, `/task/date|repeat|scope`)
- If implementation exists: short progressive flow. 1) choose activity/title 2) choose date/time 3) repeat/reminder if needed 4) confirm summary.
- Content: grouped fields, all labels visible, 24h localization, inline validation; keep draft across steps.
- Editing recurring series: ask `Chỉ lần này` vs `Các lần sau` **only if business model supports**; avoid hidden destructive scope.
- Save: preserve exact repo contract `go/pop(result)` until reviewed; no double insert.
- If existing route is `FeaturePlaceholder`, do not create fake functional form; leave explicit gap in PR with UX shell/empty state or implement separately with real repository and tests.

## E15 · Reminder + voice (legacy `/reminder/:taskId`, `/today/voice`)
- Reminder: context title, scheduled time, one primary action for current state; optional Snooze only if service supports it; review permission states.
- Voice: `Nói để thêm việc`, visible record/stop/processing/error states, consent/permission, transcript review before saving; no pretend speech recognition if not available.
- Read-aloud: user-triggered, pause/stop/replay, textual equivalent, optional read button on long content.

## Elderly acceptance scenarios
1. User chooses tab Lịch, selects tomorrow, opens item, Back returns to tomorrow without losing scroll.
2. User opens Hoạt động, selects Thói quen, visits a category, Back retains Thói quen.
3. User navigates from previously saved `/habits/:key` and sees correct category (no 404).
4. Voice/read-aloud can be interrupted; when unavailable, message is truthful.
5. At 200% font scale, no crucial button or bottom label is cut off.
6. Dashboard `/today` UI content is unchanged in this phase; legacy route policy still works.

## Typography dependency — TYPE-01
Mọi chữ UI trên các màn/component thuộc tài liệu này phải dùng semantic tokens tại `02_VISUAL_TOKENS.md` → TYPE-01 (v1.1.0), gồm cả nhãn navigation, form, hint/error, dialog, loading/empty/placeholder và metadata. Không định nghĩa lại cỡ chữ/weight tại đây hoặc giảm chữ vì density. Shared chưa xác định vai trò dùng bộ elderly; layout phải wrap/scroll và tự tăng chiều cao theo chữ.
