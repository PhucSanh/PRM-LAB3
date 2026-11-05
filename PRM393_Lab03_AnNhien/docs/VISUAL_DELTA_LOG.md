> **Intro mới nhất:** người dùng yêu cầu chữ lớn/đậm hơn trên ảnh intro. Đã cập nhật wordmark Noto Serif 38/tracking 1.5, tagline 16/600, description 20/600 và CTA 20/600 với target 64dp. Các giá trị intro này thay các mô tả Regular ở dưới; typography ngoài intro giữ nguyên. Xem golden welcome mới; Android screenshots cũ là trước chỉnh sửa này.

# VELORA reference-first — bản hiện hành

Người dùng đã bác bỏ font/độ đậm và bố cục của lượt v2 trước. Yêu cầu mới: dựng sát màn giới thiệu và main page của VELORA trước, rồi chọn font/size rõ cho người lớn tuổi, đồng nhất các màn còn lại. Các báo cáo typography v1.1 và evidence `velora-v2/` là lịch sử, không phải baseline để khôi phục.

[Đối chiếu từng panel mẫu với app](evidence/velora-reference-first/comparison.html). [Yêu cầu layout hiện hành](AnNhien_VELORA_Visual_Replication_Spec_v2/docs/uiux/16_REFERENCE_FIRST_LAYOUT.md). [Typography hiện hành](AnNhien_VELORA_Visual_Replication_Spec_v2/docs/uiux/15_ACCESSIBLE_TYPOGRAPHY_OVERRIDE.md).

## Đã sửa sau phản hồi

| Vấn đề cũ | Bản hiện hành |
|---|---|
| Serif Bold và body 24/600 làm cả màn quá nặng | Noto Serif Display Regular thật cho heading ngắn; Be Vietnam Pro Regular cho nội dung; semibold chỉ ở title/action |
| Font picker và tiêu đề chào lớn chen vào welcome | `/intro` gồm artwork, emblem, wordmark giãn chữ, tagline, đoạn mô tả ngắn, pager có hoạt động và pine CTA đáy |
| Main là trang lịch có banner trang trí | Greeting/name → featured pine với landscape tròn phải → 3 ô tint → section + thẻ task thật |
| 3 tab không khớp anatomy home mẫu | Bác có 5 đích thật: Trang chủ, Khám phá, Thói quen, Gia đình, Cá nhân. Caregiver giữ 3 khu vực công việc |
| Date controls đẩy task ra ngoài màn đầu | Thẻ task gọn xuất hiện trước các nút ngày trước/sau; date picker vẫn truy cập ngay qua Xem lịch |
| CTA/heading bị cắt khi chữ lớn | Nút và header reflow, primary target 56dp, góc bo có giới hạn; không khóa scale hay FittedBox |

Body Bác 18sp × cỡ Lớn mặc định 1.15 ≈ 20.7sp; secondary 16, metadata/nav 14, page heading 30 Regular. Giữ lựa chọn cỡ chữ và cơ chế scale đến ×2. Các form, cài đặt, gia đình, auth, suggestion và detail dùng cùng nền matte, pine, font, pill và khoảng cách. Short section dùng sans, không biến mọi nhãn thành serif.

## Ba khác biệt chính cần biết khi đối chiếu

| Màn | Khác biệt 1 | Khác biệt 2 | Khác biệt 3 |
|---|---|---|---|
| Intro | Brand/copy An Nhiên tiếng Việt | Body/CTA lớn hơn chữ rất nhỏ trong mockup | Artwork vẽ lại bằng Dart thay ảnh gốc |
| Main | Nội dung thói quen/lịch thật thay thiền mẫu | Metadata/date/status đúng repository | Nav tiếng Việt và tên dài có thể xuống dòng |
| Hoạt động | 9 habit keys thật thay catalogue thiền | Saved là unavailable state trung thực | Cards/columns reflow ở cỡ chữ lớn |
| Habit detail | Description thật thay ratings/session count | CTA lên lịch thay subscription price | Không chế audio player |
| Task detail | Thời gian/trạng thái/lời nhắc thật | Edit/complete đúng ngày được phép | Long content cuộn, serif chỉ cho title |
| Caregiver | Lịch/suggestion có quyền truy cập thật | Form/time/message giữ nguyên hành vi | Navigation phù hợp 3 khu vực công việc |
| Family/contact editor | Contact/pairing permissions thật | Field validation và dirty confirmation | Copy phone/Save/Undo giữ hành vi |
| Settings/account/inbox/onboarding | Không có panel tương ứng cụ thể trong 4 ảnh mẫu | Dùng cùng visual system | Errors/permissions/undo không bị bỏ vì bố cục |

Không gọi bản này là đo pixel-perfect từ Figma: nguồn là ảnh mockup AI. Mẫu được mở và xem lại từ link người dùng cùng ảnh đính kèm. Không ship tên VELORA, source artwork, fake OS chrome, subscription, ratings hay meditation data vào sản phẩm.

## Asset và phạm vi

- Font Noto Serif Display Regular/Bold bundled; font Việt đủ dấu; OFL được đóng gói và đăng ký Flutter LicenseRegistry. Be Vietnam Pro giữ local.
- Artwork: `lib/widgets/botanical_scene.dart`, không tải mạng, không ảnh nguồn production. Reference chỉ lưu trong docs để đối chiếu.
- `/intro` public chỉ là nội dung giới thiệu. Bắt đầu → protected home qua guard hiện có; auth/deep links/notification vẫn được kiểm tra. `/welcome` giữ luồng onboarding; chọn chữ trong bottom sheet.
- Không sửa dashboard source `/today`, services, models, Firebase rules/schema, reminder scheduling hay notification payloads. Main mới là `/calendar`.

## QA

- Bộ ảnh actual-font: 360×800 / 390×844, hệ thống ×1 / ×1.5 / ×2. Có kiểm tra low-width và high-contrast, không shrink chữ.
- Android: build/dev launch thành công; đã bấm Bắt đầu từ intro sang home, lưu screenshots thật, chụp home 200% và khôi phục system font scale đúng 1.0 ban đầu.
- TalkBack, VoiceOver, physical-device và production-account Firebase E2E chưa được xác nhận; dev screenshots dùng fake repositories.

## Kết quả cuối

- `flutter test`: **777 passed**, bao gồm so sánh golden cuối không dùng `--update-goldens`.
- `flutter analyze`: **No issues found**.
- `flutter build apk --debug --no-pub -t lib/main_dev.dart`: thành công; bản dev dùng fake services.
- 36 ảnh VELORA ở 6 màn ×2 kích thước ×3 mức scale, 8 route snapshots và 4 typography snapshots; xem trực tiếp trước khi chốt.
- Đã kiểm tra intro paging, 5 đích điều hướng thật, quay lại từ account và intro CTA không vượt auth guard.
- `git diff --check`: sạch. Không có thay đổi ở `/today` source, services, models, Firebase hay Android integration.
