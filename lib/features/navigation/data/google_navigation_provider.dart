import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/maneuver_info.dart';
import '../domain/route_destination.dart';
import '../domain/navigation_provider.dart';
import '../domain/navigation_state.dart';
import '../domain/route_info.dart';
import 'google_maneuver_mapper.dart';
import 'state_broadcaster.dart';

/// Resmi `google_navigation_flutter` paketi üzerinden canlı navigasyon.
class GoogleNavigationProvider implements NavigationProvider {
  final _state = StateBroadcaster<NavigationState>(
    const NavigationState.idle(isReady: false),
  );
  final _subscriptions = <StreamSubscription<void>>[];

  static const termsDialogHintDelay = Duration(seconds: 12);

  String _destinationName = '';
  bool _simulated = false;
  bool _preparing = false;
  int _attempt = 0;

  @override
  String get id => 'google';

  @override
  Stream<NavigationState> watch() => _state.stream;

  @override
  Future<void> prepare() async {
    if (_state.value.isReady || _preparing) return;
    _preparing = true;
    final attempt = ++_attempt;
    try {
      debugPrint('[nav] prepare: checking terms');
      if (!await GoogleMapsNavigator.areTermsAccepted()) {
        debugPrint('[nav] prepare: showing terms dialog');
        // Anahtar reddedildiğinde SDK pencereyi hiç açmıyor ve bu çağrı
        // sonuçlanmıyor. Bekleme uzarsa kullanıcıya nedenini göster; pencere
        // gerçekten açıksa ve sonradan kabul edilirse akış normal sürer.
        final watchdog = Timer(termsDialogHintDelay, () {
          // Takılan çağrıyı bırak; "Tekrar dene" yeni bir deneme başlatabilsin.
          _preparing = false;
          _attempt++;
          _fail(
            NavigationError.apiKeyRejected,
            detail:
                'Terms dialog did not complete; check logcat for '
                '"Authorization failure" (API enabled? key restrictions?)',
          );
        });
        final bool accepted;
        try {
          accepted = await GoogleMapsNavigator.showTermsAndConditionsDialog(
            'TurkMax',
            'TurkMax',
          );
        } finally {
          watchdog.cancel();
        }
        if (attempt != _attempt) return;
        if (!accepted) return _fail(NavigationError.termsNotAccepted);
      }
      debugPrint('[nav] prepare: requesting location permission');
      final location = await Permission.locationWhenInUse.request();
      if (!location.isGranted) {
        return _fail(NavigationError.locationPermissionDenied);
      }
      if (!await Permission.location.serviceStatus.isEnabled) {
        return _fail(
          NavigationError.locationUnavailable,
          detail: 'Device location service is turned off',
        );
      }
      // Rehberlik bildirimi için; reddedilse de navigasyon çalışır.
      await Permission.notification.request();

      debugPrint('[nav] prepare: initializing session');
      await GoogleMapsNavigator.initializeNavigationSession(
        taskRemovedBehavior: TaskRemovedBehavior.quitService,
      );
      debugPrint('[nav] prepare: session ready');
      _attachListeners();
      _state.emit(const NavigationState.idle());
    } on Exception catch (e) {
      debugPrint('[nav] prepare failed: $e');
      _fail(NavigationError.unknown, detail: e.toString());
    } finally {
      if (attempt == _attempt) _preparing = false;
    }
  }

