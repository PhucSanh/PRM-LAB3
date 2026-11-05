# 01 — Product goals, scope & UX principles

## Sứ mệnh
An Nhiên hỗ trợ người lớn tuổi thực hiện hoạt động sinh hoạt thường ngày, xây dựng thói quen bền vững, nhận lời nhắc/đề xuất phù hợp và kết nối gia đình; người thân hỗ trợ lên lịch và gợi ý mà không làm mất quyền chủ động của người lớn tuổi.

## Đối tượng
| Đối tượng | Mục tiêu | Rủi ro UX | Hướng thiết kế |
|---|---|---|---|
| Người cao tuổi (primary) | Biết lịch đã lên, hoàn thành/dời/bỏ qua, tìm hoạt động phù hợp, liên hệ gia đình | Chữ nhỏ, gesture ẩn, mất phương hướng, modal quá nhiều, sợ sai | 1 mục tiêu/màn, typography lớn, CTA rõ, nhiều đường quay lại, xác nhận khi hủy |
| Người thân/caregiver | Quản lý lịch, đề xuất hoạt động, quan sát kết quả, ghép đôi | Mật độ thông tin, form dài, trạng thái gửi không rõ | Ngữ cảnh, filter, form theo bước, status chính xác, hiệu quả thao tác |
| Người dùng accessibility | TalkBack/VoiceOver, phóng chữ, tăng tương phản, giảm chuyển động | Icon-only, clipping, màu là tín hiệu duy nhất | Semantic labels, 200% text scale, accessible targets, explicit state |

Không suy đoán năng lực kỹ thuật hay thị lực của mọi người cao tuổi là giống nhau. Người thân không được xem như quản trị viên với quyền vượt quá server authorization.

## JTBD
- “Khi mở **Lịch**, tôi muốn biết những việc đã lên kế hoạch cho ngày đang xem để không bỏ sót.”
- “Khi muốn có ý tưởng mới, tôi mở **Hoạt động → Khám phá**, xem mô tả ngắn và lưu/đặt lịch tùy khả năng thực tế.”
- “Khi làm việc thường xuyên, tôi vào **Hoạt động → Thói quen** để xem và điều chỉnh nếu chức năng đã sẵn có.”
- “Khi cần giúp đỡ, tôi vào **Gia đình** và biết liên hệ ai.”
- “Khi gợi ý hoạt động cho người thân, tôi muốn thấy trạng thái gửi, được xem, đồng ý/từ chối rõ ràng.”

## North-star UX (đo bằng thử nghiệm, không tự công bố thành kết quả)
- Người dùng phân biệt được **Lịch** và **Hoạt động** từ nhãn/giới thiệu ngắn.
- Tác vụ cốt lõi đến được trong <= 3 bước điều hướng chính (không tính login/onboarding; cần đo trên prototype).
- Không có CTA không hoạt động; nếu feature thiếu, hiển thị trạng thái có lý do.
- Back không làm mất thay đổi chưa lưu hoặc quay sai vai trò.
- Voice cung cấp hỗ trợ **tùy chọn**, không auto-play bất ngờ.

## Visual principles
1. **Calm, not cold:** nền ivory, sắc xanh thực vật sâu, coral điểm nhấn hiếm, không neon.
2. **Premium, not ornamental:** khoảng trắng có chủ đích, chữ tốt, ít shadow/card, không glassmorphism.
3. **Lively, not childish:** illustration botanical giới hạn, pressed/success micro-motion, ảnh/đồ họa có ý nghĩa.
4. **Accessible, not oversized everywhere:** elderly type/controls thoải mái; caregiver vừa đủ, semantic scaling vẫn nguyên.
5. **One job per surface:** một hành động chính, ít lựa chọn cạnh tranh.
6. **List-first:** lịch/hoạt động/thông báo chủ yếu là danh sách có nhóm, không card lồng card.
7. **Truthful status:** đã gửi ≠ đã được duyệt ≠ đã thêm lịch ≠ đã hoàn thành.
8. **Privacy by design:** không hiện thông tin sức khỏe/đời sống nhạy cảm ra notification preview nếu không cần.

## Phạm vi
**Có:** theme tokens, icon, navigation/shell, onboarding, auth, lịch, hoạt động (Khám phá/Đã lưu/Thói quen), gia đình, ghép đôi, đề xuất, tạo/sửa hoạt động, inbox, hồ sơ, settings, help/data, voice controls, tất cả trạng thái và responsive.

**Không:** thiết kế/refactor dashboard `/today`, backend redesign, model/schema migration nếu không có phê duyệt, bổ sung AI/analytics mới, xây tính năng mới ngoài chức năng đang có/đã được sản phẩm chốt, dark mode production (tokens chỉ phải có đường mở rộng), redesign các debug/demo pages thành sản phẩm chính.

## Giới hạn nguồn
Bộ tài liệu dựa trên **ZIP gốc `PRM-LAB3-feat-noti-demo.zip` gửi 2026-11-05**, không phải source đã được sửa trong các ZIP v2/v3 trước. Phải re-audit nếu checkout repo đã cập nhật.

## Typography dependency — TYPE-01
Mọi chữ UI trên các màn/component thuộc tài liệu này phải dùng semantic tokens tại `02_VISUAL_TOKENS.md` → TYPE-01 (v1.1.0), gồm cả nhãn navigation, form, hint/error, dialog, loading/empty/placeholder và metadata. Không định nghĩa lại cỡ chữ/weight tại đây hoặc giảm chữ vì density. Shared chưa xác định vai trò dùng bộ elderly; layout phải wrap/scroll và tự tăng chiều cao theo chữ.
