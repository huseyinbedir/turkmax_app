import 'package:equatable/equatable.dart';

/// Telefonun topbar'da gösterilen durumu.
class DeviceStatus extends Equatable {
  const DeviceStatus({this.batteryPercent, this.isCharging = false});

  /// 0–100; platform henüz bildirmediyse `null`.
  final int? batteryPercent;
  final bool isCharging;

  bool get isBatteryLow =>
      !isCharging && batteryPercent != null && batteryPercent! <= 15;

  @override
  List<Object?> get props => [batteryPercent, isCharging];
}
