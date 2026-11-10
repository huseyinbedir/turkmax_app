import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../../app/di/environments.dart';
import '../../../core/platform/channel_names.dart';
import '../domain/diagnostics_repository.dart';
import '../domain/platform_info.dart';

@LazySingleton(as: DiagnosticsRepository, env: [kEnvDevice])
class PlatformDiagnosticsRepository implements DiagnosticsRepository {
  const PlatformDiagnosticsRepository();

  static const _methods = MethodChannel(ChannelNames.system);

  @override
  Future<PlatformInfo?> platformInfo() async {
    try {
      final map = await _methods.invokeMapMethod<String, Object?>(
        'getPlatformInfo',
      );
      if (map == null) return null;
      return PlatformInfo(
        osVersion: map['osVersion']! as String,
        sdkInt: map['sdkInt']! as int,
        deviceModel: map['deviceModel']! as String,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
