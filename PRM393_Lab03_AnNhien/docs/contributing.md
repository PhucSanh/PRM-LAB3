# Hướng dẫn đóng góp

1. Tạo nhánh từ `main`: `feat/<mã-feature>-<mô-tả>` (vd. `feat/F4-them-viec`).
2. Đọc tài liệu theo thứ tự trong [onboarding-new-member.md](onboarding-new-member.md).
3. Code theo MVVM: View → ViewModel → service (qua interface trong `providers.dart`).
4. Viết test ViewModel với service Fake, có cả nhánh Empty / Error.
5. Chạy `flutter analyze` và `flutter test`.
6. Commit theo [commit-convention.md](commit-convention.md).
7. Mở PR vào `main`, điền mẫu PR, tự chấm theo [pr-checklist.md](pr-checklist.md).
8. Sau khi merge: cập nhật trạng thái màn trong `docs/design-traceability.md`.

Không commit tài khoản test, API key hay `local.properties`.
