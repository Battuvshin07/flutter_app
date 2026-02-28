import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'glass_card.dart';

// ══════════════════════════════════════════════════════════════════
//  Admin Section Header
//  Section title with optional trailing widget (chevron, toggle, etc.)
// ══════════════════════════════════════════════════════════════════

class AdminSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.accentGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: AppTheme.sectionTitle),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTap,
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Content Management Action Card
//  Square card with icon, title, subtitle for admin actions
// ══════════════════════════════════════════════════════════════════

class AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;

  const AdminActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.accentGold;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: AppTheme.cardBorder.withOpacity(0.4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTheme.captionBold.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: AppTheme.caption.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  User Management List Tile
//  Shows avatar, name, level, role badge, action buttons
// ══════════════════════════════════════════════════════════════════

class AdminUserTile extends StatelessWidget {
  final String name;
  final String level;
  final String role;
  final String? avatarAsset;
  final bool isSuspended;
  final VoidCallback? onSuspend;
  final VoidCallback? onDelete;

  const AdminUserTile({
    super.key,
    required this.name,
    required this.level,
    required this.role,
    this.avatarAsset,
    this.isSuspended = false,
    this.onSuspend,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = role.toLowerCase() == 'admin';
    final roleColor = isAdmin ? AppTheme.accentGold : const Color(0xFF60A5FA);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 10),
      opacity: 0.45,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withOpacity(0.5), width: 2),
              color: AppTheme.surfaceLight,
            ),
            child: ClipOval(
              child: avatarAsset != null
                  ? Image.asset(
                      avatarAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        color: AppTheme.textSecondary,
                        size: 22,
                      ),
                    )
                  : Icon(
                      Icons.person_rounded,
                      color: AppTheme.textSecondary,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + Level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.captionBold.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  level,
                  style: AppTheme.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),

          // Level badge
          _Badge(
            text: level,
            color: AppTheme.xpGreen,
          ),
          const SizedBox(width: 6),

          // Role badge
          _Badge(
            text: role,
            color: roleColor,
          ),
          const SizedBox(width: 10),

          // Suspend button
          _ActionButton(
            label: isSuspended ? 'Activate' : 'Suspend',
            color: isSuspended ? AppTheme.xpGreen : AppTheme.streakOrange,
            onTap: onSuspend,
          ),
          const SizedBox(width: 6),

          // Delete button
          _ActionButton(
            label: 'Delete',
            color: AppTheme.crimson,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Small badge widget ─────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTheme.chip.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

// ── Small action button ─────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(
          label,
          style: AppTheme.chip.copyWith(color: color, fontSize: 10),
        ),
      ),
    );
  }
}
