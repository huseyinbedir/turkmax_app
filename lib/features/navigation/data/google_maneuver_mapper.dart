import 'package:google_navigation_flutter/google_navigation_flutter.dart';

import '../domain/maneuver_info.dart';

/// Navigation SDK'nın ayrıntılı manevra türlerini cockpit'in sade kümesine
/// indirger. SDK'nın vermediği bilgi üretilmez; tanınmayan türler `unknown`.
ManeuverType mapGoogleManeuver(Maneuver maneuver) {
  final name = maneuver.name;
  bool has(String part) => name.contains(part);

  if (maneuver == Maneuver.unknown || has('ferry')) return ManeuverType.unknown;
  if (name.startsWith('roundabout')) return ManeuverType.roundabout;
  if (has('UTurn')) return ManeuverType.uTurn;
  if (name.startsWith('destination')) return ManeuverType.arrive;
  if (has('SharpLeft')) return ManeuverType.sharpLeft;
  if (has('SharpRight')) return ManeuverType.sharpRight;
  if (has('SlightLeft') || has('KeepLeft')) return ManeuverType.slightLeft;
  if (has('SlightRight') || has('KeepRight')) return ManeuverType.slightRight;
  if (maneuver == Maneuver.forkLeft || maneuver == Maneuver.mergeLeft) {
    return ManeuverType.slightLeft;
  }
  if (maneuver == Maneuver.forkRight || maneuver == Maneuver.mergeRight) {
    return ManeuverType.slightRight;
  }
  if (name.endsWith('Left')) return ManeuverType.left;
  if (name.endsWith('Right')) return ManeuverType.right;
  return ManeuverType.straight;
}
