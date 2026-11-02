# Bộ prompt F2 · Onboarding của Bác (Flow 1)

Phân công: **Hương** (bản chia task 02/11/2026). Bộ prompt này để chạy bằng AI agent, từng bước một, giống `docs/prompt/F0/`.

**Xong khi** (design-traceability.md › F2): đi hết S01 → Hôm nay có việc đầu tiên; từ chối quyền thì hiện S13d; mở lại app không hỏi lại.

## Thứ tự chạy

| Bước | File | Làm gì | Màn / khung |
| --- | --- | --- | --- |
| 01 | `01-services.md` | Interface + Fake: `SettingsService`, `ProfileService`, `ReminderService`; 3 ViewModel rỗng + test khung | — |
| 02 | `02-s01-chao-mung.md` | Chọn cỡ chữ, đổi chữ toàn app ngay | S01 |
| 03 | `03-s02-ho-so.md` | Xác nhận tên, nhập tên, giờ thức dậy | S02 (3 khung) · DLG-WakeTime |
| 04 | `04-s13-nhac-viec.md` | Xin quyền thông báo, nhánh bị từ chối | S13 · S13d |
| 05 | `05-n01-thu-loi-nhac.md` | Gửi thử lời nhắc, hỏi đã nhận chưa | N01 · N02 · N03 |
| 06 | `06-n04-viec-dau-tien.md` | Chọn và lưu việc đầu tiên, đánh dấu xong onboarding | N04 · N05 · N18 · N19 |
| 07 | `07-kiem-tra-pr.md` | Chạy hết luồng, tự chấm `rule.md`, cập nhật docs, soạn `PR-F2.md` | toàn F2 |

Mỗi bước: dán **cả file** vào agent, chạy xong thì agent tự điền mục "Kết quả chạy" ở cuối file đó. Đọc kết quả, làm phần "Việc người dùng cần làm tay", rồi commit trước khi sang bước sau.

## Trước khi chạy bước 01

1. `main` đã có F0 (theme + widget dùng chung). Nếu chưa merge thì chưa làm F2.
2. Kiểm tra Hương đã có nhánh F2 chưa: `git fetch --all && git branch -a | grep -i F2`.
   - Chưa có: `git checkout main && git pull && git checkout -b feat/F2-onboarding`.
   - Có rồi: checkout nhánh đó, đừng làm song song.
3. Báo Hương (và cả nhóm) là F2 đang được làm, để không ai sửa trùng `OnboardingViewModel`, `TryReminderViewModel`, `FirstTaskViewModel`.
4. Kiểm tra `SettingsService` / `ProfileService` / `ReminderService` đã có ở nhánh nào chưa (F8 của Sanh, F4 / F6 của Khang cũng dùng). Có rồi thì bước 01 dùng lại, không viết bản thứ hai.

## Commit gợi ý (thứ tự)

```
feat(F2): service onboarding – interface + Fake Settings / Profile / Reminder, khung 3 ViewModel
feat(F2): S01 chào mừng – chọn cỡ chữ
feat(F2): S02 thiết lập hồ sơ + chọn giờ thức dậy
feat(F2): S13 / S13d cho phép nhắc việc
feat(F2): N01–N03 thử lời nhắc
feat(F2): N04–N18 việc đầu tiên, đánh dấu xong onboarding
docs(F2): cập nhật traceability, architecture, tự chấm rule.md
```
