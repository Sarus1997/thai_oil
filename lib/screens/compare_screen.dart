import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/fuel_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// หน้าเปรียบเทียบราคาน้ำมันทุกปั้มแบบ side-by-side
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});
  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  String _selectedFuelType = 'gasohol_91';
  bool _isLoading = false;

  // ราคาทุกปั้มสำหรับ fuel type ที่เลือก
  Map<String, double?> _allPrices = {};

  static const Map<String, String> _fuelLabels = {
    'gasohol_91': 'แก๊สโซฮอล์ 91',
    'gasohol_95': 'แก๊สโซฮอล์ 95',
    'gasohol_e20': 'E20',
    'gasohol_e85': 'E85',
    'diesel': 'ดีเซล',
    'diesel_b20': 'ดีเซล B20',
    'premium_diesel': 'ดีเซลพรีเมียม',
    'gasoline_95': 'เบนซิน 95',
    'ngv': 'NGV',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadComparison());
  }

  Future<void> _loadComparison() async {
    setState(() => _isLoading = true);
    final provider = context.read<AppProvider>();

    // ดึงราคาจากทุกปั้มพร้อมกัน
    final results = <String, double?>{};
    for (final brand in FuelBrand.all) {
      final prices = await provider.fuelService.fetchPrices(brand.id);
      final match = prices
          .where((p) =>
              p.type == _selectedFuelType ||
              p.type.contains(_selectedFuelType
                  .replaceAll('gasohol_', '')
                  .replaceAll('_', '')))
          .toList();
      results[brand.id] = match.isNotEmpty ? match.first.price : null;
    }

    if (mounted)
      setState(() {
        _allPrices = results;
        _isLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    // เรียงราคาจากถูกไปแพง (กรองเฉพาะที่มีราคา)
    final sorted = _allPrices.entries.where((e) => e.value != null).toList()
      ..sort((a, b) => a.value!.compareTo(b.value!));

    final minPrice = sorted.isNotEmpty ? sorted.first.value! : 0.0;
    final maxPrice = sorted.isNotEmpty ? sorted.last.value! : 1.0;
    final range = maxPrice - minPrice;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('เปรียบเทียบราคา',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _loadComparison,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
      body: Column(
        children: [
          // Fuel type selector
          _buildFuelTypeSelector(),
          const SizedBox(height: 8),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : sorted.isEmpty
                    ? const Center(
                        child: Text('ไม่มีข้อมูลสำหรับประเภทน้ำมันนี้',
                            style: TextStyle(color: AppTheme.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: sorted.length,
                        itemBuilder: (_, i) {
                          final entry = sorted[i];
                          final brand = FuelBrand.all.firstWhere(
                              (b) => b.id == entry.key,
                              orElse: () => FuelBrand.all.first);
                          final price = entry.value!;
                          final ratio =
                              range > 0 ? (price - minPrice) / range : 0.5;
                          final isCheapest = i == 0;
                          final isMostExpensive = i == sorted.length - 1;

                          return _CompareCard(
                            rank: i + 1,
                            brand: brand,
                            price: price,
                            ratio: ratio,
                            isCheapest: isCheapest,
                            isMostExpensive: isMostExpensive,
                            savingVsMax: maxPrice - price,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelTypeSelector() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _fuelLabels.entries.map((e) {
          final selected = _selectedFuelType == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFuelType = e.key);
                _loadComparison();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.border,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  final int rank;
  final FuelBrand brand;
  final double price;
  final double ratio;
  final bool isCheapest;
  final bool isMostExpensive;
  final double savingVsMax;

  const _CompareCard({
    required this.rank,
    required this.brand,
    required this.price,
    required this.ratio,
    required this.isCheapest,
    required this.isMostExpensive,
    required this.savingVsMax,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = isCheapest
        ? AppTheme.green
        : isMostExpensive
            ? AppTheme.red
            : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCheapest ? AppTheme.greenBg.withOpacity(0.4) : AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCheapest ? AppTheme.green.withOpacity(0.3) : AppTheme.border,
          width: isCheapest ? 1 : 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCheapest ? AppTheme.green : AppTheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$rank',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isCheapest
                              ? Colors.white
                              : AppTheme.textSecondary)),
                ),
              ),
              const SizedBox(width: 10),
              BrandIconBadge(brandId: brand.id, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(brand.name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        if (isCheapest) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('ถูกสุด',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    if (savingVsMax > 0)
                      Text(
                          'ประหยัดกว่า ฿${savingVsMax.toStringAsFixed(2)}/ลิตร',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.green)),
                  ],
                ),
              ),
              Text('฿${price.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color:
                          isCheapest ? AppTheme.green : AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          // Price bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isCheapest ? 0.15 : ratio.clamp(0.15, 1.0),
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
