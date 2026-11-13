# Quy ước commit

Repo dùng dạng **Conventional Commits**: `<loại>(<phạm vi>): <mô tả>`.

| Loại | Khi nào dùng | Ví dụ |
| --- | --- | --- |
| `feat` | Thêm tính năng | `feat(F4): thêm màn sửa việc` |
| `fix` | Sửa lỗi | `fix(CR-07): bắt lỗi mất mạng khi lưu việc` |
| `docs` | Chỉ sửa tài liệu | `docs(index): thêm mục tài liệu kỹ thuật` |
| `test` | Thêm / sửa test | `test(F3): thêm test nhánh Empty` |
| `refactor` | Đổi cấu trúc, không đổi hành vi | `refactor(router): tách redirect` |
| `style` | Định dạng, không đổi logic | `style: dart format` |
| `chore` | Việc phụ (cấu hình, script) | `chore: cập nhật .gitignore` |

- Bản sửa từ AI review: `fix(CR-xx): …` và ghi vào `docs/code-review.md`.
- Mỗi commit một việc; commit bằng tài khoản GitHub của chính người làm.
