import 'package:injectable/injectable.dart';

import '../../../app/di/environments.dart';
import '../domain/device_status.dart';
import '../domain/device_status_repository.dart';

@LazySingleton(as: DeviceStatusRepository, env: [kEnvFake])
class FakeDeviceStatusRepository implements DeviceStatusRepository {
  const FakeDeviceStatusRepository({
    @ignoreParam
    this.status = const DeviceStatus(batteryPercent: 82, isCharging: true),
  });

  final DeviceStatus status;

  @override
  Stream<DeviceStatus> watch() => Stream.value(status);
}
