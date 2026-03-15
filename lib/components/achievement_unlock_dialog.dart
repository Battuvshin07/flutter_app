import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════
//  ACHIEVEMENT UNLOCK DIALOG - Celebration popup when earned
// ══════════════════════════════════════════════════════════════════

class AchievementUnlockDialog extends StatefulWidget {
  final String title;
  final String imagePath;
  final int expReward;

  const AchievementUnlockDialog({
    super.key,
    required this.title,
    required this.imagePath,
    required this.expReward,
  });

  @override
  State<AchievementUnlockDialog> createState() =>
      _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _particleCtrl;

  // ── Entry animations (staggered via Interval) ─────────────────
  late final Animation<double> _dialogScale;
  late final Animation<double> _dialogFade;
  late final Animation<double> _emojiScale;
  late final Animation<double> _iconScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _expFade;
  late final Animation<double> _btnFade;
  late final Animation<int> _expCount;

  // ── Continuous pulse ──────────────────────────────────────────
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Dialog pop-in
    _dialogScale = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );
    _dialogFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
    );

    // Trophy emoji bounces in first
    _emojiScale = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.15, 0.55, curve: Curves.elasticOut),
    );

    // Achievement icon pops in with elastic
    _iconScale = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.30, 0.70, curve: Curves.elasticOut),
    );

    // Title slides up + fades in
    _titleFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.50, 0.78, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.50, 0.78, curve: Curves.easeOut),
    ));

    // EXP badge
    _expFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.62, 0.85, curve: Curves.easeOut),
    );
    _expCount = IntTween(begin: 0, end: widget.expReward).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.62, 1.0, curve: Curves.easeOut),
      ),
    );

    // Button fades in last
    _btnFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );

    // Continuous glow pulse (0.15 → 0.55 alpha)
    _pulse = Tween<double>(begin: 0.15, end: 0.55).animate(_pulseCtrl);

    _entryCtrl.forward();

    // Particles burst slightly after dialog appears
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _particleCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entryCtrl, _pulseCtrl, _particleCtrl]),
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // ── Sparkle particles ────────────────────────────────
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SparklesParticlePainter(
                      progress: _particleCtrl.value,
                    ),
                  ),
                ),
              ),

              // ── Main card ────────────────────────────────────────
              ScaleTransition(
                scale: _dialogScale,
                child: FadeTransition(
                  opacity: _dialogFade,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1C2840), AppTheme.surface],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: AppTheme.accentGold
                            .withValues(alpha: 0.3 + _pulse.value * 0.25),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold
                              .withValues(alpha: _pulse.value * 0.7),
                          blurRadius: 48,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy emoji
                        ScaleTransition(
                          scale: _emojiScale,
                          child: const Text(
                            '🏆',
                            style: TextStyle(fontSize: 52),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // "АМЖИЛТ НЭЭГДЛЭЭ!" label
                        FadeTransition(
                          opacity: _emojiScale,
                          child: Text(
                            'АМЖИЛТ НЭЭГДЛЭЭ!',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.accentGold,
                              fontSize: 11,
                              letterSpacing: 2.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Achievement image with pulsing glow
                        ScaleTransition(
                          scale: _iconScale,
                          child: Container(
                            width: 124,
                            height: 124,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.accentGold.withValues(
                                    alpha: 0.4 + _pulse.value * 0.45),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentGold
                                      .withValues(alpha: _pulse.value * 0.9),
                                  blurRadius: 20 + _pulse.value * 20,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: const Color(0xFFFFD700)
                                      .withValues(alpha: _pulse.value * 0.3),
                                  blurRadius: 60,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(62),
                              child: Image.asset(
                                widget.imagePath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Title
                        SlideTransition(
                          position: _titleSlide,
                          child: FadeTransition(
                            opacity: _titleFade,
                            child: Text(
                              'Та "${widget.title}" боллоо!',
                              style: AppTheme.h2.copyWith(fontSize: 20),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // XP badge with counting animation
                        FadeTransition(
                          opacity: _expFade,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.accentGold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color:
                                    AppTheme.accentGold.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('⭐', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  '+${_expCount.value} EXP',
                                  style: AppTheme.captionBold.copyWith(
                                    color: AppTheme.accentGold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),

                        // Close button
                        FadeTransition(
                          opacity: _btnFade,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.accentGold,
                                    Color(0xFFFFE08A),
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentGold
                                        .withValues(alpha: 0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Баярлалаа!',
                                style: AppTheme.button.copyWith(
                                  color: AppTheme.background,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Sparkle particle painter ──────────────────────────────────────

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final bool isGold;
  final double delay;

  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.isGold,
    required this.delay,
  });
}

class _SparklesParticlePainter extends CustomPainter {
  final double progress;

  static final _rng = Random(7);
  static final List<_Particle> _particles = List.generate(32, (i) {
    final base = (i / 32) * 2 * pi;
    return _Particle(
      angle: base + _rng.nextDouble() * 0.5,
      speed: 70 + _rng.nextDouble() * 130,
      size: 3.0 + _rng.nextDouble() * 5.5,
      isGold: _rng.nextDouble() > 0.35,
      delay: _rng.nextDouble() * 0.25,
    );
  });

  const _SparklesParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in _particles) {
      final t = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final eased = Curves.easeOut.transform(t);
      final dist = eased * p.speed;
      final opacity = (1.0 - t * t).clamp(0.0, 1.0);

      final pos = Offset(
        center.dx + cos(p.angle) * dist,
        center.dy + sin(p.angle) * dist - eased * 24,
      );

      final color = (p.isGold ? AppTheme.accentGold : Colors.white)
          .withValues(alpha: opacity * 0.9);

      _drawStar(canvas, pos, p.size * (1 - t * 0.25), color);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const points = 4;
    final innerR = r * 0.38;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2;
      final radius = i.isEven ? r : innerR;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklesParticlePainter old) => old.progress != progress;
}
