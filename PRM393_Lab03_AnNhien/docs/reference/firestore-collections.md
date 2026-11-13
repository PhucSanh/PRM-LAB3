# Tra cứu: Collection Firestore & Storage

Bản đầy đủ (kèm trường chi tiết): `docs/architecture.md` mục 10. Bảng này chỉ tóm tắt để tra nhanh.

| Đường dẫn | Ai ghi | Feature |
| --- | --- | --- |
| `users/{uid}` | chủ tài khoản | F1, F2, F8 |
| `users/{uid}/tasks/{taskId}` | chủ (con cháu đã ghép nối chỉ đọc) | F3, F4, F5, F7, F14 |
| `users/{uid}/completions/{date_taskId}` | chủ (con cháu đã ghép nối chỉ đọc) | F3, F6, F9, F14 |
| `users/{uid}/family/{personId}` | chủ | F11 |
| `users/{uid}/notifications/{id}` | chủ | F10 |
| `users/{momUid}/suggestions/{id}` | con cháu đã ghép nối tạo, mẹ cập nhật | F12, F14 |
| `pairings/{code}` | máy mẹ tạo, hết hạn sau 10 phút | F13 |
| `habits/{key}` | chỉ đọc từ app | F9 |
| Storage `reports/{uid}/{week}.pdf` | chủ, tối đa 5 MB | F7 |

Quy tắc bảo mật: `firebase/firestore.rules`, `firebase/storage.rules`.
