import 'dart:async';

import '../domain/maneuver_info.dart';
import '../domain/route_destination.dart';
import '../domain/navigation_provider.dart';
import '../domain/navigation_state.dart';
import '../domain/route_info.dart';
import 'state_broadcaster.dart';

/// Çevrimdışı demo navigasyonu. Ürettiği her durum `isSimulated: true` taşır.
class FakeNavigationProvider implements NavigationProvider {
  FakeNavigationProvider({this.tick = const Duration(seconds: 1)});

  /// Simülasyon adımı aralığı.
  final Duration tick;

  static const _speedMetersPerTick = 12; // ~43 km/sa
  static const totalMeters = 4200;

  static const _legs = <(ManeuverType, int, String)>[
    (ManeuverType.right, 350, 'Atatürk Blv.'),
    (ManeuverType.straight, 900, 'İnönü Cd.'),
    (ManeuverType.roundabout, 600, 'Cumhuriyet Mey.'),
    (ManeuverType.left, 1250, 'Sahil Yolu'),
    (ManeuverType.slightRight, 700, 'Liman Cd.'),
    (ManeuverType.arrive, 400, 'Varış'),
  ];

  final _state = StateBroadcaster<NavigationState>(
    const NavigationState.idle(isSimulated: true),
  );
  Timer? _timer;

  @override
  String get id => 'fake';

  @override
  Stream<NavigationState> watch() => _state.stream;

  @override
  Future<void> prepare() async {}

  @override
  Future<void> startNavigation(
    RouteDestination destination, {
    bool simulate = false,
  }) async {
    _timer?.cancel();
    var travelled = 0;
    _state.emit(stateAt(travelled, destinationName: destination.title));
    _timer = Timer.periodic(tick, (timer) {
      travelled += _speedMetersPerTick;
      final next = stateAt(travelled, destinationName: destination.title);
      _state.emit(next);
      if (next.status == NavigationStatus.arrived) timer.cancel();
    });
  }

  @override
  Future<void> stopNavigation() async {
    _timer?.cancel();
    _timer = null;
    _state.emit(const NavigationState.idle(isSimulated: true));
  }

  /// [travelledMeters] kadar yol alındığındaki demo durumu (saf fonksiyon).
  static NavigationState stateAt(
    int travelledMeters, {
    String destinationName = 'Demo varış noktası',
  }) {
    final travelled = travelledMeters.clamp(0, totalMeters);
    var legEnd = 0;
    for (final (type, length, road) in _legs) {
      legEnd += length;
      if (travelled < legEnd) {
        final remaining = totalMeters - travelled;
        return NavigationState(
          status: NavigationStatus.guiding,
          isSimulated: true,
          maneuver: ManeuverInfo(
            type: type,
            distanceMeters: legEnd - travelled,
            roadName: road,
          ),
          route: RouteInfo(
            destinationName: destinationName,
            remainingDistanceMeters: remaining,
            remainingDuration: Duration(
              seconds: remaining ~/ _speedMetersPerTick,
            ),
          ),
        );
      }
    }
    return const NavigationState(
      status: NavigationStatus.arrived,
      isSimulated: true,
    );
  }
}
