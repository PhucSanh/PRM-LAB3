# 03 — Iconography, illustration & motion

## Chính sách icon
**Approved:** **Material Symbols Rounded**. Trong project hiện có `Icons.*_rounded` Flutter Material; nếu chuyển sang Material Symbols bằng font/package mới, phải chứng minh bundle assets/license, hỗ trợ offline và kiểm tra icon alignment trước khi đổi. Không bắt buộc thêm dependency nếu Material Rounded hiện có đạt yêu cầu hình thức.

- Không mix Cupertino / Lucide / Font Awesome / emoji giữa các icon UI chính.
- Kích thước glyph: 24dp caregiver, 28–32dp elderly ở hành động chính; hit target độc lập ≥48dp.
- Một semantic concept = một glyph; outline/default + fill/selected trong cùng họ khi tồn tại.
- Icon-only chỉ dùng khi thông dụng (Back, Close, Bell, Play/Pause), vẫn bắt buộc tooltip/semantic label. Hành động hủy/xóa/đổi trạng thái phải có chữ.
- Không phóng icon glyph lên 72dp khi chỉ cần tăng hit target.
- Icon decorative không nhận accessibility focus; trạng thái có nhãn nên semantics gộp đúng.

## Bảng ánh xạ bắt buộc
| Meaning | Material Symbols Rounded name gợi ý | Label vi-VN | Tránh |
|---|---|---|---|
| Lịch | `calendar_month` | Lịch | icon đồng hồ cho calendar |
| Hoạt động | `spa` / `eco` (chọn một cho tab) | Hoạt động | thay nhiều glyph cho một tab |
| Khám phá | `explore` | Khám phá | emoji kính lúp |
| Đã lưu | `bookmark` | Đã lưu | dùng `favorite` nếu là bookmark |
| Thói quen | `repeat` / `self_improvement` (chọn một) | Thói quen | dùng cùng icon tab Hoạt động |
| Gia đình | `family_restroom` | Gia đình | icon nhóm không nhất quán |
| Gợi ý | `lightbulb` | Gợi ý | dùng bell / mail không phân biệt |
| Nhắc nhở | `notifications` | Thông báo | nhầm với gợi ý |
| Thêm | `add` | Thêm hoạt động | floating plus vô danh |
| Chỉnh sửa | `edit` | Chỉnh sửa | icon pencil lệch style |
| Lưu | `bookmark_add` / `save` theo nghĩa | Lưu | nhầm lưu thư viện vs lưu form |
| Hoàn thành | `task_alt` | Đã hoàn thành | chỉ màu xanh không chữ |
| Bỏ qua | `event_busy` | Bỏ qua hôm nay | `close` vô nghĩa |
| Dời | `schedule` | Dời lịch | `refresh` gây nhầm đồng bộ |
| Voice đọc | `volume_up` | Đọc nội dung | tự phát âm thanh |
| Voice dừng | `stop_circle` | Dừng đọc | nút play khi đang phát |
| Voice nói | `mic` | Nói để thêm việc | mic không trạng thái permission |
| Cài đặt | `settings` | Cài đặt | menu hamburger ở mọi màn |
| Hồ sơ | `account_circle` | Hồ sơ | icon gia đình |
| Back | `arrow_back` | Quay lại | chevrons không label ở flow elderly |
| Lỗi | `error` | Có lỗi xảy ra | warning chung cho error |
| Thành công | `check_circle` | Thành công | icon hoàn thành nếu là gửi đề xuất |
| Ghép đôi | `link` / `group_add` | Kết nối gia đình | mã QR khi không dùng QR |

**Migration note:** `lib/theme/app_icons.dart` là single icon dictionary hiện tại. Thay mapping theo ngữ nghĩa rồi migration dần; không tự rewrite tên field khi các nơi sử dụng còn phụ thuộc.

## 9 nhóm thói quen
Repo hiện có `HabitPalette` với 9 key và bộ icon nội bộ: `move`, `purpose`, `downshift`, `eighty`, `plant`, `tea`, `belong`, `family`, `tribe`. Giữ **ID, model, stored values và ngữ nghĩa** nguyên vẹn; chỉ thay presentation. Không chuyển các key sang tiếng Việt trong Firestore. Mỗi nhóm nên có icon dễ nhận biết + text, accent tint mềm; không dùng 9 màu saturated ngang nhau.

## Illustration
- Chủ đề: botanical forms, lá cây, ánh sáng tự nhiên, tương tác người thân, bình trà, bước chân nhẹ; trưởng thành, không infantile.
- Phong cách: hình phẳng có chút texture/gradient tinh tế, nét mềm, một ngôn ngữ hình vẽ cho onboarding/empty/success.
- Giới hạn: onboarding 1 illustration/step; empty state 1 illustration nhỏ; không đặt illustration sau mọi row/list.
- Assets thuộc sở hữu rõ nguồn/license; export SVG/PNG có kích thước hợp lý; `flutter_svg` có trong pubspec nhưng phải bảo đảm semantics nếu illustration có nghĩa.
- Dùng icon + text thay thế nếu không có asset chất lượng; **không lấy AI-generated sample web làm asset production mà chưa được duyệt**.

## Motion specs
| Interaction | Duration target | Curve | Notes |
|---|---|---|---|
| Button press feedback | 80–120ms | easeOut | Tint / scale <=0.98, không nảy quá mức |
| State transition / selection | 140–200ms | easeInOut | Cập nhật icon + label |
| Expand/collapse | 180–240ms | easeInOut | Preserve reading order |
| Page transition | 200–300ms | Material platform appropriate | Reduced motion -> immediate/subtle fade |
| Success confirmation | 220–350ms | easeOut | Một lần, không infinite loop |
| Loading | system progress | n/a | Có text status khi lâu, tránh animation phân tâm |

No autoplay audio/video. Không dùng continuous parallax/background animations. Khi OS reduced motion bật, bỏ scale/move animations không cần thiết, giữ feedback tức thì qua trạng thái/từ ngữ. Haptic là phụ trợ tùy chọn, không bắt buộc để hiểu kết quả.

## Typography dependency — TYPE-01
Nhãn icon, tooltip, trạng thái voice và feedback dùng token tại `02_VISUAL_TOKENS.md` → TYPE-01 v1.1.0. Không dùng caption nhỏ/mỏng để bù cho icon; glyph size và hit target độc lập với cỡ chữ.
