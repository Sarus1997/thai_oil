import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/fuel_model.dart';

// ─── Brand Chip ───────────────────────────────────────────────────────────────
class BrandChip extends StatelessWidget {
  final FuelBrand brand;
  final bool isSelected;
  final VoidCallback onTap;

  const BrandChip({
    super.key,
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: 0.5,
          ),
        ),
        child: Text(
          brand.shortName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Brand Icon Badge ─────────────────────────────────────────────────────────
class BrandIconBadge extends StatelessWidget {
  final String brandId;
  final double size;

  const BrandIconBadge({super.key, required this.brandId, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final config = _brandConfig(brandId);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: config['bg'] as Color,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(
        child: Text(
          config['label'] as String,
          style: TextStyle(
            fontSize: size * 0.28,
            fontWeight: FontWeight.w800,
            color: config['color'] as Color,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _brandConfig(String id) {
    switch (id) {
      case 'shell':
        return {'label': 'SH', 'color': AppTheme.shellColor, 'bg': AppTheme.shellBg};
      case 'bcp':
        return {'label': 'BCP', 'color': AppTheme.bcpColor, 'bg': AppTheme.bcpBg};
      case 'pt':
        return {'label': 'PT', 'color': AppTheme.ptColor, 'bg': AppTheme.ptBg};
      case 'caltex':
        return {'label': 'CAL', 'color': AppTheme.amber, 'bg': AppTheme.amberBg};
      default:
        return {'label': 'PTT', 'color': AppTheme.pttColor, 'bg': AppTheme.pttBg};
    }
  }
}

// ─── Price Change Badge ───────────────────────────────────────────────────────
class PriceChangeBadge extends StatelessWidget {
  final double change;

  const PriceChangeBadge({super.key, required this.change});

  @override
  Widget build(BuildContext context) {
    if (change == 0) {
      return _badge('─ คงที่', AppTheme.textSecondary, AppTheme.surface);
    } else if (change > 0) {
      return _badge('▲ +${change.toStringAsFixed(2)}', AppTheme.red, AppTheme.redBg);
    } else {
      return _badge('▼ ${change.toStringAsFixed(2)}', AppTheme.blue, AppTheme.blueBg);
    }
  }

  Widget _badge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Price Card ───────────────────────────────────────────────────────────────
class FuelPriceCard extends StatelessWidget {
  final FuelPrice price;
  final bool isHighlight;

  const FuelPriceCard({super.key, required this.price, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isHighlight ? AppTheme.cardHighlight : AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight ? AppTheme.primary.withOpacity(0.5) : AppTheme.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            price.typeLabel,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: price.price.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isHighlight ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
                const TextSpan(
                  text: ' ฿/ล.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          PriceChangeBadge(change: price.change),
        ],
      ),
    );
  }
}

// ─── Shimmer Loading Card ─────────────────────────────────────────────────────
class ShimmerCard extends StatefulWidget {
  final double height;
  final double? width;

  const ShimmerCard({super.key, required this.height, this.width});

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment(_animation.value - 1, 0),
            end: Alignment(_animation.value, 0),
            colors: const [AppTheme.surface, Color(0xFF1E2540), AppTheme.surface],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
