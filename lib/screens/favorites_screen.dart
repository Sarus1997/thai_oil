import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_provider.dart';
import '../models/fuel_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'station_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final favs = provider.favorites;
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              _buildHeader(context, favs.length),
              favs.isEmpty
                  ? const Expanded(child: _EmptyFavorites())
                  : Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        itemCount: favs.length,
                        itemBuilder: (_, i) => _FavCard(
                          station: favs[i],
                          onTap: () {
                            provider.selectStation(favs[i]);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const StationDetailScreen()));
                          },
                          onRemove: () => provider.toggleFavorite(favs[i]),
                          onNav: () => _openMaps(favs[i]),
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      color: AppTheme.background,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text('รายการโปรด',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$count แห่ง',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Future<void> _openMaps(GasStation s) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${s.lat},${s.lng}&travelmode=driving');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: const Icon(Icons.favorite_border_rounded,
                color: AppTheme.textMuted, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('ยังไม่มีรายการโปรด',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('กดไอคอน ♡ ที่หน้ารายละเอียดปั้ม\nเพื่อเพิ่มในรายการโปรด',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FavCard extends StatelessWidget {
  final GasStation station;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onNav;
  const _FavCard(
      {required this.station,
      required this.onTap,
      required this.onRemove,
      required this.onNav});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: [
          // ── Mini Map ─────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 100,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(station.lat, station.lng),
                  initialZoom: 15,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    retinaMode: MediaQuery.of(context).devicePixelRatio > 1,
                    userAgentPackageName: 'com.example.fuelthai',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(station.lat, station.lng),
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _brandColor(station.brandId),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: _brandColor(station.brandId)
                                    .withOpacity(0.4),
                                blurRadius: 6)
                          ],
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          // ── Info Row ─────────────────────────────────────────────────────
          InkWell(
            onTap: onTap,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  BrandIconBadge(brandId: station.brandId, size: 38),
                  const SizedBox(width: 10),
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
                        if (station.address.isNotEmpty)
                          Text(station.address,
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  // Actions
                  IconButton(
                    icon: const Icon(Icons.directions_rounded,
                        size: 18, color: AppTheme.primary),
                    onPressed: onNav,
                    tooltip: 'นำทาง',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded,
                        size: 18, color: AppTheme.red),
                    onPressed: () {
                      onRemove();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppTheme.surface,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          content: const Text('นำออกจากรายการโปรดแล้ว',
                              style: TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 13)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'นำออก',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
}
