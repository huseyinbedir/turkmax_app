import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/injection.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_dimens.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import 'diagnostics_cubit.dart';
import 'diagnostics_state.dart';

class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => getIt<DiagnosticsCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.diagnosticsTitle)),
        body: BlocBuilder<DiagnosticsCubit, DiagnosticsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final info = state.platformInfo;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.memory),
                        title: Text(l10n.diagnosticsNativeBridge),
                        subtitle: Text(
                          state.isNativeBridgeAvailable
                              ? l10n.diagnosticsNativeBridgeOk
                              : l10n.diagnosticsNativeBridgeUnavailable,
                        ),
                      ),
                      if (info != null)
                        ListTile(
                          leading: const Icon(Icons.phone_android),
                          title: Text(l10n.diagnosticsPlatform),
                          subtitle: Text(
                            '${info.deviceModel} · Android ${info.osVersion} '
                            '(API ${info.sdkInt})',
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _FrameTest(state: state),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.diagnosticsHardwareNotice,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FrameTest extends StatelessWidget {
  const _FrameTest({required this.state});

  final DiagnosticsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final frame = state.frame;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.diagnosticsFrameTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        if (frame != null && state.frameStatus == FrameTestStatus.success) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: AspectRatio(
              aspectRatio: frame.width / frame.height,
              child: Image.memory(
                frame.jpegBytes,
                fit: BoxFit.fill,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: AppColors.elevated,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.diagnosticsFrameInfo(
              frame.width,
              frame.height,
              frame.jpegBytes.length,
              (frame.encodeDuration.inMicroseconds / 1000).toStringAsFixed(1),
            ),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.frameStatus == FrameTestStatus.failure) ...[
          Text(
            l10n.diagnosticsFrameError,
            style: const TextStyle(color: AppColors.danger),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        FilledButton.icon(
          onPressed: state.frameStatus == FrameTestStatus.capturing
              ? null
              : context.read<DiagnosticsCubit>().captureFrame,
          icon: const Icon(Icons.image_outlined),
          label: Text(l10n.diagnosticsFrameCapture),
        ),
      ],
    );
  }
}
