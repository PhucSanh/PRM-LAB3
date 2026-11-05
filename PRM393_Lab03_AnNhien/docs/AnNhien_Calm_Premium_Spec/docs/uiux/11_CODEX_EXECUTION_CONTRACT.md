# 11 — Codex execution contract, decisions and handoff

## Mandatory reading order
`CODEX_START_HERE.md` → `README.md` of spec package → `10_REPO_MIGRATION_PLAN.md` → `04_INFORMATION_ARCHITECTURE.md` → `02_VISUAL_TOKENS.md` → `03_ICONOGRAPHY_MOTION.md` → `05_COMPONENT_LIBRARY.md` → role screen docs → `09_ACCESSIBILITY_AND_QA.md` → `13_TRACEABILITY_MATRIX.md`.

## The deliverable is code implementation, NOT an image imitation
Use the design **direction** and specs, not unverified AI inspiration images. The ZIP contains no claimed Figma coordinates/screenshots. Preserve Material/Flutter platform behavior and user’s actual project architecture. For any ambiguous layout, prioritize hierarchy, accessibility, minimal surfaces, consistent visual treatment, and write down implementation decisions.

## Milestone-by-milestone Codex instruction
```
You are a senior Flutter mobile UX engineer. Implement An Nhiên Calm & Premium according to all docs/uiux/*.md.
First inspect the checked-out source and compare it with 10_REPO_MIGRATION_PLAN.md; then write a concise delta audit.
Do not edit lib/screens/today/today_screen.dart and do not design dashboard UI.
Maintain existing Firebase/Riverpod/GoRouter business behavior, privacy boundaries, auth/session/notification compatibility, and Vietnamese locale.
Keep Calm & Premium across both roles: Be Vietnam Pro; botanical forest green and ivory; consistent Material Rounded icon dictionary; list-first layout; restrained shadows; lively but subtle illustrations/micro-motion; WCAG-oriented accessibility.
Elderly tabs: Lịch / Hoạt động (Khám phá, Đã lưu, Thói quen) / Gia đình.
Caregiver tabs: Lịch / Gợi ý / Gia đình.
Audit old /today /week /habits /family and notification deep links before migrating.
Do not invent backend/features or demonstrate data that isn't real. Keep placeholders explicitly flagged or implement end-to-end if authorized and fully testable.
Work in small milestones with tests. Before each milestone state files, route impact and acceptance criteria. After each milestone report changed files, tests run, what could not be tested and risks remaining.
```

## Definition of Done for each PR
- [ ] Scope says which spec IDs addressed; no dashboard changes.
- [ ] `flutter analyze` passes in supported environment.
- [ ] `flutter test` passes, new widget tests cover changed components.
- [ ] Navigation tests cover affected route/deep link/Back/role.
- [ ] 200% text scale, accessibility semantics and 48dp tap target checked.
- [ ] Screen visuals reviewed at 360/390dp with high contrast and long Vietnamese copy.
- [ ] No fake data, no no-op CTA, no fabricated success statuses.
- [ ] Feature/backend/model behavior unchanged unless separately approved.
- [ ] Screenshot/golden and before/after notes attached (when tooling available).
- [ ] Document unresolved dependencies/risks rather than silently marking complete.

## PR sequence and team collision avoidance
1. Theme & foundations ownership: one developer at a time owns `lib/theme/*` and shared `lib/widgets/*` design changes.
2. Routing ownership: one developer owns `lib/router/app_router.dart`, `lib/widgets/app_shell.dart`; other features avoid editing those files concurrently.
3. Elderly screens branch: calendar + activity (with placeholder gap tracked) + family.
4. Caregiver screens branch: caregiver schedule/form, suggestion and family.
5. Shared screens branch: account/onboarding/settings/inbox.
6. Integration owner resolves shared imports and runs cross-role test matrix.

Keep role feature branches and routing PR dependencies explicit. A “single massive PR” is not recommended.

## Escalation decisions (do not invent)
- Is `/today` legacy deep link redirect permitted immediately, or must remain standalone until all external links retire?
- Is Explore/Saved backed by actual models/repositories or only conceptual scope? If missing, implement only real UI state and raise feature work.
- Caregiver Family root might not currently exist; confirm existing permissions and design scope.
- If role switch is supported, establish which device route remains visible.
- If demo guard defaults off, which behavior must be verified for course demo vs production?
- Can TTS/voice features actually pause/replay/record? Inspect service before exposing actions.

## Summary reporting format (for Codex)
```
Milestone:
Scope IDs:
Files changed:
Routes added/changed/aliased:
Visual decisions / deviations:
Backend behavior preserved:
Tests run (exact commands / pass-fail):
Accessibility checks:
Known gaps and unimplemented features:
Dashboard untouched: yes/no
```

## Mandatory typography override — TYPE-01 v1.1.0
`02_VISUAL_TOKENS.md` → TYPE-01 is authoritative for all typography. Never reuse v1.0.0 elderly body 18sp/400 or caregiver body 16sp/400. Elderly body is 24sp/600, secondary 22sp/600, buttons 22sp/700, tabs 20sp/700, all UI at least 20sp/600; caregiver body 20sp/600, floor 18sp/600. Shared screens without resolved role default to elderly. Use local font weights and semantic tokens; never shrink or clip essential labels to fit. This overrides aesthetic/density interpretations, including legacy prompts. Before coding, declare the token mapping; before marking complete, pass the TYPE-01 P0 checks in `09_ACCESSIBILITY_AND_QA.md`. Record shared-theme effects on `/today` without editing its file/layout.
