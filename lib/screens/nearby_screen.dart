import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/fuel_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'station_detail_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _mapExpanded = true;
  Set<String> _filterBrands = {};

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final stations = _filteredStations(provider.nearbyStations);

        return Scaffold(
          body: Column(
            children: [
              _buildHeader(context),
              _buildSearchBar(),
              _buildBrandFilters(provider),
              if (_mapExpanded) _buildMap(provider, stations),
              Expanded(child: _buildStationList(context, provider, stations)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text('ปั้มใกล้เคียง',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          ),
          GestureDetector(
            onTap: () => setState(() => _mapExpanded = !_mapExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(_mapExpanded ? Icons.map_rounded : Icons.list_rounded,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(_mapExpanded ? 'รายการ' : 'แผนที่',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'ค้นหาปั้มหรือพื้นที่...',
                  hintStyle: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandFilters(AppProvider provider) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FilterChip(
            label: 'ทั้งหมด',
            isSelected: _filterBrands.isEmpty,
            onTap: () => setState(() => _filterBrands.clear()),
          ),
          const SizedBox(width: 6),
          ...FuelBrand.all.take(4).map((b) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _FilterChip(
                  label: b.shortName,
                  isSelected: _filterBrands.contains(b.id),
                  onTap: () => setState(() {
                    if (_filterBrands.contains(b.id)) {
                      _filterBrands.remove(b.id);
                    } else {
                      _filterBrands.add(b.id);
                    }
                  }),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMap(AppProvider provider, List<GasStation> stations) {
    final lat = provider.currentPosition?.latitude ?? 9.5341;
    final lng = provider.currentPosition?.longitude ?? 100.0630;

    final markers = stations.map((s) {
      return Marker(
        markerId: MarkerId(s.id),
        position: LatLng(s.lat, s.lng),
        infoWindow: InfoWindow(
          title: s.name,
          snippet: '฿${s.prices.first.price.toStringAsFixed(2)}/ลิตร',
        ),
        onTap: () {
          provider.selectStation(s);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StationDetailScreen()));
        },
      );
    }).toSet();

    return SizedBox(
      height: 200,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 13),
        onMapCreated: (c) => _mapController = c,
        markers: markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        style: _mapStyle,
      ),
    );
  }

  Widget _buildStationList(BuildContext context, AppProvider provider, List<GasStation> stations) {
    if (provider.isLoadingStations) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerCard(height: 72),
        ),
      );
    }

    if (stations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: AppTheme.textMuted, size: 40),
            SizedBox(height: 8),
            Text('ไม่พบปั้มที่ค้นหา', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: stations.length,
      itemBuilder: (_, i) => _StationCard(
        station: stations[i],
        onTap: () {
          provider.selectStation(stations[i]);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StationDetailScreen()));
        },
      ),
    );
  }

  List<GasStation> _filteredStations(List<GasStation> all) {
    return all.where((s) {
      final matchSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.address.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchBrand = _filterBrands.isEmpty || _filterBrands.contains(s.brandId);
      return matchSearch && matchBrand;
    }).toList();
  }

  static const String _mapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#0a0e1a"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#7b82a8"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0e1a"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a2040"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#0d1525"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0d1b2d"}]},
    {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#12182e"}]},
    {"featureType":"transit","stylers":[{"visibility":"off"}]}
  ]''';
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final GasStation station;
  final VoidCallback onTap;

  const _StationCard({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final prices = station.prices.take(3).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                BrandIconBadge(brandId: station.brandId, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(station.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const SizedBox(height: 2),
                      Text(station.address,
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 7, color: station.isOpen ? AppTheme.green : AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(station.isOpen ? 'เปิดอยู่' : 'ปิดแล้ว',
                              style: TextStyle(fontSize: 9, color: station.isOpen ? AppTheme.green : AppTheme.textMuted)),
                          const SizedBox(width: 6),
                          const Icon(Icons.star_rounded, size: 9, color: AppTheme.amber),
                          const SizedBox(width: 2),
                          Text('${station.rating}', style: const TextStyle(fontSize: 9, color: AppTheme.amber)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${station.distance.toStringAsFixed(1)} กม.',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMuted),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 0.5, color: AppTheme.border),
            const SizedBox(height: 10),
            Row(
              children: prices.map((p) => Expanded(
                    child: Column(
                      children: [
                        Text(p.typeLabel,
                            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary), textAlign: TextAlign.center),
                        const SizedBox(height: 2),
                        Text('฿${p.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
