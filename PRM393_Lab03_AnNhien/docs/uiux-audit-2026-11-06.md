# Rà soát và tối ưu UI/UX — 2026-11-06

## Thay đổi đã thực hiện

| Vấn đề tìm được | Kết quả |
|---|---|
| Nút, thanh điều hướng và nhóm trên home mất action do excludeSemantics | Bổ sung action trên node; test kích hoạt semantics thực sự gọi callback/mở đúng màn |
| Ô nhập chỉ có nhãn hiển thị rời | Gộp nhãn với editable semantics, giữ setText; thêm Done và chạm ngoài để đóng bàn phím |
| CTA thêm việc chìm dưới danh sách dài | CTA cố định; bộ chọn ngày trước danh sách; truyền ngày qua route/form |
| Chi tiết thói quen bắt chọn lại | Mở thẳng form giờ với đúng nhóm và tên; fallback summary đúng nhóm |
| Nhãn 5 tab bị bẻ từng chữ ở 200% | Menu danh sách ở text scaler >1.6 trên màn hẹp; không giảm chữ |
| Lỗi giờ lại báo tên trống | Lỗi riêng từng trường; focus/scroll tới phần cần sửa; giới hạn tên 80 ký tự |
| Có thể gọi lưu chồng; thông báo lỗi giống đã lưu offline | Chặn lần gọi khi đang lưu; thông báo chưa lưu, giữ draft để thử lại |
| Tài khoản hiện thao tác cả hai vai trò | Chỉ hiện ghép nối đúng vai trò; công cụ thử nghiệm chỉ debug |
| Tab đã lưu dẫn tới chức năng chưa có | Ẩn khỏi lựa chọn thông thường; deep link cũ giữ giải thích và lối ra |

## Kiểm chứng

- `flutter test`: **847 tests passed** (`/tmp/uiux-accepted-tests.log`).
- Sau thay API test semantics từ deprecated pipelineOwner sang binding event: chạy lại widget/button + migration, **117 tests passed** (`/tmp/uiux-final-semantics.log`).
- Golden có font Be Vietnam Pro/Noto thật; xem trực tiếp ảnh home 390dp/100%, home 360dp/200%, detail 360dp/200%. Bộ migration kiểm tra màn 320/390/800dp ở 200%, cùng golden 360/390dp ở 100/150/200%.
- `flutter analyze`: **No issues found** (`/tmp/uiux-final-analyze.log`).
- `flutter build apk --debug -t lib/main.dart`: **thành công**, APK `build/app/outputs/flutter-apk/app-debug.apk` (`/tmp/uiux-final-build.log`). Gradle có cảnh báo tương thích Kotlin/plugin, không chặn build.
- `git diff --check`: sạch.

## Giới hạn thực tế

Không có thiết bị/emulator Android kết nối để nghiệm thu TalkBack, bàn phím và tích hợp native trên máy thật; test semantics không được coi là thử TalkBack thực tế. Chưa có usability study với người cao tuổi.

Trạng thái backend từ lượt trước giữ nguyên: Firestore rules đã deploy; Firebase Functions chưa deploy vì project cần Blaze. Luồng ghép nối/gợi ý thật vẫn cần giải quyết điều kiện triển khai đó và thử end-to-end trước khi gọi toàn app sẵn sàng production. Lượt này không đổi billing hay backend schema.
