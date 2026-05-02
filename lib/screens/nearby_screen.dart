import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_provider.dart';
import '../models/fuel_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/horizontal_scroll_list.dart';
import 'station_detail_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _mapExpanded = true;
  Set<String> _filterBrands = {};
  String _query = '';
  DateTime? _lastSearch;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value, AppProvider provider) {
    setState(() => _query = value);
    _lastSearch = DateTime.now();
    final ts = _lastSearch;
    Future.delayed(const Duration(milliseconds: 700), () {
      if (_lastSearch == ts) provider.searchStations(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final stations = _filtered(provider.nearbyStations);
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              _buildHeader(context, provider),
              _buildSearchBar(provider),
              _buildFiltersRow(provider),
              if (_mapExpanded) _buildMap(provider, stations),
              Expanded(child: _buildList(context, provider, stations)),
            ],
          ),
        );
      },
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AppProvider provider) {
    return Container(
      color: AppTheme.background,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text('ปั้มใกล้เคียง',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
          ),
          // OSM attribution badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: const Text('© OpenStreetMap',
                style: TextStyle(fontSize: 8, color: AppTheme.textMuted)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _mapExpanded = !_mapExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: Icon(
                _mapExpanded ? Icons.list_rounded : Icons.map_rounded,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Row(
          children: [
            provider.isSearching
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AppTheme.primary))
                : const Icon(Icons.search_rounded,
                    size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => _onSearchChanged(v, provider),
                style:
                    const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'ค้นหาพื้นที่ เช่น "ลาดพร้าว", "เชียงใหม่"...',
                  hintStyle:
                      TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                  provider.searchStations('');
                },
                child: const Icon(Icons.close_rounded,
                    size: 15, color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Filters + Radius ─────────────────────────────────────────────────────
  Widget _buildFiltersRow(AppProvider provider) {
    final radiusItems = [1000.0, 3000.0, 5000.0, 10000.0];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand filter chips (scrollable) ─────────────────────────
          HorizontalScrollListSurface(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _FilterChip(
                label: 'ทั้งหมด',
                isSelected: _filterBrands.isEmpty,
                onTap: () => setState(() => _filterBrands.clear()),
              ),
              const SizedBox(width: 6),
              ...FuelBrand.all.map((b) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _FilterChip(
                      label: b.shortName,
                      isSelected: _filterBrands.contains(b.id),
                      onTap: () => setState(() => _filterBrands.contains(b.id)
                          ? _filterBrands.remove(b.id)
                          : _filterBrands.add(b.id)),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 6),
          // ── Radius row + count ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.radar_rounded,
                    size: 11, color: AppTheme.textSecondary),
                const SizedBox(width: 5),
                const Text('รัศมี',
                    style:
                        TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                const SizedBox(width: 8),
                Expanded(
                  child: HorizontalScrollListSurface(
                    height: 26,
                    padding: EdgeInsets.zero,
                    children: radiusItems.map((r) {
                      final label = r < 1000
                          ? '${r.toInt()}ม.'
                          : '${(r / 1000).toStringAsFixed(0)}กม.';
                      final sel = provider.searchRadius == r;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => provider.setRadius(r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppTheme.primary.withOpacity(0.18)
                                  : AppTheme.card,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color:
                                      sel ? AppTheme.primary : AppTheme.border,
                                  width: 0.5),
                            ),
                            child: Text(label,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: sel
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w400)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (provider.nearbyStations.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('${provider.nearbyStations.length} แห่ง',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── OpenStreetMap (flutter_map) ───────────────────────────────────────────
  Widget _buildMap(AppProvider provider, List<GasStation> stations) {
    final lat = provider.currentPosition?.latitude ?? 13.7563;
    final lng = provider.currentPosition?.longitude ?? 100.5018;
    final center = LatLng(lat, lng);

    return SizedBox(
      height: 210,
      child: ClipRect(
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // OSM Tile Layer — Dark style จาก CartoDB
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              tileProvider: CancellableNetworkTileProvider(),
              userAgentPackageName: 'com.example.fuelthai',
              maxZoom: 19,
              retinaMode: MediaQuery.of(context).devicePixelRatio > 1,
            ),
            // Station Markers
            MarkerLayer(
              markers: [
                // User position
                Marker(
                  point: center,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.primary.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2)
                      ],
                    ),
                  ),
                ),
                // Station pins
                ...stations.map((s) => Marker(
                      point: LatLng(s.lat, s.lng),
                      width: 36,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () {
                          provider.selectStation(s);
                          _mapController.move(LatLng(s.lat, s.lng), 15);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const StationDetailScreen()));
                        },
                        child: _StationMapPin(brandId: s.brandId),
                      ),
                    )),
              ],
            ),
            // OSM Attribution (required)
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(
                      Uri.parse('https://openstreetmap.org/copyright')),
                ),
                TextSourceAttribution('CartoDB',
                    onTap: () => launchUrl(Uri.parse('https://carto.com'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Station List ──────────────────────────────────────────────────────────
  Widget _buildList(
      BuildContext context, AppProvider provider, List<GasStation> stations) {
    if (provider.isLoadingStations) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerCard(height: 110),
        ),
      );
    }

    if (provider.stationsError != null) {
      return _buildError(provider);
    }

    if (stations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_gas_station_outlined,
                color: AppTheme.textMuted, size: 44),
            SizedBox(height: 10),
            Text('ไม่พบปั้มน้ำมันในพื้นที่นี้',
                style: TextStyle(color: AppTheme.textSecondary)),
            SizedBox(height: 4),
            Text('ลองขยายรัศมี หรือค้นหาพื้นที่อื่น',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: stations.length,
      itemBuilder: (_, i) => _StationCard(
        station: stations[i],
        onTap: () {
          provider.selectStation(stations[i]);
          if (_mapExpanded) {
            _mapController.move(LatLng(stations[i].lat, stations[i].lng), 15.5);
          }
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const StationDetailScreen()));
        },
      ),
    );
  }

  Widget _buildError(AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppTheme.textMuted, size: 44),
            const SizedBox(height: 12),
            Text(provider.stationsError!,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: provider.refresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<GasStation> _filtered(List<GasStation> all) {
    if (_filterBrands.isEmpty) return all;
    return all.where((s) => _filterBrands.contains(s.brandId)).toList();
  }
}

// ─── Map Pin Widget ───────────────────────────────────────────────────────────
class _StationMapPin extends StatelessWidget {
  final String brandId;
  const _StationMapPin({required this.brandId});

  @override
  Widget build(BuildContext context) {
    final color = _brandColor(brandId);
    final label = _brandLabel(brandId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
                textAlign: TextAlign.center),
          ),
        ),
        // Triangle pointer
        CustomPaint(size: const Size(10, 6), painter: _TrianglePainter(color)),
      ],
    );
  }

  static Color _brandColor(String id) {
    switch (id) {
      case 'ptt':
        return const Color(0xFF22C55E);
      case 'shell':
        return const Color(0xFFF59E0B);
      case 'bcp':
        return const Color(0xFF3B82F6);
      case 'pt':
        return const Color(0xFFEF4444);
      case 'caltex':
        return const Color(0xFFF97316);
      case 'susco':
        return const Color(0xFF8B5CF6);
      default:
        return AppTheme.primary;
    }
  }

  static String _brandLabel(String id) {
    const labels = {
      'ptt': 'PTT',
      'shell': 'Shell',
      'bcp': 'BCP',
      'pt': 'PT',
      'caltex': 'Caltex',
      'susco': 'SUSCO',
      'irpc': 'IRPC',
      'pure': 'Pure',
    };
    return labels[id] ?? id.toUpperCase();
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.primary.withOpacity(0.15) : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
              width: isSelected ? 1 : 0.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary)),
      ),
    );
  }
}

// ─── Station Card ─────────────────────────────────────────────────────────────
class _StationCard extends StatelessWidget {
  final GasStation station;
  final VoidCallback onTap;

  const _StationCard({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final mainPrices = station.prices
        .where((p) => ['gasohol_91', 'gasohol_95', 'diesel', 'gasohol_e20']
            .any((k) => p.type.contains(k)))
        .take(3)
        .toList();

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
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      if (station.address.isNotEmpty)
                        Text(station.address,
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 7, color: AppTheme.green),
                          const SizedBox(width: 4),
                          Text(station.hours,
                              style: const TextStyle(
                                  fontSize: 9, color: AppTheme.green)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${station.distance.toStringAsFixed(1)} กม.',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ),
                    const SizedBox(height: 6),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppTheme.textMuted),
                  ],
                ),
              ],
            ),
            if (mainPrices.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(height: 0.5, color: AppTheme.border),
              const SizedBox(height: 10),
              Row(
                children: mainPrices
                    .map((p) => Expanded(
                          child: Column(
                            children: [
                              Text(p.typeLabel,
                                  style: const TextStyle(
                                      fontSize: 8,
                                      color: AppTheme.textSecondary),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('฿${p.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
