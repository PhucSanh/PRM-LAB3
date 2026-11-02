# CLAUDE.md – An Nhiên (PRM393 Lab 3)

App Flutter Android lịch sinh hoạt Power 9 cho người 65+ ("Bác"), có chế độ thứ hai cho "Con cháu". Kiến trúc **MVVM + Riverpod**, backend **Firebase** (dự án `prm393-145c9`). Thiết kế gốc: Figma `K3JczHkChbUWoDBkXZYMhR` (Lab 2).

Ngôn ngữ làm việc: **tiếng Việt** (docs, commit message mô tả, câu chữ trong app). Tên biến / class tiếng Anh.

## Lệnh hay dùng

```bash
flutter pub get
flutter analyze                 # phải sạch trước khi mở PR
flutter test                    # test ViewModel bằng service giả
flutter run -d emulator-5554    # lần đầu build lâu (8 plugin Firebase); sau đó dùng hot reload
dart format lib test
```

Chỉ sửa code Dart thì hot reload / restart. Đổi `pubspec.yaml` hoặc `android/` thì phải `flutter run` lại. Không chạy `flutter clean` khi không cần.

## Đọc gì trước khi code một màn (theo thứ tự)

1. `../An-Nhien_Chia-task_Lab3.md` – feature của mình, danh sách màn + node Figma, mục **"Xong khi"**. **File này là phân công mới nhất (02/11/2026)**; bảng phân công trong `README.md` đã cũ (F14 nay là của Hiếu, slides nay là của Sanh).
2. `docs/design-traceability.md` – dòng của màn: node Figma, route, ViewModel, nguồn dữ liệu, trạng thái.
3. `docs/architecture.md` – thư mục, route map (mục 7), service (mục 8), ViewModel ↔ service (mục 9), Firestore (mục 10), widget dùng chung (mục 13), **luật bị chấm (mục 15)**.
4. Đặc tả màn trong tài liệu Lab 2 (`flutter-handoff.md`, tìm theo mã màn).
5. `AppStyleGuide.md` + `vocabulary.md` – câu chữ.
6. `docs/analytics-plan.md` – event của màn.
7. Sau khi làm: tự chấm theo `rule.md` (11 luật cho người 65+), cập nhật `docs/design-traceability.md` (+ `docs/architecture.md` nếu thêm ViewModel / service / route).

**Lưu ý đường dẫn Lab 2:** docs ghi `docs/lab2/…` nhưng thư mục này **chưa có trong repo**. Tới khi được chép vào, đọc bản gốc ở repo Lab 2 (`../../prm393-lab2-an-nhien/`):

| Docs ghi | Bản gốc trong repo Lab 2 |
| --- | --- |
| `lab2/flutter-handoff.md` | `flutter-handoff.md` |
| `lab2/user-flow.md` | `ux/user-flow.md` |
| `lab2/persona.md` | `ux/persona.md` |
| `lab2/rule.md`, `lab2/accessibility.md`, `lab2/design-decisions.md` | cùng tên ở thư mục gốc |
| `lab2/design-tokens.md` | `assets/stitch/DESIGN.md` |
| `lab2/AppStyleGuide.md`, `lab2/vocabulary.md`, `lab2/PRD.md` | `assets/stitch/` cùng tên |

Tài liệu Lab 2 là **chỉ đọc**. Muốn lệch thiết kế: ghi dòng `DT-xx` cuối `docs/design-traceability.md` + sửa Figma. Figma lệch Stitch thì Figma thắng.

## Kiến trúc

```
lib/
  theme/       token Lab 2 → AppColors, HabitPalette, AppSpacing, AppRadius, AppSizes, AppTheme
  widgets/     component Lab 2 dùng chung (AppButton, AppBackBar, AppShell, Loading/Empty/ErrorView…)
  router/      go_router (app_router.dart); redirect đăng nhập / vai trò
  models/      lớp Dart thuần, fromMap/toMap
  services/    interface + Fake… + Firebase…; providers.dart = nơi DUY NHẤT chọn bản dùng
  viewmodels/  Riverpod Notifier giữ UiState; ui_state.dart
  screens/<feature>/  màn hình
  utils/       AppException (userMessage = câu cho Bác)
test/          test ViewModel (override bằng Fake)
e2e_test/      ARTEMIS (pytest)
firebase/      firestore.rules, storage.rules, remote-config-defaults.json
```

