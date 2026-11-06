# Groq — nói để thêm lịch

## Trạng thái

Code Flutter và callable `interpretVoiceTask` đã nối; key chưa được cung cấp, chưa gọi Groq thật, chưa deploy endpoint. Production dùng `FirebaseVoiceTaskService`, không dùng kết quả Fake. Project Firebase `prm393-145c9` ở lượt trước bị chặn deploy Functions vì cần Blaze; key riêng không giải quyết điều kiện hạ tầng này. Không tự nâng billing.

## Luồng của Bác

1. Mở Nói để thêm việc, bấm Bắt đầu nói hoặc gõ câu.
2. Bấm **Hiểu lời Bác nói**: app gửi phần chữ và ngày ngữ cảnh nếu có, qua callable có Firebase Auth tới Groq. Không gửi bản ghi âm tới Groq.
3. Thiếu ngày/giờ hoặc mơ hồ: đọc câu hỏi, cho Bác nói/gõ câu trả lời bổ sung. Tối đa 4 lượt, mỗi lượt 500 ký tự; có thể sửa câu ban đầu để bắt đầu lại.
4. Đủ thông tin: hiển thị tên việc, ngày, giờ và lặp; đọc lại bằng TTS Android. **Dùng lịch này** chỉ điền form F4; chưa có task nào được lưu.
5. Bác kiểm tra/chỉnh sửa và bấm Lưu theo luồng hiện tại. Key chưa bật, lỗi mạng hoặc provider lỗi: giữ câu nói, cho thử lại và nhập tay.

## Cấu hình key (thực hiện sau khi có key)

Chạy từ gốc app, dùng CLI đã cài ở `firebase/tests/node_modules/.bin/firebase`:

```bash
firebase/tests/node_modules/.bin/firebase functions:secrets:set GROQ_API_KEY --project prm393-145c9
firebase/tests/node_modules/.bin/firebase deploy --only functions:interpretVoiceTask --project prm393-145c9
```

Lệnh đầu hỏi giá trị secret trong terminal. Không đặt key trong Dart, `--dart-define`, Remote Config, google-services.json hay commit. Secret Manager chỉ được bind vào endpoint này. Model mặc định `openai/gpt-oss-20b` chạy trên **Groq**; có thể cấu hình server parameter `GROQ_VOICE_MODEL`, nhưng model thay thế phải hỗ trợ strict JSON Schema. Mẫu `.env.example` chỉ chứa tên model, không chứa key.

Local emulator: sao chép `firebase/functions/.secret.local.example` thành `.secret.local` cùng thư mục rồi điền key tại máy. File thật đã bị gitignore. `.env.example` và `.secret.local.example` chỉ là mẫu. Production dùng Secret Manager, không lấy key từ file example.

## Giới hạn và quyền

- Callable `asia-southeast1`, xác thực bắt buộc; 8 yêu cầu/phút, 60/ngày/UID, đếm bằng transaction `voiceUsage/{uid}`. Client không đọc/sửa/xoá quota; rules catch-all hiện có từ chối và đã có test riêng.
- Chỉ lưu counters và expiresAt trong quota, không lưu transcript. expiresAt là dữ liệu cho TTL nếu cấu hình sau này, chưa coi như đã bật chính sách TTL.
- Request Groq timeout 18 giây, callable 30 giây, Flutter 35 giây; output tối đa 2048 tokens. Không retry ngầm làm tăng số lượt gọi. Giới hạn số instance 3, concurrency 8/instance.
- Không log transcript, Authorization, secret hoặc body lỗi provider. Chỉ gửi các câu do Bác nhập; không gửi tài khoản, liên hệ hay toàn bộ lịch.
- Structured JSON được kiểm tra lại ở backend và Flutter: kiểu dữ liệu, 9 nhóm, enum lặp, ngày thật 2020–2100, giờ/phút, tên tối đa 80 ký tự, lịch tương lai. Múi giờ UTC+07/Asia/Ho_Chi_Minh.
- Không cấp tool ghi/xoá lịch cho LLM. Yêu cầu sửa/xoá hoặc nhiều việc phải hỏi lại. Kết quả về sau khi đăng xuất/dispose bị bỏ. Lưu vẫn dùng TaskRepository và quyền hiện có.
- Kiểm tra schema không chứng minh model hiểu đúng câu. Bác luôn duyệt bản nháp; cần chạy eval thật với key trước nghiệm thu.

## Kiểm chứng

- `flutter test`: 860 passed (`/tmp/groq-full-tests.log`).
- `flutter analyze`: sạch (`/tmp/groq-final-analyze.log`).
- `npm run check --prefix firebase/functions`: mọi module CJS hợp lệ.
- `flutter build apk --debug -t lib/main.dart`: thành công (`/tmp/groq-build.log`); APK ở `build/app/outputs/flutter-apk/app-debug.apk`.
- `git diff --check`: sạch.
- `test/voice_task_test.dart`: hỏi lại/giữ ngữ cảnh, điền đủ form nhưng chưa ghi, lỗi/mất key, sửa câu vô hiệu bản cũ, chống gọi trùng, logout trong lúc chờ, thời điểm đã qua, lỗi/malformed callable.
- `test/voice_task_screen_test.dart`: UI đầu-cuối với fixture tại 360dp 100%/200%, 412dp 200%, loading/disabled/manual. 3 golden dùng font thật, đã xem trực tiếp bản 360dp ở 100%/200%.
- Backend tests gồm mock transport Groq, input/response validation, mốc chuyển năm UTC+07, che lỗi, quota đồng thời và rule chống reset quota. Lượt nghiệm thu cuối: **36/36 passed**, gồm cả rule chống đọc/reset quota (`/tmp/groq-accepted-backend.log`).

Sau khi cấu hình key local, chạy 8 ca Groq thật (gọi API có thể phát sinh chi phí; không ghi task):

```bash
node --env-file=firebase/functions/.secret.local firebase/functions/evaluate-voice.cjs
```

Eval chỉ in mã ca PASS/FAIL, không in câu nói hoặc key. Bao gồm ngày mai, 8 giờ chưa rõ sáng/tối, bổ sung buổi sáng, thiếu ngày, tối nay, chuyển năm, yêu cầu xoá và nhiều việc. Chưa chạy trong lượt này vì chưa có key. Chưa kiểm thử nhận tiếng Việt/TTS và Groq end-to-end trên Android thật vì không có thiết bị kết nối.

## Tài liệu API đã đối chiếu

- [Groq Structured Outputs](https://console.groq.com/docs/structured-outputs): strict JSON Schema và danh sách model hỗ trợ.
- [Firebase environment/secret configuration](https://firebase.google.com/docs/functions/config-env): defineSecret/Secret Manager.
