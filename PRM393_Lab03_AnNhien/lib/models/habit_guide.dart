/// Nội dung hướng dẫn theo nhóm thói quen, hiện ở màn Chi tiết việc.
/// Là nội dung của app (như `guidedActivities`), không phải lời khuyên y tế.
class HabitGuide {
  const HabitGuide(
      {required this.benefit,
      required this.prepare,
      required this.steps,
      required this.note});

  /// Vì sao việc này tốt cho Bác.
  final String benefit;

  /// Những thứ nên chuẩn bị: (khoá hình minh hoạ, tên).
  final List<(String, String)> prepare;

  /// Các bước làm ngắn gọn.
  final List<String> steps;

  /// Lưu ý nhẹ nhàng, luôn nhắc Bác làm theo sức mình.
  final String note;
}

const _defaultGuide = HabitGuide(
  benefit: 'Một việc nhỏ đều đặn mỗi ngày giúp Bác thấy ngày trôi qua nhẹ '
      'nhàng và có ý nghĩa.',
  prepare: [
    ('time', 'Một khoảng thời gian rảnh'),
    ('seat', 'Chỗ ngồi thoải mái'),
    ('water', 'Một cốc nước'),
  ],
  steps: [
    'Bắt đầu chậm rãi, theo nhịp của Bác.',
    'Làm từng phần nhỏ, nghỉ khi thấy mỏi.',
    'Xong thì đánh dấu “Đã làm” để ghi nhận.',
  ],
  note: 'Bác làm theo sức mình. Thấy mệt thì dừng và nghỉ ngơi.',
);

