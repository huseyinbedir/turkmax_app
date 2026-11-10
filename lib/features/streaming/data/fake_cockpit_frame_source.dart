import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../../app/di/environments.dart';
import '../domain/cockpit_frame.dart';
import '../domain/cockpit_frame_source.dart';

@LazySingleton(as: CockpitFrameSource, env: [kEnvFake])
class FakeCockpitFrameSource implements CockpitFrameSource {
  const FakeCockpitFrameSource();

  @override
  String get id => 'fake';

  @override
  Future<CockpitFrame> captureFrame() async => CockpitFrame(
    // Yalnızca JPEG SOI/EOI işaretleri; çözülebilir bir görüntü değildir.
    jpegBytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]),
    width: 480,
    height: 234,
    encodeDuration: Duration.zero,
    sourceId: id,
  );
}