Mẫu để chép khi làm màn mới: `lib/screens/today/` + `lib/viewmodels/today_view_model.dart` + `test/today_view_model_test.dart`. Màn chưa làm là `FeaturePlaceholder` trong `lib/router/app_router.dart`: làm màn nào thì thay đúng dòng đó.

Luồng: View gửi sự kiện → ViewModel (`Notifier`) gọi service qua interface → trả `UiState` → View vẽ bằng `switch`.

```dart
sealed class UiState<T> {}   // UiLoading → LoadingView · UiEmpty → EmptyView · UiError → ErrorView + "Thử lại" · UiData
```

Hành động một lần (lưu, xoá, dời…) trả kết quả về View để hiện Snackbar / điều hướng; View không tự gọi service.

## Luật bị chấm (architecture.md mục 15) – không được vi phạm

1. Widget / screen **không** gọi `FirebaseAuth.instance`, `FirebaseFirestore.instance`, `FirebaseAnalytics.instance`, `http`… Chỉ đi qua service.
2. Logic nằm trong ViewModel / service, **không** nằm trong `build()`.
3. Mỗi màn tải dữ liệu có `UiState` riêng, vẽ đủ **Loading / Empty / Error (+ Thử lại) / Data**.
4. Service tiêm qua `lib/services/providers.dart`; test ViewModel bằng `overrideWithValue(Fake…)`, không phụ thuộc mạng.
5. **Không** viết cứng màu, cỡ chữ, khoảng cách: chỉ dùng `lib/theme/`.
6. Câu chữ theo `AppStyleGuide.md` + `vocabulary.md`; thiết kế theo `rule.md`.
7. Màn của mọi người **chỉ** dùng widget trong `lib/widgets/`. Thiếu widget → báo Sanh (F0), không tự làm bản riêng trong thư mục màn.

## Ràng buộc UI cho người 65+

- Màn 360 × 800 dp; kiểm tra ở **360 và 412 dp**, không tràn chữ.
- Chữ Be Vietnam Pro, **không có chữ < 20 sp**. Cỡ chữ người dùng chọn = `textScaler` 1.0 / 1.15 / 1.3 toàn app; layout phải chịu được 2.0.
- Vùng chạm tối thiểu `AppSizes.minTarget` (72 dp), cách nhau `AppSpacing.betweenTargets`; nút chính 60 dp.
- Bottom nav 4 tab có nhãn, `maxLines: 1`. Nút Back có chữ ("Quay lại").
- Mọi thay đổi có **Hoàn tác** (`UndoSnackbar`, không tự tắt). Xoá / ngưng lịch phải hỏi lại và nói rõ hậu quả.
- Lỗi nhập có ví dụ ("Ví dụ…"), `errorText` có icon. Tương phản cao = đổi `ColorScheme`.
- Biến thể Figma (S03-later, G08b…) là **state** của màn gốc, không phải route mới.

## Service, dữ liệu, Firebase

- Mỗi service có bản `Fake…` (chạy ngay, dùng cho test) và `Firebase…`. Production trong `providers.dart` đang dùng bản Firebase.
- Service cần thêm (architecture.md mục 8.2): người làm feature viết **interface + Fake**; **Hiếu** viết bản Firebase. Package Firebase: Hiếu thêm. Package khác: đề xuất trong PR.
- Firestore: `users/{uid}` (role, settings…), `users/{uid}/tasks|completions|family|notifications`, `users/{momUid}/suggestions`, `pairings/{code}`, `habits/{key}`; Storage `reports/{uid}/{week}.pdf`. Trường mới: đề xuất trong PR, Hiếu chốt.
- 9 khoá thói quen: `move`, `purpose`, `downshift`, `eighty`, `plant`, `tea`, `belong`, `family`, `tribe` (không hard-code danh sách, nạp từ `habits`).
- Remote Config: `snooze_minutes` (10), `voice_input_enabled` (true), `home_max_upcoming` (6).
- Lỗi: service bắt exception SDK → ném `AppException`; ViewModel chỉ đọc `userMessage`. Lỗi thật (lưu việc, upload PDF) → `CrashService.recordError` (non-fatal).

