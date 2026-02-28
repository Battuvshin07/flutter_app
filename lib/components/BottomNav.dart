import 'package:flutter/material.dart';
import '../screens/persons_screen.dart';
import '../screens/history_journey_screen.dart';
import '../screens/map_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/culture_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.account_balance, label: 'Хүмүүс'),
    _NavItem(icon: Icons.event_note, label: 'Үйл явдал'),
    _NavItem(icon: Icons.map_outlined, label: 'Газрын зураг'),
    _NavItem(icon: Icons.quiz_outlined, label: 'Quiz'),
    _NavItem(icon: Icons.museum_outlined, label: 'Соёл'),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    Widget? screen;
    switch (index) {
      case 0:
        screen = const PersonsScreen();
        break;
      case 1:
        screen = const HistoryJourneyScreen();
        break;
      case 2:
        screen = const MapScreen();
        break;
      case 3:
        screen = const QuizScreen();
        break;
      case 4:
        screen = const CultureScreen();
        break;
    }
    if (screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen!),
      ).then((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          _items.length,
          (index) => _buildNavItem(_items[index], index),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFFD94B2B) : Colors.grey.shade500;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
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
