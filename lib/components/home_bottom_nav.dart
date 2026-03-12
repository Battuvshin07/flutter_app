import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/history_journey_screen.dart';
import '../screens/map_screen.dart';
import '../screens/persons_screen.dart';
import '../screens/profile_screen.dart';

/// G) Floating bottom navigation bar
/// 358×64, radius 22, blur/glass effect, 4 items, active underline 24×3.
class HomeBottomNav extends StatefulWidget {
  const HomeBottomNav({super.key});

  @override
  State<HomeBottomNav> createState() => _HomeBottomNavState();
}

class _HomeBottomNavState extends State<HomeBottomNav> {
  int _selected = 0;

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Нүүр'),
    _NavItem(icon: Icons.military_tech_rounded, label: 'Хүмүүс'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Судлах'),
    _NavItem(icon: Icons.public_rounded, label: 'Зураг'),
    _NavItem(icon: Icons.person_rounded, label: 'Профайл'),
  ];

  void _onTap(int index) {
    if (index == _selected) return;
    setState(() => _selected = index);

    Widget? screen;
    switch (index) {
      case 1:
        screen = const PersonsScreen();
        break;
      case 2:
        screen = const HistoryJourneyScreen();
        break;
      case 3:
        screen = const MapScreen();
        break;
      case 4:
        screen = const ProfileScreen();
        break;
    }
    if (screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen!),
      ).then((_) {
        if (mounted) setState(() => _selected = 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.pagePadding,
        right: AppTheme.pagePadding,
        bottom: bottomPad + 8,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _items.length,
              (i) => _buildItem(_items[i], i),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(_NavItem item, int index) {
    final isActive = _selected == index;
    final color = isActive ? AppTheme.accentGold : AppTheme.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(index),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppTheme.chip.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            // Active underline
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 24 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.accentGold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
