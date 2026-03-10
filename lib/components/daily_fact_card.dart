import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/models/culture_model.dart';
import '../services/culture_service.dart';

/// C) Daily Fact swipe card – PageView + dot indicator
/// Randomly picks 3 cultures daily (seed = YYYYMMDD) from Firestore.
class DailyFactCard extends StatefulWidget {
  const DailyFactCard({super.key});

  @override
  State<DailyFactCard> createState() => _DailyFactCardState();
}

class _DailyFactCardState extends State<DailyFactCard> {
  final PageController _controller = PageController();
  int _current = 0;
  late final Future<List<CultureModel>> _cultureFuture;

  // Material icon name → emoji fallback for the circular badge
  static const _emojiMap = {
    'landscape': '🏕️',
    'shield': '⚔️',
    'route': '🛤️',
    'temple_buddhist': '🕌',
    'edit_note': '📜',
    'local_dining': '🍖',
  };

  @override
  void initState() {
    super.initState();
    _cultureFuture = CultureService().getCultures();
  }

  /// Picks 3 cultures deterministically for today using a date-based seed.
  List<CultureModel> _pickDailyThree(List<CultureModel> all) {
    if (all.isEmpty) return [];
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final shuffled = List<CultureModel>.from(all)..shuffle(Random(seed));
    return shuffled.take(3).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CultureModel>>(
      future: _cultureFuture,
      builder: (context, snapshot) {
        final facts = snapshot.hasData && snapshot.data!.isNotEmpty
            ? _pickDailyThree(snapshot.data!)
            : <CultureModel>[];
        final count = facts.isEmpty ? 3 : facts.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section title + dots ──
              Row(
                children: [
                  Text('Өдрийн баримт', style: AppTheme.sectionTitle),
                  const Spacer(),
                  Row(
                    children: List.generate(
                      count,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: _current == i ? 16 : 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: _current == i
                              ? AppTheme.accentGold
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),

              // ── PageView cards ──
              SizedBox(
                height: 84,
                child: facts.isEmpty
                    ? _buildShimmerCard()
                    : PageView.builder(
                        controller: _controller,
                        itemCount: facts.length,
                        onPageChanged: (i) => setState(() => _current = i),
                        itemBuilder: (_, i) => _buildFactCard(facts[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Placeholder shown while cultures are loading.
  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactCard(CultureModel culture) {
    final emoji = _emojiMap[culture.icon ?? ''] ?? '🌍';
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          // Emoji circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          // Culture description
          Expanded(
            child: Text(
              culture.description,
              style: AppTheme.caption.copyWith(
                color: AppTheme.textPrimary,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
