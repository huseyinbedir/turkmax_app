import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_dimens.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../media/domain/media_state.dart';
import 'cockpit_panel.dart';

/// Sağ alt: çalan medya.
class MediaCard extends StatelessWidget {
  const MediaCard({super.key, required this.media});

  final MediaState? media;

  @override
  Widget build(BuildContext context) {
    final item = media;
    if (item == null) {
      return CockpitPanel(
        child: Center(
          child: Text(
            AppLocalizations.of(context).mediaEmpty,
            style: TftTextStyles.caption,
          ),
        ),
      );
    }
    return CockpitPanel(
      child: Row(
        children: [
          Icon(
            item.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            size: 24,
            color: AppColors.primary,
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
                if (item.artist != null)
                  Text(
                    item.artist!,
                    style: TftTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
