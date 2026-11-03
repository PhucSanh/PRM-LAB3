# Công việc Hiếu — triển khai 03/11/2026

## Quyết định phiên làm việc

- Theo yêu cầu người dùng: **guard mặc định tắt**, mở `/today` để test demo. Không đổi Firebase rules thành public.
- `AUTH_GUARD=true` là tuỳ chọn kiểm thử nghiệm thu riêng; test auth tự bật bằng provider override.
- Commit theo mốc, ghi kết quả kiểm tra thật. Không coi test Fake là Firebase/thiết bị thật.
- Không bật billing, không tạo bucket hoặc tự bật Google provider. Không gửi thông báo cho người khác.

## Chạy

Từ thư mục `PRM393_Lab03_AnNhien`:

```bash
flutter pub get
flutter run -t lib/main_dev.dart  # demo Fake, không cần Firebase
flutter run -t lib/main.dart     # Firebase thật, guard vẫn tắt
flutter run --dart-define=AUTH_GUARD=true # chỉ khi cần nghiệm thu F1
flutter test test/auth_routing_test.dart test/account_view_model_test.dart test/f10_test.dart
```

## Mốc 1: demo và kiểm thử F1

Tách tuỳ chọn guard khỏi code comment; giữ mặc định false. Khôi phục logic auth/role/onboarding cho test opt-in; notification pending được xử lý độc lập khi demo. Không bật guard của bản demo. Test auth bật riêng nên không cần bỏ test hay thay expected cho qua.

Các phần tiếp theo và kết quả kiểm tra sẽ được bổ sung sau mỗi mốc.
