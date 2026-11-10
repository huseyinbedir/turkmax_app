import 'route_destination.dart';
import 'navigation_state.dart';

/// Kritik soyutlama 1/3: navigasyon kaynağı.
///
/// Uygulamalar:
/// * `GoogleNavigationProvider` — `google_navigation_flutter` ile canlı rota.
/// * `FakeNavigationProvider` — API anahtarı/konum olmadan demo ve testler.
///
/// Cockpit ve streaming katmanları yalnızca bu arayüzü tanır.
abstract interface class NavigationProvider {
  /// Sağlayıcı kimliği (tanılama için), ör. `fake`, `google`.
  String get id;

  /// Güncel durum ve sonraki değişiklikler. Abone olunduğunda son durumu
  /// hemen yayınlar.
  Stream<NavigationState> watch();

  /// Oturumu hazırlar (koşullar, izinler, SDK). Sonuç [watch] üzerinden gelir.
  Future<void> prepare();

  /// [destination] için rota hesaplar ve rehberliği başlatır.
  ///
  /// [simulate] yalnızca geliştirme içindir: konumu rota boyunca yapay
  /// olarak ilerletir ve durum `isSimulated: true` olarak işaretlenir.
  Future<void> startNavigation(
    RouteDestination destination, {
    bool simulate = false,
  });

  /// Rehberliği kontrollü biçimde sonlandırır.
  Future<void> stopNavigation();
}
