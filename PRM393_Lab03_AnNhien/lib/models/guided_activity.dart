/// Curated instructions are app content; habit metadata still comes from HabitRepository.
class GuidedActivity {
  const GuidedActivity(
      this.id, this.habitKey, this.title, this.minutes, this.steps);
  final String id, habitKey, title;
  final int minutes;
  final List<String> steps;
  String get interest => switch (id) {
        'water-10' || 'plant-10' || 'flower-15' => 'Cây cối',
        'music-10' ||
        'sing-10' ||
        'draw-15' ||
        'craft-15' =>
          'Âm nhạc & sáng tạo',
        'read-15' || 'journal-5' || 'puzzle-10' || 'poem-10' => 'Đọc & học hỏi',
        'call-5' ||
        'tea-15' ||
        'photo-10' ||
        'friend-5' ||
        'club-15' ||
        'neighbor-10' ||
        'tea-family-10' =>
          'Gặp gỡ & trò chuyện',
        'salad-15' || 'slow-meal-15' || 'recipe-15' => 'Bếp nhà',
        _ => 'Vận động & thư giãn',
      };
}

const guidedActivities = [
  GuidedActivity('breathe-5', 'downshift', 'Thư giãn cùng nhịp thở', 5, [
    'Chọn chỗ ngồi thoải mái, đặt chân vững và thả lỏng vai.',
    'Chú ý nhịp thở tự nhiên. Bác không cần nín thở hay cố thở sâu.',
    'Nếu thấy không thoải mái, Bác dừng và nghỉ theo nhịp của mình.',
  ]),
  GuidedActivity('walk-10', 'move', 'Đi bộ nhẹ nhàng', 10, [
    'Chọn đoạn đường quen thuộc, bằng phẳng và phù hợp với Bác.',
    'Đi theo nhịp thoải mái; có thể rủ người thân cùng đi.',
    'Bác có thể nghỉ hoặc dừng bất cứ lúc nào, không cần đi đủ thời gian.',
  ]),
  GuidedActivity('water-10', 'move', 'Tưới cây', 10, [
    'Chọn vài chậu cây ở vị trí dễ với tới.',
    'Dùng bình nước vừa sức, thong thả chăm từng cây.',
    'Cất đồ gọn gàng và nghỉ khi Bác muốn.',
  ]),
  GuidedActivity('call-5', 'family', 'Gọi người thân', 5, [
    'Chọn một người Bác muốn hỏi thăm trong mục Gia đình.',
    'Chia sẻ một chuyện nhỏ trong ngày và hỏi thăm người ấy.',
    'Nếu chưa gọi được, Bác có thể hẹn một giờ khác.',
  ]),
  GuidedActivity('tea-15', 'tea', 'Trà chiều cùng bạn', 15, [
    'Chọn một người bạn hoặc người thân để ngồi trò chuyện.',
    'Chuẩn bị đồ uống quen thuộc với Bác.',
    'Để điện thoại sang bên và dành thời gian lắng nghe nhau.',
  ]),
  GuidedActivity('plan-5', 'purpose', 'Chọn một niềm vui hôm nay', 5, [
    'Nghĩ về một việc nhỏ khiến Bác thấy vui hoặc có ý nghĩa.',
    'Chọn một việc vừa sức và một thời điểm thuận tiện.',
    'Thêm việc đó vào lịch nếu Bác muốn được nhắc.',
  ]),
  GuidedActivity('music-10', 'downshift', 'Nghe một bản nhạc yêu thích', 10, [
    'Chọn một bản nhạc quen, chỉnh âm lượng vừa nghe.',
    'Ngồi thoải mái, dành ít phút tận hưởng giai điệu.',
  ]),
  GuidedActivity('read-15', 'purpose', 'Đọc vài trang sách', 15, [
    'Chọn sách hoặc một bài viết bạn thấy hứng thú.',
    'Ngồi ở nơi đủ sáng và nghỉ mắt khi cần.',
  ]),
  GuidedActivity(
      'photo-10', 'family', 'Xem ảnh và kể chuyện cùng con cháu', 10, [
    'Chọn vài tấm ảnh có kỷ niệm vui.',
    'Kể một câu chuyện và hỏi con cháu về kỷ niệm của mình.',
  ]),
  GuidedActivity('friend-5', 'tribe', 'Hỏi thăm một người bạn cũ', 5, [
    'Chọn một người bạn lâu rồi chưa trò chuyện.',
    'Gọi hoặc nhắn một lời hỏi thăm, hẹn lúc thuận tiện nếu bạn bận.',
  ]),
  GuidedActivity('club-15', 'belong', 'Tìm một câu lạc bộ gần nhà', 15, [
    'Nghĩ về một sở thích bạn muốn chia sẻ cùng mọi người.',
    'Nhờ người quen tìm một nhóm phù hợp và hỏi lịch sinh hoạt.',
  ]),
  GuidedActivity('salad-15', 'plant', 'Chuẩn bị một đĩa rau nhiều màu', 15, [
    'Chọn các loại rau quen thuộc, rửa sạch trước khi chuẩn bị.',
    'Chế biến theo khẩu vị và chế độ ăn thường ngày của bạn.',
  ]),
  GuidedActivity('slow-meal-15', 'eighty', 'Dành thời gian ăn chậm', 15, [
    'Chọn một bữa ăn và cất điện thoại sang bên.',
    'Ăn thong thả, chú ý hương vị và cảm giác vừa đủ của mình.',
  ]),
  GuidedActivity('journal-5', 'purpose', 'Ghi lại một điều vui hôm nay', 5, [
    'Lấy một cuốn sổ hoặc mở ghi chú trên điện thoại.',
    'Viết một điều khiến bạn vui, dù chỉ là chuyện rất nhỏ.',
  ]),
  GuidedActivity('plant-10', 'plant', 'Chăm một chậu rau nhỏ', 10, [
    'Chọn chậu rau đặt ở vị trí dễ với tới.',
    'Nhặt lá khô, xem đất có cần tưới và nghỉ khi thấy mỏi.',
  ]),
  GuidedActivity('neighbor-10', 'belong', 'Trò chuyện với người hàng xóm', 10, [
    'Chọn lúc thuận tiện để chào hỏi một người hàng xóm quen.',
    'Chia sẻ một chuyện nhỏ hoặc hỏi thăm ngày hôm nay của họ.',
  ]),
  GuidedActivity(
      'tea-family-10', 'tea', 'Pha đồ uống và ngồi cùng người thân', 10, [
    'Chuẩn bị đồ uống quen thuộc theo sở thích của mỗi người.',
    'Ngồi cùng nhau và lắng nghe một câu chuyện trong ngày.',
  ]),
  GuidedActivity('tidy-10', 'move', 'Sắp xếp một góc nhà nhỏ', 10, [
    'Chọn một ngăn bàn hoặc góc nhỏ dễ dọn.',
    'Sắp từng món vừa sức, tránh nâng vật nặng hay với cao.',
  ]),
  GuidedActivity('flower-15', 'move', 'Cắm vài nhành hoa trong nhà', 15, [
    'Chọn một chiếc bình nhỏ và vài nhành hoa Bác thích.',
    'Sắp hoa theo ý mình rồi đặt ở góc dễ ngắm.',
  ]),
  GuidedActivity('sing-10', 'downshift', 'Hát theo một bài nhạc quen', 10, [
    'Mở một bài nhạc Bác yêu thích với âm lượng vừa nghe.',
    'Hát hoặc ngân nga theo giai điệu, không cần thuộc hết lời.',
  ]),
  GuidedActivity('draw-15', 'purpose', 'Vẽ một góc vườn bằng bút màu', 15, [
    'Chuẩn bị giấy và vài cây bút màu trong tầm tay.',
    'Vẽ chậu cây hoặc cảnh trước cửa theo cách Bác thích.',
  ]),
  GuidedActivity('craft-15', 'purpose', 'Làm một tấm thiệp nhỏ', 15, [
    'Chọn giấy, bút và vài hình trang trí có sẵn.',
    'Viết lời chúc và trang trí tấm thiệp gửi người Bác quý.',
  ]),
  GuidedActivity('puzzle-10', 'purpose', 'Thử một ô chữ vui', 10, [
    'Chọn ô chữ hoặc trò tìm từ có chữ đủ lớn, dễ nhìn.',
    'Làm theo nhịp của Bác, có thể rủ một người cùng chơi.',
  ]),
  GuidedActivity(
      'poem-10', 'purpose', 'Đọc và chép một câu thơ yêu thích', 10, [
    'Chọn một bài thơ hoặc câu nói Bác muốn giữ lại.',
    'Đọc chậm, ghi lại vài dòng và chia sẻ nếu Bác thích.',
  ]),
  GuidedActivity('recipe-15', 'plant', 'Ghi lại một món ăn gia đình', 15, [
    'Chọn món quen thuộc Bác hay nấu cho người thân.',
    'Ghi các nguyên liệu và vài bước chính để chia sẻ cùng con cháu.',
  ]),
];
GuidedActivity? guidedActivityById(String id) =>
    guidedActivities.where((a) => a.id == id).firstOrNull;
