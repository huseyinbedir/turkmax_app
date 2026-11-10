import 'route_destination.dart';

class PlaceSearchException implements Exception {
  const PlaceSearchException(this.message);

  final String message;

  @override
  String toString() => 'PlaceSearchException: $message';
}

/// Adres/işletme adı araması.
abstract interface class PlaceSearchRepository {
  /// [sessionToken] aynı arama oturumundaki istekleri gruplar.
  Future<List<RouteDestination>> search(
    String query, {
    required String sessionToken,
  });
}
