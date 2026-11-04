# Prompt F8 · Cài đặt hiển thị & hồ sơ (Sanh)

Chạy **lần lượt** từng file trong nhánh F8, mỗi file một phiên agent mới (dán: "Đọc và thực hiện `docs/prompt/F8/0x-….md`"). Xong mỗi bước: đọc mục "Kết quả chạy" ở cuối file, trả lời câu agent hỏi, chạy thử trên máy, rồi commit trước khi sang bước sau.

| Bước | File | Làm gì | Commit gợi ý |
| --- | --- | --- | --- |
| 01 | `01-viewmodel-cai-dat.md` | `SettingsViewModel`, khung `ProfileViewModel`, nạp cài đặt khi mở app | `feat(F8): SettingsViewModel, khung ProfileViewModel, nạp cài đặt khi mở app` |
| 02 | `02-s10-cai-dat.md` | S10 Cài đặt hiển thị + Đăng xuất | `feat(F8): màn S10 Cài đặt hiển thị, đổi cỡ chữ toàn app, đăng xuất` |
| 03 | `03-n06-ho-so.md` | N06 Thông tin của Bác + giữ lối vào khu demo F10 | `feat(F8): màn N06 sửa hồ sơ, có Hoàn tác và hỏi khi chưa lưu` |
| 04 | `04-n08-n20-tinh.md` | N08 Cách dùng đơn giản, N20 Dữ liệu trên điện thoại | `feat(F8): màn N08 Cách dùng đơn giản và N20 Dữ liệu trên điện thoại` |
| 05 | `05-kiem-tra-pr.md` | Test cả luồng, quét luật, chốt docs, soạn `PR-F8.md` | `test(F8): test cả luồng cài đặt, chốt docs và PR-F8` |

Agent sẽ **dừng lại hỏi** ở các chỗ sau, nên chuẩn bị câu trả lời trước:

- Bước 01: nguồn đọc `honorific` / `wakeTime` cho N06 – (a) thêm `watchSetup` vào `ProfileSetupService` (interface + Fake) hay (b) chờ Hiếu; có được sửa `lib/app.dart` để nạp cài đặt khi mở app không.
- Bước 03: đã chốt với Hiếu việc chia N06 (form hồ sơ – Sanh, khu demo – Hiếu) chưa.
- Bước 04: câu chữ N20 thay "Chưa đồng bộ sang máy khác" (Lab 3 đã lưu Firebase + ghép nối).
