import 'platform_info.dart';

abstract interface class DiagnosticsRepository {
  /// Native köprü yanıt vermiyorsa `null` döner.
  Future<PlatformInfo?> platformInfo();
}