## Analytics

- Gọi `AnalyticsService.logEvent` **trong ViewModel**, không trong widget. Tên event `snake_case` ≤ 40 ký tự, theo bảng trong `docs/analytics-plan.md`.
- **Không** gửi tên, e-mail, số điện thoại, nội dung tin nhắn, tên việc tự gõ. Chỉ gửi khoá (`habit_key`), số, cờ.

## Phân quyền thư mục (ai sở hữu gì)

| Người | Feature | Sở hữu |
| --- | --- | --- |
| Sanh | F0, F8, F12 – UI + ViewModel bằng AI agent; điều phối AI code review; report + slides | `lib/theme/`, `lib/widgets/`, khai báo route trong `lib/router/`, `docs/design-traceability.md`, `docs/architecture.md`, `docs/code-review.md` |
| Hiếu | F1, F10, F13, F14 + toàn bộ Firebase / hạ tầng | `lib/services/` (bản Firebase + `providers.dart`), `lib/models/`, `firebase/`, `android/`, redirect trong router, `docs/analytics-plan.md` |
| Khang | F3, F4, F5, F6 | màn + ViewModel của mình |
| Hương | F2, F7, F9, F11; điều phối test | màn + ViewModel của mình, `e2e_test/conftest.py`, `docs/test-plan.md` |

Khi làm việc cho Sanh: **không** sửa `android/`, `firebase/`, bản `Firebase…` của service hay `providers.dart` (trừ khi được yêu cầu rõ). F8 dùng interface `SettingsService` / `ProfileService`, F12 dùng `SuggestionService`, chạy bằng bản Fake cho tới khi Hiếu nối Firebase. Thẻ G12 trên Hôm nay là widget `SuggestionCard` trong `lib/widgets/`, không sửa code F3 của Khang. ViewModel dùng chung có một chủ (xem architecture.md mục 9); muốn thêm state thì mở PR nhờ chủ duyệt.

## Git

- Nhánh: `feat/<mã-feature>-<mô-tả>` (vd. `feat/F0-nen-tang`, `feat/F12-goi-y-lich`), mở PR vào `main`. PR nhỏ, một việc.
- **F0 phải merge trước** khi ai code màn. Lịch sử git phải theo thứ tự 8 bước của đề: docs → Firebase / đăng nhập → feature → instrumentation → test → code review → report.
- Commit mỗi ngày bằng tài khoản GitHub của chính người làm. Bản sửa từ AI review: commit `fix(CR-xx): <mô tả>` và ghi vào `docs/code-review.md`.
- Không commit tài khoản test, API key, `local.properties`.

## Checklist trước khi mở PR

- [ ] `flutter analyze` sạch, `flutter test` qua.
- [ ] Màn vẽ đủ Loading / Empty / Error + Thử lại / Data.
- [ ] Không màu / cỡ chữ / spacing cứng; chỉ dùng widget trong `lib/widgets/`.
- [ ] Đúng ở 360 và 412 dp, `textScaler` 1.3 không tràn.
- [ ] Có test ViewModel với service Fake (cả nhánh Empty / Error).
- [ ] Event analytics đã gắn theo `docs/analytics-plan.md`.
- [ ] Cập nhật trạng thái màn trong `docs/design-traceability.md` (`todo` → `doing` → `done` / `changed` + DT-xx).
- [ ] Đối chiếu mục "Xong khi" của feature trong file chia task.
