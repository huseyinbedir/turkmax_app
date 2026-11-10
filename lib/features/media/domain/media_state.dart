import 'package:equatable/equatable.dart';

/// Aktif medya oturumunun cockpit'te gösterilen özeti.
class MediaState extends Equatable {
  const MediaState({
    required this.title,
    this.artist,
    this.isPlaying = false,
    this.isSimulated = false,
  });

  final String title;
  final String? artist;
  final bool isPlaying;
  final bool isSimulated;

  @override
  List<Object?> get props => [title, artist, isPlaying, isSimulated];
}
