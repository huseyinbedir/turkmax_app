import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import 'channel_names.dart';

/// Pil optimizasyonu durumu.
@lazySingleton
class DevicePower {
  const DevicePower();

  static const _channel = MethodChannel(ChannelNames.system);

  /// Uygulama pil optimizasyonundan muaf mı; bilinmiyorsa `null`.
  Future<bool?> isIgnoringBatteryOptimizations() => _guard(
    () => _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations'),
  );

  /// Sistem pil optimizasyonu ayar sayfasını açar; seçimi kullanıcı yapar.
  Future<void> openBatterySettings() =>
      _guard(() => _channel.invokeMethod<bool>('openBatterySettings'));

  static Future<T?> _guard<T>(Future<T?> Function() call) async {
    try {
      return await call();
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
