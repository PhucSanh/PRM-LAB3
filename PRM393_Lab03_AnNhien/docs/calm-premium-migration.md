> BẢN HIỆN HÀNH: người dùng đã bác bỏ font/bố cục của lượt trước. Áp dụng `AnNhien_VELORA_Visual_Replication_Spec_v2/docs/uiux/15_ACCESSIBLE_TYPOGRAPHY_OVERRIDE.md` và `16_REFERENCE_FIRST_LAYOUT.md`: reference-first, Regular font, launch intro và 5 đích nav. Xem `VISUAL_DELTA_LOG.md`; các mốc bên dưới là lịch sử.

# Calm & Premium migration — 2026-11-05

Scope: all production presentation except the source/layout of `today_screen.dart`. TYPE-01 v1.1 remains mandatory. User reference: botanical hills, forest/sage/ivory, quiet surfaces; use code-native vector illustration, not smaller/lighter reference typography.

## Repo delta and compatibility plan

Task add/edit is already implemented, unlike the ZIP baseline. Task, habit and family repositories exist. Explore/bookmarks and speech recognition have no corresponding repository/service. Do not invent these features. Existing Firebase/schema/auth/notification/preference contracts stay unchanged.

| Legacy route | Canonical destination / policy |
|---|---|
| `/today` and its children | retained in calendar branch; dashboard source untouched |
| `/week` | `/calendar` |
| `/week/:date` | `/calendar?date=:date` |
| `/week/:date/task/:id` | `/calendar/task/:id?date=:date` |
| `/today/task/:id` | real task detail, existing URL retained |
| `/habits` | `/activities?section=habits` |
| `/habits/:key` | `/activities/habits/:key` |
| `/family` and legacy children | retained; real family list, unavailable capabilities clearly flagged |
| `/caregiver/schedule`, `/caregiver/suggest` | retained in role-specific shell; query params unchanged |
| `/caregiver/task/*`, pairing, inbox, settings | retained; editor/detail flows remain on root navigator |

Milestones executed sequentially: foundations + illustration/shared screens; real calendar/activity/family views; three-tab shells + aliases; regression/golden/device QA. Acceptance: real repository states, preserved links/Back, no fake catalog/saved/voice, labels at 200%, no dashboard source diff. Missing capabilities remain explicit. See final verification section for actual results; this plan alone is not sign-off.

## Active v2 update — 2026-11-05

The user replaced the original spec with `AnNhien_VELORA_Visual_Replication_Spec_v2`. Implementation now follows its reference anatomy: original botanical artwork, warm matte/pine palette, bundled Vietnamese serif short headings, pine pill actions, real habit discovery cards and overlapping detail sheets. The previous large/bold typography request persists and is codified in v2 document 15. See `VISUAL_DELTA_LOG.md` and `evidence/velora-v2/comparison.html` for comparisons, intentional deviations and QA limitations. Earlier typography-only reports are historical evidence, not the final scope or test count.
