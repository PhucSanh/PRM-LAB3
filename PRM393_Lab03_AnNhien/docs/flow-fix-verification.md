# Kiểm chứng sửa lỗi luồng — 06/11/2026

## Thay đổi

- Sửa test TalkBack Trang chủ: cuộn danh mục vào vùng hiển thị trước khi đọc semantics và kích hoạt tap thật. Thao tác vẫn phải mở đúng màn thói quen.
- Test alias lịch chọn đúng bản sao tên việc trên lịch, kiểm tra hai thẻ dùng dữ liệu repository, rồi mở chi tiết và thói quen.
- Kiểm tra trực quan và cập nhật 21 ảnh golden theo các thẻ Trang chủ, Gia đình và hoạt động hiện hành. Test lịch xác nhận VeloraGreeting thay vì yêu cầu BotanicalScene của giao diện cũ. Không tắt kiểm tra golden/overflow; lần chạy chốt không dùng --update-goldens.
- Sửa 14 lint/warning: thêm ngoặc khối và bỏ import không dùng. Không đổi hành vi các thao tác lịch/người thân.
- Backend và bộ hiểu lời nói local hỏi lại khi một câu chứa nhiều hoạt động có giờ riêng; không tự chọn một việc để lưu. Khi Bác chọn một việc trong câu trả lời, local bỏ bản nháp nhiều việc trước đó. Có test hồi quy cho hai hoạt động, câu sửa giờ và khoảng thời gian trong cùng mệnh đề. Guard có phạm vi hẹp; những cấu trúc khác vẫn qua model/parser.
- Script kiểm chứng Groq giãn cách request và thử lại tối đa hai lần khi bị quota; chỉ in mã lỗi cho phép, không in key/transcript/provider body.
- ARTEMIS TC-01/02/13 yêu cầu JSON evidence và assert lời chào/5 mục điều hướng, hủy Google login và đăng xuất. Dùng output/expected_output của SDK ghim trong pyproject; không còn TODO assertion.
- Đồng bộ TC-09 với luồng PDF hiện hành: lưu qua Android document picker, không phụ thuộc Storage; xem flow-completion-implementation.md. Bỏ qua ảnh diff sinh tự động trong Git.

## Kết quả chạy chốt

| Kiểm tra | Kết quả | Log cục bộ của phiên |
| --- | --- | --- |
| Flutter analyze | Không có issues | /tmp/prm-final-analyze.log |
| Flutter test | 878 đạt, 0 lỗi | /tmp/prm-final-tests.log |
| Backend + Rules Emulator | 39 đạt, 0 lỗi | /tmp/prm-backend-final.log |
| Backend syntax checks | Đạt | /tmp/prm-node-final.log |
| Groq + preflight nhiều việc | 8/8 đạt; 7 ca gọi API, ca nhiều việc dừng ở guard; không ghi task | /tmp/prm-groq-final.log |
| Python ARTEMIS | AST syntax hợp lệ; chưa chạy thiết bị | — |
| git diff --check | Đạt | — |

## Chưa được xác nhận ở production

Không deploy Functions/rules hoặc gửi notification production trong phiên sửa này. Bản sửa backend cần được triển khai để có hiệu lực trên cloud.

ADB không có thiết bị kết nối. Có AVD nhưng emulator -accel-check báo thiếu /dev/kvm; chưa chạy ARTEMIS hay Google login, FCM cold start, micro/TTS, document picker và ghép nối hai máy trên Android thật. Các kết quả unit/widget/Emulator và gọi Groq trực tiếp không thay thế nghiệm thu này.
