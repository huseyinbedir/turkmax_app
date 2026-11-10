import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../../app/di/environments.dart';
import '../../../core/platform/channel_names.dart';
import '../domain/device_status.dart';
import '../domain/device_status_repository.dart';

/// Android `ACTION_BATTERY_CHANGED` yayınını EventChannel üzerinden dinler.
@LazySingleton(as: DeviceStatusRepository, env: [kEnvDevice])
class PlatformDeviceStatusRepository implements DeviceStatusRepository {
  const PlatformDeviceStatusRepository();

  static const _events = EventChannel(ChannelNames.deviceStatusEvents);

  @override
  Stream<DeviceStatus> watch() => _events
      .receiveBroadcastStream()
      .map((event) => fromMap(event as Map<Object?, Object?>))
      // Kanal yoksa (ör. iOS henüz yok) topbar pilsiz çalışmaya devam eder.
      .handleError((Object _) {}, test: (e) => e is MissingPluginException);

  static DeviceStatus fromMap(Map<Object?, Object?> map) => DeviceStatus(
    batteryPercent: map['batteryPercent'] as int?,
    isCharging: map['isCharging'] as bool? ?? false,
  );
}
