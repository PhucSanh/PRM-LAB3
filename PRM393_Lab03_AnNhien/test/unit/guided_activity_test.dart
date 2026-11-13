import 'package:an_nhien/models/guided_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GuidedActivity Category Mapping Unit Tests', () {
    test('1. maps plant and gardening activity IDs to Cây cối category', () {
      const actWater = GuidedActivity('water-10', 'move', 'Tưới cây', 10, []);
      const actPlant = GuidedActivity('plant-10', 'move', 'Trồng rau', 10, []);
      expect(actWater.interest, 'Cây cối');
      expect(actPlant.interest, 'Cây cối');
    });

    test('2. maps creative and musical IDs to Âm nhạc & sáng tạo category', () {
      const actMusic = GuidedActivity('music-10', 'downshift', 'Nghe nhạc', 10, []);
      const actSing = GuidedActivity('sing-10', 'downshift', 'Hát quan họ', 10, []);
      expect(actMusic.interest, 'Âm nhạc & sáng tạo');
      expect(actSing.interest, 'Âm nhạc & sáng tạo');
    });

    test('3. defaults unknown activity IDs to Vận động & thư giãn', () {
      const actUnknown = GuidedActivity('custom-99', 'general', 'Hoạt động tự do', 15, []);
      expect(actUnknown.interest, 'Vận động & thư giãn');
    });
  });
}\n