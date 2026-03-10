import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../data/models/culture_model.dart';
import '../screens/culture_list_screen.dart';
import '../screens/culture_detail_screen.dart';

/// G) Featured list – top 3 culture items from AppProvider.
/// Each card navigates to CultureDetailScreen.
/// "Дэлгэрэнгүй" footer navigates to CultureListScreen.
class FeaturedList extends StatelessWidget {
  const FeaturedList({super.key});

  // Matches culture_list_screen.dart mappings
  static const _iconMap = {
    'landscape': Icons.landscape_rounded,
    'shield': Icons.shield_rounded,
    'route': Icons.route_rounded,
    'temple_buddhist': Icons.temple_buddhist_rounded,
    'edit_note': Icons.edit_note_rounded,
    'restaurant': Icons.restaurant_rounded,
  };

  static const _accentPalette = [
    AppTheme.accentGold,
    Color(0xFF64B5F6),
    AppTheme.streakOrange,
    AppTheme.xpGreen,
    AppTheme.crimson,
    Color(0xFFCE93D8),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final all = provider.cultures;
        // Show up to 3 featured culture items
        final featured = all.length > 3 ? all.sublist(0, 3) : all;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Онцлох', style: AppTheme.sectionTitle),
                  const Spacer(),
                  Text(
                    'Соёл ба Нийгэм',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              if (featured.isEmpty)
                Center(
                  child:
                      Text('Соёлын мэдээлэл олдсонгүй', style: AppTheme.body),
                )
              else
                ...featured.asMap().entries.map((e) {
                  final index = e.key;
                  final item = e.value;
                  final accent = _accentPalette[index % _accentPalette.length];
                  final icon =
                      _iconMap[item.icon] ?? Icons.info_outline_rounded;
                  return _FeaturedCultureCard(
                    item: item,
                    accentColor: accent,
                    icon: icon,
                  );
                }),
              const SizedBox(height: 4),
              // ── "Дэлгэрэнгүй" footer button ──────────────────
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CultureListScreen()),
                ),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.accentGold.withOpacity(0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Дэлгэрэнгүй үзэх',
                        style: AppTheme.chip.copyWith(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          color: AppTheme.accentGold, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Individual culture card ────────────────────────────────────────
class _FeaturedCultureCard extends StatefulWidget {
  final CultureModel item;
  final Color accentColor;
  final IconData icon;

  const _FeaturedCultureCard({
    required this.item,
    required this.accentColor,
    required this.icon,
  });

  @override
  State<_FeaturedCultureCard> createState() => _FeaturedCultureCardState();
}

class _FeaturedCultureCardState extends State<_FeaturedCultureCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final title = widget.item.title;
    final subtitle = widget.item.description;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CultureDetailScreen(
              item: widget.item,
              accentColor: widget.accentColor,
              icon: widget.icon,
            ),
          ),
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
              // Image / icon thumb
              _buildThumb(widget.item, widget.accentColor, widget.icon),
              const SizedBox(width: 12),
              // Text
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.captionBold.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumb(CultureModel item, Color accent, IconData icon) {
    final hasImage =
        item.coverImageUrl != null && item.coverImageUrl!.trim().isNotEmpty;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm - 1),
        child: hasImage
            ? Image.network(
                item.coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(icon, color: accent, size: 24),
              )
            : Icon(icon, color: accent, size: 24),
      ),
    );
  }
}
