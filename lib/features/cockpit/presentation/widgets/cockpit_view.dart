import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_dimens.dart';
import '../cockpit_state.dart';
import 'cockpit_top_bar.dart';
import 'media_card.dart';
import 'navigation_card.dart';
import 'notification_card.dart';
import 'synthetic_map_panel.dart';

/// TurkMax'in tek cockpit ekranı. Tam olarak 480×234 mantıksal pikselde
/// çizilir; farklı boyutlarda göstermek için dışarıdan ölçeklenir
/// (ör. `FittedBox`).
class CockpitView extends StatelessWidget {
  const CockpitView({super.key, required this.state, this.map});

  final CockpitState state;

  /// Sol paneldeki harita; verilmezse sentetik harita çizilir.
  final Widget? map;

  @override
  Widget build(BuildContext context) {
    const gap = AppSpacing.xs;
    final mapFlex = (TftSpec.mapFraction * 100).round();
    return SizedBox(
      width: TftSpec.width,
      height: TftSpec.height,
      child: MediaQuery.withNoTextScaling(
        child: ColoredBox(
          color: AppColors.background,
          child: Column(
            children: [
              SizedBox(
                height: TftSpec.topBarHeight,
                child: CockpitTopBar(state: state),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(gap, 0, gap, gap),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: mapFlex,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: map ?? const SyntheticMapPanel(),
                        ),
                      ),
                      const SizedBox(width: gap),
                      Expanded(
                        flex: 100 - mapFlex,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 42,
                              child: NavigationCard(
                                navigation: state.navigation,
                                now: state.now,
                              ),
                            ),
                            const SizedBox(height: gap),
                            Expanded(
                              flex: 26,
                              child: NotificationCard(
                                notification: state.notification,
                              ),
                            ),
                            const SizedBox(height: gap),
                            Expanded(
                              flex: 32,
                              child: MediaCard(media: state.media),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
