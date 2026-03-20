import 'dart:convert';

import 'package:http/http.dart' as http;

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
  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<GeocodingResult> searchLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw Exception('Location cannot be empty');
    }

    final tries = <String>[
      '$trimmed, Nigeria',
      trimmed,
    ];

    for (final candidate in tries) {
      final uri = Uri.parse(
        '$_baseUrl?q=${Uri.encodeQueryComponent(candidate)}&format=jsonv2&limit=5&countrycodes=ng&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'MixApp/1.0 (OpenStreetMap Nominatim Usage)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        continue;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) {
        continue;
      }

      final ngResults = decoded
          .map((e) => Map<String, dynamic>.from(e))
          .where((item) {
            final address = Map<String, dynamic>.from(item['address'] ?? {});
            final countryCode =
                (address['country_code'] ?? '').toString().toLowerCase();
            final displayName =
                (item['display_name'] ?? '').toString().toLowerCase();

            return countryCode == 'ng' || displayName.contains('nigeria');
          })
          .toList();

      final picked = ngResults.isNotEmpty ? ngResults.first : Map<String, dynamic>.from(decoded.first);
      final lat = double.tryParse((picked['lat'] ?? '').toString());
      final lon = double.tryParse((picked['lon'] ?? '').toString());

      if (lat == null || lon == null) {
        continue;
      }

      return GeocodingResult(
        displayName: (picked['display_name'] ?? trimmed).toString(),
        latitude: lat,
        longitude: lon,
      );
    }

    throw Exception(
      'Location not found in Nigeria. Please enter a clearer Nigerian address, area, town, or landmark.',
    );
  }
}
