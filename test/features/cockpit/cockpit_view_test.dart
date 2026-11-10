import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkmax/core/design/app_dimens.dart';
import 'package:turkmax/core/design/app_theme.dart';
import 'package:turkmax/core/l10n/generated/app_localizations.dart';
import 'package:turkmax/features/cockpit/presentation/cockpit_state.dart';
import 'package:turkmax/features/cockpit/presentation/widgets/cockpit_view.dart';
import 'package:turkmax/features/connection/domain/tft_connection_state.dart';
import 'package:turkmax/features/device_status/domain/device_status.dart';
import 'package:turkmax/features/media/domain/media_state.dart';
import 'package:turkmax/features/navigation/data/fake_navigation_provider.dart';
import 'package:turkmax/features/notifications/domain/notification_summary.dart';

Future<void> pumpCockpit(WidgetTester tester, CockpitState state) async {
  tester.view.physicalSize = const Size(TftSpec.width, TftSpec.height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Center(child: CockpitView(state: state)),
    ),
  );
}

void main() {
  final now = DateTime(2026, 11, 10, 9, 7);

  testWidgets('renders at exactly 480x234 without overflow', (tester) async {
    await pumpCockpit(
      tester,
      CockpitState(
        now: now,
        navigation: FakeNavigationProvider.stateAt(0),
        device: const DeviceStatus(batteryPercent: 82, isCharging: true),
        connection: const TftConnectionState(phase: TftConnectionPhase.ready),
        media: const MediaState(
          title: 'Çok uzun bir şarkı adı ki satıra sığmasın diye yazıldı',
          artist: 'Sanatçı',
          isPlaying: true,
        ),
        notification: const NotificationSummary(
          appName: 'Mesajlar',
          title: 'Çok uzun bir gönderen adı burada',
          preview: 'Tek satıra sığmayacak kadar uzun bir bildirim özeti metni',
          unreadCount: 12,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(CockpitView)),
      const Size(TftSpec.width, TftSpec.height),
    );
    expect(find.text('09:07'), findsOneWidget);
    expect(find.text('%82'), findsOneWidget);
    expect(find.byKey(const Key('cockpit.charging')), findsOneWidget);
    expect(find.text('350 m'), findsOneWidget);
    expect(find.text('9+'), findsOneWidget);
    // Navigasyon demo verisi → açıkça etiketlenmeli.
    expect(find.byKey(const Key('cockpit.demoBadge')), findsOneWidget);
  });

  testWidgets('empty state shows placeholders and no demo badge', (
    tester,
  ) async {
    await pumpCockpit(tester, CockpitState(now: now));

    expect(tester.takeException(), isNull);
    expect(find.text('Rota yok'), findsOneWidget);
    expect(find.text('Yeni bildirim yok'), findsOneWidget);
    expect(find.text('Çalan medya yok'), findsOneWidget);
    expect(find.text('--'), findsOneWidget);
    expect(find.byKey(const Key('cockpit.demoBadge')), findsNothing);
    expect(find.byKey(const Key('cockpit.charging')), findsNothing);
  });
}
