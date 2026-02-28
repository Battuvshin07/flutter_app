import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated neon-glow progress bar used for quiz progress,
/// skill meters, and other gamified indicators.
class NeonProgressBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final double height;
  final Color? barColor;
  final Color? trackColor;
  final bool showGlow;

  const NeonProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.barColor,
    this.trackColor,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = barColor ?? AppTheme.accentGold;
    final track = trackColor ?? AppTheme.surfaceLight;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        color: track,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth * progress.clamp(0.0, 1.0);
          return Stack(
            children: [
              // Glow layer
              if (showGlow && barWidth > 0)
                Positioned(
                  left: 0,
                  top: -2,
                  bottom: -2,
                  width: barWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.55),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              // Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                width: barWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.75),
                    ],
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
