import 'package:flutter_test/flutter_test.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:turkmax/features/navigation/data/google_maneuver_mapper.dart';
import 'package:turkmax/features/navigation/data/google_navigation_provider.dart';
import 'package:turkmax/features/navigation/data/google_place_search_repository.dart';
import 'package:turkmax/features/navigation/domain/maneuver_info.dart';
import 'package:turkmax/features/navigation/domain/navigation_state.dart';

void main() {
  group('mapGoogleManeuver', () {
    const expectations = {
      Maneuver.turnLeft: ManeuverType.left,
      Maneuver.turnRight: ManeuverType.right,
      Maneuver.turnSharpLeft: ManeuverType.sharpLeft,
      Maneuver.turnSlightRight: ManeuverType.slightRight,
      Maneuver.turnKeepLeft: ManeuverType.slightLeft,
      Maneuver.forkRight: ManeuverType.slightRight,
      Maneuver.mergeLeft: ManeuverType.slightLeft,
      Maneuver.offRampLeft: ManeuverType.left,
      Maneuver.onRampSharpRight: ManeuverType.sharpRight,
      Maneuver.turnUTurnClockwise: ManeuverType.uTurn,
      Maneuver.offRampUTurnCounterclockwise: ManeuverType.uTurn,
      Maneuver.roundaboutLeftClockwise: ManeuverType.roundabout,
      Maneuver.roundaboutUTurnCounterclockwise: ManeuverType.roundabout,
      Maneuver.destination: ManeuverType.arrive,
      Maneuver.destinationLeft: ManeuverType.arrive,
      Maneuver.straight: ManeuverType.straight,
      Maneuver.depart: ManeuverType.straight,
      Maneuver.nameChange: ManeuverType.straight,
      Maneuver.mergeUnspecified: ManeuverType.straight,
      Maneuver.ferryBoat: ManeuverType.unknown,
      Maneuver.unknown: ManeuverType.unknown,
    };

    test('maps representative maneuvers', () {
      expectations.forEach((maneuver, expected) {
        expect(mapGoogleManeuver(maneuver), expected, reason: maneuver.name);
      });
    });

    test('every SDK maneuver maps without throwing', () {
      for (final maneuver in Maneuver.values) {
        expect(mapGoogleManeuver(maneuver), isA<ManeuverType>());
      }
    });
  });

  test('route status maps to user-facing errors', () {
    NavigationError map(NavigationRouteStatus s) =>
        GoogleNavigationProvider.mapRouteStatus(s);
    expect(
      map(NavigationRouteStatus.routeNotFound),
      NavigationError.routeNotFound,
    );
    expect(map(NavigationRouteStatus.networkError), NavigationError.network);
    expect(
      map(NavigationRouteStatus.locationUnavailable),
      NavigationError.locationUnavailable,
    );
    expect(
      map(NavigationRouteStatus.apiKeyNotAuthorized),
      NavigationError.apiKeyRejected,
    );
    expect(
      map(NavigationRouteStatus.quotaExceeded),
      NavigationError.quotaExceeded,
    );
    expect(map(NavigationRouteStatus.internalError), NavigationError.unknown);
  });

  group('GooglePlaceSearchRepository.parse', () {
    test('reads place predictions and skips other suggestions', () {
      const body = '''
{"suggestions":[
  {"placePrediction":{"placeId":"abc","text":{"text":"Kadıköy İskelesi, İstanbul"},
    "structuredFormat":{"mainText":{"text":"Kadıköy İskelesi"},"secondaryText":{"text":"İstanbul"}}}},
  {"queryPrediction":{"text":{"text":"kadıköy kafe"}}},
  {"placePrediction":{"placeId":"def","text":{"text":"Kadıköy"}}},
  {"placePrediction":{"text":{"text":"kimliksiz"}}}
]}''';
      final results = GooglePlaceSearchRepository.parse(body);
      expect(results.map((r) => r.placeId), ['abc', 'def']);
      expect(results.first.title, 'Kadıköy İskelesi');
      expect(results.first.subtitle, 'İstanbul');
      expect(results.last.title, 'Kadıköy');
      expect(results.last.subtitle, isNull);
      expect(results.every((r) => !r.isSimulated), isTrue);
    });

    test('empty or unexpected bodies give no results', () {
      expect(GooglePlaceSearchRepository.parse('{}'), isEmpty);
      expect(GooglePlaceSearchRepository.parse('[]'), isEmpty);
    });

    test('extracts API error message', () {
      expect(
        GooglePlaceSearchRepository.errorMessage(
          '{"error":{"code":403,"message":"API key not valid"}}',
        ),
        'API key not valid',
      );
      expect(
        GooglePlaceSearchRepository.errorMessage('<html>'),
        'unknown error',
      );
    });
  });
}
