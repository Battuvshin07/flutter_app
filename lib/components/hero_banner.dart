import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// B) Hero Banner Card – 358×188, radius 20
/// Background illustration with gradient overlay, title, subtitle, CTA.
class HeroBanner extends StatefulWidget {
  final VoidCallback? onStartExploring;

  const HeroBanner({super.key, this.onStartExploring});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.of(context).size.width - 32; // 16 padding each side
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.97),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: SizedBox(
              width: width,
              height: 188,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/pic_2.png',
                    fit: BoxFit.cover,
                    cacheWidth: 720,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.background.withOpacity(0.85),
                        ],
                        stops: const [0.2, 1.0],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── "NEW" badge ──
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Text(
                            'ШИНЭ: Судлах Түүхүүд',
                            style: AppTheme.chip.copyWith(
                              color: AppTheme.background,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Монголын Эзэнт\nГүрнийг нээ',
                          style:
                              AppTheme.h2.copyWith(fontSize: 20, height: 1.25),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Монголын тал нутгаас дэлхийн хамгийн агуу\nэзэнт гүрэн рүү аялахад бэлэн үү?',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ── CTA ──
                        GestureDetector(
                          onTap: widget.onStartExploring,
                          child: Container(
                            width: 140,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.textPrimary,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: Center(
                              child: Text(
                                'Судалж эхлэх',
                                style: AppTheme.button.copyWith(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
