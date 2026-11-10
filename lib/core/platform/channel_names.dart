/// Flutter ↔ Android native kanal adları.
///
/// Kotlin tarafındaki karşılığı: `com.turkmax.app.channels.ChannelNames`.
/// İki dosya birlikte güncellenmelidir.
abstract final class ChannelNames {
  static const String system = 'turkmax/system';
  static const String deviceStatusEvents = 'turkmax/device_status/events';
  static const String connection = 'turkmax/connection';
  static const String connectionEvents = 'turkmax/connection/events';
  static const String streaming = 'turkmax/streaming';
}
