# 02 — Visual foundations & token contract

**Design reference:** Calm & Premium của toàn bộ app; **không sao chép một ảnh tham khảo AI thành layout pixel-perfect**. Ảnh tham khảo trong hội thoại chỉ định hướng thẩm mỹ: sage/forest + warm ivory, khoảng trắng, bề mặt nhẹ, botanical illustration.

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

## Typography — TYPE-01 (quy chuẩn bắt buộc, bản 1.1.0)

**Nguồn chuẩn duy nhất cho cỡ chữ/độ đậm:** mục TYPE-01 này. Các màn, components, gallery và tests phải tham chiếu bảng dưới; không tạo bảng typography riêng. Quy chuẩn này thay thế toàn bộ thông số typography của bản 1.0.0. “Premium”, “minimal” hoặc “density” không phải lý do để giảm cỡ chữ/độ đậm.

**Font:** Be Vietnam Pro local. Repo đã khai báo Regular (400), SemiBold (600), Bold (700). Dùng đúng asset 600/700, không giả lập nét đậm, không thêm font mạng. Regular vẫn có thể giữ trong bundle nhưng **không dùng weight dưới 600 cho chữ UI** trong phạm vi migration, kể cả placeholder, hint, metadata, trạng thái chưa chọn và disabled.

Các số là **logical sp ở text scale 1.0**, là baseline tối thiểu, chưa nhân cỡ chữ người dùng/hệ thống. Không dùng thiết lập “Lớn” để bù cho baseline nhỏ. Chỉ tăng token tập trung khi cần; không tự giảm token tại màn.

| Text role / semantic token | Elderly (sp) | Caregiver (sp) | Weight | Line height | Dùng cho |
|---|---:|---:|---:|---:|---|
| `display` | 34 | 32 | 700 | 1.25 | Hero intro rất hiếm |
| `pageTitle` | 30 | 28 | 700 | 1.35 | Tiêu đề màn |
| `sectionTitle` | 26 | 24 | 700 | 1.40 | Tiêu đề nhóm |
| `itemTitle` | 24 | 22 | 700 | 1.40 | Tên hoạt động, thành viên, mục danh sách |
| `bodyPrimary` | 24 | 20 | 600 | 1.50 | Nội dung chính, dữ liệu nhập, nội dung dialog |
| `bodySecondary` | 22 | 18 | 600 | 1.50 | Mô tả, helper, hint, lỗi nhập |
| `buttonLabel` | 22 | 20 | 700 | 1.40 | Mọi CTA chính/phụ/tertiary |
| `tabLabel` | 20 | 18 | 700 | 1.40 | Bottom nav, rail, segmented tabs, filter chip |
| `caption` | 20 | 18 | 600 | 1.50 | Metadata phụ, trạng thái, timestamp |

### Áp dụng và phân cấp
- Elderly: **không chữ UI nào dưới 20sp/600**. Nội dung cần đọc để quyết định không được hạ thành caption: giờ thực hiện, liều lượng nếu model có, hướng dẫn, cảnh báo và lỗi quan trọng dùng ít nhất `bodySecondary` (22sp/600); tên việc dùng `itemTitle` (24sp/700).
- Caregiver: **không chữ UI nào dưới 18sp/600**, body chính 20sp/600. Khác mật độ bằng tổ chức nội dung và spacing, không dùng lại body 16sp hay caption 13–14sp.
- Màn dùng chung trước khi biết vai trò (onboarding/login/role), dialog/global overlay chưa có role context: **mặc định elderly**. Khi đã xác định caregiver, có thể dùng bộ caregiver; không suy role chỉ từ chuỗi URL.
- Map đủ 15 slots `TextTheme` và các Material component themes (input/helper/error, chip, picker, tooltip, snackbar, dialog, navigation) vào token phù hợp. Không để fallback Material tạo chữ nhỏ/mỏng. Widget dùng token; không hardcode fontSize/fontWeight thấp hơn.
- Chữ phụ phân cấp bằng vị trí, khoảng trắng và màu semantic đủ tương phản; không dùng opacity để làm chữ mờ, không giảm weight. Không dùng mọi text cùng một cỡ: giữ hierarchy theo bảng.
- Giữ tùy chọn cỡ chữ và high contrast; scale theo hệ thống. Không khóa, giảm hoặc đặt trần mới cho text scaling để vừa layout. Nếu code có trần hiện hữu, ghi nhận riêng; không tuyên bố đã hỗ trợ mức hệ thống vượt trần khi chưa kiểm thử.

### Layout đi cùng chữ lớn
- Không `FittedBox(scaleDown)`, auto-size giảm font, ép một dòng hay ellipsis với tiêu đề, nhãn nút, tab, hướng dẫn và lỗi quan trọng. Cho xuống dòng, tăng chiều cao và scroll; chỉ metadata không thiết yếu được truncate nếu có cách đọc đầy đủ.
- Button/row/field/nav dùng **minHeight**, không fixed height chặn nhiều dòng; có padding dọc để chữ và dấu tiếng Việt không chạm mép. Giữ target hiện có 72dp cho elderly; label wrap làm control cao hơn nếu cần. Không hạ target để nhét thêm nội dung.
- Bottom nav vẫn 3 đích, nhãn luôn hiện, có thể nhiều dòng và chiều cao thích ứng tại 200%; segmented tabs có thể scroll ngang. Không chuyển bottom nav thành grid hoặc giấu nhãn.
- Không giảm chữ ở màn hẹp. 320/360dp dùng padding phù hợp, bố trí dọc, scroll và giảm phần trang trí trước.
- `/today` vẫn ngoài phạm vi sửa file/layout. Theme hoặc component dùng chung có thể tác động chữ trên màn này: phải ghi rõ tác động gián tiếp và kiểm tra regression, không tự sửa dashboard để che overflow.

## Spacing / dimensions (dp)
- Base spacing scale: **4, 8, 12, 16, 20, 24, 32, 40, 48**. Dùng token, không tùy tiện 17/19/23.
- Screen horizontal padding: **20** elderly, **20–24** caregiver; compact <=360dp có thể 16 sau QA.
- Section gap: 24–32. Label-to-field: 8. Row/field gap: 12–16. Divider inset theo text.
- Card radius: 20–24 nếu thực sự là card; input: 14–16; button: 16–20; chip: pill.
- Elevation: ưu tiên **0**; overlay/raised surface soft elevation <=2, không nhiều shadow nặng.
- Tap targets: caregiver tối thiểu **48×48dp**, đề xuất 48–56dp; elderly trong repo này giữ **minTarget 72dp** cho button/row/field. Đây là minimum, tự tăng theo chữ wrap; không giảm để nhét thêm nội dung.
- App bar: nội dung linh hoạt; không cố định height=88 khi scaling gây overflow. Bottom nav min height theo typography + safe area, không fixed 96 cứng.
- Input field minHeight: **72dp elderly**, **56dp caregiver**; chữ nhập theo `bodyPrimary`, padding và chiều cao thích ứng khi scale.

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
