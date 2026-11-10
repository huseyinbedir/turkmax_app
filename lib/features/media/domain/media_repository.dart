import 'media_state.dart';

/// Aktif medya oturumu; çalan bir şey yoksa `null` yayınlar.
///
/// Gerçek uygulama (Android MediaSessionManager) henüz yok.
abstract interface class MediaRepository {
  Stream<MediaState?> watch();
}
