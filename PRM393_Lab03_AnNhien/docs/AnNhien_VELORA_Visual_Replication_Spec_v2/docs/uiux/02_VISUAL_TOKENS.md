# 02 — Visual foundations & token contract

**LATEST USER OVERRIDE — reference first:** Người dùng bác bỏ giao diện chữ quá lớn/đậm và yêu cầu clone bố cục VELORA trước, rồi chọn chữ rõ cho người lớn tuổi. Áp dụng 15 và 16: heading chức năng dùng Be Vietnam Pro SemiBold 600; serif chỉ dành cho wordmark intro; không áp bảng 24/600 và 30/700 cũ. Trang mở đầu và main page phải theo reference.


**Priority override (v2):** Dùng `14_VELORA_VISUAL_REPLICATION.md` và ảnh VELORA làm visual target. Bảng màu và typography bên dưới là baseline cũ; nơi xung đột, dùng visual token v2 sau khi kiểm thử tương phản. Pixel-perfect tuyệt đối không thể xác nhận từ một ảnh render AI, nhưng yêu cầu visual fidelity tối đa trong giới hạn sản phẩm An Nhiên.

## Brand palette — baseline
| Token đề xuất | Hex | Vai trò | Quy tắc |
|---|---|---|---|
| `brand.forest.700` | `#285C4A` | Primary action, selected, focus | Chữ trắng cho primary CTA (phải test contrast) |
| `brand.forest.800` | `#204A3C` | Pressed/hover | Không thay bằng màu nhạt khi pressed |
| `brand.sage.500` | `#79A58D` | Secondary decorative accent | Không mặc định dùng làm chữ nhỏ trên ivory |
| `brand.sage.100` | `#E5EEE8` | Selected chip, icon background | Chữ forest đậm |
| `brand.ivory.50` | `#F8F7F2` | App background elderly + general | Màu nền, không bao quanh bằng viền liên tục |
| `brand.coral.400` | `#E8A58E` | Warm illustration, highlights | **Không** dùng làm alert/error/foreground nhỏ |
| `neutral.ink.900` | `#24342F` | Primary text | Nội dung dài |
| `neutral.white` | `#FFFFFF` | Elevated surface | Form, sheet, panel |
| `neutral.muted.700` | `#526057` | Supporting copy | Phải test với nền tương ứng |
| `neutral.border.200` | `#E3E7DF` | Divider | Không bắt buộc border quanh mọi component |
| `status.success` | `#236D50` | Thành công | Icon + text, không chỉ màu |
| `status.warning` | `#8A5100` | Cần chú ý | Tránh tô toàn thẻ vàng |
| `status.error` | `#B42318` | Lỗi | Error copy + icon |

**Quan trọng:** Đây là palette đề xuất, chưa phải kiểm chứng tương phản cho **tất cả** cặp foreground/background. Mọi token dùng cho text/icons cần kiểm tra ở trạng thái normal/disabled/selected/pressed trên light/high-contrast. Được điều chỉnh hue/lightness tối thiểu để đạt AA, ghi lại trong change log. Không hardcode hex ở màn; tạo semantic ColorScheme.

### Semantic aliases bắt buộc
`surface.app`, `surface.primary`, `surface.subtle`, `surface.selected`, `surface.overlay`, `text.primary`, `text.secondary`, `text.inverse`, `icon.primary`, `icon.secondary`, `action.primary`, `action.primaryPressed`, `action.secondary`, `border.subtle`, `border.focus`, `status.successFg`, `status.warningFg`, `status.errorFg`, `state.disabledBg`, `state.disabledFg`.

Khuyến nghị map sang Material 3 `ColorScheme`; màu trạng thái tính năng không được tự tiện dùng brand coral thay warning/error. Dark theme chỉ thiết kế semantic alias và avoid hard-coded color; chưa yêu cầu hoàn thiện trong phase này.

