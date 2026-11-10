import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/injection.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_dimens.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../domain/bonded_device.dart';
import '../domain/stream_settings.dart';
import '../domain/tft_connection_state.dart';
import 'connection_cubit.dart';
import 'connection_labels.dart';

/// Bluetooth yönetimi: eşleşmiş cihazlar, bağlan/kes, yayın başlat/durdur,
/// durum, FPS ve hata mesajları.
class ConnectionPage extends StatelessWidget {
  const ConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => getIt<ConnectionCubit>()
        ..loadDevices()
        ..refreshLog()
        ..refreshBatteryStatus(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.homeConnectionTitle)),
        body: BlocBuilder<ConnectionCubit, ConnectionViewState>(
          builder: (context, state) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _StatusCard(state: state),
              if (state.receiverFrame != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _ReceiverCard(frame: state.receiverFrame!),
              ],
              const SizedBox(height: AppSpacing.lg),
              _DevicesCard(state: state),
              const SizedBox(height: AppSpacing.lg),
              _SettingsCard(state: state),
              const SizedBox(height: AppSpacing.lg),
              _PowerCard(state: state),
              const SizedBox(height: AppSpacing.lg),
              _LogCard(state: state),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.connectionUnverifiedNotice,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final ConnectionViewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ConnectionCubit>();
    final connection = state.connection;
    final phase = connection.phase;
    final stats = connection.stats;
    final error = connection.errorCode;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  phase.isLinkUp
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: phase == TftConnectionPhase.failed
                      ? AppColors.danger
                      : phase.isLinkUp
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    connectionPhaseLabel(l10n, phase),
                    key: const Key('connection.phase'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (connection.deviceName != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                connection.partNumber == null
                    ? connection.deviceName!
                    : '${connection.deviceName} · ${connection.partNumber} · '
                          '${connection.frameWidth}×${connection.frameHeight}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ] else if (state.lastDeviceName != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.connectionLastDevice(state.lastDeviceName!),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            if (error != null &&
                (phase == TftConnectionPhase.failed ||
                    phase == TftConnectionPhase.reconnecting)) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                connectionErrorText(l10n, error),
                key: const Key('connection.error'),
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            if (phase == TftConnectionPhase.streaming && stats != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.connectionStats(
                  stats.fps.toStringAsFixed(1),
                  stats.averageAckMs.toStringAsFixed(0),
                  stats.quality,
                  (stats.lastJpegBytes / 1024).toStringAsFixed(1),
                ),
                key: const Key('connection.stats'),
              ),
              Text(
                l10n.connectionFrameCounts(
                  stats.framesAcked,
                  stats.framesSent,
                  stats.ackTimeouts,
                ),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            if (phase.isActive) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (phase == TftConnectionPhase.ready)
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('connection.startStreaming'),
                        onPressed: cubit.startStreaming,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.connectionStartStreaming),
                      ),
                    ),
                  if (phase == TftConnectionPhase.streaming)
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('connection.stopStreaming'),
                        onPressed: cubit.stopStreaming,
                        icon: const Icon(Icons.stop),
                        label: Text(l10n.connectionStopStreaming),
                      ),
                    ),
                  if (phase.isLinkUp) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('connection.disconnect'),
                      onPressed: cubit.disconnect,
                      child: Text(l10n.connectionDisconnect),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReceiverCard extends StatelessWidget {
  const _ReceiverCard({required this.frame});

  final Uint8List frame;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.connectionReceiverTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AspectRatio(
                aspectRatio: TftSpec.aspectRatio,
                child: Image.memory(
                  frame,
                  key: const Key('connection.receiverImage'),
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: AppColors.elevated),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevicesCard extends StatelessWidget {
  const _DevicesCard({required this.state});

  final ConnectionViewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ConnectionCubit>();
    final busy = state.connection.phase.isActive;
    final devices = [...state.devices, if (kDebugMode) BondedDevice.fake];

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.connectionPairedDevices,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.connectionRefresh,
                  onPressed: state.isLoadingDevices ? null : cubit.loadDevices,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          if (state.devicesError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                connectionErrorText(l10n, state.devicesError!),
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          else if (!state.isLoadingDevices && state.devices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n.connectionNoDevices,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          for (final device in devices)
            ListTile(
              leading: Icon(
                device.isFake
                    ? Icons.science_outlined
                    : device.likelyCcu
                    ? Icons.two_wheeler
                    : Icons.bluetooth,
              ),
              title: Text(device.name),
              subtitle: Text(
                device.isFake
                    ? l10n.connectionFakeDeviceHint
                    : device.likelyCcu
                    ? '${device.address} · ${l10n.connectionLikelyCcu}'
                    : device.address,
              ),
              trailing: TextButton(
                key: Key('connection.connect.${device.address}'),
                onPressed: busy ? null : () => cubit.connect(device),
                child: Text(l10n.connectionConnect),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// Saha testi ayarları: bir sonraki bağlantıda geçerli olur.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.state});

  final ConnectionViewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ConnectionCubit>();
    final settings = state.settings;
    final locked = state.connection.phase.isActive;

    Widget choice<T>({
      required String label,
      required T value,
      required Map<T, String> options,
      required ValueChanged<T> onSelected,
    }) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final entry in options.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: entry.key == value,
                  onSelected: locked ? null : (_) => onSelected(entry.key),
                ),
            ],
          ),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.streamSettingsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              locked ? l10n.streamSettingsLocked : l10n.streamSettingsHint,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            choice<FrameSourceKind>(
              label: l10n.streamSettingsSource,
              value: settings.source,
              options: {
                FrameSourceKind.cockpit: l10n.streamSettingsSourceCockpit,
                FrameSourceKind.synthetic: l10n.streamSettingsSourceSynthetic,
              },
              onSelected: (v) =>
                  cubit.updateSettings(settings.copyWith(source: v)),
            ),
            if (settings.source == FrameSourceKind.cockpit)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.streamSettingsCockpitNotice,
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                  ),
                ),
              ),
            choice<int?>(
              label: l10n.streamSettingsResolution,
              value: settings.frameHeight,
              options: {
                null: l10n.streamSettingsAuto,
                234: '480×234',
                240: '480×240',
              },
              onSelected: (v) =>
                  cubit.updateSettings(settings.copyWith(frameHeight: () => v)),
            ),
            choice<int>(
              label: l10n.streamSettingsQuality,
              value: settings.quality,
              options: const {20: '20', 40: '40', 60: '60'},
              onSelected: (v) =>
                  cubit.updateSettings(settings.copyWith(quality: v)),
            ),
            choice<int>(
              label: l10n.streamSettingsFps,
              value: settings.maxFps,
              options: const {5: '5', 10: '10', 15: '15'},
              onSelected: (v) =>
                  cubit.updateSettings(settings.copyWith(maxFps: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.navStatusActive,
              onChanged: locked
                  ? null
                  : (v) => cubit.updateSettings(
                      settings.copyWith(navStatusActive: v),
                    ),
              title: Text(l10n.streamSettingsNavStatus),
              subtitle: Text(l10n.streamSettingsNavStatusHint),
            ),
          ],
        ),
      ),
    );
  }
}

