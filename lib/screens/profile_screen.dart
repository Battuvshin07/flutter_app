import 'dart:ui';
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
  late final Stream<AppUser?> _userStream;
  bool _darkMode = true;

  // Real-time user state
  AppUser? _currentUser;
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
          const SizedBox(height: 28),
          _buildAchievementsSection(),
          const SizedBox(height: 28),
          _buildPersonalInfoSection(),
          const SizedBox(height: 20),
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
          const SizedBox(width: 40),
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
          style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
        ),
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

  // ── Personal Info ────────────────────────────────────────────────
  Widget _buildPersonalInfoSection() {
    final displayName = _currentUser?.effectiveName ?? 'Хэрэглэгч';
    final email = _currentUser?.email ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ХУВИЙН МЭДЭЭЛЭЛ',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
                child: Text(
                  'Засах',
                  style: AppTheme.captionBold.copyWith(
                    color: AppTheme.accentGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'НЭР',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(displayName, style: AppTheme.body),
                    ],
                  ),
                ),
                const Divider(
                    height: 1, thickness: 1, color: AppTheme.cardBorder),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ИМЭЙЛ',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(email, style: AppTheme.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Achievements ─────────────────────────────────────────────────
  Widget _buildAchievementsSection() {
    final level = UserService.levelFromXP(_currentUser?.totalXP ?? 0);

    const achievementDefs = [
      (
        icon: Icons.shield_rounded,
        title: 'Эхлэл',
        requiredLevel: 2,
        color: Color(0xFFFFD700)
      ),
      (
        icon: Icons.military_tech_rounded,
        title: 'Сурагч',
        requiredLevel: 4,
        color: Color(0xFF4ADE80)
      ),
      (
        icon: Icons.auto_awesome_rounded,
        title: 'Баатар',
        requiredLevel: 7,
        color: Color(0xFF60A5FA)
      ),
      (
        icon: Icons.emoji_events_rounded,
        title: 'Хаан',
        requiredLevel: 10,
        color: Color(0xFFF472B6)
      ),
    ];

    final cards = <Widget>[];
    for (int i = 0; i < achievementDefs.length; i++) {
      final def = achievementDefs[i];
      final unlocked = level >= def.requiredLevel;
      cards.add(_AchievementCard(
        icon: unlocked ? def.icon : Icons.lock_rounded,
        color: unlocked ? def.color : AppTheme.textSecondary,
        title: unlocked ? def.title : 'Lvl ${def.requiredLevel}',
        isLocked: !unlocked,
      ));
      if (i < achievementDefs.length - 1) cards.add(const SizedBox(width: 12));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
          child: Text(
            'АМЖИЛТУУД',
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
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

  // ── Settings ─────────────────────────────────────────────────────
  Widget _buildSettingsRow({
    required IconData icon,
    required String label,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.accentGold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTheme.body)),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin block — only for admins
          if (context.watch<AuthProvider>().isAdmin) ...[
            Text(
              'ADMIN',
              style: AppTheme.caption.copyWith(
                color: AppTheme.textSecondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: _buildSettingsRow(
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminGate(
                      child: AdminDashboardScreen(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'ТОХИРГОО',
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              children: [
                _buildSettingsRow(
                  icon: Icons.language_rounded,
                  label: 'Хэл',
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                const Divider(
                    height: 1, thickness: 1, color: AppTheme.cardBorder),
                _buildSettingsRow(
                  icon: Icons.dark_mode_rounded,
                  label: 'Харанхуй горим',
                  trailing: SizedBox(
                    height: 28,
                    child: Switch(
                      value: _darkMode,
                      onChanged: (v) => setState(() => _darkMode = v),
                      activeThumbColor: AppTheme.accentGold,
                      activeTrackColor:
                          AppTheme.accentGold.withValues(alpha: 0.3),
                      inactiveThumbColor: AppTheme.textSecondary,
                      inactiveTrackColor: AppTheme.surfaceLight,
                    ),
                  ),
                  onTap: () => setState(() => _darkMode = !_darkMode),
                ),
                const Divider(
                    height: 1, thickness: 1, color: AppTheme.cardBorder),
                _buildSettingsRow(
                  icon: Icons.logout_rounded,
                  label: 'Гарах',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  onTap: () => _showSignOutDialog(),
                ),
              ],
            ),
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
