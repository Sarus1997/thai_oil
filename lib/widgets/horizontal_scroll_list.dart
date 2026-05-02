import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget ที่ wrap horizontal scroll พร้อม gradient fade ขอบซ้าย-ขวา
/// และ scroll indicator ให้รู้ว่า scroll ได้
class HorizontalScrollList extends StatefulWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  final double height;
  final double fadeWidth;

  const HorizontalScrollList({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.height = 40,
    this.fadeWidth = 20,
  });

  @override
  State<HorizontalScrollList> createState() => _HorizontalScrollListState();
}

class _HorizontalScrollListState extends State<HorizontalScrollList> {
  final ScrollController _ctrl = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  void _onScroll() => _checkScroll();

  void _checkScroll() {
    if (!_ctrl.hasClients) return;
    setState(() {
      _canScrollLeft = _ctrl.offset > 4;
      _canScrollRight = _ctrl.offset < _ctrl.position.maxScrollExtent - 4;
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // ── Scroll list ──────────────────────────────────────────────
          ListView(
            controller: _ctrl,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: widget.padding,
            children: widget.children,
          ),
          // ── Left fade ───────────────────────────────────────────────
          if (_canScrollLeft)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: widget.fadeWidth,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppTheme.background,
                        AppTheme.background.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // ── Right fade ──────────────────────────────────────────────
          if (_canScrollRight)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: widget.fadeWidth,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        AppTheme.background,
                        AppTheme.background.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// เหมือนกัน แต่ background เป็นสี surface (ใช้ใน nearby screen)
class HorizontalScrollListSurface extends StatefulWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  final double height;

  const HorizontalScrollListSurface({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.height = 36,
  });

  @override
  State<HorizontalScrollListSurface> createState() =>
      _HorizontalScrollListSurfaceState();
}

class _HorizontalScrollListSurfaceState
    extends State<HorizontalScrollListSurface> {
  final ScrollController _ctrl = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!_ctrl.hasClients) return;
    setState(() {
      _canScrollLeft = _ctrl.offset > 4;
      _canScrollRight = _ctrl.offset < _ctrl.position.maxScrollExtent - 4;
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_check);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = AppTheme.background;
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          ListView(
            controller: _ctrl,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: widget.padding,
            children: widget.children,
          ),
          if (_canScrollLeft)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 24,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [bg, Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),
          if (_canScrollRight)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 24,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [bg, Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
