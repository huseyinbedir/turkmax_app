import 'dart:typed_data';

/// TFT'ye gönderilmeye hazır, kodlanmış tek bir cockpit karesi.
class CockpitFrame {
  const CockpitFrame({
    required this.jpegBytes,
    required this.width,
    required this.height,
    required this.encodeDuration,
    required this.sourceId,
  });

  final Uint8List jpegBytes;
  final int width;
  final int height;
  final Duration encodeDuration;

  /// Kareyi üreten kaynağın kimliği (ör. `synthetic`).
  final String sourceId;
}
