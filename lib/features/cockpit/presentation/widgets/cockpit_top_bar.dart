import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_dimens.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../connection/domain/tft_connection_state.dart';
import '../cockpit_formatters.dart';
import '../cockpit_state.dart';

class CockpitTopBar extends StatelessWidget {
  const CockpitTopBar({super.key, required this.state});

  final CockpitState state;

  @override
  Widget build(BuildContext context) {
    final device = state.device;
    final battery = device.batteryPercent;
    final batteryColor = device.isBatteryLow
        ? AppColors.danger
        : AppColors.text;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            CockpitFormatters.clock(state.now),
            key: const Key('cockpit.clock'),
            style: TftTextStyles.topBar,
          ),
          if (state.hasSimulatedContent) ...[
            const SizedBox(width: AppSpacing.sm),
            const _DemoBadge(),
          ],
          const Spacer(),
          Icon(
            state.connection.phase.isLinkUp
                ? Icons.bluetooth_connected
                : Icons.bluetooth_disabled,
            key: const Key('cockpit.bluetooth'),
            size: 14,
            color: switch (state.connection.phase) {
              TftConnectionPhase.ready ||
              TftConnectionPhase.streaming => AppColors.accent,
              TftConnectionPhase.failed => AppColors.danger,
              _ => AppColors.textSecondary,
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          if (device.isCharging)
            const Icon(
              Icons.bolt,
              key: Key('cockpit.charging'),
              size: 13,
              color: AppColors.accent,
            ),
          Icon(
            device.isBatteryLow ? Icons.battery_alert : Icons.battery_std,
            size: 14,
            color: batteryColor,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            battery == null ? '--' : '%$battery',
            key: const Key('cockpit.battery'),
            style: TftTextStyles.topBar.copyWith(color: batteryColor),
          ),
        ],
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.warning),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 1,
        ),
        child: Text(
          AppLocalizations.of(context).demoBadge,
          key: const Key('cockpit.demoBadge'),
          style: TftTextStyles.label.copyWith(color: AppColors.warning),
        ),
      ),
    );
  }
}
