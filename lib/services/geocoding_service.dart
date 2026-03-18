import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  Future<LatLng?> searchLocation(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(q)}&limit=1',
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'MaamahsMix/1.0 (com.maamahsmix.app)',
      },
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as List<dynamic>;
    if (data.isEmpty) return null;

    final item = data.first as Map<String, dynamic>;
    final lat = double.tryParse((item['lat'] ?? '').toString());
    final lon = double.tryParse((item['lon'] ?? '').toString());

    if (lat == null || lon == null) return null;

    return LatLng(lat, lon);
  }
}
