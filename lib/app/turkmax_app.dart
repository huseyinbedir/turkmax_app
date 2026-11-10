import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design/app_theme.dart';
import '../core/l10n/generated/app_localizations.dart';
import 'router/app_router.dart';

class TurkMaxApp extends StatefulWidget {
  const TurkMaxApp({super.key});

  @override
  State<TurkMaxApp> createState() => _TurkMaxAppState();
}

class _TurkMaxAppState extends State<TurkMaxApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Birincil dil Türkçe; cihaz dili İngilizce ise İngilizce kullanılır.
      localeResolutionCallback: (locale, supported) => supported.firstWhere(
        (s) => s.languageCode == locale?.languageCode,
        orElse: () => const Locale('tr'),
      ),
    );
  }
}
