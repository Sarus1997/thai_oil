import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fuel_model.dart';

class FuelService {
  static const String _apiUrl = 'https://api.chnwt.dev/thai-oil-api/latest';

  Map<String, List<FuelPrice>>? _cachedPrices;
  DateTime? _lastFetch;
  String _updateDate = '';

  String get updateDate => _updateDate;

  Future<Map<String, List<FuelPrice>>> fetchAllPrices() async {
    // Cache 30 นาที
    if (_cachedPrices != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 30) {
      return _cachedPrices!;
    }

    final response =
        await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode}');
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final responseData = json['response'] as Map<String, dynamic>;
    _updateDate = responseData['date'] as String? ?? '';
    final stations = responseData['stations'] as Map<String, dynamic>;

    final result = <String, List<FuelPrice>>{};

    stations.forEach((brandKey, brandData) {
      final fuels = brandData as Map<String, dynamic>;
      final prices = <FuelPrice>[];

      fuels.forEach((fuelKey, fuelData) {
        final data = fuelData as Map<String, dynamic>;
        prices.add(FuelPrice(
          type: fuelKey,
          typeLabel: data['name'] as String,
          price: double.tryParse(data['price'] as String) ?? 0.0,
          change: 0.0,
          category: _categorize(fuelKey, data['name'] as String),
        ));
      });

      result[brandKey] = prices;
    });

    _cachedPrices = result;
    _lastFetch = DateTime.now();
    return result;
  }

  Future<List<FuelPrice>> fetchPrices(String brandId) async {
    final all = await fetchAllPrices();
    return all[brandId] ?? [];
  }

  void invalidateCache() {
    _cachedPrices = null;
    _lastFetch = null;
  }

  static String _categorize(String key, String name) {
    if (key.contains('diesel') ||
        key.contains('disel') ||
        name.contains('ดีเซล')) return 'ดีเซล';
    if (key.contains('e85') || name.contains('E85')) return 'เอทานอล';
    if (key.contains('e20') || name.contains('E20')) return 'เอทานอล';
    if (key.contains('ngv') || name.contains('NGV')) return 'ก๊าซ';
    if (name.contains('เบนซิน')) return 'เบนซิน';
    return 'แก๊สโซฮอล์';
  }
}
