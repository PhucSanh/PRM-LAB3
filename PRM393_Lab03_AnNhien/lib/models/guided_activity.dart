/// Curated instructions are app content; habit metadata still comes from HabitRepository.
class GuidedActivity {
  const GuidedActivity(
      this.id, this.habitKey, this.title, this.minutes, this.steps);
  final String id, habitKey, title;
  final int minutes;
  final List<String> steps;
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
];
GuidedActivity? guidedActivityById(String id) =>
    guidedActivities.where((a) => a.id == id).firstOrNull;
