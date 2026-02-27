import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/culture_screen.dart';

/// F) Featured list – section title + list item cards 358×72.
class FeaturedList extends StatelessWidget {
  const FeaturedList({super.key});

  static const List<_FeaturedItem> _items = [
    _FeaturedItem(
      title: 'Их хааны нэрлэх ёс',
      subtitle: 'Чингис хааны өргөмжлөл',
      emoji: '🏆',
      color: Color(0xFF3D2E1E),
    ),
    _FeaturedItem(
      title: 'Аянга Хаан',
      subtitle: 'Өгөдэй хааны түүх',
      emoji: '⚡',
      color: Color(0xFF1E2D45),
    ),
    _FeaturedItem(
      title: 'Хархорумын нууц',
      subtitle: 'Эзэнт гүрний нийслэл',
      emoji: '🏛️',
      color: Color(0xFF2A1E3D),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Онцлох', style: AppTheme.sectionTitle),
          const SizedBox(height: AppTheme.spacing12),
          ..._items.map((item) => _FeaturedCard(item: item)),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatefulWidget {
  final _FeaturedItem item;
  const _FeaturedCard({required this.item});

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CultureScreen()),
        );
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              // Thumb
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.item.color,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Center(
                  child: Text(
                    widget.item.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Text
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: AppTheme.captionBold.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.subtitle,
                      style: AppTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedItem {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;

  const _FeaturedItem({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
  });
}
