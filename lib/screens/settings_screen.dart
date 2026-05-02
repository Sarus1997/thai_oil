import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_provider.dart';
import '../models/fuel_model.dart';
import '../theme/app_theme.dart';
import 'compare_screen.dart';
import 'calculator_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSection('🔔 การแจ้งเตือน', [
                      _ToggleTile(
                        icon: Icons.price_change_rounded,
                        iconBg: const Color(0xFF1A3A1A),
                        iconColor: AppTheme.green,
                        title: 'แจ้งเตือนเมื่อราคาเปลี่ยน',
                        subtitle:
                            'รับการแจ้งเตือนทุกครั้งที่ราคาน้ำมันมีการปรับ',
                        value: provider.notifyPriceChange,
                        onChanged: provider.setNotifyPriceChange,
                      ),
                      _ToggleTile(
                        icon: Icons.local_offer_rounded,
                        iconBg: const Color(0xFF2D2000),
                        iconColor: AppTheme.amber,
                        title: 'แจ้งเตือนโปรโมชัน',
                        subtitle: 'แจ้งเตือนเมื่อมีโปรโมชันน้ำมันใกล้บ้าน',
                        value: provider.notifyNearbyDeals,
                        onChanged: provider.setNotifyNearbyDeals,
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildSection('⛽ การตั้งค่าปั้ม', [
                      _SelectTile<String>(
                        icon: Icons.local_gas_station_rounded,
                        iconBg: const Color(0xFF0F1635),
                        iconColor: AppTheme.primary,
                        title: 'ปั้มเริ่มต้น',
                        subtitle: 'แสดงราคาปั้มนี้เป็นค่าเริ่มต้น',
                        value: provider.defaultBrandId,
                        items: FuelBrand.all
                            .map((b) => DropdownMenuItem(
                                value: b.id, child: Text(b.name)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) provider.setDefaultBrand(v);
                        },
                        displayValue: provider.defaultBrand.name,
                      ),
                      _SelectTile<String>(
                        icon: Icons.opacity_rounded,
                        iconBg: const Color(0xFF001A2D),
                        iconColor: AppTheme.blue,
                        title: 'ประเภทน้ำมันที่ใช้',
                        subtitle: 'น้ำมันที่คุณเติมเป็นประจำ',
                        value: provider.defaultFuelType,
                        items: const [
                          DropdownMenuItem(
                              value: 'gasohol_91',
                              child: Text('แก๊สโซฮอล์ 91')),
                          DropdownMenuItem(
                              value: 'gasohol_95',
                              child: Text('แก๊สโซฮอล์ 95')),
                          DropdownMenuItem(
                              value: 'gasohol_e20', child: Text('E20')),
                          DropdownMenuItem(
                              value: 'gasohol_e85', child: Text('E85')),
                          DropdownMenuItem(
                              value: 'diesel', child: Text('ดีเซล')),
                          DropdownMenuItem(
                              value: 'diesel_b20', child: Text('ดีเซล B20')),
                          DropdownMenuItem(
                              value: 'premium_diesel',
                              child: Text('ดีเซลพรีเมียม')),
                          DropdownMenuItem(
                              value: 'gasoline_95', child: Text('เบนซิน 95')),
                          DropdownMenuItem(value: 'ngv', child: Text('NGV')),
                        ],
                        onChanged: (v) {
                          if (v != null) provider.setDefaultFuelType(v);
                        },
                        displayValue: _fuelLabel(provider.defaultFuelType),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildSection('🛠️ เครื่องมือ', [
                      _LinkTile(
                        icon: Icons.compare_arrows_rounded,
                        iconBg: const Color(0xFF2D2000),
                        iconColor: AppTheme.amber,
                        title: 'เปรียบเทียบราคาทุกปั้ม',
                        subtitle: 'ดูว่าปั้มไหนถูกสุดสำหรับน้ำมันแต่ละประเภท',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CompareScreen())),
                      ),
                      _LinkTile(
                        icon: Icons.calculate_rounded,
                        iconBg: const Color(0xFF0F2D1A),
                        iconColor: AppTheme.green,
                        title: 'คำนวณค่าน้ำมัน',
                        subtitle: 'คำนวณค่าใช้จ่ายและระยะทางจากจำนวนลิตร/เงิน',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CalculatorScreen())),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildSection('📡 แหล่งข้อมูล', [
                      _LinkTile(
                        icon: Icons.api_rounded,
                        iconBg: const Color(0xFF1A2040),
                        iconColor: AppTheme.textSecondary,
                        title: 'Thai Oil API',
                        subtitle: 'api.chnwt.dev/thai-oil-api',
                        trailing: provider.apiDate.isNotEmpty
                            ? Text('อัพเดท ${provider.apiDate}',
                                style: const TextStyle(
                                    fontSize: 9, color: AppTheme.green))
                            : null,
                        onTap: () => launchUrl(Uri.parse(
                            'https://api.chnwt.dev/thai-oil-api/latest')),
                      ),
                      _LinkTile(
                        icon: Icons.map_rounded,
                        iconBg: const Color(0xFF1A2040),
                        iconColor: AppTheme.textSecondary,
                        title: 'OpenStreetMap',
                        subtitle: 'แผนที่และข้อมูลปั้มน้ำมัน (Overpass API)',
                        onTap: () => launchUrl(Uri.parse(
                            'https://www.openstreetmap.org/copyright')),
                      ),
                      _LinkTile(
                        icon: Icons.place_rounded,
                        iconBg: const Color(0xFF1A2040),
                        iconColor: AppTheme.textSecondary,
                        title: 'Nominatim Geocoding',
                        subtitle: 'ระบบค้นหาตำแหน่งจาก OSM',
                        onTap: () => launchUrl(
                            Uri.parse('https://nominatim.openstreetmap.org')),
                      ),
                      _InfoTile(
                        icon: Icons.update_rounded,
                        iconBg: const Color(0xFF1A2040),
                        iconColor: AppTheme.textSecondary,
                        title: 'ความถี่อัพเดทราคา',
                        subtitle: 'Cache ทุก 30 นาที • ราคาอัพเดทรายวัน',
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildSection('ℹ️ เกี่ยวกับแอพ', [
                      _InfoTile(
                        icon: Icons.local_gas_station_rounded,
                        iconBg: AppTheme.primary.withOpacity(0.15),
                        iconColor: AppTheme.primary,
                        title: 'FuelTH',
                        subtitle: 'แอพตรวจสอบราคาน้ำมัน',
                        trailing: const Text('v1.0.0',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary)),
                      ),
                      _InfoTile(
                        icon: Icons.info_outline_rounded,
                        iconBg: const Color(0xFF1A2040),
                        iconColor: AppTheme.textSecondary,
                        title: 'ข้อมูลราคา',
                        subtitle:
                            'ราคาที่แสดงเป็นราคาปลีก กรุงเทพฯ และปริมณฑล ราคาต่างจังหวัดอาจแตกต่าง',
                      ),
                      _LinkTile(
                        icon: Icons.gavel_rounded,
                        iconBg: const Color(0xFF1A2040),
                        iconColor: AppTheme.textSecondary,
                        title: 'นโยบายความเป็นส่วนตัว',
                        subtitle: 'แอพนี้ไม่เก็บข้อมูลส่วนตัวของผู้ใช้',
                        onTap: () {},
                      ),
                      _LinkTile(
                        icon: Icons.share_rounded,
                        iconBg: const Color(0xFF1A2040),
                        iconColor: AppTheme.textSecondary,
                        title: 'แชร์แอพ',
                        subtitle: 'แนะนำ FuelTH ให้เพื่อน',
                        onTap: () => launchUrl(
                            Uri.parse('https://play.google.com/store')),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'FuelTH v1.0.0 • Made with ❤️ in Thailand\nข้อมูลราคาจาก Thai Oil API • แผนที่จาก OSM',
                        style:
                            TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.background,
      expandedHeight: 90,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D1B4B), AppTheme.background],
            ),
          ),
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 44, 20, 12),
          child: const Align(
            alignment: Alignment.bottomLeft,
            child: Text('ตั้งค่า',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.3)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Container(height: 0.5, color: AppTheme.border),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  static String _fuelLabel(String type) {
    const map = {
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
    return map[type] ?? type;
  }
}

// ── Tile Widgets ──────────────────────────────────────────────────────────────
class _BaseTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _BaseTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary),
                      maxLines: 2),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _SelectTile<T> extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle, displayValue;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _SelectTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(displayValue,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            final isSelected = item.value == value;
            return InkWell(
              onTap: () {
                onChanged(item.value);
                Navigator.pop(context);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: DefaultTextStyle(
                        style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400),
                        child: item.child,
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.primary, size: 18),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing!,
          const SizedBox(width: 4),
          const Icon(Icons.open_in_new_rounded,
              size: 13, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final Widget? trailing;

  const _InfoTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
    );
  }
}
