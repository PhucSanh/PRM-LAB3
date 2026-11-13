# Tra cứu nhanh: Token giao diện

Chi tiết: `docs/architecture.md` mục 12. Không viết cứng màu, cỡ chữ, khoảng cách — chỉ dùng `lib/theme/`.

## Cỡ chữ (Be Vietnam Pro)

| Kiểu | sp |
| --- | --- |
| `display` | 34 |
| `headline` | 30 |
| `title-md` | 26 |
| `title-lg`, `body-lg` | 24 |
| `label-btn` | 22 |
| `body-md`, `caption`, `label-nav` | 20 |

## Kích thước

| Token | Giá trị |
| --- | --- |
| `AppSizes.minTarget` | 72 dp |
| `AppSpacing.screen` | 20 |
| `AppSpacing.betweenTargets` | 20 |
| `AppSizes.icon` / `AppSizes.habitIcon` | 32 / 48 |
| `AppSizes.navBar` | 96 |

## Cỡ chữ người dùng chọn

`AppFontScale`: Vừa 1.0 · Lớn 1.15 (mặc định) · Rất lớn 1.3 · trần `maxTextScale` 2.0.

## Màu

Lấy qua `Theme.of(context).colorScheme` để chế độ tương phản cao (`AppTheme.highContrast()`) có tác dụng.
