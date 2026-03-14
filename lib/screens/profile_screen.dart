import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../services/culture_service.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'admin_dashboard_screen.dart';
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

  // Real-time user state
  AppUser? _currentUser;
  double _xpTarget = 0.0;
  bool _retryFlag = false;

  // Inline edit state
  bool _isEditing = false;
  bool _isSaving = false;
  final TextEditingController _nameCtrl = TextEditingController();
  Uint8List? _pickedImageBytes;

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
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Inline edit helpers ──────────────────────────────────────────
  void _enterEditMode() {
    _nameCtrl.text = _currentUser?.effectiveName ?? '';
    _pickedImageBytes = null;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _pickedImageBytes = null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (xFile != null && mounted) {
      final bytes = await xFile.readAsBytes();
      setState(() => _pickedImageBytes = bytes);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final success = await profile.updateProfile(
      displayName: _nameCtrl.text.trim(),
      avatarBytes: _pickedImageBytes,
    );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (success) {
        _isEditing = false;
        _pickedImageBytes = null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Амжилттай хадгаллаа' : 'Алдаа гарлаа'),
        backgroundColor: success ? const Color(0xFF4ADE80) : AppTheme.crimson,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────
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
          bottom: false,
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
          _buildStatisticsSection(),
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
      child: Text('Профайл',
          textAlign: TextAlign.center, style: AppTheme.sectionTitle),
    );
  }

  // ── Avatar + Name + Level ────────────────────────────────────────
  Widget _buildAvatarSection() {
    final user = _currentUser;
    final level = UserService.levelFromXP(user?.totalXP ?? 0);
    final displayName = user?.effectiveName ?? 'Хэрэглэгч';
    final photoUrl = user?.photoUrl;
    final initials = user?.initials ?? '?';

    Widget avatarChild;
    if (_isEditing && _pickedImageBytes != null) {
      avatarChild = Image.memory(_pickedImageBytes!, fit: BoxFit.cover);
    } else if (photoUrl?.isNotEmpty == true) {
      avatarChild = Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitialsAvatar(initials),
      );
    } else {
      avatarChild = _buildInitialsAvatar(initials);
    }

    final avatarCircle = Container(
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
      child: ClipOval(child: avatarChild),
    );

    return Column(
      children: [
        GestureDetector(
          onTap: _isEditing ? _pickImage : null,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              avatarCircle,
              if (_isEditing)
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppTheme.background, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppTheme.background, size: 16),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
        ),
        if (_isEditing) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Text(
              'Зураг солих',
              style: AppTheme.captionBold.copyWith(
                color: AppTheme.accentGold,
                fontSize: 13,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 14),
          Text(displayName, style: AppTheme.h2),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
          ),
        ],
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

  // ── Statistics ───────────────────────────────────────────────────
  String _formatLastActive(DateTime? dt) {
    if (dt == null) return '–';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Одоо';
    if (diff.inHours < 24) return '${diff.inHours}ц өмнө';
    if (diff.inDays == 1) return 'Өчигдөр';
    return '${diff.inDays}өдрийн өмнө';
  }

  Widget _buildStatisticsSection() {
    final user = _currentUser;
    final storiesCount = user?.storiesCompleted ?? 0;
    final lastActive = user?.lastActiveDate ?? user?.lastLogin;

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'СТАТИСТИК',
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, double>>(
            future: CultureService().loadProgress(),
            builder: (context, snapshot) {
              final cultureCount = snapshot.hasData
                  ? snapshot.data!.values.where((v) => v == 1.0).length
                  : 0;
              return Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.menu_book_rounded,
                      value: '$storiesCount',
                      label: 'Түүх',
                      color: AppTheme.accentGold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.account_balance_rounded,
                      value: '$cultureCount',
                      label: 'Соёл',
                      color: const Color(0xFF60A5FA),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.schedule_rounded,
                      value: _formatLastActive(lastActive),
                      label: 'Сүүлд идэвхтэй',
                      color: const Color(0xFF4ADE80),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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
                onTap: _isEditing ? _cancelEdit : _enterEditMode,
                child: Text(
                  _isEditing ? 'Болих' : 'Засах',
                  style: AppTheme.captionBold.copyWith(
                    color: _isEditing
                        ? AppTheme.textSecondary
                        : AppTheme.accentGold,
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
                // Name row
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
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
                      const SizedBox(height: 6),
                      if (_isEditing)
                        TextField(
                          controller: _nameCtrl,
                          style: AppTheme.body
                              .copyWith(color: AppTheme.textPrimary),
                          cursorColor: AppTheme.accentGold,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: AppTheme.surfaceLight,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              borderSide: const BorderSide(
                                  color: AppTheme.cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              borderSide: const BorderSide(
                                  color: AppTheme.cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              borderSide: const BorderSide(
                                  color: AppTheme.accentGold, width: 1.5),
                            ),
                          ),
                        )
                      else
                        Text(displayName, style: AppTheme.body),
                    ],
                  ),
                ),
                const Divider(
                    height: 1, thickness: 1, color: AppTheme.cardBorder),
                // Email row — always read-only
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
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
          // Save button — only in edit mode
          if (_isEditing) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentGold, Color(0xFFFFE08A)],
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
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.background,
                          ),
                        )
                      : Text(
                          'Хадгалах',
                          style: AppTheme.captionBold.copyWith(
                            color: AppTheme.background,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Achievements ─────────────────────────────────────────────────
  Widget _buildAchievementsSection() {
    final level = UserService.levelFromXP(_currentUser?.totalXP ?? 0);

    const achievementDefs = [
      (
        image: 'assets/images/achievements/icon1.png',
        title: 'Аравтын ноён',
        requiredLevel: 2,
      ),
      (
        image: 'assets/images/achievements/icon2.png',
        title: 'Зуутын ноён',
        requiredLevel: 4,
      ),
      (
        image: 'assets/images/achievements/icon3.png',
        title: 'Мянгатын ноён',
        requiredLevel: 7,
      ),
      (
        image: 'assets/images/achievements/icon4.png',
        title: 'Түмтийн ноён',
        requiredLevel: 10,
      ),
    ];

    final cards = <Widget>[];

    // Most recently unlocked = highest requiredLevel (strict unlock order).
    // Show unlocked first (descending level), then locked (ascending level).
    final unlockedDefs = achievementDefs
        .where((d) => level >= d.requiredLevel)
        .toList()
      ..sort((a, b) => b.requiredLevel.compareTo(a.requiredLevel));
    final lockedDefs = achievementDefs
        .where((d) => level < d.requiredLevel)
        .toList()
      ..sort((a, b) => a.requiredLevel.compareTo(b.requiredLevel));
    final sorted = [...unlockedDefs, ...lockedDefs];

    for (int i = 0; i < sorted.length; i++) {
      final def = sorted[i];
      final unlocked = level >= def.requiredLevel;
      cards.add(_AchievementCard(
        imagePath: def.image,
        title: unlocked ? def.title : 'Lvl ${def.requiredLevel}',
        isLocked: !unlocked,
      ));
      if (i < sorted.length - 1) cards.add(const SizedBox(width: 12));
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

// ── Stat Tile ──────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTheme.h2.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Achievement Card (glassmorphism) ───────────────────────────────
class _AchievementCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final bool isLocked;

  const _AchievementCard({
    required this.imagePath,
    required this.title,
    this.isLocked = false,
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
            color: isLocked
                ? AppTheme.surface.withValues(alpha: 0.3)
                : AppTheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: isLocked
                  ? AppTheme.textSecondary.withValues(alpha: 0.1)
                  : AppTheme.accentGold.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: isLocked
                    ? AppTheme.textSecondary.withValues(alpha: 0.08)
                    : AppTheme.accentGold.withValues(alpha: 0.15),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: isLocked
                    ? Container(
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          color: AppTheme.textSecondary.withValues(alpha: 0.4),
                          size: 28,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
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
