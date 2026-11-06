# 12 — Vietnamese microcopy, content design & language

## Voice & tone
Calm, respectful, warm and adult; concise without being clinical or patronizing. Prefer direct verbs; do not overuse “Bác” in every sentence; use configured name/pronoun from user profile where available and appropriate. Avoid shame/guilt when skipping, forgetting or rejecting activity. No jokes in alerts/errors.

## Navigation & labels (approved)
| Context | Final label | Do not use |
|---|---|---|
| Elderly tab 1 | `Lịch` | `Lịch tuần` as top-level if calendar supports daily/weekly |
| Elderly tab 2 | `Hoạt động` | `Thói quen` as top-level |
| Elderly tab 3 | `Gia đình` | `Người thân` as a differently named duplicate tab |
| Activity subtab 1 | `Khám phá` | `Gợi ý` if it could be mistaken for family suggestion |
| Activity subtab 2 | `Đã lưu` | `Đã làm` |
| Activity subtab 3 | `Thói quen` | `Hoạt động thường xuyên` in nav label |
| Caregiver tab 1 | `Lịch` | `Tổng quan` |
| Caregiver tab 2 | `Gợi ý` | `Nhắn tin` |
| Caregiver tab 3 | `Gia đình` | `Quản lý` as vague replacement |

## Copy by context
| Context | Recommended copy | Notes |
|---|---|---|
| Empty schedule | `Chưa có hoạt động nào trong ngày này.` | Avoid `Bạn chưa làm gì hôm nay` |
| Explore | `Tìm hoạt động phù hợp` | Do not promise AI personalization without it |
| Empty saved | `Chưa có hoạt động được lưu.` | CTA `Khám phá hoạt động` |
| Empty family | `Chưa kết nối với người thân.` | `Kết nối ngay` if supported |
| Form create | `Thêm hoạt động` | Specific enough |
| Save form | `Lưu hoạt động` | Not `OK` |
| Caregiver send | `Gửi gợi ý` | Sending distinct from accept |
| Sent success | `Đã gửi gợi ý.` | No claim recipient read it |
| Accept suggestion | `Đồng ý` | Need detail of actual impact |
| Reject suggestion | `Từ chối gợi ý` | Not shaming wording |
| Loading | `Đang tải hoạt động…` | Context-specific status |
| Network failure | `Chưa thể tải dữ liệu. Vui lòng thử lại.` | One next step |
| Error retry | `Thử lại` | Buttons active only when action exists |
| Permission denied | `Bạn chưa bật thông báo. Bạn có thể bật trong Cài đặt của điện thoại.` | Platform-specific next step |
| Reminder | `Đến giờ thực hiện hoạt động` | Include actual activity |
| Voice play | `Đọc nội dung` | Text available regardless |
| Voice stop | `Dừng đọc` | Avoid icon-only if ambiguous |
| Dirty form | `Bạn muốn bỏ những thay đổi chưa lưu?` | `Tiếp tục chỉnh sửa` / `Bỏ thay đổi` |
| Deleted entity | `Nội dung này không còn khả dụng.` | Back home appropriate role |
| Completed state | `Đã hoàn thành` | Not motivational gamification |

## Date/time formatting
- Default locale `vi-VN`, time 24h, weekday written out where helpful (`Thứ Năm, 05/11/2026`); no fixed global date hardcoded.
- Duration `15 phút`, `1 giờ 30 phút` where actual model has duration. Status should carry explicit wording, never color alone.
- User time zone from existing settings/system; avoid converting date-only strings through UTC such that day shifts.

## Errors & validation
- Required: `Vui lòng nhập tên hoạt động.`
- Time invalid: `Vui lòng chọn giờ hợp lệ.`
- Repeat conflict: show actual constraint rather than generic error.
- Auth failure: do not reveal whether account exists if unsafe.
- Expired pairing: `Mã kết nối đã hết hạn. Vui lòng tạo mã mới.` (only if expiration proven).
- Failed send: `Chưa thể gửi gợi ý. Nội dung bạn đã nhập vẫn được giữ lại.` when draft preservation implemented.

## Suggested style details
- One sentence per paragraph in small screens, not 4 sentences below every CTA.
- Use supportive neutral labels, no infantilizing congratulations for routine events.
- Primary button label max a few Vietnamese words, but allow wrap at 200% scaling rather than shrinking glyph.
- Do not claim `Đã đồng bộ` until repository confirms; no claims about offline/local-only storage if Firebase used.
