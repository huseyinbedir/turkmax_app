/// Yalnızca zorunlu, yerel olarak saklanan ayarlar.
abstract interface class SettingsRepository {
  bool get autoReconnect;

  Future<void> setAutoReconnect(bool value);

  /// Son bağlanılan cihazın adı (bilgi amaçlı).
  String? get lastDeviceName;

  Future<void> setLastDeviceName(String value);
}
