# Bảng lệnh hay dùng

```bash
flutter pub get                 # lấy package
flutter analyze                 # phải sạch trước khi mở PR
flutter test                    # unit + widget test (service giả)
flutter test --update-goldens   # cập nhật ảnh golden khi UI đổi có chủ đích
dart format lib test            # định dạng code
flutter run -d emulator-5554    # chạy trên emulator Android
```

## Khi nào phải chạy lại

| Thay đổi | Cách áp dụng |
| --- | --- |
| Chỉ sửa code Dart | Hot reload (`r`) / hot restart (`R`) |
| Sửa `pubspec.yaml` hoặc `android/` | Dừng và `flutter run` lại |
| Lỗi build khó hiểu | Mới cân nhắc `flutter clean` |

## E2E (ARTEMIS)

Xem `e2e_test/README.md`.
