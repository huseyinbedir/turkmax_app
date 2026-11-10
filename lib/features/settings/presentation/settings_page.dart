import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/injection.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import 'settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => getIt<SettingsCubit>(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: ListView(
          children: [
            BlocBuilder<SettingsCubit, bool>(
              builder: (context, autoReconnect) => SwitchListTile(
                value: autoReconnect,
                onChanged: context.read<SettingsCubit>().setAutoReconnect,
                title: Text(l10n.settingsAutoReconnect),
                subtitle: Text(l10n.settingsAutoReconnectHint),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsAbout),
              subtitle: Text(l10n.settingsAboutBody),
            ),
          ],
        ),
      ),
    );
  }
}
