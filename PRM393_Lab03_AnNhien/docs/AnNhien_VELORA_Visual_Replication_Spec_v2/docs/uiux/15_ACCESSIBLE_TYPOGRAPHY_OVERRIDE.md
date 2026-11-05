# 15 — Typography theo yêu cầu mới nhất: rõ nhưng thanh thoát

**Thay hoàn toàn bản typography override trước đó.** Người dùng phản hồi font quá nặng và yêu cầu dựng sát VELORA trước, sau đó chỉnh font/size cho người lớn tuổi. Không quay lại blanket body 24/600 và serif 700. User request > 15/16 > 14 > các baseline cũ. `CLAUDE.md` và tài liệu Lab 2 giữ làm lịch sử; các chỉ số cũ xung đột không được dùng để dựng lại UI nặng chữ.

| Role | Bác | Con cháu | Weight / family |
|---|---:|---:|---|
| Wordmark / display | 34–38 | 32–36 | Noto Serif Display Regular 400 |
| Page heading | 30 | 28 | Noto Serif Display Regular 400 |
| Feature/detail heading | 26 | 24 | Noto Serif Display Regular 400 |
| Section | 20 | 20 | Be Vietnam Pro 600 |
| Task/item title | 20 | 18 | Be Vietnam Pro 600 |
| Body primary | 18 | 17 | Be Vietnam Pro Regular 400 |
| Body secondary | 16 | 16 | Be Vietnam Pro Regular 400 |
| Metadata / nav label | 14 | 14 | Be Vietnam Pro Regular 400 |
| CTA | 18 | 17 | Be Vietnam Pro 600 |

Đây là sp trước scale; lựa chọn mặc định Lớn ×1.15 vẫn giữ, body của Bác hiển thị ~20.7sp. Giữ tùy chỉnh chữ và scale hệ thống đến ×2.0 theo cơ chế hiện có. Không FittedBox, không disable scaling, không nhét toàn bộ chữ vào weight 600/700. Font Việt đủ dấu bundled và OFL; dùng Regular thật, không giả lập bằng font Bold.

Nút chính target 56dp, tự cao khi nhiều dòng; nội dung và tương phản vẫn rõ. Caption và nav nhẹ hơn nội dung quyết định. Thẻ/cột reflow ở scale lớn. Không khóa chiều cao đoạn văn để giữ ảnh đẹp. Section title dùng sans để giữ nhịp của mẫu; serif chỉ dùng heading ngắn, không dùng cho field, status, time, danh sách dài.

Implementation: `lib/theme/app_typography.dart`, `app_theme.dart`, `app_spacing.dart`. Verify actual font goldens và Android launch → home.

## Intro refinement — phản hồi mới nhất: nét mỏng, chữ nhỏ

Ngoại lệ bắt buộc cho `/intro` và `/welcome`: wordmark **Noto Serif Regular 38sp**, letter spacing **1.5** (thay Display 34sp / tracking 6); tagline **16sp/600**, tracking **0.5**; description **20sp/600** (thay 16/400); CTA **20sp/600**, minimum height **64dp**. Cỡ hiển thị tiếp tục nhân lựa chọn chữ của app/hệ thống. Font Noto Serif Regular có nét chắc hơn Display, vẫn giữ serif. Không áp thay đổi này thành body 600 cho toàn bộ app. Giữ anatomy và các role ngoài intro đã duyệt. Tokens nằm trong `AppTypography.welcome*`, không hardcode rải rác.
