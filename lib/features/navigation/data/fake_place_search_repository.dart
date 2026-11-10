import '../domain/route_destination.dart';
import '../domain/place_search_repository.dart';

/// API anahtarı yokken kullanılan demo arama sonuçları.
class FakePlaceSearchRepository implements PlaceSearchRepository {
  const FakePlaceSearchRepository();

  @override
  Future<List<RouteDestination>> search(
    String query, {
    required String sessionToken,
  }) async => [
    RouteDestination(
      title: 'Demo: $query',
      subtitle: 'Demo varış noktası',
      isSimulated: true,
    ),
  ];
}
