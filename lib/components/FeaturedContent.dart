import 'package:flutter/material.dart';
import '../screens/culture_screen.dart';

class FeaturedContent extends StatelessWidget {
  const FeaturedContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Онцлох түүхүүд',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeaturedCard(
            context,
            title: 'Монголын эзэнт гүрний үүсэл',
            description: 'Чингис хаан нүүдэлчин овгуудыг нэгтгэсэн түүх',
            imageColor: Colors.red.shade400,
            icon: Icons.workspace_premium,
          ),
          const SizedBox(height: 12),
          _buildFeaturedCard(
            context,
            title: 'Монголын цэргийн тактик',
            description: 'Дэлхийг байлдан дагуулсан хувьсгалт стратеги',
            imageColor: Colors.indigo.shade400,
            icon: Icons.shield,
          ),
          const SizedBox(height: 12),
          _buildFeaturedCard(
            context,
            title: 'Нүүдлийн амьдрал',
            description: 'Нүүдэлчин дайчдын өдөр тутмын амьдрал ба соёл',
            imageColor: Colors.teal.shade400,
            icon: Icons.landscape,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color imageColor,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CultureScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: imageColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
