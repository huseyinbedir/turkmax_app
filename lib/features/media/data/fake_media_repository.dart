import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../domain/media_repository.dart';
import '../domain/media_state.dart';

@LazySingleton(as: MediaRepository)
class FakeMediaRepository implements MediaRepository {
  const FakeMediaRepository();

  @override
  Stream<MediaState?> watch() => Stream.value(
    // Demo verisi yalnızca geliştirici derlemesinde; diğerlerinde kart boş kalır.
    !kDebugMode
        ? null
        : const MediaState(
            title: 'Demo Parça',
            artist: 'Demo Sanatçı',
            isPlaying: true,
            isSimulated: true,
          ),
  );
}
