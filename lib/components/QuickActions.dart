import 'package:flutter/material.dart';
import '../screens/persons_screen.dart';
import '../screens/history_journey_screen.dart';
import '../screens/map_screen.dart';
import '../screens/quiz_screen.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionCard(
            label: 'Хүмүүс',
            imagePath: 'assets/images/logo_1.png',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PersonsScreen(),
                ),
              );
            },
          ),
          _buildActionCard(
            label: 'Үйл явдал',
            imagePath: 'assets/images/logo_2.png',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryJourneyScreen(),
                ),
              );
            },
          ),
          _buildActionCard(
            label: 'Газрын зураг',
            imagePath: 'assets/images/logo_3.png',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapScreen(),
                ),
              );
            },
          ),
          _buildActionCard(
            label: 'Quiz',
            imagePath: 'assets/images/logo_4.png',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuizScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String label,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF0),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                imagePath,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3B2F2F),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
