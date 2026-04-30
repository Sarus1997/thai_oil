import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/fuel_model.dart';
import '../services/fuel_service.dart';
import '../services/places_service.dart';

class AppProvider extends ChangeNotifier {
  final FuelService _fuelService = FuelService();
  late final PlacesService _placesService = PlacesService(_fuelService);

  String _selectedBrandId = 'ptt';
  List<FuelPrice> _prices = [];
  List<GasStation> _nearbyStations = [];
  GasStation? _selectedStation;
  Position? _currentPosition;
  bool _isLoadingPrices = false;
  bool _isLoadingStations = false;
  bool _isSearching = false;
  String? _locationName;
  String _apiDate = '';
  String? _error;
  String? _stationsError;
  double _searchRadius = 3000; // เมตร

  // Getters
  String get selectedBrandId => _selectedBrandId;
  List<FuelPrice> get prices => _prices;
  List<GasStation> get nearbyStations => _nearbyStations;
  GasStation? get selectedStation => _selectedStation;
  Position? get currentPosition => _currentPosition;
  bool get isLoadingPrices => _isLoadingPrices;
  bool get isLoadingStations => _isLoadingStations;
  bool get isSearching => _isSearching;
  String get locationName => _locationName ?? 'กำลังระบุตำแหน่ง...';
  String get apiDate => _apiDate;
  String? get error => _error;
  String? get stationsError => _stationsError;
  double get searchRadius => _searchRadius;
  FuelBrand get selectedBrand =>
      FuelBrand.all.firstWhere((b) => b.id == _selectedBrandId,
          orElse: () => FuelBrand.all.first);

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadPrices(), _getCurrentLocation()]);
  }

  Future<void> selectBrand(String brandId) async {
    _selectedBrandId = brandId;
    notifyListeners();
    await _loadPrices();
  }

  Future<void> _loadPrices() async {
    _isLoadingPrices = true;
    _error = null;
    notifyListeners();
    try {
      _prices = await _fuelService.fetchPrices(_selectedBrandId);
      _apiDate = _fuelService.updateDate;
    } catch (e) {
      _error = 'โหลดราคาไม่ได้: กรุณาตรวจสอบอินเทอร์เน็ต';
    }
    _isLoadingPrices = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _fuelService.invalidateCache();
    await _loadPrices();
    if (_currentPosition != null) await _loadNearbyStations();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useMockLocation('GPS ไม่ได้เปิด');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _useMockLocation('ไม่ได้รับสิทธิ์ตำแหน่ง');
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _locationName = 'ตำแหน่งปัจจุบัน';
      notifyListeners();
      await _loadNearbyStations();
    } catch (_) {
      _useMockLocation('กรุงเทพมหานคร (ทดสอบ)');
    }
  }

  void _useMockLocation(String label) {
    _currentPosition = Position(
      latitude: 13.7563, longitude: 100.5018, // กรุงเทพฯ
      timestamp: DateTime.now(), accuracy: 0, altitude: 0,
      heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    _locationName = label;
    notifyListeners();
    _loadNearbyStations();
  }

  Future<void> _loadNearbyStations() async {
    if (_currentPosition == null) return;
    _isLoadingStations = true;
    _stationsError = null;
    notifyListeners();
    try {
      _nearbyStations = await _placesService.searchNearby(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        radiusMeters: _searchRadius,
      );
    } catch (e) {
      _stationsError = 'ค้นหาปั้มไม่ได้: $e';
    }
    _isLoadingStations = false;
    notifyListeners();
  }

  Future<void> searchStations(String query) async {
    if (_currentPosition == null) return;
    _isSearching = true;
    notifyListeners();
    try {
      if (query.trim().isEmpty) {
        await _loadNearbyStations();
      } else {
        _nearbyStations = await _placesService.searchByText(
          query,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }
    } catch (_) {
      _stationsError = 'ค้นหาไม่สำเร็จ';
    }
    _isSearching = false;
    notifyListeners();
  }

  Future<void> setRadius(double radiusMeters) async {
    _searchRadius = radiusMeters;
    await _loadNearbyStations();
  }

  void selectStation(GasStation station) {
    _selectedStation = station;
    notifyListeners();
  }
}
