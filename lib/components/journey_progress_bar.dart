import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Thin rounded progress bar for the journey header.
/// Shows completed / total with gold fill and subtle track.
class JourneyProgressBar extends StatelessWidget {
  final int completed;
  final int total;
  final double height;

  const JourneyProgressBar({
    super.key,
    required this.completed,
    required this.total,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$completed/$total',
            style: AppTheme.captionBold.copyWith(
              color: AppTheme.accentGold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              color: AppTheme.surfaceLight,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    color: AppTheme.accentGold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
