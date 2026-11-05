# 14 — VELORA VISUAL REPLICATION CONTRACT (APPROVED REFERENCE)

**LATEST USER OVERRIDE — reference first:** Người dùng bác bỏ giao diện chữ quá lớn/đậm và yêu cầu clone bố cục VELORA trước, rồi chọn chữ rõ cho người lớn tuổi. Áp dụng 15 và 16: heading chức năng dùng Be Vietnam Pro SemiBold 600; serif chỉ dành cho wordmark intro; không áp bảng 24/600 và 30/700 cũ. Trang mở đầu và main page phải theo reference.


**Status: MANDATORY / supersedes generic aesthetics in v1.** **Reference:** [https://mygifai.com/inspiration/insp_mp45kj70dawpsw](https://mygifai.com/inspiration/insp_mp45kj70dawpsw). **Reference image:** [https://pic.mygifai.com/inspirations/1778682388994-xnbt7d36eo.jpg](https://pic.mygifai.com/inspirations/1778682388994-xnbt7d36eo.jpg). **Source image is third-party design inspiration, not a production asset.** This document refers to a *four-phone AI mockup*, NOT source Figma files or precise design tokens. All numeric measurements below are implementation targets/inferences, NOT measured ground truth. Do not claim literal pixel-perfect identity without comparison screenshots and/or design source.

## User intention (non-negotiable)
Clone the **VELORA mockup's visible art direction as closely as possible** across An Nhiên's in-scope existing screens, adapted to the An Nhiên product. Do **not** settle for a generic sage-green Material app. Preserve An Nhiên content, Vietnamese language, accessibility, existing behavior, auth, Firebase, and navigation semantics. Exclude existing `/today` dashboard from change.

## Reference anatomy: what is ACTUALLY in the image

| Ref panel | Observed visual | Transfer into An Nhiên | Prohibited copying |
|---|---|---|---|
| 01 Welcome | near-white matte canvas; large circular washed-sage sun behind thin dark green botanical branch; pale layered organic hill shapes below; understated small emblem and widely letter-spaced wordmark; airy explanatory text; dark pine pill CTA pinned above bottom safe area; tiny pagination dots | onboarding/role entry: custom original botanical vector, restrained wordmark, very large breathing space, dominant single CTA, restrained dots | 'velora' name, English tagline, actual proprietary art asset |
| 02 Home | editorial small salutation; large elegant serif name; dark-forest featured card with abstract arc/hills and off-white typography; 3 small tinted category tiles; sparse navigation with glyph and labels | **visual vocabulary only** for Activities discovery/saved/habits and caregiver Suggestions, not `/today` screen; one featured surface maximum, soft individual category tints | rebuild dashboard, meditation fake data, 5-tab VELORA navigation |
| 03 Program detail | full-bleed muted landscape hero ~top third with translucent hills/sun; rounded ivory content sheet overlapping the art; editorial serif two-line heading; restrained stats; sparse feature rows with pale square icons; dark-green bottom CTA | activity detail or suggestion detail: immersive original landscape header, elevated white/ivory sheet, structured feature list, sticky bottom CTA if relevant | subscription price CTA or meditation-specific claims |
| 04 Session player | very large circular abstract landscape artwork; centered serif title + tiny uppercase metadata; short support text; three small benefits; near-bottom pine pill button | voice/detail session when functionally appropriate: large original circular artwork, readable play/pause controls and transcript; only implement if functionality exists | invent a meditation player or audio source |

## Visual signature to reproduce (10-point contract)
1. **Matte warm white canvas**, not green-tinted full-screen backgrounds, no heavy outlines.
2. **Dark desaturated pine green** used boldly and sparingly for hero/primary action; sage reserved for soft illustrations.
3. **Organic layers**: sun discs, circular frames, overlapping rolling hills, fine botanical stems, subtle tonal transparency. Avoid generic gradient blobs.
4. **Editorial type duality**: expressive high-contrast serif for large, *short* headings only; legible Be Vietnam Pro sans for body, forms, accessibility. Select a licensed Vietnamese-capable serif after checking glyphs (including full diacritics) and bundle legally; fallback to Be Vietnam Pro if no suitable font. Do NOT blindly render Latin-only serif for Vietnamese headings.
5. **Very deliberate whitespace**: one major focal anchor per screen; around 24dp baseline content inset; consistent vertical rhythm.
6. **Soft cards**: light-tinted stone/sage/blush fills, corners around 16–22dp, virtually invisible borders and no drop-shadow stacks.
7. **Dark pill CTA**: near-full width, 52–60dp height depending text scale, rounded endcaps; white label, understated trailing arrow/icon only when meaningful.
8. **Sparse rounded line icons**: thin/medium strokes, size and optical weight normalized. Use approved Material Symbols Rounded collection; selected glyph can fill. Do not imitate distinct brand logo glyphs.
9. **Quiet depth**: content sheet may overlap hero artwork, layers have meaningful hierarchy, not gratuitous elevations.
10. **Calm interaction**: low-amplitude transitions, state feedback, reduced-motion fallback; no autoplay or decorative animation necessary to perform tasks.

## Shape / composition mapping (logical dp, proposed targets)

| Element | Target at 390×844 reference viewport | Responsive rule |
|---|---|---|
| Canvas | `#FAF9F5` warm matte / subtle cream | semantic surface token; contrast-test all labels |
| Main content | 20–24dp horizontal gutters | 16dp allowed on 320–359 width; max content width on tablet |
| Featured hero | ~188–230dp height, ~18–22dp radius | dynamic height with text, not clipped; avoid irrelevant hero panels |
| Detail hero | ~250–320dp visible art region on phone | grows for localized long headers; top status/navigation safe area |
| Overlap sheet | ~24–30dp top rounded corners | main sheet scrollable; no clip of important content |
| Icon tile | ~40–48dp visual shape | tap target ≥48dp; elderly actions target ≥56dp |
| Category tile | 3-column only when labels fit | adapt to 2 columns or vertical list at large text/compact width |
| Primary CTA | 56dp preferred, pill / `999dp` radius | min 48dp target; scale vertically to fit multiline |
| Artwork circle | up to min(66vw, 260dp) | do not exceed usable viewport; accessible text remains visible |
| Page title | editorial 28–34sp where legible | fallback sans; localization-aware; avoid forced line cuts |

> These are *inferred design directives*, not extracted exact pixels, source colors or proprietary specs. Maintain a measured deviations table after comparing real emulator screenshots against reference.

## Reference-based palette (provisional, visually estimated)

- `visual.pine`: `#243D32` — forest CTA and featured surface.
- `visual.pineDeep`: `#1E332B` — pressed/high contrast.
- `visual.sageFog`: `#DCE2D7` — abstract landscape light plane.
- `visual.sageMid`: `#ADBBA9` — landscape middle plane.
- `visual.mossMuted`: `#788D7C` — distant mountain/landscape.
- `visual.canvas`: `#FAF9F5` — warm off-white full app background.
- `visual.cream`: `#F3EFE8` — card/background variation.
- `visual.blush`: `#EFE4DD` — selectively tinted category tile.
- `visual.lavenderGray`: `#EAE9EF` — tertiary category tint.
- `visual.ink`: `#27362F` — text.
- `visual.secondary`: `#5E6861` — supporting text.

Use these as **visual matching hypotheses**. Ratify with WCAG contrast checks and visual comparisons; color eyedropper on the source image if legally/technically available. Semantic tokens and accessibility take precedence. The v1 `#285C4A` forest palette is now **superseded for visual matching** where it conflicts, but unchanged code outside scope should not be modified.

## Intentional non-matches

- No direct reuse of brand **VELORA**, logo, slogans, source illustration, paid subscription copy, meditation imagery or sample tasks as An Nhiên content.
- Do not replicate mockup's 5-nav home bar: approved IA is 3 tabs by role.
- No dashboard redesign. VELORA home panel is only a style reference for other feature screens.
- Do not mimic iOS status bar, dynamic island, device frame, studio mockup or fake OS chrome inside Flutter UI.
- Exact visual matching must not override Vietnamese localization, large text, accessibility, actual feature states or platform back conventions.

## Required visual proof

1. Developer creates a side-by-side visual matrix: VELORA panel references vs An Nhiên equivalents: onboarding, Activities, activity detail, voice/suggestion where applicable.
2. Golden screenshots at 390×844 and 360×800 logical reference sizes, scale 1 and 1.5; 200% accessibility smoke screenshots and Android TalkBack / iOS VoiceOver checks.
3. Review six features individually: typography character, palette impression, composition, icon continuity, spacing rhythm, illustration coherence.
4. For each screen, write 3 most significant remaining differences in a `VISUAL_DELTA_LOG.md` during implementation; fix before marking as complete.
5. Report any licensed illustration/font assets not supplied. Do not silently replace them with unrelated emojis or stock photos.

## Implementation order

1. Original botanical/landscape **vector asset kit** (reusable primitives, with correct commercial rights), from references, not copies of third-party artwork.
2. Visual semantic tokens and type specimens; compare side-by-side before migrating screens.
3. Component gallery: hero art, pill CTA, sheet, category tile, list row, feature row, icon badges, navigation bar.
4. Onboarding & entry screen → Activities Browse/Saved/Habits → Activity detail → Caregiver Suggestions & detail → Family / Calendar / Notifications / settings.
5. Visual QA and accessibility regression. Dashboard excluded.

## Visual acceptance checklist

- [ ] Reviewer can identify VELORA visual lineage immediately without reading brand names.
- [ ] The app looks **editorial / nature-inspired**, not default Flutter Material 3 with changed colors.
- [ ] Shapes and assets are original/licensed; product identity and features remain An Nhiên.
- [ ] Large headings intentionally use a well-supported Vietnamese serif/sans pairing.
- [ ] No unnecessary borders, shadows, multi-card nesting or glossy effects.
- [ ] At least 1 real-state screenshot per screen (loaded or empty) and complete interaction states tested.
- [ ] Navigation, gestures, semantics, scaled layouts and business flows preserved.
