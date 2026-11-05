# 16 — Reference-first layout

> Latest readability override: greeting name, feature/detail/page headings use Be Vietnam Pro SemiBold 600. Only the intro wordmark stays serif. Category labels use 18sp/600. This supersedes the older serif-heading descriptions below.

Yêu cầu trực tiếp mới nhất: màn mở app giống panel 01 VELORA; main page giống panel 02; các màn còn lại đồng nhất theo đó. Ưu tiên yêu cầu này khi khác IA/typography của bản v2 cũ. Không tuyên bố literal pixel-perfect từ ảnh AI nếu chưa có source thiết kế.

- Launch `/intro`: botanical circle/waves tràn ngang, emblem nhỏ, wordmark serif Regular giãn chữ, tagline nhẹ, mô tả ngắn, 3 chấm có paging thật, một pine pill CTA đáy. Không nhét font picker hoặc tiêu đề chào mừng lớn vào bố cục chính. `/welcome` giữ onboarding và chọn cỡ chữ qua nút mở bottom sheet.
- CTA `/intro` → `/calendar` qua auth/role/onboarding guard hiện có. `/intro` chỉ public cho nội dung giới thiệu; không bỏ guard cho dữ liệu. Notification/deep links vẫn ưu tiên khi có pending event. Không delay timer giả.
- Main `/calendar`: greeting + profile name serif; dark pine feature với circular landscape phải; 3 tinted habit tiles; section lịch + thẻ actual task. Date picker và ngày trước/sau vẫn dùng thật. Metadata có date/status, không chế ra session/ratings.
- Navigation của Bác: 5 mục để theo anatomy mẫu — Trang chủ, Khám phá, Thói quen, Gia đình, Cá nhân. Dùng route thật hiện có. Explore và Habits chia sẻ activities branch với query rõ ràng; giữ selected state theo path/query. Caregiver giữ 3 khu vực công việc phù hợp vai trò.
- Detail: tranh tràn ngang, ivory sheet overlap, heading serif Regular, body sans Regular, CTA đúng chức năng. Settings/form/family dùng cùng type/palette và khoảng cách. Legacy `/today` không phải main route; source dashboard cũ chưa bị thay nội dung.
- Source screenshot chỉ nằm trong docs để review; artwork production là vector Dart vẽ lại. Không thay dữ liệu thật bằng meditation sample để giống hình.

QA: xem ảnh 390×844 và 360×800 cạnh reference; scale 1/1.5/2, giữ font thật. Chỉ sửa bố cục/size/weight sau khi xem ảnh; test pass không thay được visual review.
