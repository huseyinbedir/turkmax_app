import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../../app/di/environments.dart';
import '../../../core/platform/channel_names.dart';
import '../domain/cockpit_frame.dart';
import '../domain/cockpit_frame_source.dart';

/// Native `SyntheticFrameSource` + `JpegFrameEncoder` çıktısını ister.
@LazySingleton(as: CockpitFrameSource, env: [kEnvDevice])
class PlatformSyntheticFrameSource implements CockpitFrameSource {
  const PlatformSyntheticFrameSource();

  static const _methods = MethodChannel(ChannelNames.streaming);

  @override
  String get id => 'synthetic';

  @override
  Future<CockpitFrame> captureFrame() async {
    final map = await _methods.invokeMapMethod<String, Object?>(
      'captureSyntheticFrame',
    );
    if (map == null) {
      throw PlatformException(code: 'NO_FRAME', message: 'Empty frame reply');
    }
    return CockpitFrame(
      jpegBytes: map['jpeg']! as Uint8List,
      width: map['width']! as int,
      height: map['height']! as int,
      encodeDuration: Duration(microseconds: map['encodeMicros']! as int),
      sourceId: id,
    );
  }
}
