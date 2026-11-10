import 'package:flutter/painting.dart';

/// TurkMax tek teması: Premium Dark Teal.
///
/// Uygulamada başka bir renk paleti veya tema varyantı yoktur; yeni renkler
/// yalnızca buraya eklenir.
abstract final class AppColors {
  static const Color background = Color(0xFF081416);
  static const Color surface = Color(0xFF102527);
  static const Color elevated = Color(0xFF173234);
  static const Color primary = Color(0xFF14B8A6);
  static const Color accent = Color(0xFF2DD4BF);
  static const Color text = Color(0xFFF0FAF9);
  static const Color textSecondary = Color(0xFF9BB5B3);
  static const Color border = Color(0xFF284346);

  /// Durum renkleri (yalnızca anlam taşıyan göstergeler için).
  static const Color warning = Color(0xFFF5B942);
  static const Color danger = Color(0xFFF26D6D);
}
