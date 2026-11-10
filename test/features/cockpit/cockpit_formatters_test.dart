import 'package:flutter_test/flutter_test.dart';
import 'package:turkmax/features/cockpit/presentation/cockpit_formatters.dart';

void main() {
  test('clock is 24h zero padded', () {
    expect(CockpitFormatters.clock(DateTime(2026, 1, 1, 7, 5)), '07:05');
    expect(CockpitFormatters.clock(DateTime(2026, 1, 1, 23, 59)), '23:59');
  });

  test('distance formatting', () {
    expect(CockpitFormatters.distance(7), '7 m');
    expect(CockpitFormatters.distance(354), '350 m');
    expect(CockpitFormatters.distance(996), '1,0 km');
    expect(CockpitFormatters.distance(1250), '1,3 km');
    expect(CockpitFormatters.distance(120400), '120 km');
  });

  test('duration formatting', () {
    expect(CockpitFormatters.duration(const Duration(seconds: 61)), '2 dk');
    expect(
      CockpitFormatters.duration(const Duration(minutes: 65)),
      '1 sa 05 dk',
    );
  });
}
