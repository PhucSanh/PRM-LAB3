# AN NHIÊN — CALM & PREMIUM UI/UX SPECIFICATION

**Version:** 1.1.0 · **Date:** 2026-11-05 · **Status:** Approved direction / implementation specification · **Language:** vi-VN

> Đây là **bộ tài liệu thiết kế**, không chứa source Flutter đã chỉnh sửa, không phải screenshot hay thiết kế Figma pixel-perfect. Áp dụng cho toàn bộ app **ngoại trừ dashboard / màn `/today`**, vốn **out of scope** của phase này. Chưa có xác nhận build hoặc kiểm thử người cao tuổi.

## Quyết định đã chốt (KHÔNG tự đảo ngược)

1. **Toàn app dùng một phong cách Calm & Premium**; không còn tách phong cách C riêng cho caregiver. Caregiver chỉ khác **mật độ thông tin** và tác vụ quản lý, không khác brand/font family/icon system; cỡ chữ theo token vai trò tại TYPE-01.
2. Visual: **Botanical Forest Green + Warm Ivory + Sage + Soft Coral**, Be Vietnam Pro, Material Symbols **Rounded**, icon đồng nhất, có nhãn rõ, sinh động có kiểm soát, tối giản nhưng không nhạt nhẽo.
3. Người cao tuổi: **Lịch · Hoạt động · Gia đình**. Hoạt động có **Khám phá · Đã lưu · Thói quen**. Lịch chỉ hiển thị/quản lý việc **đã lên kế hoạch**.
4. Người thân: **Lịch · Gợi ý · Gia đình**; cùng design system.
5. **Không code/thiết kế lại dashboard** trong phase này; không thêm tab Hôm nay. Với route `/today` cũ, cần chiến lược tương thích chứ không thay màn này bằng một dashboard mới.
6. Ưu tiên hiện đại, tinh tế và trực quan **đồng thời đáp ứng accessibility**; không hy sinh cỡ chữ/touch target/contrast để trông đẹp hơn.
7. **Không làm giả tính năng hoặc dữ liệu**: màn placeholder phải được xử lý minh bạch; backend, Firebase, auth, notifications, voice, preference/rejection logic hiện tại không được tự thay đổi ngữ nghĩa.

## Cấu trúc tài liệu & thứ tự đọc

| File | Nội dung | Người dùng |
|---|---|---|
| [01_PRODUCT_PRINCIPLES.md](docs/uiux/01_PRODUCT_PRINCIPLES.md) | Product goals, personas, UX principles, scope | PO / toàn team |
| [02_VISUAL_TOKENS.md](docs/uiux/02_VISUAL_TOKENS.md) | Color, type, spacing, radius, elevation, responsive | FE / designer |
| [03_ICONOGRAPHY_MOTION.md](docs/uiux/03_ICONOGRAPHY_MOTION.md) | Icon dictionary, illustrations, motion, feedback | FE / designer |
| [04_INFORMATION_ARCHITECTURE.md](docs/uiux/04_INFORMATION_ARCHITECTURE.md) | Sitemap, vai trò, taxonomy, navigation contract | FE / backend |
| [05_COMPONENT_LIBRARY.md](docs/uiux/05_COMPONENT_LIBRARY.md) | Component API, variants, states | FE |
| [06_ELDERLY_SCREENS.md](docs/uiux/06_ELDERLY_SCREENS.md) | Screen-by-screen người cao tuổi, onboarding, lịch, hoạt động, gia đình | FE / QA |
| [07_CAREGIVER_SCREENS.md](docs/uiux/07_CAREGIVER_SCREENS.md) | Caregiver flow, lịch, gợi ý, gia đình, task form | FE / QA |
| [08_SHARED_SCREENS_AND_STATES.md](docs/uiux/08_SHARED_SCREENS_AND_STATES.md) | Settings, account, inbox, voice, empty/error/loading | FE / QA |
| [09_ACCESSIBILITY_AND_QA.md](docs/uiux/09_ACCESSIBILITY_AND_QA.md) | a11y, responsive, tests, acceptance | QA / FE |
| [10_REPO_MIGRATION_PLAN.md](docs/uiux/10_REPO_MIGRATION_PLAN.md) | Grounded repo inventory, route migration, safe implementation order | Codex / FE |
| [11_CODEX_EXECUTION_CONTRACT.md](docs/uiux/11_CODEX_EXECUTION_CONTRACT.md) | Instructions, task prompts, validation, definition of done | Codex |
| [12_COPY_AND_CONTENT.md](docs/uiux/12_COPY_AND_CONTENT.md) | Vietnamese microcopy, error text, tone | FE / content |
| [13_TRACEABILITY_MATRIX.md](docs/uiux/13_TRACEABILITY_MATRIX.md) | Yêu cầu → file → trạng thái nghiệm thu | PO / QA |

**Cho Codex bắt đầu tại:** [`CODEX_START_HERE.md`](CODEX_START_HERE.md). Chép toàn bộ thư mục `docs/uiux` và `CODEX_START_HERE.md` vào gốc repo. Có thể chép `.codex/` nếu muốn giữ prompt mẫu. `README.md` của project không được tự ý thay bằng file này.

## Thứ tự ưu tiên khi có xung đột
1. Yêu cầu sản phẩm chốt trong file này + mục **Out of scope**.
2. An toàn dữ liệu, hợp đồng API, authorization, runtime behavior đang hoạt động.
3. Accessibility / tính tương thích và điều hướng.
4. Các specification trong `docs/uiux` (tokens, component, screens).
5. Style implementation hiện có.

Bất đồng quan trọng hoặc feature thiếu backend: **ghi ADR/issue, không phỏng đoán**. Ví dụ số màu dưới đây là **design target** cần contrast-check, không phải cam kết mọi tổ hợp đều đạt AA.

## Cập nhật 1.1.0 — chữ rõ cho người cao tuổi (2026-11-05)

Theo yêu cầu sản phẩm, bỏ baseline chữ nhỏ/mỏng của bản 1.0.0. **TYPE-01 trong [02_VISUAL_TOKENS.md](docs/uiux/02_VISUAL_TOKENS.md#typography--type-01-quy-chuẩn-bắt-buộc-bản-110) là nguồn duy nhất cho typography**: elderly body 24sp/600, chữ phụ 22sp/600, nhãn nút 22sp/700, tab 20sp/700, chữ UI tối thiểu 20sp/600. Caregiver body 20sp/600, tối thiểu 18sp/600. Màn shared chưa biết role dùng elderly. Mọi ví dụ cũ, style hiện hữu và diễn giải “premium = chữ nhỏ/mảnh” phải nhường cho TYPE-01. Thay đổi này chỉ sửa đặc tả; CODE/QA chưa được nghiệm thu.
