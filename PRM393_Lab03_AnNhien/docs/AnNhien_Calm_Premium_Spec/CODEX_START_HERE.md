# CODEX START HERE — AN NHIÊN CALM & PREMIUM

## Mục tiêu
Refactor UI/UX **toàn ứng dụng ngoại trừ `/today` dashboard** theo bộ `docs/uiux`, với navigation 3 tab theo vai trò, giữ nguyên logic nghiệp vụ và tích hợp đang hoạt động. Đọc `README.md` của gói spec trước.

## Không được làm
- KHÔNG sửa/thiết kế lại `lib/screens/today/today_screen.dart` trong phase này, kể cả khi có lời mời tối ưu.
- KHÔNG tự ý thay Firebase schema, provider semantics, auth guards, deep link, message payload, notification routing, reminder scheduling, recurrence scope, hay preference rejection rules.
- KHÔNG tự tạo dữ liệu giả/hành động no-op để làm màn đẹp; nếu feature chưa triển khai, ghi rõ, dùng empty/coming-soon có định hướng hoặc giữ màn hoạt động cũ.
- KHÔNG trộn nhiều họ icon, dùng Unicode emoji làm icon chính, giảm tương phản, tắt text scaling, giấu lỗi qua `FittedBox`.
- KHÔNG xoá route cũ nếu còn được navigation, notification, test hoặc link bên ngoài sử dụng.
- KHÔNG copy nhầm file `README.md` của bộ spec đè lên README project.

## Cách làm
1. Đọc `10_REPO_MIGRATION_PLAN.md`, `04_INFORMATION_ARCHITECTURE.md`, `02_VISUAL_TOKENS.md`.
2. Audit repo thực tế (phiên bản code hiện tại có thể khác ZIP 2026-11-04); lập bảng changed/unaffected route & feature; ghi giả định.
3. Tạo tokens/components + widget gallery; không migrate toàn bộ một PR.
4. Migrate onboarding + auth + shared; triển khai shell/route map theo vai trò và mapping legacy; rồi screen features theo từng PR; giữ `/today` nguyên nội dung.
5. Thêm widget/golden/a11y tests; `flutter analyze`, `flutter test` và smoke test simulator/device nếu môi trường hỗ trợ.
6. Đưa ra summary cho từng PR: files changed, behavior preserved, screenshots/golden, test results, outstanding decisions.

## Prompt gợi ý
> Act as a senior Flutter mobile engineer and design-system implementer. Read `README.md` of the UIUX spec package, all `docs/uiux/*.md`, and `CODEX_START_HERE.md`. Implement strictly according to the approved Calm & Premium spec, preserving existing business logic and excluding the `/today` dashboard. First produce a repo-aware implementation plan and route compatibility matrix; then implement one independently testable phase at a time. Do not invent backend or silently remove routes. Verify accessibility, golden/widget tests, and report any discrepancies or unimplemented features.

**Gate:** Nếu repo mới không có cùng cấu trúc/route ở `10_REPO_MIGRATION_PLAN.md`, ưu tiên source mới và báo delta, không ghi đè mù quáng.

## Typography gate — TYPE-01 (1.1.0)
Đọc và áp dụng bảng TYPE-01 trong `docs/uiux/02_VISUAL_TOKENS.md` trước mọi thay đổi theme/màn. Elderly body 24sp/600, secondary 22sp/600, button 22sp/700, tab 20sp/700; không chữ UI dưới 20sp/600. Caregiver body 20sp/600, sàn 18sp/600. Shared chưa biết role dùng elderly. Không dùng lại baseline 1.0.0, không giảm chữ để vừa màn. Dùng đúng font local 600/700; kiểm tra token, wrap, 200% và Material fallback. Đây là thay đổi tài liệu, không chứng nhận implementation đã đạt.