const _guides = <String, HabitGuide>{
  'move': HabitGuide(
    benefit: 'Vận động nhẹ giúp người thư thái, ngủ ngon hơn và giữ cho '
        'chân tay linh hoạt mỗi ngày.',
    prepare: [
      ('shoes', 'Giày dép êm, vừa chân'),
      ('water', 'Nước uống'),
      ('hat', 'Mũ nón khi ra nắng'),
      ('phone', 'Điện thoại để liên lạc'),
    ],
    steps: [
      'Khởi động nhẹ: xoay cổ tay, cổ chân vài vòng.',
      'Đi hoặc tập theo nhịp thoải mái, vẫn nói chuyện được là vừa.',
      'Nghỉ ngắn khi cần, uống vài ngụm nước.',
      'Kết thúc bằng vài nhịp thở chậm.',
    ],
    note: 'Chọn đường bằng phẳng, đủ ánh sáng. Thấy chóng mặt hay mệt thì '
        'dừng lại và nghỉ.',
  ),
  'downshift': HabitGuide(
    benefit: 'Dành ít phút chậm lại giúp đầu óc nhẹ nhõm, bớt căng thẳng '
        'trong ngày.',
    prepare: [
      ('seat', 'Chỗ ngồi yên tĩnh'),
      ('music', 'Bản nhạc nhẹ (nếu thích)'),
      ('tea', 'Cốc nước ấm'),
    ],
    steps: [
      'Ngồi thoải mái, thả lỏng vai.',
      'Thở theo nhịp tự nhiên, chú ý hơi thở ra vào.',
      'Nghĩ về một điều khiến Bác thấy bình yên.',
    ],
    note: 'Không cần cố gắng. Bác có thể dừng bất cứ lúc nào.',
  ),
  'family': HabitGuide(
    benefit: 'Trò chuyện với người thân giúp Bác thấy gần gũi, vui vẻ và '
        'được quan tâm.',
    prepare: [
      ('phone', 'Điện thoại đã sạc'),
      ('seat', 'Chỗ ngồi thoải mái'),
      ('note', 'Một chuyện nhỏ muốn kể'),
    ],
    steps: [
      'Chọn người thân trong mục Gia đình.',
      'Hỏi thăm và kể một chuyện vui trong ngày.',
      'Hẹn lần trò chuyện tiếp theo nếu Bác muốn.',
    ],
    note: 'Nếu chưa gọi được, Bác có thể dời sang giờ khác.',
  ),
  'tea': HabitGuide(
    benefit: 'Ngồi uống trà, trò chuyện cùng bạn bè giúp tinh thần thoải '
        'mái và gắn bó hơn.',
    prepare: [
      ('tea', 'Ấm trà hoặc đồ uống quen'),
      ('people', 'Bạn bè, người thân'),
      ('seat', 'Bàn ghế thoải mái'),
    ],
    steps: [
      'Mời một người bạn hoặc người thân cùng ngồi.',
      'Pha đồ uống Bác thích.',
      'Để điện thoại sang bên, lắng nghe và chia sẻ.',
    ],
    note: 'Uống vừa đủ, tránh uống trà quá đặc vào buổi tối.',
  ),
  'plant': HabitGuide(
    benefit: 'Ăn thêm rau, đậu, trái cây giúp bữa ăn nhẹ bụng và đủ chất.',
    prepare: [
      ('veg', 'Rau xanh, đậu'),
      ('fruit', 'Trái cây theo mùa'),
      ('bowl', 'Bát đĩa vừa phần'),
    ],
    steps: [
      'Chọn một món rau hoặc đậu cho bữa này.',
      'Rửa sạch, nấu mềm vừa ăn.',
      'Ăn chậm, nhai kỹ và thưởng thức.',
    ],
    note: 'Nếu Bác đang ăn kiêng theo bác sĩ, hãy làm theo hướng dẫn đó.',
  ),
  'eighty': HabitGuide(
    benefit: 'Ăn vừa đủ no giúp bụng nhẹ nhàng, dễ chịu sau bữa ăn.',
    prepare: [
      ('bowl', 'Bát nhỏ vừa phần'),
      ('water', 'Cốc nước'),
      ('seat', 'Bữa ăn không vội'),
    ],
    steps: [
      'Lấy phần ăn vừa phải.',
      'Ăn chậm, nhai kỹ, trò chuyện cùng người thân.',
      'Dừng lại khi thấy no vừa.',
    ],
    note: 'Bác ăn theo khẩu phần phù hợp với sức khoẻ của mình.',
  ),
  'purpose': HabitGuide(
    benefit: 'Làm một việc mình yêu thích giúp mỗi ngày có niềm vui và '
        'ý nghĩa riêng.',
    prepare: [
      ('note', 'Sổ tay ghi lại ý tưởng'),
      ('time', 'Khoảng thời gian rảnh'),
      ('seat', 'Góc ngồi quen thuộc'),
    ],
    steps: [
      'Nghĩ về một việc nhỏ Bác thấy vui hoặc có ích.',
      'Bắt đầu từ phần dễ nhất.',
      'Ghi lại điều Bác đã làm được hôm nay.',
    ],
    note: 'Không cần làm xong hết trong một lần. Từng chút một là đủ.',
  ),
  'belong': HabitGuide(
    benefit: 'Tham gia sinh hoạt cộng đồng giúp Bác có thêm bạn và thấy '
        'mình gắn bó với mọi người.',
    prepare: [
      ('calendar', 'Giờ giấc buổi sinh hoạt'),
      ('shoes', 'Trang phục thoải mái'),
      ('phone', 'Điện thoại để liên lạc'),
    ],
    steps: [
      'Xem lại giờ và địa điểm sinh hoạt.',
      'Đi cùng người quen nếu có thể.',
      'Chào hỏi, tham gia theo sức của Bác.',
    ],
    note: 'Nhờ người thân đưa đón nếu đường xa hoặc trời tối.',
  ),
  'tribe': HabitGuide(
    benefit: 'Gặp gỡ, trò chuyện với bạn bè giúp tinh thần vui tươi, '
        'bớt cô đơn.',
    prepare: [
      ('people', 'Bạn bè, hàng xóm'),
      ('tea', 'Chút trà nước'),
      ('game', 'Bàn cờ hoặc trò chơi quen'),
    ],
    steps: [
      'Hẹn một người bạn hoặc hàng xóm.',
      'Cùng trò chuyện, chơi cờ hoặc đi dạo.',
      'Hẹn lần gặp tiếp theo.',
    ],
    note: 'Bác chọn chỗ gặp gần nhà, đi lại thuận tiện.',
  ),
};

HabitGuide habitGuideOf(String habitKey) => _guides[habitKey] ?? _defaultGuide;

/// Số ảnh có sẵn trong `assets/images/habits/` cho từng thói quen.
const _photoCount = <String, int>{
  'move': 3,
  'downshift': 3,
  'family': 2,
  'tea': 3,
  'plant': 3,
  'eighty': 3,
  'purpose': 3,
  'belong': 3,
  'tribe': 2,
};

/// Ảnh minh hoạ của thói quen (ảnh đầu dùng làm ảnh lớn). Rỗng nếu chưa có.
List<String> habitPhotosOf(String habitKey) => [
      for (var i = 0; i < (_photoCount[habitKey] ?? 0); i++)
        'assets/images/habits/${habitKey}_$i.jpg'
    ];
