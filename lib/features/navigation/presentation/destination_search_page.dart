import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/injection.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_dimens.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import 'destination_search_cubit.dart';

/// Varış noktası araması. Yalnızca telefonda gösterilir; TFT'de klavye yoktur.
/// Seçilen `RouteDestination` ile geri döner.
class DestinationSearchPage extends StatelessWidget {
  const DestinationSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => getIt<DestinationSearchCubit>(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: TextField(
              key: const Key('search.field'),
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                border: InputBorder.none,
              ),
              onChanged: context.read<DestinationSearchCubit>().queryChanged,
            ),
          ),
          body: BlocBuilder<DestinationSearchCubit, DestinationSearchState>(
            builder: (context, state) => switch (state.status) {
              SearchStatus.idle => _Message(l10n.searchPrompt),
              SearchStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              SearchStatus.empty => _Message(l10n.searchEmpty),
              SearchStatus.failure => _Message(
                l10n.searchFailed,
                detail: kDebugMode ? state.errorDetail : null,
                isError: true,
              ),
              SearchStatus.results => ListView.separated(
                itemCount: state.results.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final place = state.results[index];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(place.title),
                    subtitle: place.subtitle == null
                        ? null
                        : Text(place.subtitle!),
                    onTap: () => context.pop(place),
                  );
                },
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.detail, this.isError = false});

  final String text;
  final String? detail;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError ? AppColors.danger : AppColors.textSecondary,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
