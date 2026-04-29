import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/fuel_model.dart';
import '../services/fuel_service.dart';

class AppProvider extends ChangeNotifier {
  final FuelService _service = FuelService();

  String _selectedBrandId = 'ptt';
  List<FuelPrice> _prices = [];
  List<GasStation> _nearbyStations = [];
  GasStation? _selectedStation;
  Position? _currentPosition;
  bool _isLoadingPrices = false;
  bool _isLoadingStations = false;
  String? _locationName;
  DateTime? _lastUpdated;

  String get selectedBrandId => _selectedBrandId;
  List<FuelPrice> get prices => _prices;
  List<GasStation> get nearbyStations => _nearbyStations;
  GasStation? get selectedStation => _selectedStation;
  Position? get currentPosition => _currentPosition;
  bool get isLoadingPrices => _isLoadingPrices;
  bool get isLoadingStations => _isLoadingStations;
  String get locationName => _locationName ?? 'กำลังระบุตำแหน่ง...';
  DateTime? get lastUpdated => _lastUpdated;

  FuelBrand get selectedBrand =>
      FuelBrand.all.firstWhere((b) => b.id == _selectedBrandId);

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadPrices();
    await _getCurrentLocation();
  }

  Future<void> selectBrand(String brandId) async {
    _selectedBrandId = brandId;
    notifyListeners();
    await _loadPrices();
  }

  Future<void> _loadPrices() async {
    _isLoadingPrices = true;
    notifyListeners();
    _prices = await _service.fetchPrices(_selectedBrandId);
    _lastUpdated = DateTime.now();
    _isLoadingPrices = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadPrices();
    if (_currentPosition != null) {
      await _loadNearbyStations();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationName = 'ไม่สามารถระบุตำแหน่งได้';
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationName = 'ไม่ได้รับอนุญาตใช้ตำแหน่ง';
          notifyListeners();
          return;
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _locationName =
          'เกาะสมุย, สุราษฎร์ธานี'; // Use geocoding package for real address
      notifyListeners();
      await _loadNearbyStations();
    } catch (e) {
      _locationName = 'ไม่สามารถระบุตำแหน่งได้';
      // Use mock location for dev
      _currentPosition = Position(
        latitude: 9.5341,
        longitude: 100.0630,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      await _loadNearbyStations();
      notifyListeners();
    }
  }

  Future<void> _loadNearbyStations() async {
    if (_currentPosition == null) return;
    _isLoadingStations = true;
    notifyListeners();
    _nearbyStations = await _service.fetchNearbyStations(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    _isLoadingStations = false;
    notifyListeners();
  }

  void selectStation(GasStation station) {
    _selectedStation = station;
    notifyListeners();
  }
}
