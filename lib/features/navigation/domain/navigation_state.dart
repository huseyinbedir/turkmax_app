import 'package:equatable/equatable.dart';

import 'maneuver_info.dart';
import 'route_info.dart';

enum NavigationStatus { idle, routing, guiding, rerouting, arrived }

/// Kullanıcıya gösterilecek navigasyon hata türleri.
enum NavigationError {
  termsNotAccepted,
  locationPermissionDenied,
  locationUnavailable,
  network,
  routeNotFound,
  apiKeyRejected,
  quotaExceeded,
  unknown,
}

/// Navigasyonun anlık durumu. Hem gerçek hem test sağlayıcısı bu modeli üretir.
class NavigationState extends Equatable {
  const NavigationState({
    required this.status,
    this.isReady = true,
    this.route,
    this.maneuver,
    this.error,
    this.errorDetail,
    this.isSimulated = false,
  });

  const NavigationState.idle({this.isSimulated = false, this.isReady = true})
    : status = NavigationStatus.idle,
      route = null,
      maneuver = null,
      error = null,
      errorDetail = null;

  final NavigationStatus status;

  /// Sağlayıcının oturumu hazır mı (koşullar, izinler, SDK oturumu).
  final bool isReady;
  final RouteInfo? route;
  final ManeuverInfo? maneuver;
  final NavigationError? error;

  /// Tanılama için ham ayrıntı; kullanıcı metni olarak gösterilmez.
  final String? errorDetail;

  /// Veriler gerçek bir sürüşten değil demo/simülasyondan geliyorsa `true`.
  /// Arayüz bu durumu kullanıcıya açıkça etiketlemek zorundadır.
  final bool isSimulated;

  bool get isActive =>
      status == NavigationStatus.routing ||
      status == NavigationStatus.guiding ||
      status == NavigationStatus.rerouting;

  @override
  List<Object?> get props => [
    status,
    isReady,
    route,
    maneuver,
    error,
    errorDetail,
    isSimulated,
  ];
}
