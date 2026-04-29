import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fuel_model.dart';

class FuelService {
  static const String _baseUrl =
      'https://api.fuelthai.example.com'; // Replace with real API

  // Mock data — replace with real API call
  static List<FuelPrice> getMockPrices(String brandId) {
    final Map<String, List<FuelPrice>> data = {
      'ptt': [
        FuelPrice(
          type: 'gasohol91',
          typeLabel: 'แก๊สโซฮอล์ 91',
          price: 40.13,
          change: 0.20,
          category: 'เบนซิน',
        ),
        FuelPrice(
          type: 'gasohol95',
          typeLabel: 'แก๊สโซฮอล์ 95',
          price: 42.35,
          change: 0.00,
          category: 'เบนซิน',
        ),
        FuelPrice(
          type: 'e20',
          typeLabel: 'E20',
          price: 38.44,
          change: -0.10,
          category: 'เอทานอล',
        ),
        FuelPrice(
          type: 'e85',
          typeLabel: 'E85',
          price: 34.99,
          change: 0.00,
          category: 'เอทานอล',
        ),
        FuelPrice(
          type: 'diesel',
          typeLabel: 'ดีเซล B7',
          price: 33.59,
          change: 0.00,
          category: 'ดีเซล',
        ),
        FuelPrice(
          type: 'dieselb20',
          typeLabel: 'ดีเซล B20',
          price: 33.19,
          change: -0.20,
          category: 'ดีเซล',
        ),
        FuelPrice(
          type: 'premiumdiesel',
          typeLabel: 'ดีเซลพรีเมียม',
          price: 36.75,
          change: 0.10,
          category: 'ดีเซล',
        ),
      ],
      'shell': [
        FuelPrice(
          type: 'gasohol91',
          typeLabel: 'แก๊สโซฮอล์ 91',
          price: 40.35,
          change: 0.20,
          category: 'เบนซิน',
        ),
        FuelPrice(
          type: 'gasohol95',
          typeLabel: 'แก๊สโซฮอล์ 95',
          price: 42.55,
          change: 0.00,
          category: 'เบนซิน',
        ),
        FuelPrice(
          type: 'e20',
          typeLabel: 'E20',
          price: 38.64,
          change: -0.10,
          category: 'เอทานอล',
        ),
        FuelPrice(
          type: 'e85',
          typeLabel: 'E85',
          price: 35.19,
          change: 0.00,
          category: 'เอทานอล',
        ),
        FuelPrice(
          type: 'diesel',
          typeLabel: 'ดีเซล B7',
          price: 33.79,
          change: 0.00,
          category: 'ดีเซล',
        ),
        FuelPrice(
          type: 'premiumdiesel',
          typeLabel: 'ดีเซลพรีเมียม',
          price: 36.95,
          change: 0.10,
          category: 'ดีเซล',
        ),
      ],
      'bcp': [
        FuelPrice(
          type: 'gasohol91',
          typeLabel: 'แก๊สโซฮอล์ 91',
          price: 39.98,
          change: 0.20,
          category: 'เบนซิน',
        ),
        FuelPrice(
          type: 'gasohol95',
          typeLabel: 'แก๊สโซฮอล์ 95',
          price: 42.15,
          change: 0.00,
          category: 'เบนซิน',
        ),
        FuelPrice(
          type: 'e20',
          typeLabel: 'E20',
          price: 38.24,
          change: -0.10,
          category: 'เอทานอล',
        ),
        FuelPrice(
          type: 'e85',
          typeLabel: 'E85',
          price: 34.79,
          change: 0.00,
          category: 'เอทานอล',
        ),
        FuelPrice(
          type: 'diesel',
          typeLabel: 'ดีเซล B7',
          price: 33.39,
          change: 0.00,
          category: 'ดีเซล',
        ),
        FuelPrice(
          type: 'premiumdiesel',
          typeLabel: 'ดีเซลพรีเมียม',
          price: 36.55,
          change: 0.10,
          category: 'ดีเซล',
        ),
      ],
      'pt': [
        FuelPrice(
          type: 'gasohol91',
          typeLabel: 'แก๊สโซฮอล์ 91',
          price: 39.89,
          change: 0.20,
          category: 'เบนซิน',
        ),
        FuelPrice(
          type: 'gasohol95',
          typeLabel: 'แก๊สโซฮอล์ 95',
          price: 41.99,
          change: 0.00,
          category: 'เบนซิน',
        ),
        FuelPrice(
          type: 'e20',
          typeLabel: 'E20',
          price: 38.09,
          change: -0.10,
          category: 'เอทานอล',
        ),
        FuelPrice(
          type: 'diesel',
          typeLabel: 'ดีเซล B7',
          price: 33.29,
          change: 0.00,
          category: 'ดีเซล',
        ),
      ],
    };
    return data[brandId] ?? data['ptt']!;
  }

