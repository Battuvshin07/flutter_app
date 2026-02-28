import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Gamified answer button for quiz screens.
/// Shows letter circle (A/B/C/D), gold border on select,
/// green glow for correct, crimson for wrong after reveal.
class QuizAnswerButton extends StatelessWidget {
  final String text;
  final int index; // 0-3 → A-D
  final bool isSelected;
  final bool isRevealed; // answers revealed
  final bool isCorrect; // this option is the right answer
  final VoidCallback? onTap;

  const QuizAnswerButton({
    super.key,
    required this.text,
    required this.index,
    this.isSelected = false,
    this.isRevealed = false,
    this.isCorrect = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colours based on state
    Color borderColor = AppTheme.cardBorder;
    Color bgColor = AppTheme.surface.withOpacity(0.6);
    Color letterBg = AppTheme.surfaceLight;
    Color letterFg = AppTheme.textSecondary;
    Color textColor = AppTheme.textPrimary;
    IconData? trailingIcon;

    if (isRevealed) {
      if (isCorrect) {
        // Correct answer – green
        borderColor = AppTheme.xpGreen;
        bgColor = AppTheme.xpGreen.withOpacity(0.12);
        letterBg = AppTheme.xpGreen.withOpacity(0.25);
        letterFg = AppTheme.xpGreen;
        textColor = AppTheme.xpGreen;
        trailingIcon = Icons.check_circle_rounded;
      } else if (isSelected) {
        // Selected but wrong – crimson
        borderColor = AppTheme.crimson;
        bgColor = AppTheme.crimson.withOpacity(0.12);
        letterBg = AppTheme.crimson.withOpacity(0.25);
        letterFg = AppTheme.crimson;
        textColor = AppTheme.crimson;
        trailingIcon = Icons.cancel_rounded;
      }
    } else if (isSelected) {
      // Pre-reveal selected – gold accent
      borderColor = AppTheme.accentGold;
      letterBg = AppTheme.accentGold.withOpacity(0.2);
      letterFg = AppTheme.accentGold;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            if (isRevealed && isCorrect)
              BoxShadow(
                color: AppTheme.xpGreen.withOpacity(0.25),
                blurRadius: 12,
              ),
            if (isRevealed && isSelected && !isCorrect)
              BoxShadow(
                color: AppTheme.crimson.withOpacity(0.2),
                blurRadius: 12,
              ),
          ],
        ),
        child: Row(
          children: [
            // Letter circle
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: letterBg,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: AppTheme.captionBold.copyWith(
                    color: letterFg,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTheme.body.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: textColor, size: 22),
          ],
        ),
      ),
    );
  }
}
