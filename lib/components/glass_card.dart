import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable glassmorphism card with dark surface, subtle border,
/// optional glow, and frosted-glass blur effect.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? glowColor;
  final double glowIntensity;
  final double blurAmount;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = AppTheme.radiusLg,
    this.glowColor,
    this.glowIntensity = 0.0,
    this.blurAmount = 12.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glow = glowColor ?? AppTheme.accentGold;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppTheme.cardBorder.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            if (glowIntensity > 0)
              BoxShadow(
                color: glow.withValues(alpha: glowIntensity.clamp(0.0, 1.0)),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
