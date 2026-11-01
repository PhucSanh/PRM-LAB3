/// Firebase Remote Config. Bản thật: B – Hiếu, F10.
/// Giá trị mặc định phải trùng firebase/remote-config-defaults.json.
abstract final class RemoteConfigKeys {
  static const snoozeMinutes = 'snooze_minutes'; // S14 "Nhắc lại sau N phút"
  static const voiceInputEnabled = 'voice_input_enabled'; // S05 nút "Nói việc"
  static const homeMaxUpcoming = 'home_max_upcoming'; // S03 số việc hiện
}

abstract interface class RemoteConfigService {
  Future<void> init();
  int getInt(String key);
  bool getBool(String key);
  Stream<Set<String>> get onUpdated;
}

class FakeRemoteConfigService implements RemoteConfigService {
  FakeRemoteConfigService([Map<String, Object>? values]) : _values = {..._defaults, ...?values};

  static const _defaults = <String, Object>{
    RemoteConfigKeys.snoozeMinutes: 10,
    RemoteConfigKeys.voiceInputEnabled: true,
    RemoteConfigKeys.homeMaxUpcoming: 6,
  };
  final Map<String, Object> _values;

  @override
  Future<void> init() async {}

  @override
  int getInt(String key) => (_values[key] as num?)?.toInt() ?? 0;

  @override
  bool getBool(String key) => _values[key] as bool? ?? false;

  @override
  Stream<Set<String>> get onUpdated => const Stream.empty();
}
