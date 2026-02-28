import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/culture_topic_card.dart';

/// FR-07: Соёл, нийгмийн амьдралын мэдээлэл таниулах
/// Dark + gold gamified culture list & detail
class CultureScreen extends StatelessWidget {
  const CultureScreen({super.key});

  static const _iconMap = {
    'landscape': Icons.landscape,
    'shield': Icons.shield,
    'route': Icons.route,
    'temple_buddhist': Icons.temple_buddhist,
    'edit_note': Icons.edit_note,
    'restaurant': Icons.restaurant,
  };

  static const _accentPalette = [
    AppTheme.accentGold,
    Color(0xFF64B5F6), // sky blue
    AppTheme.streakOrange,
    AppTheme.xpGreen,
    AppTheme.crimson,
    Color(0xFFCE93D8), // lavender
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              Color(0xFF0F1A2E),
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    final cultureList = provider.culture;
                    if (cultureList.isEmpty) {
                      return Center(
                        child: Text('Соёлын мэдээлэл олдсонгүй',
                            style: AppTheme.body),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.pagePadding,
                        vertical: 12,
                      ),
                      itemCount: cultureList.length,
                      itemBuilder: (context, index) {
                        final item = cultureList[index];
                        final accent =
                            _accentPalette[index % _accentPalette.length];
                        final icon =
                            _iconMap[item['icon']] ?? Icons.info_outline;
                        return CultureTopicCard(
                          icon: icon,
                          title: item['title'] ?? '',
                          description: item['description'] ?? '',
                          accentColor: accent,
                          onTap: () => _showDetail(context, item, accent, icon),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceLight,
                border: Border.all(
                  color: AppTheme.accentGold.withOpacity(0.35),
                ),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppTheme.accentGold, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Соёл ба нийгэм',
                style: AppTheme.h2.copyWith(fontSize: 19)),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceLight,
            ),
            child: const Icon(Icons.museum_outlined,
                color: AppTheme.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> item,
      Color accent, IconData icon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _CultureDetailScreen(item: item, accent: accent, icon: icon),
      ),
    );
  }
}

// ── Detail screen ───────────────────────────────────────────────────
class _CultureDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color accent;
  final IconData icon;

  const _CultureDetailScreen({
    required this.item,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              Color(0xFF0F1A2E),
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.pagePadding, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surfaceLight,
                          border: Border.all(
                            color: AppTheme.accentGold.withOpacity(0.35),
                          ),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: AppTheme.accentGold, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Дэлгэрэнгүй',
                          style: AppTheme.h2.copyWith(fontSize: 19)),
                    ),
                    const SizedBox(width: 38), // balance
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.pagePadding),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Icon with glow
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(0.12),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.25),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(icon, color: accent, size: 44),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        item['title'] ?? '',
                        style: AppTheme.h2.copyWith(fontSize: 22),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['description'] ?? '',
                        style: AppTheme.body.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Details card
                      GlassCard(
                        glowColor: accent,
                        glowIntensity: 0.06,
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          item['details'] ?? item['description'] ?? '',
                          style: AppTheme.body.copyWith(height: 1.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
