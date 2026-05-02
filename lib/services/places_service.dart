import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/fuel_model.dart';
import '../services/fuel_service.dart';

/// ค้นหาปั้มน้ำมันด้วย Nominatim (OpenStreetMap) + Overpass API
/// ฟรี 100% ไม่ต้องใช้ API Key
class PlacesService {
  // Nominatim — geocoding / text search
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';
  // Overpass API — ค้นหา POI บนแผนที่
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  static const Map<String, String> _brandNameMap = {
    'ptt': 'ptt',
    'ปตท': 'ptt',
    'p.t.t': 'ptt',
    'shell': 'shell',
    'เชลล์': 'shell',
    'bangchak': 'bcp',
    'บางจาก': 'bcp',
    'bcp': 'bcp',
    'pt max': 'pt',
    'pt ': 'pt',
    'พีที': 'pt',
    'caltex': 'caltex',
    'คาลเท็กซ์': 'caltex',
    'susco': 'susco',
    'ซัสโก้': 'susco',
    'irpc': 'irpc',
    'pure': 'pure',
  };

  static const Map<String, String> _brandDisplayNames = {
    'ptt': 'ปตท.',
    'shell': 'เชลล์',
    'bcp': 'บางจาก',
    'pt': 'พีที',
    'caltex': 'คาลเท็กซ์',
    'susco': 'ซัสโก้',
    'irpc': 'ไออาร์พีซี',
    'pure': 'เพียว',
  };

  final FuelService fuelService;
  PlacesService(this.fuelService);

  /// ค้นหาปั้มน้ำมันในรัศมีด้วย Overpass API
  Future<List<GasStation>> searchNearby(
    double lat,
    double lng, {
    double radiusMeters = 3000,
  }) async {
    // Overpass QL query — หา amenity=fuel ในรัศมี
    final query = '''
[out:json][timeout:25];
(
  node["amenity"="fuel"](around:${radiusMeters.toInt()},$lat,$lng);
  way["amenity"="fuel"](around:${radiusMeters.toInt()},$lat,$lng);
);
out body center;
''';

    final response = await http.post(
      Uri.parse(_overpassUrl),
      body: query,
      headers: {'Content-Type': 'text/plain'},
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200)
      throw Exception('Overpass API error: ${response.statusCode}');

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final elements = (json['elements'] as List<dynamic>?) ?? [];
    final allPrices = await fuelService.fetchAllPrices();

    return _mapElements(elements, lat, lng, allPrices);
  }

  /// ค้นหาด้วยชื่อพื้นที่ + ปั้ม — Nominatim geocode แล้ว Overpass ค้นรอบนั้น
  Future<List<GasStation>> searchByText(
    String query,
    double lat,
    double lng,
  ) async {
    // 1. Geocode ข้อความด้วย Nominatim
    double searchLat = lat;
    double searchLng = lng;

    if (query.trim().isNotEmpty) {
      try {
        final geoUri = Uri.parse(
          '$_nominatimUrl/search'
          '?q=${Uri.encodeComponent(query)}'
          '&format=json&limit=1&countrycodes=th',
        );
        final geoResp = await http.get(geoUri, headers: {
          'User-Agent': 'FuelThai/1.0'
        }).timeout(const Duration(seconds: 8));

        if (geoResp.statusCode == 200) {
          final geoData =
              jsonDecode(utf8.decode(geoResp.bodyBytes)) as List<dynamic>;
          if (geoData.isNotEmpty) {
            final first = geoData.first as Map<String, dynamic>;
            searchLat = double.tryParse(first['lat'] as String) ?? lat;
            searchLng = double.tryParse(first['lon'] as String) ?? lng;
          }
        }
      } catch (_) {
        // geocode ไม่ได้ — ใช้ GPS ปัจจุบัน
      }
    }

    // 2. ค้นหาปั้มรอบตำแหน่งที่ geocode ได้
    return searchNearby(searchLat, searchLng, radiusMeters: 5000);
  }

  List<GasStation> _mapElements(
    List<dynamic> elements,
    double userLat,
    double userLng,
    Map<String, List<FuelPrice>> allPrices,
  ) {
    final stations = <GasStation>[];

    for (final el in elements) {
      final e = el as Map<String, dynamic>;
      final tags = (e['tags'] as Map<String, dynamic>?) ?? {};

      // ชื่อปั้ม
      final name = (tags['name'] ??
          tags['name:th'] ??
          tags['brand'] ??
          'ปั้มน้ำมัน') as String;
      final brandId = _detectBrand(name, tags['brand'] as String? ?? '');

      // พิกัด — node ใช้ lat/lon โดยตรง, way ใช้ center
      double eLat, eLng;
      if (e.containsKey('lat')) {
        eLat = (e['lat'] as num).toDouble();
        eLng = (e['lon'] as num).toDouble();
      } else {
        final center = e['center'] as Map<String, dynamic>?;
        if (center == null) continue;
        eLat = (center['lat'] as num).toDouble();
        eLng = (center['lon'] as num).toDouble();
      }

      final dist = _haversineKm(userLat, userLng, eLat, eLng);

      // ที่อยู่จาก tags
      final addr = _buildAddress(tags);

      // เวลาเปิด-ปิด
      final openingHours = tags['opening_hours'] as String?;
      final isOpen24 = openingHours == '24/7';

      stations.add(GasStation(
        id: '${e['type']}_${e['id']}',
        name: name,
        brand: _brandDisplayNames[brandId] ?? brandId,
        brandId: brandId,
        address: addr,
        lat: eLat,
        lng: eLng,
        distance: dist,
        rating: 0.0,
        reviewCount: 0,
        hours: isOpen24 ? 'เปิด 24 ชั่วโมง' : (openingHours ?? 'ไม่ระบุ'),
        isOpen: true,
        prices: allPrices[brandId] ?? [],
      ));
    }

    // เรียงตามระยะทาง + กรองซ้ำ
    stations.sort((a, b) => a.distance.compareTo(b.distance));
    return stations;
  }

  static String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    final street = tags['addr:street'] as String?;
    final city =
        tags['addr:city'] ?? tags['addr:suburb'] ?? tags['addr:district'];
    final postcode = tags['addr:postcode'] as String?;
    if (street != null) parts.add(street);
    if (city != null) parts.add(city as String);
    if (postcode != null) parts.add(postcode);
    return parts.join(', ');
  }

  static String _detectBrand(String name, String brand) {
    final combined = '$name $brand'.toLowerCase();
    for (final entry in _brandNameMap.entries) {
      if (combined.contains(entry.key.toLowerCase())) return entry.value;
    }
    return 'ptt';
  }

  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return r * 2 * math.asin(math.sqrt(a.toDouble()));
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
