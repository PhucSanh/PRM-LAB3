# Đồng bộ UI còn sót — 2026-11-05

Nguồn hiện hành: palette VELORA của app, heading Be Vietnam Pro SemiBold 600 đã được người dùng yêu cầu để dễ đọc. Giữ font/size intro đã duyệt và auth Google/Firebase bật mặc định.

## Các điểm cũ đã xử lý

| Nhóm | Trước | Sau |
|---|---|---|
| Đăng nhập/chọn vai trò | Wordmark khác intro; role là đoạn văn + nút rời | Wordmark/artwork cùng intro; ô lựa chọn chung và CTA ghim đáy |
| Thẻ dùng chung | Trắng/transparent/outline lẫn nhau | AppSurface, CardTheme, SectionCard, NavRow cùng nền cream, radius 20; high-contrast outline giữ theo theme |
| Thói quen/form lịch | Màu nhấn bão hòa, icon trắng và hàng chọn chật | Palette sage/blush/lavender/pine; HabitTile dùng chung, trạng thái chữ dưới tên |
| Input | Nền trắng, viền dày và góc khác card | Nền cream, góc 16, viền nhẹ; focus/error vẫn rõ |
| Ngày/lặp/phạm vi | AppBar Material riêng và layout Center cố định | AppBackBar, CalmPageHeader, checkbox tiles cùng palette; nội dung cuộn |
| Quay lại | Factory đo padding khác nút thật, chia ngang cứng 50/50 làm mất chữ | Đo padding thực, chia đúng chiều rộng; xếp dọc khi chữ lớn |
| Reminder/suggestion/onboarding | Preview/quote viền nặng và footer kẻ ngang | Mảng cream, mép footer liền canvas, deck không shadow dày |
| Save success/error/offline | Icon khổng lồ, error Column thiếu vùng cuộn, nhãn đích cũ | IconCircle chung, error/offline cuộn được; Về trang chủ đúng route `/calendar` |
| Cài đặt/account/inbox/caregiver | Các khung riêng không cùng bề mặt | Cùng header, thẻ, màu/icon/typography từ các component chung |

[Xem ảnh](evidence/ui-consistency/index.html). Thêm 20 golden tại 360×800, scale 1 và 2 cho role, account, activity picker, repeat, profile, help, data, inbox, reminder và scope. Các golden home/detail/caregiver/settings và 64 kiểm tra typography đa kích thước tiếp tục chạy. Profile golden dùng stream snapshot hữu hạn trong fixture để tránh `.first` chờ cancel ở fake time; không sửa service production.

## Bảo toàn hành vi

Không đổi ViewModel/service/model, schema, notification payload, scheduling, guard hoặc vai trò. Kiểm tra vẫn bao gồm save/undo, dirty confirmation, chọn ngày/lặp, đăng nhập/đăng xuất và deep link. Dashboard `/today` giữ bố cục theo phạm vi ban đầu; các component dùng chung trên đó nhận theme mới, không bị thay tính năng.

TalkBack/VoiceOver và smoke với tài khoản production chưa được xác nhận trong lượt này; không có thiết bị adb kết nối. APK build từ `lib/main.dart` dùng Firebase thật, không phải preview tự đăng nhập.

## Kết quả cuối

- `flutter test`: **799 passed**, gồm toàn bộ golden comparison không dùng update mode.
- `flutter analyze`: **No issues found**.
- APK debug từ `lib/main.dart`: build thành công, giữ đăng nhập Google/Firebase bật mặc định.
- Đã kiểm tra ảnh role/settings/activity/repeat và sửa hai lỗi đọc chữ thực tế: header Quay lại bị cắt, ô hoạt động bị bóp cột.
- Thêm 20 golden ở 100%/200% cho các màn trước đây thiếu coverage; các luồng lưu/undo/auth/onboarding đều qua.
- `git diff --check`: sạch. Không xác nhận cài/emulator smoke vì adb chưa có thiết bị kết nối.
