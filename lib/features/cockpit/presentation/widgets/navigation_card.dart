import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_dimens.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../navigation/domain/maneuver_info.dart';
import '../../../navigation/domain/navigation_state.dart';
import '../cockpit_formatters.dart';
import 'cockpit_panel.dart';

/// Sağ üst: aktif dönüş yönlendirmesi.
class NavigationCard extends StatelessWidget {
  const NavigationCard({
    super.key,
    required this.navigation,
    required this.now,
  });

  final NavigationState navigation;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maneuver = navigation.maneuver;
    final route = navigation.route;

    if (maneuver == null) {
      final message = switch (navigation.status) {
        NavigationStatus.arrived => l10n.navArrived,
        NavigationStatus.rerouting => l10n.navRerouting,
        NavigationStatus.routing || NavigationStatus.guiding => l10n.navRouting,
        _ => l10n.navIdle,
      };
      return CockpitPanel(
        child: Center(
          child: Text(
            message,
            style: TftTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return CockpitPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Icon(
                maneuverIcon(maneuver.type),
                size: 34,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CockpitFormatters.distance(maneuver.distanceMeters),
                    key: const Key('cockpit.maneuverDistance'),
                    style: TftTextStyles.headline,
                  ),
                ),
              ),
            ],
          ),
          if (maneuver.roadName != null)
            Text(
              maneuver.roadName!,
              style: TftTextStyles.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (route != null)
            Text(
              '${CockpitFormatters.distance(route.remainingDistanceMeters)} · '
              '${l10n.navEta(CockpitFormatters.clock(route.etaFrom(now)))}',
              style: TftTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  static IconData maneuverIcon(ManeuverType type) => switch (type) {
    ManeuverType.straight => Icons.straight,
    ManeuverType.slightLeft => Icons.turn_slight_left,
    ManeuverType.left => Icons.turn_left,
    ManeuverType.sharpLeft => Icons.turn_sharp_left,
    ManeuverType.slightRight => Icons.turn_slight_right,
    ManeuverType.right => Icons.turn_right,
    ManeuverType.sharpRight => Icons.turn_sharp_right,
    ManeuverType.uTurn => Icons.u_turn_left,
    ManeuverType.roundabout => Icons.roundabout_right,
    ManeuverType.arrive => Icons.flag,
    ManeuverType.unknown => Icons.navigation,
  };
}
