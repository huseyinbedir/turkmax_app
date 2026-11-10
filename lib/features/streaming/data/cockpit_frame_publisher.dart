import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/platform/channel_names.dart';
import '../../cockpit/presentation/cockpit_formatters.dart';
import '../../cockpit/presentation/cockpit_state.dart';
import '../../navigation/domain/navigation_state.dart';

/// Cockpit içeriğini native tarafa bildirir. TFT'ye giden kare native tarafta
/// çizildiği için (uygulama arka plandayken de güncel kalsın diye) burada
/// yalnızca içerik hazırlanır; metinler tek yerde, Dart'ta biçimlendirilir.
@lazySingleton
class CockpitFramePublisher {
  CockpitFramePublisher();

  static const _channel = MethodChannel(ChannelNames.streaming);

  Map<String, Object?>? _last;

  Future<void> publish(CockpitState state, AppLocalizations l10n) async {
    final payload = buildPayload(state, l10n);
    if (_mapEquals(payload, _last)) return;
    _last = payload;
    try {
      await _channel.invokeMethod<void>('setCockpitState', payload);
    } on MissingPluginException {
      // Native köprü yok (testler, iOS).
    } on PlatformException {
      // Bir sonraki değişiklikte yeniden denenir.
      _last = null;
    }
  }

  /// Native `CockpitFrameState` ile aynı alanlar (saf fonksiyon).
  static Map<String, Object?> buildPayload(
    CockpitState state,
    AppLocalizations l10n,
  ) {
    final navigation = state.navigation;
    final maneuver = navigation.maneuver;
    final route = navigation.route;
    final notification = state.notification;
    final media = state.media;
    return {
      'maneuver': maneuver?.type.name,
      'maneuverDistance': maneuver == null
          ? null
          : CockpitFormatters.distance(maneuver.distanceMeters),
      'roadName': maneuver?.roadName,
      'routeLine': maneuver == null || route == null
          ? null
          : '${CockpitFormatters.distance(route.remainingDistanceMeters)} · '
                '${l10n.navEta(CockpitFormatters.clock(route.etaFrom(state.now)))}',
      'navigationMessage': switch (navigation.status) {
        NavigationStatus.arrived => l10n.navArrived,
        NavigationStatus.rerouting => l10n.navRerouting,
        NavigationStatus.routing || NavigationStatus.guiding => l10n.navRouting,
        NavigationStatus.idle => l10n.navIdle,
      },
      'notificationTitle': notification?.title,
      'notificationPreview': notification?.preview,
      'notificationCount': notification?.unreadCount ?? 0,
      'notificationEmptyText': l10n.notificationsEmpty,
      'mediaTitle': media?.title,
      'mediaArtist': media?.artist,
      'mediaPlaying': media?.isPlaying ?? false,
      'mediaEmptyText': l10n.mediaEmpty,
      'demoBadge': state.hasSimulatedContent ? l10n.demoBadge : null,
      'darkMap': true,
    };
  }

  static bool _mapEquals(Map<String, Object?> a, Map<String, Object?>? b) {
    if (b == null || a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
