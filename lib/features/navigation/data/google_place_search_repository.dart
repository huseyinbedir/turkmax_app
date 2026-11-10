import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/platform/maps_config.dart';
import '../domain/route_destination.dart';
import '../domain/place_search_repository.dart';

/// Places API (New) Autocomplete — REST.
///
/// Android uygulamasıyla kısıtlı anahtarın kabul edilmesi için paket adı ve
/// imza özeti başlık olarak gönderilir.
class GooglePlaceSearchRepository implements PlaceSearchRepository {
  GooglePlaceSearchRepository(this._config, this._client);

  final MapsConfig _config;
  final http.Client _client;

  static final _endpoint = Uri.parse(
    'https://places.googleapis.com/v1/places:autocomplete',
  );

  @override
  Future<List<RouteDestination>> search(
    String query, {
    required String sessionToken,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _config.apiKey ?? '',
              if (_config.packageName != null)
                'X-Android-Package': _config.packageName!,
              if (_config.certSha1 != null) 'X-Android-Cert': _config.certSha1!,
            },
            body: jsonEncode({
              'input': query,
              'sessionToken': sessionToken,
              'languageCode': 'tr',
              'regionCode': 'TR',
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException catch (e) {
      throw PlaceSearchException('network: ${e.message}');
    } on http.ClientException catch (e) {
      throw PlaceSearchException('network: ${e.message}');
    } on Exception catch (e) {
      throw PlaceSearchException('request failed: $e');
    }

    if (response.statusCode != 200) {
      throw PlaceSearchException(
        'HTTP ${response.statusCode}: ${errorMessage(response.body)}',
      );
    }
    return parse(utf8.decode(response.bodyBytes));
  }

  /// Autocomplete yanıtından yer tahminlerini çıkarır (saf fonksiyon).
  static List<RouteDestination> parse(String body) {
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) return const [];
    final suggestions = json['suggestions'];
    if (suggestions is! List) return const [];

    final results = <RouteDestination>[];
    for (final suggestion in suggestions) {
      if (suggestion is! Map) continue;
      final prediction = suggestion['placePrediction'];
      if (prediction is! Map) continue;
      final placeId = prediction['placeId'];
      if (placeId is! String || placeId.isEmpty) continue;

      final structured = prediction['structuredFormat'];
      final title =
          _text(structured is Map ? structured['mainText'] : null) ??
          _text(prediction['text']);
      if (title == null) continue;
      results.add(
        RouteDestination(
          title: title,
          subtitle: _text(
            structured is Map ? structured['secondaryText'] : null,
          ),
          placeId: placeId,
        ),
      );
    }
    return results;
  }

  static String errorMessage(String body) {
    try {
      final json = jsonDecode(body);
      final error = json is Map ? json['error'] : null;
      final message = error is Map ? error['message'] : null;
      if (message is String) return message;
    } on FormatException {
      // Gövde JSON değil.
    }
    return 'unknown error';
  }

  static String? _text(Object? node) {
    final text = node is Map ? node['text'] : null;
    return text is String && text.isNotEmpty ? text : null;
  }
}
