import 'package:go_router/go_router.dart';

import '../../features/cockpit/presentation/home_page.dart';
import '../../features/connection/presentation/connection_page.dart';
import '../../features/diagnostics/presentation/diagnostics_page.dart';
import '../../features/navigation/presentation/destination_search_page.dart';
import '../../features/settings/presentation/settings_page.dart';

/// Yalnızca gerekli telefon sayfaları. Cockpit tek ekrandır; alternatif mod
/// veya dashboard rotası eklenmez.
abstract final class AppRoutes {
  static const String home = '/';
  static const String diagnostics = '/diagnostics';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String connection = '/connection';
}

GoRouter createAppRouter() => GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.diagnostics,
      builder: (context, state) => const DiagnosticsPage(),
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) => const DestinationSearchPage(),
    ),
    GoRoute(
      path: AppRoutes.connection,
      builder: (context, state) => const ConnectionPage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