  static List<GasStation> getMockNearbyStations(double lat, double lng) {
    return [
      GasStation(
        id: '1',
        name: 'PTT สาขาเกาะสมุย',
        brand: 'ปตท.',
        brandId: 'ptt',
        address: 'ถ.เฉวง, เกาะสมุย',
        lat: lat + 0.005,
        lng: lng + 0.003,
        distance: 1.2,
        rating: 4.1,
        reviewCount: 128,
        hours: 'เปิด 24 ชั่วโมง',
        isOpen: true,
        prices: getMockPrices('ptt'),
      ),
      GasStation(
        id: '2',
        name: 'Shell บ่อผุด',
        brand: 'เชลล์',
        brandId: 'shell',
        address: 'ถ.รอบเกาะ, บ่อผุด',
        lat: lat - 0.008,
        lng: lng + 0.010,
        distance: 2.8,
        rating: 4.3,
        reviewCount: 95,
        hours: '06:00 - 22:00 น.',
        isOpen: true,
        prices: getMockPrices('shell'),
      ),
      GasStation(
        id: '3',
        name: 'บางจาก นาทอน',
        brand: 'บางจาก',
        brandId: 'bcp',
        address: 'ถ.นาทอน, เกาะสมุย',
        lat: lat + 0.012,
        lng: lng - 0.005,
        distance: 3.5,
        rating: 3.9,
        reviewCount: 67,
        hours: '06:00 - 23:00 น.',
        isOpen: true,
        prices: getMockPrices('bcp'),
      ),
      GasStation(
        id: '4',
        name: 'PT เกาะสมุย',
        brand: 'พีที',
        brandId: 'pt',
        address: 'ถ.เฉวง-บ่อผุด',
        lat: lat - 0.015,
        lng: lng - 0.008,
        distance: 4.1,
        rating: 4.0,
        reviewCount: 43,
        hours: 'เปิด 24 ชั่วโมง',
        isOpen: true,
        prices: getMockPrices('pt'),
      ),
      GasStation(
        id: '5',
        name: 'Shell ลิปะน้อย',
        brand: 'เชลล์',
        brandId: 'shell',
        address: 'ถ.ลิปะน้อย',
        lat: lat + 0.018,
        lng: lng + 0.012,
        distance: 5.2,
        rating: 4.2,
        reviewCount: 55,
        hours: '05:30 - 22:30 น.',
        isOpen: false,
        prices: getMockPrices('shell'),
      ),
    ];
  }

  // Real API call structure (uncomment and configure when API is available)
  Future<List<FuelPrice>> fetchPrices(String brandId) async {
    try {
      // final response = await http.get(
      //   Uri.parse('$_baseUrl/prices?brand=$brandId'),
      //   headers: {'Authorization': 'Bearer YOUR_API_KEY'},
      // ).timeout(const Duration(seconds: 10));
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body) as List;
      //   return data.map((e) => FuelPrice.fromJson(e)).toList();
      // }
      await Future.delayed(
        const Duration(milliseconds: 600),
      ); // Simulate network
      return getMockPrices(brandId);
    } catch (e) {
      return getMockPrices(brandId);
    }
  }

  Future<List<GasStation>> fetchNearbyStations(
    double lat,
    double lng, {
    double radius = 5.0,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      return getMockNearbyStations(lat, lng);
    } catch (e) {
      return getMockNearbyStations(lat, lng);
    }
  }
}