## Typography (logical sp, ở scale=1.0; phải scale với hệ thống)
**Font:** Be Vietnam Pro, giữ bundling local hiện có; weights 400, 600, 700. Tiêu đề ngắn bổ sung Noto Serif Display Regular bundled/OFL theo 14; không tải từ CDN.

| Role | Elderly | Caregiver | Weight | Line height | Dùng cho |
|---|---:|---:|---|---:|---|
| Display | 34–38 | 32–36 | 400 serif | 1.20 | Wordmark |
| Page title | 30 | 28 | 600 sans | 1.25 | Heading ngắn |
| Section title | 20 | 20 | 600 sans | 1.35 | Section |
| Card/task title | 20 | 18 | 600 sans | 1.35 | Actual item |
| Body primary | 18 | 17 | 400 sans | 1.50 | Nội dung |
| Body secondary | 16 | 16 | 400 sans | 1.50 | Mô tả |
| Button | 18 | 17 | 600 sans | 1.30 | CTA |
| Nav label / metadata | 14 | 14 | 400 sans | 1.45 | Nhãn phụ |

**Không** sử dụng fontSize 20 cho tất cả text roles; không khóa textScaleFactor. Không `FittedBox(scaleDown)` để che lỗi overflow. Cho phép multiline và chiều cao tự giãn. Ngoại lệ truncation chỉ với metadata không mang tính quyết định; cung cấp full content qua semantics/tap.

## Spacing / dimensions (dp)
- Base spacing scale: **4, 8, 12, 16, 20, 24, 32, 40, 48**. Dùng token, không tùy tiện 17/19/23.
- Screen horizontal padding: **20** elderly, **20–24** caregiver; compact <=360dp có thể 16 sau QA.
- Section gap: 24–32. Label-to-field: 8. Row/field gap: 12–16. Divider inset theo text.
- Card radius: 20–24 nếu thực sự là card; input: 14–16; button: 16–20; chip: pill.
- Elevation: ưu tiên **0**; overlay/raised surface soft elevation <=2, không nhiều shadow nặng.
- Tap targets: min **48×48 dp Android**, đề xuất chính **56–60dp elderly**, caregiver **48–56dp**; nếu current repo yêu cầu 72dp cho hành động critical, bảo toàn accessibility/tài liệu coursework cho đến khi thống nhất. Không mặc định giảm mọi vùng chạm từ 72 xuống 48.
- App bar: nội dung linh hoạt; không cố định height=88 khi scaling gây overflow. Bottom nav min height theo typography + safe area, không fixed 96 cứng.
- Input field min visual height 56dp; chạm ít nhất 48dp, elderly nên ≥60dp.

## Density
- Elderly: comfortable/accessible, số lựa chọn mỗi viewport thấp, nhiều bề mặt trắng trống và nhãn rõ.
- Caregiver: comfortable/standard, timeline/danh sách dày hơn một mức nhưng giữ tokens chung.
- Tùy chỉnh **high contrast, text scale, reduced motion** là accessibility setting, không phải theme thương hiệu riêng.

## Responsive
| Width (logical dp) | Navigation | Content |
|---|---|---|
| `< 360` | Bottom nav 3 đích + label, cân nhắc multiline | 16px padding; text tự xuống dòng |
| `360–599` | Bottom nav 3 đích | 20px padding; lists |
| `600–839` | Navigation rail hoặc adaptive nav | max content width 640–720; giữ alignment |
| `>=840` | Navigation rail + content panel nếu hợp lý | max width 900–1100; avoid stretched forms |

`SafeArea`, keyboard inset, dynamic text scaling và landscape là bắt buộc kiểm thử. Không chuyển bottom nav thành grid 2×2 do text scale. Tablet không tự suy ra cần split pane nếu nội dung không phù hợp.

## Visual QA
Các màn cần thoáng: không lặp tiêu đề “Lịch” ba lần trong app bar, hero và section; không hơn một primary filled CTA rõ ràng trong cùng viewport hành động; tránh card-inside-card và outline/colored surface lồng nhau; mọi section có hierarchy bằng typography + whitespace trước khi dùng border/elevation.
