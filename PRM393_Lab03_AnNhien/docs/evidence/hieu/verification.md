# Bằng chứng kiểm chứng Hiếu — 04/11/2026

Môi trường: Flutter 3.47.3 / Dart 3.13.3, Node 22.23.2,
Android AVD `Medium_Phone_API_37.0` chạy read-only/headless, serial emulator-5556.
Backend thử nghiệm project `demo-an-nhien`. Không dùng dữ liệu/tài khoản production.

| Kiểm tra | Kết quả thực tế | Phạm vi chứng minh |
|---|---|---|
| `flutter analyze --no-pub` | No issues found | Static analysis toàn app |
| `flutter test --no-pub` | 308 tests passed | Unit/widget, recurrence/scope/status/VM, layout 360/412dp × chữ 1x/2x |
| `npm test --prefix firebase/tests` | 19 tests passed, 0 failed/skip | Firestore/Storage Rules + Admin domain transactions trên Emulator |
| Firebase native integration | ≥3 lượt thành công; lượt cuối PASS sau bổ sung CR-H03 | Android SDK Auth/Firestore/Functions; 3 named app sessions; không phải hai máy vật lý |
| Native notification integration | 2 lượt thành công; lượt sau gồm giữ lịch ngày sau khi snooze | NotificationManager active/pending, schedule/snooze/cancel/cleanup; chưa chứng minh Doze/reboot |
| `npm run check --prefix firebase/functions` | PASS | Node syntax |
| `bash -n scripts/*.sh` | PASS | Shell syntax |
| YAML parse workflows | PASS | Chỉ syntax local, chưa GitHub Actions run |

Firebase native final run:

```text
native Firebase: two accounts pair, schedule, accept, status per day, revoke
00:10 +1: All tests passed!
Script exited successfully (code 0)
```

Unit/widget final run:

```text
00:28 +308: All tests passed!
```

Thông báo native final run:

```text
Android notification plugin: show, schedule, snooze, cancel and sign-out cleanup
00:02 +1: All tests passed!
```

Ảnh chụp thực từ APK demo đã cài trên AVD, không phải ảnh Figma hay Console giả:

- [Hub demo](android-demo.png)
- [Lịch của mẹ](android-calendar.png)

ARTEMIS, Google Sign-In thật, FCM/Crashlytics/Remote Config Console, Storage cloud,
metrics ≤90 giây và nghiệm thu trên máy vật lý chưa được thay bằng các kết quả này.
