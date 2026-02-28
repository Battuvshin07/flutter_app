import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';
import 'auth_gate.dart';

// ══════════════════════════════════════════════════════════════════
//  PROFILE SCREEN – gamified user profile for Mongolian history app
// ══════════════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _accuracyController;
  late final Animation<double> _xpAnimation;
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _accuracyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _xpAnimation = Tween<double>(begin: 0.0, end: 0.68).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward();
    _accuracyController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _accuracyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F1A2E),
              AppTheme.background,
              Color(0xFF0A0F1A),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildAppBar(),
                const SizedBox(height: 20),
                _buildAvatarSection(),
                const SizedBox(height: 24),
                _buildStatsRow(),
                const SizedBox(height: 28),
                _buildAchievementsSection(),
                const SizedBox(height: 28),
                _buildStudyProgressSection(),
                const SizedBox(height: 28),
                _buildFriendsSection(),
                const SizedBox(height: 28),
                _buildSettingsSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary,
                size: 18,
              ),
            ),
          ),
          const Spacer(),
          Text('Профайл', style: AppTheme.sectionTitle),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: AppTheme.textSecondary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar + Name + Level ────────────────────────────────────────
  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentGold, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/pic_2.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.surfaceLight,
                    child: const Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accentGold,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                'Level 12',
                style: AppTheme.chip.copyWith(
                  color: AppTheme.background,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Хаятар', style: AppTheme.h2),
        const SizedBox(height: 4),
        Text(
          '#F4C84A',
          style: AppTheme.caption.copyWith(color: AppTheme.accentGold),
        ),
        const SizedBox(height: 14),
        _buildXpProgressBar(),
      ],
    );
  }

  Widget _buildXpProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '18,400 XP',
                style: AppTheme.chip.copyWith(color: AppTheme.xpGreen),
              ),
              Text(
                '68%',
                style: AppTheme.chip.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _xpAnimation,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _xpAnimation.value,
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceLight,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              icon: '🪙',
              label: '2450',
              suffix: 'XP',
              color: AppTheme.accentGold,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _StatChip(
              icon: '💎',
              label: '18,400',
              suffix: 'XP',
              color: AppTheme.xpGreen,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _StatChip(
              icon: '🛡️',
              label: '7 days',
              suffix: '+',
              color: AppTheme.streakOrange,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _StatChip(
              icon: '⭐',
              label: '#23',
              suffix: 'ланк',
              color: AppTheme.accentGold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Achievements ─────────────────────────────────────────────────
  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
          child: Text('Achievements', style: AppTheme.sectionTitle),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.pagePadding,
            ),
            children: const [
              _AchievementCard(
                icon: Icons.emoji_events_rounded,
                color: Color(0xFFFFD700),
                title: 'Алтан цом',
              ),
              SizedBox(width: 12),
              _AchievementCard(
                icon: Icons.shield_rounded,
                color: Color(0xFF4ADE80),
                title: 'Хамгаалагч',
              ),
              SizedBox(width: 12),
              _AchievementCard(
                icon: Icons.military_tech_rounded,
                color: Color(0xFF60A5FA),
                title: 'Медаль',
              ),
              SizedBox(width: 12),
              _AchievementCard(
                icon: Icons.auto_awesome_rounded,
                color: Color(0xFFF472B6),
                title: 'Од',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Study Progress ───────────────────────────────────────────────
  Widget _buildStudyProgressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Будалсан сүэдвүэд', style: AppTheme.sectionTitle),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _AnimatedProgressRow(
                      label: 'Хүмүүс',
                      value: 0.85,
                      color: AppTheme.accentGold,
                      controller: _progressController,
                    ),
                    const SizedBox(height: 14),
                    _AnimatedProgressRow(
                      label: 'Тулаан',
                      value: 0.60,
                      color: AppTheme.accentGold,
                      controller: _progressController,
                    ),
                    const SizedBox(height: 14),
                    _AnimatedProgressRow(
                      label: 'Газрын зураг',
                      value: 0.92,
                      color: AppTheme.accentGold,
                      controller: _progressController,
                    ),
                    const SizedBox(height: 18),
                    _buildStreakBadge(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _AccuracyGauge(controller: _accuracyController),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF4C84A), Color(0xFFFFE08A)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            '7-day streik!',
            style: AppTheme.captionBold.copyWith(
              color: AppTheme.background,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Friends ──────────────────────────────────────────────────────
  Widget _buildFriendsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
          child: Row(
            children: [
              Text('Габууд', style: AppTheme.sectionTitle),
              const Spacer(),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 70,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.pagePadding,
            ),
            children: const [
              _FriendCard(
                name: 'Хаатар',
                tag: '#F4C84A',
                emoji: '🗡️',
              ),
              SizedBox(width: 10),
              _FriendCard(
                name: 'Хаятар',
                tag: '#F4C84A',
                emoji: '🔥',
              ),
              SizedBox(width: 10),
              _FriendCard(
                name: 'Баатар',
                tag: '#A9B3C9',
                emoji: '⚔️',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Settings ─────────────────────────────────────────────────────
  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Admin Dashboard',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ADMIN',
                style: AppTheme.chip.copyWith(
                  color: AppTheme.accentGold,
                  fontSize: 10,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminDashboardScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.edit_rounded,
            label: 'Edit Profile',
            trailing: Text(
              '#F4C84A',
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            ),
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.language_rounded,
            label: 'Language',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Монгол / English',
                style: AppTheme.chip.copyWith(
                  color: AppTheme.accentGold,
                  fontSize: 10,
                ),
              ),
            ),
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            label: 'Dark Mode',
            trailing: SizedBox(
              height: 28,
              child: Switch(
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
                activeThumbColor: AppTheme.accentGold,
                activeTrackColor: AppTheme.accentGold.withValues(alpha: 0.3),
                inactiveThumbColor: AppTheme.textSecondary,
                inactiveTrackColor: AppTheme.surfaceLight,
              ),
            ),
            onTap: () => setState(() => _darkMode = !_darkMode),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            onTap: () => _showSignOutDialog(),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text('Гарах', style: AppTheme.sectionTitle),
        content: Text(
          'Та гарахдаа итгэлтэй байна уу?',
          style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Үгүй',
              style:
                  AppTheme.captionBold.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Тийм',
              style: AppTheme.captionBold.copyWith(color: AppTheme.crimson),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  REUSABLE SUB-WIDGETS
// ══════════════════════════════════════════════════════════════════

// ── Stat Chip ──────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  final String suffix;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.suffix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label $suffix',
              style: AppTheme.chip.copyWith(color: color, fontSize: 10),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Achievement Card (glassmorphism) ───────────────────────────────
class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _AchievementCard({
    required this.icon,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTheme.chip.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Animated Progress Row ──────────────────────────────────────────
class _AnimatedProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final AnimationController controller;

  const _AnimatedProgressRow({
    required this.label,
    required this.value,
    required this.color,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(begin: 0.0, end: value).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final percent = (animation.value * 100).toInt();
        return Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: AppTheme.caption,
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: animation.value,
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 34,
              child: Text(
                '$percent%',
                style: AppTheme.chip.copyWith(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Accuracy Gauge ─────────────────────────────────────────────────
class _AccuracyGauge extends StatelessWidget {
  final AnimationController controller;

  const _AccuracyGauge({required this.controller});

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final percent = (animation.value * 100).toInt();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [
              Text(
                '$percent%',
                style: AppTheme.h2.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 70,
                height: 70,
                child: CustomPaint(
                  painter: _GaugePainter(
                    progress: animation.value,
                    trackColor: AppTheme.surfaceLight,
                    progressColor: AppTheme.textPrimary,
                    strokeWidth: 6,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.center_focus_strong_rounded,
                      color: AppTheme.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accuracy',
                style: AppTheme.caption.copyWith(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Gauge Painter ──────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _GaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi * 0.75;
    const totalAngle = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalAngle,
      false,
      trackPaint,
    );

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalAngle * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Friend Card ────────────────────────────────────────────────────
class _FriendCard extends StatelessWidget {
  final String name;
  final String tag;
  final String emoji;

  const _FriendCard({
    required this.name,
    required this.tag,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceLight,
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTheme.captionBold.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                tag,
                style: AppTheme.chip.copyWith(
                  color: AppTheme.accentGold,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.accentGold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Найз',
              style: AppTheme.chip.copyWith(
                color: AppTheme.background,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Tile ──────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.accentGold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTheme.captionBold.copyWith(fontSize: 14),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
