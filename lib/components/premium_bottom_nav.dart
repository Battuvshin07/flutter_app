import 'package:flutter/material.dart';
import 'dart:math' as math;

class PremiumBottomNav extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<NavItem> items;
  final Color activeColor;
  final Color inactiveColor;
  final Color navbarColor;

  const PremiumBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.items,
    this.activeColor = const Color(0xFFFF9500),
    this.inactiveColor = const Color(0xFF8E8E93),
    this.navbarColor = const Color(0xFF1C1C1E),
  });

  @override
  State<PremiumBottomNav> createState() => _PremiumBottomNavState();
}

class _PremiumBottomNavState extends State<PremiumBottomNav>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _bounceController;
  double _previousIndex = 0;

  static const double _navHeight = 58.0;
  static const double _buttonSize = 52.0;
  static const double _buttonRise = 16.0; // how high button rises above navbar

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex.toDouble();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(PremiumBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      setState(() => _previousIndex = oldWidget.selectedIndex.toDouble());
      _slideController.forward(from: 0);
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final navWidth = constraints.maxWidth;
        final itemWidth = navWidth / widget.items.length;

        return SizedBox(
          height: _navHeight + _buttonRise,
          child: AnimatedBuilder(
            animation: Listenable.merge([_slideController, _bounceController]),
            builder: (context, _) {
              final slideT = Curves.easeInOutCubic.transform(_slideController.value);
              final pos = _previousIndex +
                  (widget.selectedIndex - _previousIndex) * slideT;

              final bounceT = _bounceController.value;
              final scale = 1.0 + math.sin(bounceT * math.pi) * 0.18;
              final yLift = math.sin(bounceT * math.pi) * 5.0;

              final btnX = pos * itemWidth + itemWidth / 2 - _buttonSize / 2;
              final btnY = _buttonRise - yLift;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Navbar body with notch ──
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _navHeight,
                    child: CustomPaint(
                      painter: _NavbarPainter(
                        notchCenterX: pos * itemWidth + itemWidth / 2,
                        color: widget.navbarColor,
                      ),
                      child: Row(
                        children: List.generate(
                          widget.items.length,
                          (i) => _buildItem(i, itemWidth),
                        ),
                      ),
                    ),
                  ),

                  // ── Floating active button ──
                  Positioned(
                    left: btnX,
                    top: btnY - 4,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: _buttonSize,
                        height: _buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.activeColor,
                              widget.activeColor.withValues(alpha: 0.75),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.activeColor.withValues(alpha: 0.45),
                              blurRadius: 18,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.items[widget.selectedIndex].icon,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildItem(int index, double itemWidth) {
    final isActive = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () => widget.onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _navHeight,
        width: itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: isActive ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.items[index].icon,
                color: widget.inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? widget.activeColor : widget.inactiveColor,
              ),
              child: Text(widget.items[index].label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavbarPainter extends CustomPainter {
  final double notchCenterX;
  final Color color;

  static const double _notchRadius = 36.0;
  static const double _cornerRadius = 22.0;

  _NavbarPainter({required this.notchCenterX, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // ── Smooth notch path ──
    final path = Path();

    // Top-left corner
    path.moveTo(0, _cornerRadius);
    path.arcToPoint(
      Offset(_cornerRadius, 0),
      radius: const Radius.circular(_cornerRadius),
    );

    // Left of notch
    final notchLeft = notchCenterX - _notchRadius;
    path.lineTo(math.max(_cornerRadius, notchLeft - _notchRadius * 0.4), 0);

    // Smooth entry curve into notch
    path.cubicTo(
      notchLeft - _notchRadius * 0.1, 0,
      notchLeft, _notchRadius * 0.6,
      notchCenterX - _notchRadius * 0.6, _notchRadius * 0.95,
    );

    // Bottom of notch (arc)
    path.arcToPoint(
      Offset(notchCenterX + _notchRadius * 0.6, _notchRadius * 0.95),
      radius: const Radius.circular(_notchRadius * 1.05),
      clockwise: false,
    );

    // Smooth exit curve out of notch
    final notchRight = notchCenterX + _notchRadius;
    path.cubicTo(
      notchRight, _notchRadius * 0.6,
      notchRight + _notchRadius * 0.1, 0,
      math.min(size.width - _cornerRadius, notchRight + _notchRadius * 0.4), 0,
    );

    // Top-right corner
    path.lineTo(size.width - _cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width, _cornerRadius),
      radius: const Radius.circular(_cornerRadius),
    );

    // Right, bottom, left sides
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, _cornerRadius);
    path.close();

    // Shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.4), 12, false);

    // Fill
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_NavbarPainter old) =>
      old.notchCenterX != notchCenterX || old.color != color;
}

class NavItem {
  final IconData icon;
  final String label;
  const NavItem({required this.icon, required this.label});
}
