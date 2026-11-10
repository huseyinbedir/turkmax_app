import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Gerçek harita yapılandırılmış ama henüz gösterilemiyorken (oturum hazır
/// değil) kullanılan nötr yer tutucu. Sahte rota çizmez.
class MapUnavailablePanel extends StatelessWidget {
  const MapUnavailablePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 28,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).mapUnavailable,
              style: TftTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
