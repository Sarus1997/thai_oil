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
    final station = context.watch<AppProvider>().selectedStation;
    if (station == null) return const SizedBox();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, station),
          SliverToBoxAdapter(child: _buildInfo(station)),
          SliverToBoxAdapter(child: _buildPriceList(station)),
          SliverToBoxAdapter(child: _buildActions(context, station)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, GasStation station) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.textPrimary),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D1B4B), AppTheme.background],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  BrandIconBadge(brandId: station.brandId, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(station.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        const SizedBox(height: 3),
                        Text(station.address,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
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

  Widget _buildInfo(GasStation station) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _InfoChip(
            icon: Icons.circle,
            iconColor: station.isOpen ? AppTheme.green : AppTheme.textMuted,
            text: station.isOpen ? 'เปิดอยู่' : 'ปิดแล้ว',
          ),
          const SizedBox(width: 8),
          _InfoChip(icon: Icons.access_time_rounded, text: station.hours),
          const SizedBox(width: 8),
          _InfoChip(icon: Icons.near_me_rounded, text: '${station.distance.toStringAsFixed(1)} กม.'),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppTheme.amber, size: 14),
              const SizedBox(width: 3),
              Text('${station.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text(' (${station.reviewCount})', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceList(GasStation station) {
    final grouped = <String, List<FuelPrice>>{};
    for (final p in station.prices) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ),
                  ...entry.value.map((p) => _PriceRow(price: p)),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, GasStation station) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openMaps(station),
              icon: const Icon(Icons.directions_rounded, size: 18),
              label: const Text('นำทางไปปั้มนี้', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.favorite_border_rounded, size: 18),
              label: const Text('เพิ่มในรายการโปรด', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.border, width: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(GasStation station) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${station.lat},${station.lng}&travelmode=driving',
    );
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _InfoChip({required this.icon, required this.text, this.iconColor = AppTheme.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: iconColor),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(price.typeLabel,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ),
          PriceChangeBadge(change: price.change),
          const SizedBox(width: 12),
          Text(
            '${price.price.toStringAsFixed(2)} ฿',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}
