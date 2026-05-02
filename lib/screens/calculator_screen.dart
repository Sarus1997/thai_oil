import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/fuel_model.dart';
import '../theme/app_theme.dart';

/// คำนวณค่าเติมน้ำมัน — ใส่จำนวนลิตร หรือ จำนวนเงิน
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _litersCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController(text: '10');

  String _selectedFuelType = 'gasohol_91';
  double? _selectedPrice;

  static const Map<String, String> _fuelLabels = {
    'gasohol_91': 'แก๊สโซฮอล์ 91',
    'gasohol_95': 'แก๊สโซฮอล์ 95',
    'gasohol_e20': 'E20',
    'gasohol_e85': 'E85',
    'diesel': 'ดีเซล',
    'diesel_b20': 'ดีเซล B20',
    'premium_diesel': 'ดีเซลพรีเมียม',
    'gasoline_95': 'เบนซิน 95',
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrice());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _litersCtrl.dispose();
    _amountCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  void _loadPrice() {
    final provider = context.read<AppProvider>();
    final match =
        provider.prices.where((p) => p.type == _selectedFuelType).toList();
    if (match.isNotEmpty) {
      setState(() => _selectedPrice = match.first.price);
    }
  }

  // ── จากลิตร → เงิน ────────────────────────────────────────────────────
  double? get _litersToMoney {
    final liters = double.tryParse(_litersCtrl.text);
    if (liters == null || _selectedPrice == null) return null;
    return liters * _selectedPrice!;
  }

  // ── จากเงิน → ลิตร ────────────────────────────────────────────────────
  double? get _moneyToLiters {
    final money = double.tryParse(_amountCtrl.text);
    if (money == null || _selectedPrice == null) return null;
    return money / _selectedPrice!;
  }

  // ── ระยะทางที่แล่นได้ (สมมติ km/l ตามชนิดน้ำมัน) ────────────────────
  double _assumedKmPerLiter(String fuelType) {
    const map = {
      'gasohol_91': 12.0,
      'gasohol_95': 13.0,
      'gasohol_e20': 11.5,
      'gasohol_e85': 10.0,
      'diesel': 14.0,
      'diesel_b20': 13.5,
      'premium_diesel': 14.5,
      'gasoline_95': 13.5,
    };
    return map[fuelType] ?? 12.0;
  }

  double? get _distanceFromLiters {
    final liters = double.tryParse(_litersCtrl.text);
    if (liters == null) return null;
    return liters * _assumedKmPerLiter(_selectedFuelType);
  }

  double? get _distanceFromMoney {
    final liters = _moneyToLiters;
    if (liters == null) return null;
    return liters * _assumedKmPerLiter(_selectedFuelType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('คำนวณค่าน้ำมัน',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'ใส่จำนวนลิตร'),
            Tab(text: 'ใส่จำนวนเงิน'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── เลือกประเภทน้ำมัน + ราคา ────────────────────────────────
          _buildFuelSelector(),
          // ── Tabs ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildLitersTab(),
                _buildMoneyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ประเภทน้ำมัน',
              style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _fuelLabels.entries.map((e) {
                final sel = _selectedFuelType == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedFuelType = e.key);
                      _loadPrice();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.primary : AppTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: sel ? AppTheme.primary : AppTheme.border,
                            width: 0.5),
                      ),
                      child: Text(e.value,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  sel ? Colors.white : AppTheme.textSecondary)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_selectedPrice != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.local_gas_station_rounded,
                    size: 12, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  'ราคาปัจจุบัน: ฿${_selectedPrice!.toStringAsFixed(2)} / ลิตร',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLitersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input
          _buildInputCard(
            label: 'จำนวนลิตร',
            hint: 'เช่น 30',
            suffix: 'ลิตร',
            controller: _litersCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // Results
          if (_litersToMoney != null) ...[
            _ResultCard(
              icon: Icons.payments_rounded,
              iconColor: AppTheme.green,
              label: 'ค่าน้ำมันที่ต้องจ่าย',
              value: '฿${_litersToMoney!.toStringAsFixed(2)}',
              valueColor: AppTheme.green,
            ),
            const SizedBox(height: 10),
            _ResultCard(
              icon: Icons.route_rounded,
              iconColor: AppTheme.blue,
              label: 'ระยะทางโดยประมาณ',
              value: '${_distanceFromLiters!.toStringAsFixed(0)} กม.',
              subtitle:
                  'อัตราสิ้นเปลือง ~${_assumedKmPerLiter(_selectedFuelType).toStringAsFixed(0)} กม./ลิตร',
              valueColor: AppTheme.blue,
            ),
            const SizedBox(height: 10),
            _ResultCard(
              icon: Icons.local_gas_station_rounded,
              iconColor: AppTheme.amber,
              label: 'ราคาต่อลิตร',
              value: '฿${_selectedPrice?.toStringAsFixed(2) ?? "-"}',
              valueColor: AppTheme.amber,
            ),
          ],
          const SizedBox(height: 20),
          _buildPresetButtons(isLiters: true),
        ],
      ),
    );
  }

  Widget _buildMoneyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputCard(
            label: 'จำนวนเงิน',
            hint: 'เช่น 500',
            suffix: 'บาท',
            controller: _amountCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_moneyToLiters != null) ...[
            _ResultCard(
              icon: Icons.water_drop_rounded,
              iconColor: AppTheme.blue,
              label: 'จำนวนน้ำมันที่ได้',
              value: '${_moneyToLiters!.toStringAsFixed(2)} ลิตร',
              valueColor: AppTheme.blue,
            ),
            const SizedBox(height: 10),
            _ResultCard(
              icon: Icons.route_rounded,
              iconColor: AppTheme.green,
              label: 'ระยะทางโดยประมาณ',
              value: '${_distanceFromMoney!.toStringAsFixed(0)} กม.',
              subtitle:
                  'อัตราสิ้นเปลือง ~${_assumedKmPerLiter(_selectedFuelType).toStringAsFixed(0)} กม./ลิตร',
              valueColor: AppTheme.green,
            ),
          ],
          const SizedBox(height: 20),
          _buildPresetButtons(isLiters: false),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required String hint,
    required String suffix,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                  ],
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                        fontSize: 24, color: AppTheme.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Text(suffix,
                  style: const TextStyle(
                      fontSize: 16, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButtons({required bool isLiters}) {
    final presets = isLiters
        ? ['10', '20', '30', '40', '50', 'เต็มถัง (40L)']
        : ['100', '200', '300', '500', '1000'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ค่าที่นิยม',
            style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((p) {
            return GestureDetector(
              onTap: () {
                final val = p.contains('เต็มถัง') ? '40' : p;
                setState(() {
                  if (isLiters) {
                    _litersCtrl.text = val;
                  } else {
                    _amountCtrl.text = val;
                  }
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Text(p,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final Color valueColor;

  const _ResultCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 9, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: valueColor)),
        ],
      ),
    );
  }
}
