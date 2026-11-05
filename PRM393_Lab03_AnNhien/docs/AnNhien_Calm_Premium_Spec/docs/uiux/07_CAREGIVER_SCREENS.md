# 07 — Caregiver screen-by-screen specification

## Caregiver UX principle
**Cùng Calm & Premium**, không chuyển sang dashboard doanh nghiệp: Forest Green, Warm Ivory, Be Vietnam Pro, Material Rounded, no heavy data-card wall. Khác elderly ở mật độ form/danh sách (body 20sp/600, tối thiểu 18sp/600 theo TYPE-01 tại `02_VISUAL_TOKENS.md`) và khả năng quản lý nhiều nhiệm vụ trong một hành trình. Không tự cấp quyền đọc/sửa của caregiver ngoài server rule.

## C01 · Caregiver shell
3 tabs: **Lịch · Gợi ý · Gia đình**. Persistent branch states. Global Inbox, Account/Settings contextually. Notification badges only when real count exists. If user not paired → pairing flow instead of empty schedule. Root Back platform expected. No elder shell embedded.

## C02 · Pairing `/caregiver/pair`, `/pairing/code`
- Simple progress: explanation → code input/display (depending role) → verify/confirm → connected state.
- Code: monospace/numeric readable, copy control with feedback; lifetime and retry from actual service only.
- Protect privacy: mask identifiers if needed, clear permission explanation and owner identity before success.
- Error states: expired, invalid, already used, network unavailable, not authorized. Form remains usable; no fake pairing.
- Keep pairing logic `firebase_pairing_service.dart` contract unchanged.

## C03 · Caregiver Lịch `/caregiver/schedule`
- App bar `Lịch`, selected family member context if needed, one clear `Thêm hoạt động` when authorized.
- Day/Week/Month view selector only if current `CalendarView` supports it; avoid repeating oversized date cards.
- Compact calendar control + chronological schedule list, semantic status badges, inline filter only for real filter capability.
- Differentiate `Đã lên lịch`, `Đã gửi`, `Đã hoàn thành`, `Đã hủy` using real business status; no assumed transitions.
- Query params `date`, `view=day|week|month` remain compatible; filter/date restored after detail/form.
- Empty state: `Chưa có hoạt động trong khoảng thời gian này`, CTA when permission allows.

## C04 · Create task `/caregiver/task/new` and steps `/repeat`, `/review`
- Progressive flow; visible `Bước 1/3`, `Bước 2/3`, `Bước 3/3` only if these are actual steps.
- Step 1 activity/name, target person if applicable, date/time. Step 2 recurrence/reminder. Step 3 review all fields, consent/implications and submit.
- Input composition: persistent labels, grouped vertical form, auto scroll on keyboard, clear invalid instructions; no giant cards for each field.
- Primary action fixed near bottom only where safe; disabled while submitting, prevent duplicate writes.
- Abandon dirty form prompts discard/stay. Failure retains form. Sent screen reflects actual backend result.
- Preserve `CaregiverFormScreen(step: ...)` logic/provider and route result mechanisms.

## C05 · Sent `/caregiver/task/sent`
- Small success illustration/check, title with **accurate** status (`Đã gửi yêu cầu` or `Đã tạo hoạt động` based on service result), explanation, action `Về Lịch`.
- No invented statements that elderly accepted/received push notification.

## C06 · Detail `/caregiver/task/:id`
- Shows task title, scheduled date/day param, recipient, recurrence, current status where available; actions from permission and actual provider.
- Show change/delete only when implemented; respect authorization and repeat scope. Preserve `date` query on Back/deep-link context.

## C07 · Gợi ý `/caregiver/suggest`
- Purpose: compose activity suggestion for elder, not directly overwrite their schedule.
- Page should distinguish **Soạn gợi ý** and **Đã gửi** history when provider actually exposes history; if not, no fake history list.
- Compose flow: pick activity or input title (from current model), concise benefit, suggested time if supported, selected family member, review, `Gửi gợi ý`.
- Display receiver's known **strongly rejected** activities as ineligible for auto-recommendation; do not automatically override consent or silently resubmit rejected idea. If repository cannot expose preferences, note gap and do not pretend filtering works.
- Status language: `Chờ phản hồi`, `Đã đồng ý`, `Đã từ chối`, `Không thể gửi`, mapped to actual status values only.
- No intrusive modal interrupts when suggestions arrive in other tabs; use unobtrusive in-app affordance/notification.

## C08 · Gia đình (caregiver)
- Members linked via pairing with name, relationship, permission/status; list-first, section for connection management.
- Pair code flow opens as child route, not unrelated tab. No unauthorized cross-family data.
- Empty: `Chưa kết nối với người thân` + `Kết nối ngay` if pairing available.
- Actions clear: `Xem thông tin`, `Kết nối`, `Ngắt kết nối` (destructive confirmation only when implemented).

## C09 · Caregiver notifications/inbox
- Shared inbox patterns and consistent status; differentiate `Đã xem` from `Đã chấp nhận`.
- Deep links resolve caregiver shell branch after auth/pairing; expired/deleted suggestions show friendly unavailable state.

## Caregiver acceptance scenarios
1. Open caregiver `/caregiver/schedule?view=week&date=2026-11-05`, open detail, return to same date/view.
2. Create task and review → submit once; if error, no duplicate task, no lost draft.
3. Reject pairing code → validation message, no accidental account-switch.
4. Suggestion send reports `Đã gửi` only on successful repository response; not silently written as accepted.
5. Caregiver shell never shows elder Hoạt động bottom tab.
6. All caregiver screens share same palette/fonts/icon family as elder.

## Typography dependency — TYPE-01
Mọi chữ UI trên các màn/component thuộc tài liệu này phải dùng semantic tokens tại `02_VISUAL_TOKENS.md` → TYPE-01 (v1.1.0), gồm cả nhãn navigation, form, hint/error, dialog, loading/empty/placeholder và metadata. Không định nghĩa lại cỡ chữ/weight tại đây hoặc giảm chữ vì density. Shared chưa xác định vai trò dùng bộ elderly; layout phải wrap/scroll và tự tăng chiều cao theo chữ.
