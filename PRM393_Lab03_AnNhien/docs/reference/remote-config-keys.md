# Tra cứu: Khoá Remote Config

Giá trị mặc định nằm ở `firebase/remote-config-defaults.json`.

| Khoá | Kiểu | Mặc định | Tác dụng |
| --- | --- | --- | --- |
| `snooze_minutes` | số | `10` | Số phút của nút "Nhắc lại sau N phút" |
| `voice_input_enabled` | bool | `true` | Bật / tắt nút "Nói việc" (F5) |
| `home_max_upcoming` | số | `6` | Số việc tối đa hiện ở màn Hôm nay |

## Demo trên Firebase Console

1. Đổi `snooze_minutes` 10 → 15, publish.
2. Mở lại app: nút nhắc lại đổi thành "15 phút".
3. Tắt `voice_input_enabled`: nút "Nói việc" biến mất mà không cần build lại.
