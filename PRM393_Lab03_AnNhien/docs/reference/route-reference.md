# Tra cứu: Route của app

Khai báo trong `lib/router/app_router.dart` (go_router). Chi tiết điều kiện chặn: `docs/architecture.md` mục 7.

## Đăng nhập & vai trò
`/sign-in` · `/session` · `/role` · `/account`

## Onboarding (F2)
`/intro` · `/welcome` · `/setup` · `/setup/notifications` · `/setup/try-reminder` · `/setup/first-task`

## Việc & nhắc việc (F3–F6)
`/task/date` · `/task/repeat` · `/task/scope` · `/reminder/:taskId`

## Lịch tuần (F7)
`/week` · `/week/:date` · `/week/:date/task/:id` · `/calendar/export`

## Thói quen (F9)
`/habits` · `/habits/:key`

## Gia đình (F11)
`/family/add`

## Cài đặt (F8)
`/settings` · `/settings/profile` · `/settings/reminders` · `/settings/help` · `/settings/data` · `/settings/firebase-demo` · `/settings/firebase-demo/suggestions`

## Gợi ý & hộp thư (F12)
`/inbox` · `/inbox/suggestions/:id`

## Ghép nối & con cháu (F13, F14)
`/pairing/code` · `/caregiver/pair` · `/caregiver/schedule` · `/caregiver/task/new` (+ `repeat`, `review`) · `/caregiver/task/sent` · `/caregiver/task/:id`

## Khác
`/demo` · `/dev/widgets` (chỉ dùng khi phát triển)
