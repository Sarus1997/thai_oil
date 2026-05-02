import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_model.dart';
import '../services/fuel_service.dart';
import '../services/places_service.dart';

class AppProvider extends ChangeNotifier {
  final FuelService _fuelService = FuelService();
  FuelService get fuelService => _fuelService;
  late final PlacesService _placesService = PlacesService(_fuelService);

  // ── Fuel / Map ──────────────────────────────────────────────────────────
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
  double _searchRadius = 3000;

  // ── Favorites ───────────────────────────────────────────────────────────
  List<GasStation> _favorites = [];

  // ── Settings ────────────────────────────────────────────────────────────
  bool _notifyPriceChange = true;
  bool _notifyNearbyDeals = false;
  String _defaultBrandId = 'ptt';
  String _defaultFuelType = 'gasohol_91';

  // ── Getters ─────────────────────────────────────────────────────────────
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
  List<GasStation> get favorites => List.unmodifiable(_favorites);
  bool get notifyPriceChange => _notifyPriceChange;
  bool get notifyNearbyDeals => _notifyNearbyDeals;
  String get defaultBrandId => _defaultBrandId;
  String get defaultFuelType => _defaultFuelType;

  FuelBrand get selectedBrand =>
      FuelBrand.all.firstWhere((b) => b.id == _selectedBrandId,
          orElse: () => FuelBrand.all.first);
  FuelBrand get defaultBrand =>
      FuelBrand.all.firstWhere((b) => b.id == _defaultBrandId,
          orElse: () => FuelBrand.all.first);

  bool isFavorite(String stationId) => _favorites.any((s) => s.id == stationId);

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadSettings();
    _selectedBrandId = _defaultBrandId;
    await Future.wait([_loadPrices(), _getCurrentLocation()]);
  }

  // ── Brand / Prices ──────────────────────────────────────────────────────
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
    } catch (_) {
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

  // ── Location ────────────────────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _useFallback('GPS ไม่ได้เปิด');
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _useFallback('ไม่ได้รับสิทธิ์ตำแหน่ง');
        return;
      }
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _locationName = 'ตำแหน่งปัจจุบัน';
      notifyListeners();
      await _loadNearbyStations();
    } catch (_) {
      _useFallback('กรุงเทพมหานคร (ทดสอบ)');
    }
  }

  void _useFallback(String label) {
    _currentPosition = Position(
      latitude: 13.7563,
      longitude: 100.5018,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
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
      _nearbyStations = query.trim().isEmpty
          ? await _placesService.searchNearby(
              _currentPosition!.latitude, _currentPosition!.longitude,
              radiusMeters: _searchRadius)
          : await _placesService.searchByText(
              query, _currentPosition!.latitude, _currentPosition!.longitude);
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

  // ── Favorites ───────────────────────────────────────────────────────────
  Future<void> toggleFavorite(GasStation station) async {
    if (isFavorite(station.id)) {
      _favorites.removeWhere((s) => s.id == station.id);
    } else {
      _favorites.add(station);
    }
    notifyListeners();
    await _persistFavorites();
  }

  Future<void> _persistFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _favorites.map((s) => s.id).toList();
    await prefs.setStringList('fav_ids', ids);
    for (final s in _favorites) {
      await prefs.setString('fav_${s.id}_name', s.name);
      await prefs.setString('fav_${s.id}_brandId', s.brandId);
      await prefs.setString('fav_${s.id}_brand', s.brand);
      await prefs.setString('fav_${s.id}_addr', s.address);
      await prefs.setDouble('fav_${s.id}_lat', s.lat);
      await prefs.setDouble('fav_${s.id}_lng', s.lng);
      await prefs.setDouble('fav_${s.id}_dist', s.distance);
      await prefs.setString('fav_${s.id}_hours', s.hours);
      await prefs.setBool('fav_${s.id}_open', s.isOpen);
    }
  }

  Future<void> _loadFavorites(SharedPreferences prefs) async {
    final ids = prefs.getStringList('fav_ids') ?? [];
    _favorites = ids
        .map((id) => GasStation(
              id: id,
              name: prefs.getString('fav_${id}_name') ?? '',
              brandId: prefs.getString('fav_${id}_brandId') ?? 'ptt',
              brand: prefs.getString('fav_${id}_brand') ?? '',
              address: prefs.getString('fav_${id}_addr') ?? '',
              lat: prefs.getDouble('fav_${id}_lat') ?? 0,
              lng: prefs.getDouble('fav_${id}_lng') ?? 0,
              distance: prefs.getDouble('fav_${id}_dist') ?? 0,
              hours: prefs.getString('fav_${id}_hours') ?? '',
              isOpen: prefs.getBool('fav_${id}_open') ?? true,
              rating: 0,
              reviewCount: 0,
              prices: [],
            ))
        .toList();
  }

  // ── Settings ────────────────────────────────────────────────────────────
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notifyPriceChange = prefs.getBool('notify_price') ?? true;
    _notifyNearbyDeals = prefs.getBool('notify_nearby') ?? false;
    _defaultBrandId = prefs.getString('default_brand') ?? 'ptt';
    _defaultFuelType = prefs.getString('default_fuel') ?? 'gasohol_91';
    await _loadFavorites(prefs);
  }

  Future<void> setNotifyPriceChange(bool v) async {
    _notifyPriceChange = v;
    (await SharedPreferences.getInstance()).setBool('notify_price', v);
    notifyListeners();
  }

  Future<void> setNotifyNearbyDeals(bool v) async {
    _notifyNearbyDeals = v;
    (await SharedPreferences.getInstance()).setBool('notify_nearby', v);
    notifyListeners();
  }

  Future<void> setDefaultBrand(String brandId) async {
    _defaultBrandId = brandId;
    (await SharedPreferences.getInstance()).setString('default_brand', brandId);
    notifyListeners();
    await selectBrand(brandId);
  }

  Future<void> setDefaultFuelType(String fuelType) async {
    _defaultFuelType = fuelType;
    (await SharedPreferences.getInstance()).setString('default_fuel', fuelType);
    notifyListeners();
  }
}
