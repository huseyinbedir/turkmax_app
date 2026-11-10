import 'package:equatable/equatable.dart';

class PlatformInfo extends Equatable {
  const PlatformInfo({
    required this.osVersion,
    required this.sdkInt,
    required this.deviceModel,
  });

  final String osVersion;
  final int sdkInt;
  final String deviceModel;

  @override
  List<Object?> get props => [osVersion, sdkInt, deviceModel];
}
