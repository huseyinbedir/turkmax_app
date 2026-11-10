import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/platform/maps_config.dart';
import '../../features/navigation/data/fake_navigation_provider.dart';
import '../../features/navigation/data/fake_place_search_repository.dart';
import '../../features/navigation/data/google_navigation_provider.dart';
import '../../features/navigation/data/google_place_search_repository.dart';
import '../../features/navigation/domain/navigation_provider.dart';
import '../../features/navigation/domain/place_search_repository.dart';
import 'environments.dart';

@module
abstract class PlatformModule {
  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();

  @preResolve
  @Environment(kEnvDevice)
  Future<MapsConfig> get mapsConfig => MapsConfig.load();

  @Environment(kEnvFake)
  MapsConfig get fakeMapsConfig => const MapsConfig.none();

  /// API anahtarı varsa gerçek Google navigasyonu, yoksa çevrimdışı demo.
  @lazySingleton
  NavigationProvider navigationProvider(MapsConfig config) =>
      config.hasApiKey ? GoogleNavigationProvider() : FakeNavigationProvider();

  @lazySingleton
  PlaceSearchRepository placeSearchRepository(MapsConfig config) =>
      config.hasApiKey
      ? GooglePlaceSearchRepository(config, http.Client())
      : const FakePlaceSearchRepository();
}
