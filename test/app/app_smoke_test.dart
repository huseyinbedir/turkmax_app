import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turkmax/app/di/environments.dart';
import 'package:turkmax/app/di/injection.dart';
import 'package:turkmax/app/turkmax_app.dart';
import 'package:turkmax/features/cockpit/presentation/widgets/cockpit_view.dart';
import 'package:turkmax/features/connection/presentation/connection_page.dart';

Future<void> pumpApp(WidgetTester tester) async {
  tester.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(const TurkMaxApp());
  await tester.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies(environment: kEnvFake);
  });

  testWidgets('app boots to the cockpit preview and opens settings', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('TurkMax'), findsOneWidget);
    expect(find.byType(CockpitView), findsOneWidget);
    expect(find.text('%82'), findsOneWidget);
    expect(find.byKey(const Key('cockpit.demoBadge')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Otomatik yeniden bağlan'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings.auto_reconnect'), isFalse);
  });

  testWidgets('searching a destination starts and stops demo guidance', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Rota yok'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav.whereTo')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search.field')), 'Kadıköy');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    await tester.tap(find.text('Demo: Kadıköy'));
    await tester.pumpAndSettle();

    expect(find.text('Hedef: Demo: Kadıköy'), findsOneWidget);
    expect(find.text('350 m'), findsOneWidget);
    expect(find.text('Atatürk Blv.'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('nav.stop')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav.stop')));
    await tester.pumpAndSettle();
    expect(find.text('Rota yok'), findsOneWidget);
    expect(find.byKey(const Key('nav.whereTo')), findsOneWidget);
  });

  testWidgets('connection page: connect, stream, disconnect', (tester) async {
    await pumpApp(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('home.connection')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('home.connection')));
    await tester.pumpAndSettle();

    expect(find.text('Bağlı değil'), findsOneWidget);
    expect(find.text('YCCU_TEST'), findsOneWidget);
    expect(find.textContaining('Yamaha göstergesi olabilir'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('connection.connect.00:11:22:33:44:55')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hazır'), findsOneWidget);
    expect(find.textContaining('006-B3952-03 · 480×234'), findsOneWidget);

    await tester.tap(find.byKey(const Key('connection.startStreaming')));
    await tester.pumpAndSettle();
    expect(find.text('Yayın yapılıyor'), findsOneWidget);
    expect(find.textContaining('12.5 FPS'), findsOneWidget);

    // Günlük kartı periyodik olarak dolar.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    final pageList = find.descendant(
      of: find.byType(ConnectionPage),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('log.text')),
      300,
      scrollable: pageList.first,
    );
    expect(find.textContaining('fake log line'), findsOneWidget);
    await tester.drag(find.byType(ConnectionPage), const Offset(0, 5000));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('connection.disconnect')));
    await tester.pumpAndSettle();
    expect(find.text('Bağlı değil'), findsOneWidget);
    expect(find.text('Son bağlantı: YCCU_TEST'), findsOneWidget);
  });

  testWidgets('diagnostics generates a frame from the frame source', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.monitor_heart_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Çalışıyor'), findsOneWidget);

    expect(
      find.text('Gerçek motosiklet üzerinde henüz hiçbir doğrulama yapılmadı.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Kare üret'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('480×234 · 4 bayt'), findsOneWidget);
  });
}
