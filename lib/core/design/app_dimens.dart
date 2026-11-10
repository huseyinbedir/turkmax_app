/// Boşluk ölçeği (mantıksal piksel).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Köşe yarıçapı ölçeği.
abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
}

/// Yamaha XMAX (scooter CCU ailesi) TFT navigasyon alanı hedef ölçüleri.
///
/// Cockpit bu ölçülerde, 1 mantıksal piksel = 1 TFT pikseli olacak şekilde
/// tasarlanır; telefonda önizleme için ölçeklenir.
abstract final class TftSpec {
  static const double width = 480;
  static const double height = 234;
  static const double topBarHeight = 26;

  /// Gövdede sol harita panelinin genişlik oranı (kalanı sağ panel).
  static const double mapFraction = 0.66;

  static const double aspectRatio = width / height;
}
