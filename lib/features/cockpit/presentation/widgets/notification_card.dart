import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_dimens.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../notifications/domain/notification_summary.dart';
import 'cockpit_panel.dart';

/// Sağ orta: kısa bildirim özeti.
class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.notification});

  final NotificationSummary? notification;

  @override
  Widget build(BuildContext context) {
    final item = notification;
    if (item == null) {
      return CockpitPanel(
        child: Center(
          child: Text(
            AppLocalizations.of(context).notificationsEmpty,
            style: TftTextStyles.caption,
          ),
        ),
      );
    }
    return CockpitPanel(
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none,
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TftTextStyles.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.preview != null)
                  Text(
                    item.preview!,
                    style: TftTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (item.unreadCount > 1) ...[
            const SizedBox(width: AppSpacing.xs),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                child: Text(
                  item.unreadCount > 9 ? '9+' : '${item.unreadCount}',
                  style: TftTextStyles.label.copyWith(
                    color: AppColors.background,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
