import '../models/relative.dart';
import 'local_voice_task_service.dart' show foldVietnamese;

// Specific relations must precede their broader groups.
const _relations = {
  'con trai': ['con trai'],
  'con gai': ['con gai'],
  'chau trai': ['chau trai'],
  'chau gai': ['chau gai'],
  'anh trai': ['anh trai'],
  'chi gai': ['chi gai'],
  'em trai': ['em trai'],
  'em gai': ['em gai'],
  'vo': ['vo'],
  'chong': ['chong'],
  'con': ['con', 'con trai', 'con gai'],
  'chau': ['chau', 'chau trai', 'chau gai'],
  'anh chi em': ['anh chi em', 'anh trai', 'chi gai', 'em trai', 'em gai'],
  'ban be': ['ban be'],
};

String _normalize(String text) => foldVietnamese(text)
    .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Match stored relations, never infer gender from a person's name.
List<Relative> filterAssistantContacts(List<Relative> contacts,
    {required String utterance, required String target}) {
  final request = _normalize(utterance);
  final hint = _normalize(target);
  String? relationIn(String text) {
    for (final relation in _relations.keys) {
      if (RegExp('\\b$relation\\b').hasMatch(text)) return relation;
    }
    return null;
  }

  // The user's explicit relation takes precedence over a model suggestion.
  final relation = relationIn(request) ?? relationIn(hint);
  var matches = contacts;
  if (relation != null) {
    matches = matches
        .where((p) => _relations[relation]!.contains(_normalize(p.relation)))
        .toList();
  }
  // A named person narrows the relation group further when present.
  final named = matches.where((p) {
    final name = _normalize(p.name);
    return name.isNotEmpty &&
        (' $request '.contains(' $name ') || ' $hint '.contains(' $name '));
  }).toList();
  if (named.isNotEmpty) return named;
  if (relation != null || hint.isEmpty) return matches;
  if (['nguoi than', 'gia dinh', 'danh ba'].contains(hint)) return matches;
  return matches.where((p) => _normalize(p.name).contains(hint)).toList();
}
