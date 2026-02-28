import 'dart:ui';
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
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            if (glowIntensity > 0)
              BoxShadow(
                color: glow.withOpacity(glowIntensity.clamp(0.0, 1.0)),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blurAmount,
              sigmaY: blurAmount,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.75),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: AppTheme.cardBorder.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
