# An Nhiên – PRM393 Lab 3 (Flutter + Firebase)

Lịch sinh hoạt Power 9 cho người 65+. App Flutter Android, kiến trúc MVVM + Riverpod, backend Firebase.
Thiết kế: [Figma](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled) · Lab 2: repo `prm393-lab2-an-nhien`.

## Nhóm và phân công

| Người | Feature | Thư mục sở hữu |
| --- | --- | --- |
| **Sanh** (trưởng nhóm) | F0 Nền tảng · F8 Cài đặt & hồ sơ · F12 Gợi ý lịch · điều phối code review · report + slides | `lib/theme/`, `lib/widgets/`, `lib/router/`, `docs/design-traceability.md`, `docs/architecture.md`, `docs/code-review.md` |
| **Hiếu** | F1 Tài khoản + chọn vai trò · F10 Firebase · F13 Ghép nối (Flow 10) · F14 Con cháu lập lịch (Flow 11, 12) | `lib/services/`, `lib/models/`, `firebase/`, `android/`, `docs/analytics-plan.md` |
| **Khang** | F3 Hôm nay · F4 Thêm/sửa/xoá việc · F5 Giọng nói · F6 Lời nhắc (Flow 2, 3, 6, 7) · video | màn + ViewModel của feature mình |
| **Hương** | F2 Onboarding · F7 Lịch tuần + PDF · F9 Thói quen · F11 Gia đình (Flow 1, 4, 5, 8, 9) · điều phối test · video | màn + ViewModel của feature mình, `e2e_test/conftest.py`, `docs/test-plan.md` |

Mỗi người tự làm: ít nhất 1 ViewModel, test ARTEMIS cho flow của mình (≥ 3 lần), analytics event cho màn mình, sửa ≥ 1 phát hiện code review. Thầy có thể hỏi riêng từng người.

Chi tiết từng feature và màn Figma: `docs/design-traceability.md` (và `../An-Nhien_Chia-task_Lab3.md`).

## Cài đặt lần đầu (chỉ Sanh làm 1 lần, rồi commit)

```bash
# android/ đã có trong repo; không cần chạy flutter create lại.

# 2. Lấy package và chạy unit test (test override bằng service giả)
flutter pub get
flutter test
# flutter run: cần hoàn thành cấu hình Firebase Android bên dưới trước
```

`.github/` ở gốc repo đã có CODEOWNERS, mẫu PR và CI. Xem hướng dẫn bên dưới để bật AI review.

## Nối Firebase (Hiếu, ngày 1)

Hướng dẫn hiện hành và các bước Console: [docs/firebase-setup.md](docs/firebase-setup.md). Kết quả đã chạy và blocker: [docs/firebase-verification.md](docs/firebase-verification.md). Provider production đã dùng adapter Firebase; TaskRepository đang chờ nhóm thống nhất schema ngày/occurrence. Đã cấu hình dự án Firebase PRM393 (`prm393-145c9`) cho Android; kiểm chứng runtime trên thiết bị và các blocker khác được ghi trong tài liệu.

```bash
dart pub global activate flutterfire_cli
flutterfire configure            # tạo lib/firebase_options.dart + android/app/google-services.json
flutter pub add firebase_core firebase_auth google_sign_in cloud_firestore firebase_storage firebase_messaging firebase_analytics firebase_crashlytics firebase_remote_config
```

`main.dart` đã gọi `Firebase.initializeApp` trước khi chạy app; các provider đã đăng ký adapter Firebase. Cần chạy FlutterFire với project ID thật, kiểm tra cấu hình sinh ra và xử lý các blocker trong tài liệu trước khi chạy trên Android.

## Cách làm việc

1. Mỗi người làm trên nhánh `feat/<mã-feature>-<mô-tả>` (vd. `feat/F4-them-viec`), mở PR vào `main`.
2. PR nhỏ, một việc. Sanh duyệt trong ngày; AI review chạy trên PR (ghi vào `docs/code-review.md`).
3. Màn chưa làm đang là `FeaturePlaceholder` trong `lib/router/app_router.dart`: làm màn nào thì thay đúng dòng đó.
4. Code theo mẫu: `lib/screens/today/` + `lib/viewmodels/today_view_model.dart` + `test/today_view_model_test.dart`.
5. Commit mỗi ngày. Thứ tự lịch sử git theo 8 bước của đề (docs trước, rồi Firebase, rồi feature…).

## Cấu trúc

```
lib/
  main.dart, app.dart
  theme/        token Lab 2 → ThemeData
  widgets/      component Lab 2 dùng chung
  router/       go_router + chặn khi chưa đăng nhập
  models/       lớp dữ liệu thuần
  services/     interface + Fake (+ Firebase); providers.dart chọn bản dùng
  viewmodels/   Riverpod Notifier + UiState
  screens/      màn hình theo feature
  utils/        AppException
test/           test ViewModel bằng service giả
e2e_test/       ARTEMIS (pytest)
firebase/       firestore.rules, storage.rules, remote-config-defaults.json
docs/           design-traceability, architecture, analytics-plan, test-plan, code-review
evidence/ report/ slides/
```

## Phiên bản (điền khi chốt)

| Công cụ | Phiên bản |
| --- | --- |
| Flutter | |
| Dart | |
| Package | xem `pubspec.lock` |
| ARTEMIS (commit) | `351ca8422f7b5b54e80a9c1ce03a222e02415b6b` (`artemis-client`) |

## Link nộp

- Demo video: _(điền)_
- Report: `report/Lab03_<ID>.pdf` · Slides: `slides/Lab03_<ID>_slides.pdf`


## Phần Hiếu — cập nhật 04/11/2026

Hướng dẫn đầy đủ: [docs/hieu-implementation-guide.md](docs/hieu-implementation-guide.md).

```bash
flutter run -t lib/main_dev.dart # demo Fake, mở hub /demo, guard mặc định tắt
bash scripts/check-hieu.sh      # analyzer + Flutter tests + backend/rules Emulator
bash scripts/native-emulator-check.sh emulator-5556 # Firebase SDK trên Android local
```

F13/F14 đã có code và test; backend cloud chưa deploy trong phiên này. Để thử Firebase
local bằng giao diện hai máy, xem `main_emulator.dart` trong guide. Native integration
không thay bằng chứng ARTEMIS/Google Sign-In/FCM/Console/Storage production.
