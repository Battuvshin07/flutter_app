import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'admin_dashboard_screen.dart';
import 'edit_profile_screen.dart';
import 'auth_gate.dart';
import '../components/admin_gate.dart';

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
  late final Stream<AppUser?> _userStream;
  bool _darkMode = true;

  // Real-time user state
  AppUser? _currentUser;
  List<AppAchievement> _achievements = [];
  bool _achievementsLoaded = false;
  double _xpTarget = 0.0;
  bool _retryFlag = false;

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
    _xpAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _accuracyController.forward();
    _userStream = UserService.watchCurrentUser();
    // Ensure Firestore doc has all required fields
    UserService.ensureUserDocExists();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).loadProfile();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _accuracyController.dispose();
    super.dispose();
  }

  // ── XP / Progress animation helper ──────────────────────────────
  void _animateToUserXP(int totalXP) {
    final target = UserService.levelProgress(totalXP);
    if ((target - _xpTarget).abs() > 0.005) {
      if (!mounted) return;
      setState(() => _xpTarget = target);
      _progressController.forward(from: 0.0);
    }
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
          child: StreamBuilder<AppUser?>(
            stream: _userStream,
            builder: (context, snapshot) {
              // Update cached user + trigger animation on new data
              if (snapshot.hasData && snapshot.data != null) {
                final user = snapshot.data!;
                final xpChanged = _currentUser?.totalXP != user.totalXP;
                _currentUser = user;
                if (xpChanged) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _animateToUserXP(user.totalXP);
                  });
                }
                // Load achievements once
                if (!_achievementsLoaded) {
                  _achievementsLoaded = true;
                  UserService.loadAchievements(user.id).then((list) {
                    if (mounted) setState(() => _achievements = list);
                  });
                }
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  _currentUser == null) {
                return _buildSkeleton();
              }
              if (snapshot.hasError && _currentUser == null) {
                return _buildError('${snapshot.error}');
              }
              return _buildContent();
            },
          ),
        ),
      ),
    );
  }

  // ── Loading Skeleton ─────────────────────────────────────────────
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildAppBar(),
          const SizedBox(height: 32),
          // Avatar skeleton
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceLight,
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _shimmerBox(120, 18),
          const SizedBox(height: 8),
          _shimmerBox(80, 12),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: _shimmerBox(double.infinity, 8),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                    child: _shimmerBox(double.infinity, 52),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _shimmerBox(double.infinity, 120),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // ── Error View ───────────────────────────────────────────────────
  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text('Өгөгдөл ачаалахад алдаа гарлаа',
                style: AppTheme.sectionTitle, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: AppTheme.caption, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => setState(() {
                _achievementsLoaded = false;
                _retryFlag = !_retryFlag;
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentGold, Color(0xFFFFE08A)],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text('Дахин оролдох', style: AppTheme.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Content ────────────────────────────────────────────────
  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
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
          _buildSettingsSection(),
          const SizedBox(height: 20),
        ],
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
    final user = _currentUser;
    final level = UserService.levelFromXP(user?.totalXP ?? 0);
    final displayName = user?.effectiveName ?? 'Хэрэглэгч';
    final photoUrl = user?.photoUrl;
    final initials = user?.initials ?? '?';

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
                child: (photoUrl?.isNotEmpty == true)
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildInitialsAvatar(initials),
                      )
                    : _buildInitialsAvatar(initials),
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
                'Level $level',
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
        Text(displayName, style: AppTheme.h2),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: AppTheme.caption.copyWith(color: AppTheme.accentGold),
        ),
        const SizedBox(height: 14),
        _buildXpProgressBar(),
      ],
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      color: AppTheme.surfaceLight,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTheme.h2.copyWith(
          fontSize: 36,
          color: AppTheme.accentGold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildXpProgressBar() {
    final totalXP = _currentUser?.totalXP ?? 0;
    final progressPct = (_xpTarget * 100).toInt();
    // Format totalXP with thousands separator (e.g. 18,400)
    final xpLabel = totalXP >= 1000
        ? '${(totalXP ~/ 1000)},${(totalXP % 1000).toString().padLeft(3, '0')} XP'
        : '$totalXP XP';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                xpLabel,
                style: AppTheme.chip.copyWith(color: AppTheme.xpGreen),
              ),
              Text(
                '$progressPct%',
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
                  value: (_xpAnimation.value * _xpTarget).clamp(0.0, 1.0),
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
    final user = _currentUser;
    final totalXP = user?.totalXP ?? 0;
    final streakDays = user?.streakDays ?? 0;
    // Format totalXP (e.g. 18,400)
    final totalXPStr = totalXP >= 1000
        ? '${(totalXP ~/ 1000)},${(totalXP % 1000).toString().padLeft(3, '0')}'
        : '$totalXP';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              icon: '🪙',
              label: '0',
              suffix: 'XP/өдөр',
              color: AppTheme.accentGold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatChip(
              icon: '💎',
              label: totalXPStr,
              suffix: 'XP',
              color: AppTheme.xpGreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatChip(
              icon: '🛡️',
              label: '$streakDays өдөр',
              suffix: '+',
              color: AppTheme.streakOrange,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: _StatChip(
              icon: '⭐',
              label: '—',
              suffix: 'байр',
              color: AppTheme.accentGold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Achievements ─────────────────────────────────────────────────
  Widget _buildAchievementsSection() {
    // Map icon string to IconData
    IconData iconFor(String icon) {
      switch (icon) {
        case 'shield':
          return Icons.shield_rounded;
        case 'medal':
          return Icons.military_tech_rounded;
        case 'star':
          return Icons.auto_awesome_rounded;
        default:
          return Icons.emoji_events_rounded;
      }
    }

    Color colorFor(int index) {
      const colors = [
        Color(0xFFFFD700),
        Color(0xFF4ADE80),
        Color(0xFF60A5FA),
        Color(0xFFF472B6),
      ];
      return colors[index % colors.length];
    }

    // Fill up to 4 slots; pad with locked placeholders
    const displayCount = 4;
    final realCount = _achievements.length.clamp(0, displayCount);
    final cards = <Widget>[];
    for (int i = 0; i < displayCount; i++) {
      if (i < realCount) {
        final a = _achievements[i];
        cards.add(_AchievementCard(
          icon: iconFor(a.icon),
          color: colorFor(i),
          title: a.title,
          isLocked: !a.unlocked,
        ));
      } else {
        cards.add(const _AchievementCard(
          icon: Icons.lock_rounded,
          color: AppTheme.textSecondary,
          title: 'Түлхгүй',
          isLocked: true,
        ));
      }
      if (i < displayCount - 1) cards.add(const SizedBox(width: 12));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
          child: Text('Амжилтууд', style: AppTheme.sectionTitle),
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
            children: cards,
          ),
        ),
      ],
    );
  }

  // ── Study Progress ───────────────────────────────────────────────
  Widget _buildStudyProgressSection() {
    final progress = _currentUser?.progress ?? {};
    final humansProgress = (progress['humans'] ?? 0.0).clamp(0.0, 1.0);
    final historyProgress = (progress['history'] ?? 0.0).clamp(0.0, 1.0);
    final mapProgress = (progress['map'] ?? 0.0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Судалсан сэдвүүд', style: AppTheme.sectionTitle),
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
                      value: humansProgress,
                      color: AppTheme.accentGold,
                      controller: _progressController,
                    ),
                    const SizedBox(height: 14),
                    _AnimatedProgressRow(
                      label: 'Судлах Түүх',
                      value: historyProgress,
                      color: AppTheme.accentGold,
                      controller: _progressController,
                    ),
                    const SizedBox(height: 14),
                    _AnimatedProgressRow(
                      label: 'Газрын зураг',
                      value: mapProgress,
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
    final streak = _currentUser?.streakDays ?? 0;
    final label = streak > 0 ? '$streak өдрийн цуврал!' : 'Цуврал эхлүүлэх';
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
            label,
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

  // ── Settings ─────────────────────────────────────────────────────
  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        children: [
          // Admin Dashboard — only visible to admin / superAdmin
          if (context.watch<AuthProvider>().isAdmin) ...[
            _SettingsTile(
              icon: Icons.admin_panel_settings_rounded,
              label: 'Admin Dashboard',
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    builder: (_) => const AdminGate(
                      child: AdminDashboardScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          _SettingsTile(
            icon: Icons.edit_rounded,
            label: 'Профайл засах',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.language_rounded,
            label: 'Хэл',
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
            label: 'Харанхуй горим',
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
            label: 'Гарах',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            onTap: () => _showSignOutDialog(),
          ),
          // ── Debug: Seed fake data (debug builds only) ────────────
          if (kDebugMode) ...[
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.science_rounded,
              label: '[Debug] Туршилтын өгөгдөл',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.crimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DEV',
                  style: AppTheme.chip.copyWith(
                    color: AppTheme.crimson,
                    fontSize: 10,
                  ),
                ),
              ),
              onTap: () async {
                try {
                  await UserService.seedDebugData();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Туршилтын өгөгдөл амжилттай нэмэгдлээ!',
                        style: AppTheme.caption
                            .copyWith(color: AppTheme.textPrimary),
                      ),
                      backgroundColor: AppTheme.surface,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Алдаа: $e',
                          style: AppTheme.caption
                              .copyWith(color: AppTheme.crimson)),
                      backgroundColor: AppTheme.surface,
                    ),
                  );
                }
              },
            ),
          ],
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
  final bool isLocked;

  const _AchievementCard({
    required this.icon,
    required this.color,
    required this.title,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = isLocked ? AppTheme.textSecondary : color;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLocked
                ? AppTheme.surface.withValues(alpha: 0.3)
                : AppTheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: tileColor.withValues(alpha: isLocked ? 0.1 : 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: tileColor.withValues(alpha: 0.08),
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
                  color: tileColor.withValues(alpha: isLocked ? 0.06 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    color: tileColor.withValues(alpha: isLocked ? 0.4 : 1.0),
                    size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTheme.chip.copyWith(
                  fontSize: 10,
                  color: isLocked
                      ? AppTheme.textSecondary.withValues(alpha: 0.5)
                      : AppTheme.textPrimary,
                ),
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
                'Нарийвчлал',
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
