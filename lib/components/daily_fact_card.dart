import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// C) Daily Fact swipe card – PageView + dot indicator
/// Card 358×84, radius 16, icon circle 32, text, "+10 XP" pill.
class DailyFactCard extends StatefulWidget {
  const DailyFactCard({super.key});

  @override
  State<DailyFactCard> createState() => _DailyFactCardState();
}

class _DailyFactCardState extends State<DailyFactCard> {
  final PageController _controller = PageController();
  int _current = 0;

  static const List<_Fact> _facts = [
    _Fact(
      text:
          'Монголын эзэнт гүрэн бол түүхэн дэх хамгийн ТОМ тасралтгүй газар нутагтай эзэнт гүрэн — Солонгосоос Европ хүртэл тэлсэн!',
      emoji: '🌍',
      xp: 10,
    ),
    _Fact(
      text:
          'Чингис хаан олон улсын шуудангийн анхны системийг бүтээсэн — "Örtöö" буюу Өртөө.',
      emoji: '📮',
      xp: 10,
    ),
    _Fact(
      text:
          'Монголчууд хүйтэн, хуурай уур амьсгалд хадгалагдах "бортог" хэмээх хуурай махыг зохион бүтээсэн.',
      emoji: '🥩',
      xp: 10,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section title ──
          Row(
            children: [
              Text('Өдрийн баримт', style: AppTheme.sectionTitle),
              const Spacer(),
              // Dots indicator
              Row(
                children: List.generate(
                  _facts.length,
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
            child: PageView.builder(
              controller: _controller,
              itemCount: _facts.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, i) => _buildFactCard(_facts[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactCard(_Fact fact) {
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
              color: AppTheme.accentGold.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(fact.emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          // Text
          Expanded(
            child: Text(
              fact.text,
              style: AppTheme.caption.copyWith(
                color: AppTheme.textPrimary,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // XP pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.xpGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              '+${fact.xp} XP',
              style: AppTheme.chip.copyWith(
                color: AppTheme.xpGreen,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact {
  final String text;
  final String emoji;
  final int xp;
  const _Fact({required this.text, required this.emoji, required this.xp});
}
