import 'package:flutter_test/flutter_test.dart';
import 'package:turkmax/features/navigation/data/fake_navigation_provider.dart';
import 'package:turkmax/features/navigation/domain/maneuver_info.dart';
import 'package:turkmax/features/navigation/domain/navigation_state.dart';
import 'package:turkmax/features/navigation/domain/route_destination.dart';

void main() {
  test('every demo state is flagged as simulated', () {
    for (final metres in [0, 349, 350, 2000, 4199, 4200]) {
      expect(FakeNavigationProvider.stateAt(metres).isSimulated, isTrue);
    }
  });

  test('maneuver distance counts down within a leg', () {
    final start = FakeNavigationProvider.stateAt(0);
    expect(start.status, NavigationStatus.guiding);
    expect(start.maneuver!.type, ManeuverType.right);
    expect(start.maneuver!.distanceMeters, 350);
    expect(start.route!.remainingDistanceMeters, 4200);

    final next = FakeNavigationProvider.stateAt(350);
    expect(next.maneuver!.type, ManeuverType.straight);
    expect(next.maneuver!.distanceMeters, 900);
  });

  test('arrives at the end of the route', () {
    final end = FakeNavigationProvider.stateAt(4200);
    expect(end.status, NavigationStatus.arrived);
    expect(end.maneuver, isNull);
  });

  test('starts idle, guides after start, returns to idle on stop', () async {
    final provider = FakeNavigationProvider(
      tick: const Duration(milliseconds: 5),
    );
    final states = <NavigationState>[];
    final subscription = provider.watch().listen(states.add);
    await Future<void>.delayed(Duration.zero);
    expect(states.single.status, NavigationStatus.idle);
    expect(states.single.isSimulated, isTrue);

    await provider.startNavigation(const RouteDestination(title: 'Hedef'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(states.last.status, NavigationStatus.guiding);
    expect(states.last.route!.destinationName, 'Hedef');
    expect(
      states.last.maneuver!.distanceMeters,
      lessThan(states[1].maneuver!.distanceMeters),
    );

    await provider.stopNavigation();
    await Future<void>.delayed(Duration.zero);
    final count = states.length;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(states.last.status, NavigationStatus.idle);
    expect(states, hasLength(count), reason: 'timer must stop');
    await subscription.cancel();
  });

  test('late subscribers receive the current state first', () async {
    final provider = FakeNavigationProvider();
    await provider.startNavigation(const RouteDestination(title: 'Hedef'));
    final first = await provider.watch().first;
    expect(first.status, NavigationStatus.guiding);
    await provider.stopNavigation();
  });
}
