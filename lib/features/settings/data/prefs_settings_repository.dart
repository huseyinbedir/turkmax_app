import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/settings_repository.dart';

@LazySingleton(as: SettingsRepository)
class PrefsSettingsRepository implements SettingsRepository {
  const PrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _autoReconnectKey = 'settings.auto_reconnect';
  static const _lastDeviceKey = 'connection.last_device_name';

  @override
  bool get autoReconnect => _prefs.getBool(_autoReconnectKey) ?? true;

  @override
  Future<void> setAutoReconnect(bool value) =>
      _prefs.setBool(_autoReconnectKey, value);

  @override
  String? get lastDeviceName => _prefs.getString(_lastDeviceKey);

  @override
  Future<void> setLastDeviceName(String value) =>
      _prefs.setString(_lastDeviceKey, value);
}
