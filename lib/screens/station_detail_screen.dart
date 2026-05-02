import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_provider.dart';
import '../models/fuel_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class StationDetailScreen extends StatelessWidget {
  const StationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final station = provider.selectedStation;
    if (station == null) return const SizedBox();
    final isFav = provider.isFavorite(station.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, station, isFav, provider),
          SliverToBoxAdapter(child: _buildInfoChips(station)),
          SliverToBoxAdapter(child: _buildPriceList(station)),
          SliverToBoxAdapter(
              child: _buildActions(context, station, isFav, provider)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, GasStation station, bool isFav,
      AppProvider provider) {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: AppTheme.textPrimary),
        ),
      ),
      actions: [
        // ─── ปุ่ม Favorite ─────────────────────────────────────────────
        GestureDetector(
          onTap: () {
            provider.toggleFavorite(station);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppTheme.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                content: Row(
                  children: [
                    Icon(
                      isFav
                          ? Icons.favorite_border_rounded
                          : Icons.favorite_rounded,
                      color: isFav ? AppTheme.textSecondary : AppTheme.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFav
                          ? 'นำออกจากรายการโปรดแล้ว'
                          : 'เพิ่มในรายการโปรดแล้ว',
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18,
              color: isFav ? AppTheme.red : AppTheme.textSecondary,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D1B4B), AppTheme.background],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  BrandIconBadge(brandId: station.brandId, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(station.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 3),
                        if (station.address.isNotEmpty)
                          Text(station.address,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary),
                              maxLines: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info Chips ────────────────────────────────────────────────────────────
  Widget _buildInfoChips(GasStation station) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _InfoChip(
            icon: Icons.circle,
            iconColor: station.isOpen ? AppTheme.green : AppTheme.textMuted,
            text: station.isOpen ? 'เปิดอยู่' : 'ปิดแล้ว',
          ),
          if (station.hours.isNotEmpty)
            _InfoChip(icon: Icons.access_time_rounded, text: station.hours),
          _InfoChip(
              icon: Icons.near_me_rounded,
              text: '${station.distance.toStringAsFixed(1)} กม.'),
          if (station.rating > 0)
            _InfoChip(
              icon: Icons.star_rounded,
              iconColor: AppTheme.amber,
              text:
                  '${station.rating.toStringAsFixed(1)} (${station.reviewCount})',
            ),
        ],
      ),
    );
  }

  // ── Price List ────────────────────────────────────────────────────────────
  Widget _buildPriceList(GasStation station) {
    if (station.prices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: const Column(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppTheme.textMuted, size: 32),
              SizedBox(height: 8),
              Text('ราคาน้ำมันจะแสดงตามยี่ห้อปั้มที่ระบบตรวจพบ',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<FuelPrice>>{};
    for (final p in station.prices) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'ราคาน้ำมัน'),
          const SizedBox(height: 12),
          ...grouped.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 4),
                    child: Text(entry.key,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                  ),
                  ...entry.value.map((p) => _PriceRow(price: p)),
                ],
              )),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Widget _buildActions(BuildContext context, GasStation station, bool isFav,
      AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          // นำทาง
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openMaps(station),
              icon: const Icon(Icons.directions_rounded, size: 18),
              label: const Text('นำทางไปปั้มนี้',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Favorite
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                provider.toggleFavorite(station);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    content: Text(
                      isFav
                          ? 'นำออกจากรายการโปรดแล้ว'
                          : 'เพิ่มในรายการโปรดแล้ว',
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 13),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 18,
                  color: isFav ? AppTheme.red : AppTheme.textSecondary),
              label: Text(isFav ? 'อยู่ในรายการโปรดแล้ว' : 'เพิ่มในรายการโปรด',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isFav ? AppTheme.red : AppTheme.textSecondary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                    color:
                        isFav ? AppTheme.red.withOpacity(0.4) : AppTheme.border,
                    width: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // แชร์
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _shareStation(station),
              icon: const Icon(Icons.share_rounded,
                  size: 18, color: AppTheme.textSecondary),
              label: const Text('แชร์ปั้มนี้',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textSecondary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.border, width: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(GasStation station) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${station.lat},${station.lng}&travelmode=driving');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _shareStation(GasStation station) async {
    final text =
        '⛽ ${station.name}\n📍 ${station.address}\n🗺️ https://www.google.com/maps?q=${station.lat},${station.lng}';
    final url =
        Uri.parse('https://t.me/share/url?text=${Uri.encodeComponent(text)}');
    if (!await launchUrl(url)) {
      await launchUrl(Uri.parse(
          'https://www.google.com/maps?q=${station.lat},${station.lng}'));
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  const _InfoChip(
      {required this.icon,
      required this.text,
      this.iconColor = AppTheme.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: iconColor),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final FuelPrice price;
  const _PriceRow({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(price.typeLabel,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ),
          PriceChangeBadge(change: price.change),
          const SizedBox(width: 12),
          Text('${price.price.toStringAsFixed(2)} ฿',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary)),
        ],
      ),
    );
  }
}
