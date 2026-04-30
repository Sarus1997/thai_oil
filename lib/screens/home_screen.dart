import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/fuel_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'station_detail_screen.dart';
import 'nearby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _HomeTab(),
      const NearbyScreen(),
      const _FavoritesTab(),
      const _SettingsTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.local_gas_station_rounded), label: 'ราคา'),
            BottomNavigationBarItem(
                icon: Icon(Icons.map_rounded), label: 'แผนที่'),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite_rounded), label: 'รายการโปรด'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded), label: 'ตั้งค่า'),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          onRefresh: provider.refresh,
          child: CustomScrollView(
            slivers: [
              _buildHeader(context, provider),
              SliverToBoxAdapter(child: _buildBrandSelector(context, provider)),
              if (provider.error != null)
                SliverToBoxAdapter(child: _buildError(provider)),
              SliverToBoxAdapter(child: _buildPriceGrid(provider)),
              SliverToBoxAdapter(child: _buildNearbySection(context, provider)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: AppTheme.background,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded,
              size: 20, color: AppTheme.textSecondary),
          onPressed: provider.refresh,
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
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('ราคาน้ำมันวันนี้',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 12, color: AppTheme.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(provider.locationName,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ),
                  if (provider.apiDate.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        provider.apiDate,
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.green,
                            fontWeight: FontWeight.w600),
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

  Widget _buildBrandSelector(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'เลือกปั้มน้ำมัน'),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: FuelBrand.all
                  .map((brand) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: BrandChip(
                          brand: brand,
                          isSelected: provider.selectedBrandId == brand.id,
                          onTap: () => provider.selectBrand(brand.id),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.redBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.red.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 14, color: AppTheme.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(provider.error!,
                  style: const TextStyle(fontSize: 11, color: AppTheme.red)),
            ),
            GestureDetector(
              onTap: provider.refresh,
              child: const Text('ลองใหม่',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.red,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceGrid(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'ราคา${provider.selectedBrand.name}'),
          const SizedBox(height: 10),
          if (provider.isLoadingPrices)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: List.generate(6, (_) => const ShimmerCard(height: 90)),
            )
          else if (provider.prices.isEmpty)
            _buildNoPrices(provider)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
              ),
              itemCount: provider.prices.length,
              itemBuilder: (_, i) => FuelPriceCard(
                price: provider.prices[i],
                isHighlight: i == 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoPrices(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.textMuted, size: 32),
          const SizedBox(height: 8),
          Text(
            'ไม่มีข้อมูลราคาของ ${provider.selectedBrand.name}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text('กรุณาเลือกปั้มอื่น',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildNearbySection(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'ปั้มใกล้เคียง'),
          const SizedBox(height: 10),
          if (provider.isLoadingStations)
            ...List.generate(
                3,
                (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ShimmerCard(height: 72),
                    ))
          else if (provider.nearbyStations.isEmpty)
            const _EmptyStations()
          else
            ...provider.nearbyStations.take(3).map((s) => _StationListItem(
                  station: s,
                  onTap: () {
                    provider.selectStation(s);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StationDetailScreen()));
                  },
                )),
        ],
      ),
    );
  }
}

// ─── Station List Item ────────────────────────────────────────────────────────
class _StationListItem extends StatelessWidget {
  final GasStation station;
  final VoidCallback onTap;

  const _StationListItem({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final mainPrice = station.prices.isNotEmpty
        ? station.prices.firstWhere(
            (p) => p.type.contains('gasohol_91'),
            orElse: () => station.prices.first,
          )
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Row(
          children: [
            BrandIconBadge(brandId: station.brandId, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(station.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.circle,
                          size: 7,
                          color: station.isOpen
                              ? AppTheme.green
                              : AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(station.isOpen ? 'เปิดอยู่' : 'ปิดแล้ว',
                          style: TextStyle(
                              fontSize: 10,
                              color: station.isOpen
                                  ? AppTheme.green
                                  : AppTheme.textMuted)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('• ${station.hours}',
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${station.distance.toStringAsFixed(1)} กม.',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                if (mainPrice != null)
                  Text('฿${mainPrice.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.primary)),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _EmptyStations extends StatelessWidget {
  const _EmptyStations();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: const Column(
        children: [
          Icon(Icons.location_off_rounded, color: AppTheme.textMuted, size: 32),
          SizedBox(height: 8),
          Text('ไม่พบปั้มใกล้เคียง',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text('กรุณาเปิดใช้งาน GPS',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Placeholder Tabs ─────────────────────────────────────────────────────────
class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded,
                color: AppTheme.textMuted, size: 48),
            SizedBox(height: 12),
            Text('ยังไม่มีรายการโปรด',
                style: TextStyle(color: AppTheme.textSecondary)),
            SizedBox(height: 4),
            Text('กดที่หัวใจเพื่อบันทึกปั้มที่ชื่นชอบ',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่า')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingItem(
              icon: Icons.notifications_rounded,
              label: 'การแจ้งเตือน',
              sub: 'แจ้งเมื่อราคาเปลี่ยน'),
          _SettingItem(
              icon: Icons.local_gas_station_rounded,
              label: 'ปั้มเริ่มต้น',
              sub: 'PTT'),
          _SettingItem(
              icon: Icons.directions_car_rounded,
              label: 'ประเภทน้ำมันที่ใช้',
              sub: 'แก๊สโซฮอล์ 91'),
          _SettingItem(
              icon: Icons.info_outline_rounded,
              label: 'แหล่งข้อมูล',
              sub: 'api.chnwt.dev/thai-oil-api'),
          _SettingItem(
              icon: Icons.info_outline_rounded,
              label: 'เกี่ยวกับแอพ',
              sub: 'FuelTH v1.0.0'),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;

  const _SettingItem(
      {required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}
