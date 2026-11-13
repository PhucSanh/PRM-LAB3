# Hướng dẫn và Checklist Kiểm định Tiếp cận (Accessibility Guidelines for Elderly)

## 1. Tiêu chuẩn Tiếp cận Thị giác (Visual Accessibility)
- **Độ tương phản (Contrast Ratio)**:
  - Văn bản thông thường: đạt tỷ lệ tối thiểu `7:1` (chuẩn WCAG 2.1 AAA).
  - Nút bấm và icon điều hướng: đạt tỷ lệ tối thiểu `4.5:1` so với nền.
- **Cỡ chữ (Typography)**:
  - Tiêu đề chính (Header): tối thiểu 24sp - 28sp, font Sans-serif dễ đọc (Be Vietnam Pro / Roboto).
  - Nội dung mô tả (Body): tối thiểu 18sp - 20sp.
  - Phụ đề / Ghi chú (Caption): không nhỏ hơn 16sp. Tuyệt đối không dùng chữ 12sp hoặc mờ nhạt.
- **Khoảng cách dòng & lề (Spacing)**:
  - Chiều cao dòng (line-height) tối thiểu 1.5 lần cỡ chữ.
  - Khoảng cách giữa các thành phần tương tác tối thiểu 16dp để tránh chạm nhầm.

## 2. Tiêu chuẩn Tiếp cận Thính giác & Giọng nói (Audio & Voice)
- Trợ lý giọng nói An Nhiên đọc chậm rãi, phát âm rõ ràng chuẩn giọng phổ thông.
- Cho phép nghe lại âm thanh bất kỳ lúc nào với 1 chạm.
- Không phát âm thanh đột ngột ở âm lượng cực đại gây giật mình.

## 3. Checklist Kiểm tra Thực tế (Verification Checklist)
- [x] Kiểm tra hiển thị ở mức font scale 1.5x của hệ thống Android.
- [x] Không bị tràn viền (overflow) hay cắt cụt văn bản khi phóng to.
- [x] Nút quay lại (Back) luôn đặt ở góc trên bên trái với icon to và nhãn "Quay lại".
- [x] Nút hành động chính (Primary CTA) ghim cố định ở đáy màn hình, luôn nổi bật.\n