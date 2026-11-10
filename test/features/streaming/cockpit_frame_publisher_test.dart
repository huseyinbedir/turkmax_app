import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkmax/core/l10n/generated/app_localizations.dart';
import 'package:turkmax/features/cockpit/presentation/cockpit_state.dart';
import 'package:turkmax/features/media/domain/media_state.dart';
import 'package:turkmax/features/navigation/data/fake_navigation_provider.dart';
import 'package:turkmax/features/navigation/domain/navigation_state.dart';
import 'package:turkmax/features/streaming/data/cockpit_frame_publisher.dart';

void main() {
  late AppLocalizations l10n;
  final now = DateTime(2026, 11, 10, 12, 0);

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('tr'));
  });

  test('active guidance is formatted for the TFT frame', () {
    final payload = CockpitFramePublisher.buildPayload(
      CockpitState(now: now, navigation: FakeNavigationProvider.stateAt(0)),
      l10n,
    );
    expect(payload['maneuver'], 'right');
    expect(payload['maneuverDistance'], '350 m');
    expect(payload['roadName'], 'Atatürk Blv.');
    expect(payload['routeLine'], '4,2 km · Varış 12:05');
    expect(payload['demoBadge'], 'DEMO');
  });

  test('idle state carries placeholder texts and no demo badge', () {
    final payload = CockpitFramePublisher.buildPayload(
      CockpitState(now: now),
      l10n,
    );
    expect(payload['maneuver'], isNull);
    expect(payload['routeLine'], isNull);
    expect(payload['navigationMessage'], 'Rota yok');
    expect(payload['notificationTitle'], isNull);
    expect(payload['notificationEmptyText'], 'Yeni bildirim yok');
    expect(payload['mediaTitle'], isNull);
    expect(payload['mediaEmptyText'], 'Çalan medya yok');
    expect(payload['demoBadge'], isNull);
  });

  test('status messages follow navigation status', () {
    String message(NavigationStatus status) =>
        CockpitFramePublisher.buildPayload(
              CockpitState(
                now: now,
                navigation: NavigationState(status: status),
              ),
              l10n,
            )['navigationMessage']!
            as String;
    expect(message(NavigationStatus.routing), 'Rota hesaplanıyor');
    expect(message(NavigationStatus.rerouting), 'Rota yeniden hesaplanıyor');
    expect(message(NavigationStatus.arrived), 'Varış noktasına ulaşıldı');
  });

  test('media fields are passed through', () {
    final payload = CockpitFramePublisher.buildPayload(
      CockpitState(
        now: now,
        media: const MediaState(
          title: 'Parça',
          artist: 'Sanatçı',
          isPlaying: true,
        ),
      ),
      l10n,
    );
    expect(payload['mediaTitle'], 'Parça');
    expect(payload['mediaArtist'], 'Sanatçı');
    expect(payload['mediaPlaying'], isTrue);
  });
}
