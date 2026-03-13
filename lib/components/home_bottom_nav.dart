import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// G) Floating bottom navigation bar with animated bubble effect
/// Persistent across all 5 routes with animated bubble indicator.
class HomeBottomNav extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const HomeBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<HomeBottomNav> createState() => _HomeBottomNavState();
}

class _HomeBottomNavState extends State<HomeBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _bubbleController;
  late Animation<double> _bubbleAnimation;
  double _bubblePosition = 0.0;

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Нүүр'),
    _NavItem(icon: Icons.military_tech_rounded, label: 'Хүмүүс'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Судлах'),
    _NavItem(icon: Icons.public_rounded, label: 'Зураг'),
    _NavItem(icon: Icons.person_rounded, label: 'Профайл'),
  ];

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _bubbleAnimation = CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeInOutCubic,
    );
    _bubblePosition = widget.selectedIndex.toDouble();
  }

  @override
  void didUpdateWidget(HomeBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animateBubble(widget.selectedIndex);
    }
  }

  void _animateBubble(int newIndex) {
    final oldPosition = _bubblePosition;
    final newPosition = newIndex.toDouble();

    _bubbleController.reset();
    _bubbleAnimation = Tween<double>(
      begin: oldPosition,
      end: newPosition,
    ).animate(CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeInOutCubic,
    ));

    _bubbleController.forward().then((_) {
      setState(() => _bubblePosition = newPosition);
    });
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: AppTheme.pagePadding,
        right: AppTheme.pagePadding,
        bottom: 8,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      height: 64 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Stack(
        children: [
          // Animated bubble indicator
          AnimatedBuilder(
            animation: _bubbleAnimation,
            builder: (context, child) {
              final itemWidth = (MediaQuery.of(context).size.width -
                      (AppTheme.pagePadding * 2)) /
                  _items.length;
              final position = _bubbleAnimation.value * itemWidth;

              return CustomPaint(
                size: Size.infinite,
                painter: _BubblePainter(
                  position: position,
                  itemWidth: itemWidth,
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                ),
              );
            },
          ),
          // Navigation items
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _items.length,
                (i) => _buildItem(_items[i], i),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(_NavItem item, int index) {
    final isActive = widget.selectedIndex == index;
    final color = isActive ? AppTheme.accentGold : AppTheme.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTabSelected(index),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(item.icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppTheme.chip.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for animated bubble effect
class _BubblePainter extends CustomPainter {
  final double position;
  final double itemWidth;
  final Color color;

  _BubblePainter({
    required this.position,
    required this.itemWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw bubble circle
    final center = Offset(position + itemWidth / 2, size.height / 2);
    canvas.drawCircle(center, 28, paint);

    // Draw glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(center, 32, glowPaint);
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) {
    return oldDelegate.position != position || oldDelegate.color != color;
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
