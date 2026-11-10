import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/injection.dart';
import '../../../app/router/app_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_dimens.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/platform/maps_config.dart';
import '../../connection/presentation/connection_labels.dart';
import '../../navigation/domain/route_destination.dart';
import '../../navigation/domain/navigation_state.dart';
import '../../navigation/presentation/google_navigation_map.dart';
import '../../navigation/presentation/navigation_cubit.dart';
import '../../connection/domain/tft_connection_state.dart';
import '../../streaming/data/cockpit_frame_publisher.dart';
import 'cockpit_cubit.dart';
import 'cockpit_formatters.dart';
import 'cockpit_state.dart';
import 'widgets/cockpit_view.dart';
import 'widgets/map_unavailable_panel.dart';

/// Telefon ana sayfası: TFT önizlemesi, navigasyon komutları ve bağlantı
/// durumu.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CockpitCubit>()..start()),
        BlocProvider(create: (_) => getIt<NavigationCubit>()..prepare()),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // İlk içerik ve dil değişikliği; sonraki değişiklikler dinleyiciden gelir.
    _publish(context.read<CockpitCubit>().state);
  }

  /// TFT karesi native tarafta çizilir; içerik her değişiklikte bildirilir.
  void _publish(CockpitState state) => getIt<CockpitFramePublisher>().publish(
    state,
    AppLocalizations.of(context),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasRealMap = getIt<MapsConfig>().hasApiKey;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.homeDiagnostics,
            icon: const Icon(Icons.monitor_heart_outlined),
            onPressed: () => context.push(AppRoutes.diagnostics),
          ),
          IconButton(
            tooltip: l10n.homeSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<CockpitCubit, CockpitState>(
          listener: (context, state) => _publish(state),
          builder: (context, state) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                l10n.homeCockpitPreview,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: CockpitView(
                      state: state,
                      map: !hasRealMap
                          ? null
                          : state.navigation.isReady
                          ? const GoogleNavigationMap()
                          : const MapUnavailablePanel(),
                    ),
                  ),
                ),
              ),
              if (state.hasSimulatedContent) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.navigation.isSimulated
                      ? l10n.demoDataNotice
                      : l10n.demoDataNoticePartial,
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _NavigationPanel(canSimulate: hasRealMap && kDebugMode),
              const SizedBox(height: AppSpacing.lg),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: const Key('home.connection'),
                  leading: Icon(
                    state.connection.phase.isLinkUp
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                  ),
                  title: Text(l10n.homeConnectionTitle),
                  subtitle: Text(
                    [
                      connectionPhaseLabel(l10n, state.connection.phase),
                      ?state.connection.deviceName,
                      if (state.connection.stats case final stats?
                          when state.connection.phase ==
                              TftConnectionPhase.streaming)
                        '${stats.fps.toStringAsFixed(1)} FPS',
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.connection),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hedef seçme, rehberliği bitirme ve navigasyon hatalarını gösterme.
class _NavigationPanel extends StatefulWidget {
  const _NavigationPanel({required this.canSimulate});

  /// Geliştirici derlemesinde konum simülasyonu seçeneği gösterilsin mi.
  final bool canSimulate;

  @override
  State<_NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<_NavigationPanel> {
  bool _simulate = false;

  Future<void> _pickDestination() async {
    final cubit = context.read<NavigationCubit>();
    final destination = await context.push<RouteDestination>(AppRoutes.search);
    if (destination == null) return;
    await cubit.start(destination, simulate: _simulate);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<NavigationCubit>();

    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        final route = state.route;
        final error = state.error;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.navCardTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (error != null) ...[
                  Text(
                    _errorText(l10n, error),
                    key: const Key('nav.error'),
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  if (kDebugMode && state.errorDetail != null)
                    Text(
                      state.errorDetail!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (!state.isReady) ...[
                  if (error == null)
                    Text(
                      l10n.navPreparing,
                      style: const TextStyle(color: AppColors.textSecondary),
                    )
                  else
                    OutlinedButton(
                      onPressed: cubit.prepare,
                      child: Text(l10n.navRetry),
                    ),
                ] else if (state.isActive) ...[
                  Text(
                    route == null
                        ? l10n.navRouting
                        : l10n.navTo(route.destinationName),
                  ),
                  if (route != null)
                    Text(
                      l10n.navRemaining(
                        CockpitFormatters.distance(
                          route.remainingDistanceMeters,
                        ),
                        CockpitFormatters.duration(route.remainingDuration),
                      ),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  if (state.isSimulated && widget.canSimulate)
                    Text(
                      l10n.navSimulatedNotice,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    key: const Key('nav.stop'),
                    onPressed: cubit.stop,
                    icon: const Icon(Icons.close),
                    label: Text(l10n.navStop),
                  ),
                ] else ...[
                  if (state.status == NavigationStatus.arrived) ...[
                    Text(l10n.navArrived),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  FilledButton.icon(
                    key: const Key('nav.whereTo'),
                    onPressed: _pickDestination,
                    icon: const Icon(Icons.search),
                    label: Text(l10n.navWhereTo),
                  ),
                  if (widget.canSimulate)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: _simulate,
                      onChanged: (value) => setState(() => _simulate = value),
                      title: Text(l10n.navSimulate),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String _errorText(AppLocalizations l10n, NavigationError error) =>
      switch (error) {
        NavigationError.termsNotAccepted => l10n.navErrorTerms,
        NavigationError.locationPermissionDenied => l10n.navErrorPermission,
        NavigationError.locationUnavailable => l10n.navErrorLocation,
        NavigationError.network => l10n.navErrorNetwork,
        NavigationError.routeNotFound => l10n.navErrorNoRoute,
        NavigationError.apiKeyRejected => l10n.navErrorApiKey,
        NavigationError.quotaExceeded => l10n.navErrorQuota,
        NavigationError.unknown => l10n.navErrorUnknown,
      };
}