class _PowerCard extends StatelessWidget {
  const _PowerCard({required this.state});

  final ConnectionViewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ConnectionCubit>();
    final unrestricted = state.batteryUnrestricted;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(
          unrestricted == true
              ? Icons.battery_charging_full
              : Icons.battery_alert_outlined,
          color: unrestricted == true ? AppColors.accent : AppColors.warning,
        ),
        title: Text(l10n.powerTitle),
        subtitle: Text(
          unrestricted == true ? l10n.powerUnrestricted : l10n.powerRestricted,
        ),
        trailing: const Icon(Icons.open_in_new),
        onTap: () async {
          await cubit.openBatterySettings();
          await cubit.refreshBatteryStatus();
        },
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.state});

  final ConnectionViewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lines = state.logLines;
    final shown = lines.length > 80 ? lines.sublist(lines.length - 80) : lines;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.logTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  key: const Key('log.copy'),
                  onPressed: lines.isEmpty
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(
                            ClipboardData(text: lines.join('\n')),
                          );
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.logCopied)),
                          );
                        },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l10n.logCopy),
                ),
              ],
            ),
            if (state.logPath != null)
              Text(
                l10n.logSavedTo(state.logPath!),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  shown.isEmpty ? l10n.logEmpty : shown.join('\n'),
                  key: const Key('log.text'),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