  @override
  Future<void> startNavigation(
    RouteDestination destination, {
    bool simulate = false,
  }) async {
    await prepare();
    final placeId = destination.placeId;
    if (!_state.value.isReady || placeId == null) return;

    _destinationName = destination.title;
    _simulated = simulate;
    _state.emit(
      NavigationState(status: NavigationStatus.routing, isSimulated: simulate),
    );
    try {
      final status = await GoogleMapsNavigator.setDestinations(
        Destinations(
          waypoints: [
            NavigationWaypoint.withPlaceID(
              title: destination.title,
              placeID: placeId,
            ),
          ],
          displayOptions: NavigationDisplayOptions(
            showDestinationMarkers: true,
          ),
          // Türkiye kapsamında iki tekerlekli yönlendirme bulunmadığı için
          // sürüş modu kullanılır.
          routingOptions: RoutingOptions(
            travelMode: NavigationTravelMode.driving,
          ),
        ),
      );
      if (status != NavigationRouteStatus.statusOk) {
        return _state.emit(
          NavigationState(
            status: NavigationStatus.idle,
            error: mapRouteStatus(status),
            errorDetail: status.name,
          ),
        );
      }
      await GoogleMapsNavigator.startGuidance();
      if (simulate) {
        await GoogleMapsNavigator.simulator
            .simulateLocationsAlongExistingRoute();
      }
      if (_state.value.status == NavigationStatus.routing) {
        _state.emit(
          NavigationState(
            status: NavigationStatus.guiding,
            isSimulated: simulate,
          ),
        );
      }
    } on Exception catch (e) {
      _state.emit(
        NavigationState(
          status: NavigationStatus.idle,
          error: NavigationError.unknown,
          errorDetail: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> stopNavigation() async {
    if (!_state.value.isReady) return;
    await _endGuidance();
    _state.emit(const NavigationState.idle());
  }

  Future<void> _endGuidance() async {
    try {
      await GoogleMapsNavigator.stopGuidance();
      if (_simulated) await GoogleMapsNavigator.simulator.removeUserLocation();
      await GoogleMapsNavigator.clearDestinations();
    } on PlatformException {
      // Oturum zaten kapanmışsa yapılacak bir şey yok.
    } on Exception {
      // Aynı şekilde: durum yine de boşa alınır.
    }
    _simulated = false;
  }

  void _attachListeners() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions
      ..clear()
      ..addAll([
        GoogleMapsNavigator.setNavInfoListener(
          (event) => _onNavInfo(event.navInfo),
          numNextStepsToPreview: 0,
        ),
        GoogleMapsNavigator.setOnArrivalListener((_) => _onArrival()),
        GoogleMapsNavigator.setOnReroutingListener(() {
          final current = _state.value;
          if (current.isActive) {
            _state.emit(
              NavigationState(
                status: NavigationStatus.rerouting,
                route: current.route,
                maneuver: current.maneuver,
                isSimulated: _simulated,
              ),
            );
          }
        }),
      ]);
  }

  void _onNavInfo(NavInfo info) {
    final current = _state.value;
    if (!current.isActive) return;
    if (info.navState == NavState.stopped) return;

    final next = stateFromNavInfo(
      info,
      destinationName: _destinationName,
      isSimulated: _simulated,
    );
    if (next != null) _state.emit(next);
  }

  Future<void> _onArrival() async {
    final simulated = _simulated;
    await _endGuidance();
    _state.emit(
      NavigationState(status: NavigationStatus.arrived, isSimulated: simulated),
    );
  }

  void _fail(NavigationError error, {String? detail}) => _state.emit(
    NavigationState(
      status: NavigationStatus.idle,
      isReady: false,
      error: error,
      errorDetail: detail,
    ),
  );

  /// SDK'nın `NavInfo` olayını alan modeline çevirir (saf fonksiyon).
  /// SDK'nın vermediği alanlar boş bırakılır; değer uydurulmaz.
  static NavigationState? stateFromNavInfo(
    NavInfo info, {
    required String destinationName,
    required bool isSimulated,
  }) {
    final status = switch (info.navState) {
      NavState.enroute => NavigationStatus.guiding,
      NavState.rerouting => NavigationStatus.rerouting,
      NavState.stopped || NavState.unknown => null,
    };
    if (status == null) return null;

    final step = info.currentStep;
    final stepDistance = info.distanceToCurrentStepMeters;
    final remainingDistance = info.distanceToFinalDestinationMeters;
    final remainingSeconds = info.timeToFinalDestinationSeconds;

    return NavigationState(
      status: status,
      isSimulated: isSimulated,
      maneuver: step != null && stepDistance != null
          ? ManeuverInfo(
              type: mapGoogleManeuver(step.maneuver),
              distanceMeters: stepDistance,
              roadName: _nonEmpty(step.simpleRoadName ?? step.fullRoadName),
            )
          : null,
      route: remainingDistance != null && remainingSeconds != null
          ? RouteInfo(
              destinationName: destinationName,
              remainingDistanceMeters: remainingDistance,
              remainingDuration: Duration(seconds: remainingSeconds),
            )
          : null,
    );
  }

  static String? _nonEmpty(String? value) =>
      value == null || value.trim().isEmpty ? null : value;

  static NavigationError mapRouteStatus(NavigationRouteStatus status) =>
      switch (status) {
        NavigationRouteStatus.routeNotFound ||
        NavigationRouteStatus.waypointError ||
        NavigationRouteStatus.travelModeUnsupported =>
          NavigationError.routeNotFound,
        NavigationRouteStatus.networkError ||
        NavigationRouteStatus.routingTimeout => NavigationError.network,
        NavigationRouteStatus.locationUnavailable ||
        NavigationRouteStatus.locationUnknown =>
          NavigationError.locationUnavailable,
        NavigationRouteStatus.apiKeyNotAuthorized =>
          NavigationError.apiKeyRejected,
        NavigationRouteStatus.quotaExceeded ||
        NavigationRouteStatus.quotaCheckFailed => NavigationError.quotaExceeded,
        _ => NavigationError.unknown,
      };
}
