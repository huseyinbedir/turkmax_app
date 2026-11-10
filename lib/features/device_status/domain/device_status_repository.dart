import 'device_status.dart';

abstract interface class DeviceStatusRepository {
  Stream<DeviceStatus> watch();
}
