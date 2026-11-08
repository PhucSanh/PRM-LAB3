import 'package:an_nhien/models/relative.dart';
import 'package:an_nhien/services/assistant_contact_filter.dart';
import 'package:an_nhien/services/assistant_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const people = [
    Relative(id: 'son', name: 'Hùng', relation: 'Con trai', phone: '1'),
    Relative(id: 'son2', name: 'Minh', relation: 'Con trai', phone: '2'),
    Relative(id: 'daughter', name: 'Mai', relation: 'Con gái', phone: '3'),
    Relative(id: 'wife', name: 'Lan', relation: 'Vợ', phone: '4'),
    Relative(id: 'husband', name: 'Nam', relation: 'Chồng', phone: '5'),
    Relative(id: 'legacy', name: 'An', relation: 'Con', phone: '6'),
  ];
  List<String> select(String request, [String target = '']) =>
      filterAssistantContacts(people, utterance: request, target: target)
          .map((p) => p.id)
          .toList();

  test('specific relations exclude spouses and unspecified legacy gender', () {
    expect(select('Gọi cho con trai'), ['son', 'son2']);
    expect(select('goi con gai'), ['daughter']);
    expect(select('Gọi vợ'), ['wife']);
    expect(select('Gọi chồng'), ['husband']);
    expect(select('Gọi con'), ['son', 'son2', 'daughter', 'legacy']);
  });
  test('names narrow the group; no match never falls back to all contacts', () {
    expect(select('Gọi con trai Hùng'), ['son']);
    expect(select('Gọi con trai', 'Vợ'), ['son', 'son2']);
    expect(select('Gọi cháu gái'), isEmpty);
    expect(select('Gọi Bình', 'Bình'), isEmpty);
    expect(select('Gọi người thân'), hasLength(6));
  });
  test('local recognizer preserves requested person for filtering', () async {
    final reply = await LocalAssistantService().reply([
      {'role': 'user', 'content': 'Gọi cho con trai'}
    ]);
    expect(reply.action, AssistantAction.callFamily);
    expect(select('Gọi cho con trai', reply.target), ['son', 'son2']);
    final named = await LocalAssistantService().reply([
      {'role': 'user', 'content': 'Gọi cho Bình'}
    ]);
    expect(select('Gọi cho Bình', named.target), isEmpty);
  });
}
