import 'package:injectable/injectable.dart';

import '../../../app/di/environments.dart';
import '../domain/diagnostics_repository.dart';
import '../domain/platform_info.dart';

@LazySingleton(as: DiagnosticsRepository, env: [kEnvFake])
class FakeDiagnosticsRepository implements DiagnosticsRepository {
  const FakeDiagnosticsRepository();

  @override
  Future<PlatformInfo?> platformInfo() async => const PlatformInfo(
    osVersion: 'fake',
    sdkInt: 0,
    deviceModel: 'Fake Device',
  );
}
