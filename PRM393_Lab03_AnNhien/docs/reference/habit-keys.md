# Tra cứu: 9 khoá thói quen Power 9

Nguồn dữ liệu: `firebase/habits.json` (nạp vào collection `habits/{key}`). App **không** hard-code danh sách này; bảng dưới chỉ để tra cứu nhanh.

| Khoá | Tên hiển thị |
| --- | --- |
| `move` | Vận động tự nhiên |
| `purpose` | Sống có mục đích |
| `downshift` | Thư giãn mỗi ngày |
| `eighty` | Ăn vừa đủ |
| `plant` | Ăn nhiều rau, đậu |
| `tea` | Trà chiều cùng bạn |
| `belong` | Gắn kết cộng đồng |
| `family` | Gia đình trên hết |
| `tribe` | Bạn bè tích cực |

- Màu của từng thói quen: `HabitPalette` trong `lib/theme/app_colors.dart`.
- Analytics chỉ gửi khoá (`habit_key`), không gửi tên hiển thị.
