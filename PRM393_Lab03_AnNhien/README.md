# An Nhiên – PRM393 Lab 3 (Flutter + Firebase)

Lịch sinh hoạt Power 9 cho người 65+. App Flutter Android, kiến trúc MVVM + Riverpod, backend Firebase.
Thiết kế: [Figma](https://www.figma.com/design/K3JczHkChbUWoDBkXZYMhR/Untitled) · Lab 2: repo `prm393-lab2-an-nhien`.

## Nhóm và phân công

| Người | Feature | Thư mục sở hữu |
| --- | --- | --- |
| **Sanh** (trưởng nhóm) | F0 Nền tảng · F8 Cài đặt & hồ sơ · F12 Gợi ý lịch · F14 Con cháu lập lịch (Flow 11, 12) · điều phối code review · report | `lib/theme/`, `lib/widgets/`, `lib/router/`, `docs/design-traceability.md`, `docs/architecture.md`, `docs/code-review.md` |
| **Hiếu** | F1 Tài khoản + chọn vai trò · F10 Firebase · F13 Ghép nối (Flow 10) · slides | `lib/services/`, `lib/models/`, `firebase/`, `android/`, `docs/analytics-plan.md` |
| **Khang** | F3 Hôm nay · F4 Thêm/sửa/xoá việc · F5 Giọng nói · F6 Lời nhắc (Flow 2, 3, 6, 7) · video | màn + ViewModel của feature mình |
| **Hương** | F2 Onboarding · F7 Lịch tuần + PDF · F9 Thói quen · F11 Gia đình (Flow 1, 4, 5, 8, 9) · điều phối test · video | màn + ViewModel của feature mình, `e2e_test/conftest.py`, `docs/test-plan.md` |

Mỗi người tự làm: ít nhất 1 ViewModel, test ARTEMIS cho flow của mình (≥ 3 lần), analytics event cho màn mình, sửa ≥ 1 phát hiện code review. Thầy có thể hỏi riêng từng người.

Chi tiết từng feature và màn Figma: `docs/design-traceability.md` (và `../An-Nhien_Chia-task_Lab3.pdf`).

## Cài đặt lần đầu (chỉ Sanh làm 1 lần, rồi commit)

```bash
# 1. Sinh thư mục android/ (không ghi đè lib/ đã có)
flutter create . --org com.annhien --project-name an_nhien --platforms android

# 2. Lấy package (pubspec.yaml đã có sẵn) và chạy thử bằng service giả, chưa cần Firebase
flutter pub get
flutter test
flutter run
```

Sau đó đổi tên thư mục `github-templates/` thành `.github/` (chứa CODEOWNERS + mẫu PR) và điền GitHub username thật vào `CODEOWNERS`.

## Nối Firebase (Hiếu, ngày 1)

```bash
dart pub global activate flutterfire_cli
flutterfire configure            # tạo lib/firebase_options.dart + android/app/google-services.json
flutter pub add firebase_core firebase_auth google_sign_in cloud_firestore firebase_storage firebase_messaging firebase_analytics firebase_crashlytics firebase_remote_config
```

Sau đó mở `lib/main.dart` gọi `Firebase.initializeApp`, viết bản `Firebase…` của từng service trong `lib/services/` và đổi trong `lib/services/providers.dart`.

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
| ARTEMIS (commit) | |

## Link nộp

- Demo video: _(điền)_
- Report: `report/Lab03_<ID>.pdf` · Slides: `slides/Lab03_<ID>_slides.pdf`
