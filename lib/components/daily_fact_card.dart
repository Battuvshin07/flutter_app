import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/models/culture_model.dart';
import '../services/culture_service.dart';

/// Daily Fact expandable card.
/// Home screen → compact preview card.
/// Tap → Hero-animated full-screen detail page.
class DailyFactCard extends StatefulWidget {
  const DailyFactCard({super.key});

  @override
  State<DailyFactCard> createState() => _DailyFactCardState();
}

class _DailyFactCardState extends State<DailyFactCard> {
  late final Future<List<CultureModel>> _cultureFuture;

  @override
  void initState() {
    super.initState();
    _cultureFuture = CultureService().getCultures();
  }

  CultureModel? _pickDaily(List<CultureModel> all) {
    if (all.isEmpty) return null;
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final shuffled = List<CultureModel>.from(all)..shuffle(Random(seed));
    return shuffled.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CultureModel>>(
      future: _cultureFuture,
      builder: (context, snapshot) {
        final culture = snapshot.hasData ? _pickDaily(snapshot.data!) : null;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Өдрийн баримт',
                  style: AppTheme.sectionTitle.copyWith(fontSize: 20)),
              const SizedBox(height: 12),
              culture == null
                  ? _buildShimmer()
                  : _buildPreviewCard(context, culture),
            ],
          ),
        );
      },
    );
  }

  // ── Compact preview card ───────────────────────────────────────
  Widget _buildPreviewCard(BuildContext context, CultureModel culture) {
    final tag = 'daily-fact-${culture.id}';
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: _DailyFactDetailPage(
              culture: culture,
              heroTag: tag,
            ),
          ),
        ),
      ),
      child: Hero(
        tag: tag,
        flightShuttleBuilder: (_, anim, __, ___, ____) => Material(
          color: Colors.transparent,
          child: _CardShell(
            culture: culture,
            preview: true,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: _CardShell(
            culture: culture,
            preview: true,
          ),
        ),
      ),
    );
  }

  // ── Shimmer placeholder ────────────────────────────────────────
  Widget _buildShimmer() {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.surface, AppTheme.surfaceLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 14,
                  width: 110,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared card shell (used both in preview & during Hero flight) ──
class _CardShell extends StatelessWidget {
  final CultureModel culture;
  final bool preview;

  const _CardShell({
    required this.culture,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2740), Color(0xFF0F1C30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  culture.title,
                  style: AppTheme.sectionTitle.copyWith(fontSize: 22),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  culture.description,
                  style: AppTheme.body.copyWith(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: preview ? 2 : null,
                  overflow: preview ? TextOverflow.ellipsis : null,
                ),
              ],
            ),
          ),
          if (preview) ...[
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppTheme.accentGold.withValues(alpha: 0.6)),
          ],
        ],
      ),
    );
  }
}

// ── Full-screen detail page ────────────────────────────────────────
class _DailyFactDetailPage extends StatelessWidget {
  final CultureModel culture;
  final String heroTag;

  const _DailyFactDetailPage({
    required this.culture,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.textPrimary, size: 18),
                ),
              ),
              const SizedBox(height: 24),

              // Hero card (expanded)
              Hero(
                tag: heroTag,
                child: Material(
                  color: Colors.transparent,
                  child: _CardShell(
                    culture: culture,
                    preview: false,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Section label
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Дэлгэрэнгүй', style: AppTheme.sectionTitle),
                ],
              ),
              const SizedBox(height: 14),

              // Full description
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Text(
                  culture.description,
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    height: 1.8,
                  ),
                ),
              ),

              // Extra details if present
              if ((culture.details ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    culture.details!,
                    style: AppTheme.body.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
