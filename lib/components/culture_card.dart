import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dribbble-level culture topic card with icon illustration,
/// title, subtitle, animated progress bar, and lock/complete state.
class CultureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final double progress;
  final bool isCompleted;
  final String? coverImageUrl;
  final VoidCallback? onTap;

  const CultureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.progress = 0.0,
    this.isCompleted = false,
    this.coverImageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCompleted
                  ? accentColor.withOpacity(0.45)
                  : AppTheme.cardBorder.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              if (isCompleted)
                BoxShadow(
                  color: accentColor.withOpacity(0.12),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildImageArea(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTheme.sectionTitle.copyWith(
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTheme.caption.copyWith(height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRightIndicator(),
                  ],
                ),
                ...[
                  const SizedBox(height: 12),
                  _buildProgressRow(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    final hasImage = coverImageUrl != null && coverImageUrl!.trim().isNotEmpty;
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withOpacity(0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: hasImage
            ? Image.network(
                coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _iconFallback(),
              )
            : _iconFallback(),
      ),
    );
  }

  Widget _iconFallback() {
    return Container(
      color: accentColor.withOpacity(0.12),
      child: Icon(icon, color: accentColor, size: 28),
    );
  }

  Widget _buildRightIndicator() {
    if (isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.xpGreen.withOpacity(0.15),
          border: Border.all(color: AppTheme.xpGreen.withOpacity(0.35)),
        ),
        child:
            const Icon(Icons.check_rounded, color: AppTheme.xpGreen, size: 18),
      );
    }
    return Icon(
      Icons.chevron_right_rounded,
      color: AppTheme.textSecondary.withOpacity(0.5),
      size: 22,
    );
  }

  Widget _buildProgressRow() {
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$pct%',
          style: AppTheme.caption.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
