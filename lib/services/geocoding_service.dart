import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mix/models/place_suggestion_model.dart';

class GeocodingResult {
  final String displayName;
  final double latitude;
  final double longitude;

  const GeocodingResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class GeocodingService {
  static const _searchBaseUrl = 'https://nominatim.openstreetmap.org/search';
  static const _reverseBaseUrl = 'https://nominatim.openstreetmap.org/reverse';

  Map<String, String> get _headers => const {
        'User-Agent': 'MixApp/1.0 (OpenStreetMap Nominatim Usage)',
        'Accept': 'application/json',
      };

  Future<List<PlaceSuggestionModel>> searchSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final tries = <String>[
      '$trimmed, Nigeria',
      trimmed,
    ];

    for (final candidate in tries) {
      final uri = Uri.parse(
        '$_searchBaseUrl?q=${Uri.encodeQueryComponent(candidate)}&format=jsonv2&limit=6&countrycodes=ng&addressdetails=1',
      );

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode != 200) {
        continue;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) {
        continue;
      }

      final suggestions = decoded
          .map((e) => Map<String, dynamic>.from(e))
          .where((item) {
            final address = Map<String, dynamic>.from(item['address'] ?? {});
            final countryCode =
                (address['country_code'] ?? '').toString().toLowerCase();
            final displayName =
                (item['display_name'] ?? '').toString().toLowerCase();

            return countryCode == 'ng' || displayName.contains('nigeria');
          })
          .map((e) => PlaceSuggestionModel.fromMap(e))
          .where((e) => e.isValid)
          .toList();

      if (suggestions.isNotEmpty) {
        return suggestions;
      }
    }

    return [];
  }

  Future<GeocodingResult> searchLocation(String query) async {
    final suggestions = await searchSuggestions(query);

    if (suggestions.isEmpty) {
      throw Exception(
        'Location not found in Nigeria. Please enter a clearer Nigerian address, area, town, or landmark.',
      );
    }

    final best = suggestions.first;

    return GeocodingResult(
      displayName: best.displayName,
      latitude: best.latitude,
      longitude: best.longitude,
    );
  }

  Future<GeocodingResult> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      '$_reverseBaseUrl?lat=$latitude&lon=$longitude&format=jsonv2&addressdetails=1',
    );

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to resolve current location');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final displayName = (decoded['display_name'] ?? '').toString().trim();

    if (displayName.isEmpty) {
      throw Exception('Could not identify current location');
    }

    return GeocodingResult(
      displayName: displayName,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
