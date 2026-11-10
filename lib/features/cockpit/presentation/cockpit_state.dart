import 'package:equatable/equatable.dart';

import '../../connection/domain/tft_connection_state.dart';
import '../../device_status/domain/device_status.dart';
import '../../media/domain/media_state.dart';
import '../../navigation/domain/navigation_state.dart';
import '../../notifications/domain/notification_summary.dart';

/// Tek cockpit ekranının tamamını tarif eden değişmez durum.
///
/// `CockpitView` bu durumun saf bir fonksiyonudur.
class CockpitState extends Equatable {
  const CockpitState({
    required this.now,
    this.navigation = const NavigationState.idle(),
    this.device = const DeviceStatus(),
    this.connection = const TftConnectionState(),
    this.media,
    this.notification,
  });

  final DateTime now;
  final NavigationState navigation;
  final DeviceStatus device;
  final TftConnectionState connection;
  final MediaState? media;
  final NotificationSummary? notification;

  /// Ekrandaki herhangi bir bölüm demo verisi gösteriyorsa `true`.
  bool get hasSimulatedContent =>
      navigation.isSimulated ||
      (media?.isSimulated ?? false) ||
      (notification?.isSimulated ?? false);

  CockpitState copyWith({
    DateTime? now,
    NavigationState? navigation,
    DeviceStatus? device,
    TftConnectionState? connection,
    MediaState? Function()? media,
    NotificationSummary? Function()? notification,
  }) => CockpitState(
    now: now ?? this.now,
    navigation: navigation ?? this.navigation,
    device: device ?? this.device,
    connection: connection ?? this.connection,
    media: media != null ? media() : this.media,
    notification: notification != null ? notification() : this.notification,
  );

  @override
  List<Object?> get props => [
    now,
    navigation,
    device,
    connection,
    media,
    notification,
  ];
}
