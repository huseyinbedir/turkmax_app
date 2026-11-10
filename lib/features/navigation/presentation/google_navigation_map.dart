import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

/// Cockpit'in sol panelindeki gerçek Google navigasyon haritası.
///
/// Dönüş bilgisi sağ panelde gösterildiği için SDK'nın üst/alt bilgi şeritleri
/// kapatılır. Google logosu ve atıf öğelerine dokunulmaz.
class GoogleNavigationMap extends StatefulWidget {
  const GoogleNavigationMap({super.key});

  @override
  State<GoogleNavigationMap> createState() => _GoogleNavigationMapState();
}

class _GoogleNavigationMapState extends State<GoogleNavigationMap> {
  static const _locationPollInterval = Duration(seconds: 1);
  static const _locationPollAttempts = 60;

  Timer? _followTimer;

  @override
  void dispose() {
    _followTimer?.cancel();
    super.dispose();
  }

  Future<void> _configure(GoogleNavigationViewController controller) async {
    await controller.setMyLocationEnabled(true);
    await controller.setNavigationHeaderEnabled(false);
    await controller.setNavigationFooterEnabled(false);
    await controller.setRecenterButtonEnabled(false);
    await controller.setSpeedometerEnabled(false);
    await controller.setSpeedLimitIconEnabled(false);
    await controller.setReportIncidentButtonEnabled(false);
    await controller.setTrafficPromptsEnabled(false);
    _followWhenLocated(controller);
  }

  /// Görünüm oluşturulduğunda konum henüz bilinmiyor olabilir; o anda verilen
  /// takip komutu etkisiz kalır. İlk konum gelince kamerayı takibe alır.
  void _followWhenLocated(GoogleNavigationViewController controller) {
    var attempts = 0;
    _followTimer?.cancel();
    _followTimer = Timer.periodic(_locationPollInterval, (timer) async {
      attempts++;
      LatLng? location;
      try {
        location = await controller.getMyLocation();
      } on Exception {
        // Paket, konum henüz yokken null yerine hata fırlatabiliyor
        // (0.12.0); "henüz konum yok" olarak ele alınır.
        location = null;
      }
      if (!mounted) return timer.cancel();
      if (attempts == 1 || attempts % 10 == 0 || location != null) {
        debugPrint(
          '[map] location poll #$attempts: '
          '${location == null ? 'none yet' : 'fix acquired'}',
        );
      }
      if (location != null) {
        timer.cancel();
        try {
          await controller.followMyLocation(CameraPerspective.tilted);
        } on Exception catch (e) {
          debugPrint('[map] follow failed: $e');
        }
      } else if (attempts >= _locationPollAttempts) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMapsNavigationView(
      onViewCreated: _configure,
      initialNavigationUIEnabledPreference:
          NavigationUIEnabledPreference.automatic,
      initialMapColorScheme: MapColorScheme.dark,
      initialForceNightMode: NavigationForceNightMode.forceNight,
      initialCompassEnabled: false,
      initialMapToolbarEnabled: false,
      initialZoomControlsEnabled: false,
      // Önizleme küçültülerek gösterildiği için harita hareketleri kapalı;
      // kamera konumu takip eder.
      initialRotateGesturesEnabled: false,
      initialScrollGesturesEnabled: false,
      initialTiltGesturesEnabled: false,
      initialZoomGesturesEnabled: false,
    );
  }
}
