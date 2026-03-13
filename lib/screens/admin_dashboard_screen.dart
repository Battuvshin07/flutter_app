import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../components/admin/glass_card.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart' show HomeScreen;
import '../screens/persons_screen.dart';
import '../screens/map_screen.dart';
import 'admin/admin_list_screen.dart';
import 'admin/admin_collection_config.dart';
import 'admin/progress_list_screen.dart';

// ══════════════════════════════════════════════════════════════════
//  ADMIN DASHBOARD SCREEN — Modern Grid Layout
//  Grid of category cards + Stats + Quick actions
// ══════════════════════════════════════════════════════════════════

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadTotalUsers();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Provider.of<AdminProvider>(context, listen: false).refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F1A2E),
              AppTheme.background,
              Color(0xFF0A0F1A),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.accentGold,
            backgroundColor: AppTheme.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildTopBar()),
                SliverToBoxAdapter(child: _buildWelcomeHeader()),
                SliverToBoxAdapter(child: _buildErrorBanner()),
                SliverToBoxAdapter(child: _buildStatsRow()),
                SliverToBoxAdapter(child: _buildSectionTitle()),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.pagePadding,
                  ),
                  sliver: _buildCategoryGrid(),
                ),
                SliverToBoxAdapter(child: _buildSeedAchievementsTile()),
                SliverToBoxAdapter(child: _buildProgressTile()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  TOP BAR — Back + Title + Logout
  // ════════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        8,
        AppTheme.pagePadding,
        4,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF4C84A), Color(0xFFD4A017)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'ADMIN',
              style: AppTheme.chip.copyWith(
                color: AppTheme.background,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  WELCOME HEADER — Greeting + Admin name
  // ════════════════════════════════════════════════════════════════
  Widget _buildWelcomeHeader() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final displayName = auth.user?.displayName ?? 'Admin';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        20,
        AppTheme.pagePadding,
        6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сайн байна уу,',
            style: AppTheme.caption.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Admin avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF4C84A), Color(0xFFD4A017)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: AppTheme.background,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  displayName,
                  style: AppTheme.h2.copyWith(fontSize: 24),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  ERROR BANNER — shown when stream/user-count errors exist
  // ════════════════════════════════════════════════════════════════
  Widget _buildErrorBanner() {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (!admin.hasStreamError) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            12,
            AppTheme.pagePadding,
            0,
          ),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderColor: AppTheme.crimson.withValues(alpha: 0.4),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppTheme.crimson, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Өгөгдөл ачаалахад алдаа гарлаа. Дахин татна уу.',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.crimson,
                      fontSize: 12,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _onRefresh,
                  child: Icon(Icons.refresh_rounded,
                      color: AppTheme.crimson, size: 20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  STATS ROW — Total users + Total content
  // ════════════════════════════════════════════════════════════════
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        20,
        AppTheme.pagePadding,
        8,
      ),
      child: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          final contentLoaded = admin.culturesLoaded &&
              admin.personsLoaded &&
              admin.quizzesLoaded &&
              admin.eventsLoaded &&
              admin.storiesLoaded;

          // Count total content items across all collections
          final totalContent = admin.cultures.length +
              admin.persons.length +
              admin.quizzes.length +
              admin.events.length +
              admin.stories.length;

          return Row(
            children: [
              // Users stat
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people_alt_rounded,
                  label: 'Хэрэглэгч',
                  value: '${admin.totalUsers}',
                  color: const Color(0xFF60A5FA),
                  isLoaded: admin.totalUsersLoaded,
                  onRefresh: () => admin.loadTotalUsers(),
                ),
              ),
              const SizedBox(width: 12),
              // Content stat
              Expanded(
                child: _buildStatCard(
                  icon: Icons.dashboard_rounded,
                  label: 'Нийт контент',
                  value: '$totalContent',
                  color: AppTheme.accentGold,
                  isLoaded: contentLoaded,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isLoaded,
    VoidCallback? onRefresh,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (onRefresh != null)
                GestureDetector(
                  onTap: onRefresh,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    size: 18,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          isLoaded
              ? Text(
                  value,
                  style: AppTheme.h2.copyWith(fontSize: 28, color: color),
                )
              : _buildPulseBox(width: 48, height: 28, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Animated pulsing placeholder box used while data is loading.
  Widget _buildPulseBox({
    required double width,
    required double height,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color:
                color.withValues(alpha: 0.08 + 0.08 * _pulseController.value),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SECTION TITLE — "Content Manager"
  // ════════════════════════════════════════════════════════════════
  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        20,
        AppTheme.pagePadding,
        14,
      ),
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
          Text('Контент удирдах', style: AppTheme.sectionTitle),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  CATEGORY GRID — 2-column grid of collection cards
  // ════════════════════════════════════════════════════════════════
  SliverGrid _buildCategoryGrid() {
    // Define grid items with Mongolian subtitles
    final gridItems = [
      _GridItem('cultures', 'Соёл'),
      _GridItem('persons', 'Хүмүүс'),
      _GridItem('quizzes', 'Тестүүд'),
      _GridItem('events', 'Үйл явдал'),
      _GridItem('stories', 'Түүхүүд'),
      _GridItem('videos', 'Видео'),
    ];

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final gridItem = gridItems[index];
          final config = adminCollections[gridItem.key]!;
          return _buildCategoryCard(config, gridItem.subtitle);
        },
        childCount: gridItems.length,
      ),
    );
  }

  Widget _buildCategoryCard(AdminCollectionConfig config, String subtitle) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final count = config.getItems(admin).length;
        final isLoaded = config.isLoaded(admin);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminListScreen(collectionKey: config.key),
            ),
          ),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: AppTheme.radiusMd,
            opacity: 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + count badge
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: config.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: config.color.withValues(alpha: 0.25)),
                      ),
                      child: Icon(config.icon, color: config.color, size: 24),
                    ),
                    const Spacer(),
                    if (isLoaded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: config.color.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '$count',
                          style: AppTheme.chip.copyWith(
                            color: config.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      _buildPulseBox(
                        width: 32,
                        height: 22,
                        color: config.color,
                      ),
                  ],
                ),
                const Spacer(),

                // Title
                Text(
                  config.title,
                  style: AppTheme.captionBold.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                // Subtitle
                Text(
                  subtitle,
                  style: AppTheme.caption.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PROGRESS TILE — separate entry (not a typed collection)
  // ════════════════════════════════════════════════════════════════
  // ════════════════════════════════════════════════════════════════
  //  SEED ACHIEVEMENTS TILE — One-time setup button
  // ════════════════════════════════════════════════════════════════
  bool _isSeeding = false;

  Future<void> _seedAchievements() async {
    setState(() => _isSeeding = true);
    try {
      final db = FirebaseFirestore.instance;
      final achievements = [
        {
          'id': 'level_2_starter',
          'title': 'Аравтын ноён',
          'description': 'Level 2-д хүрлээ',
          'icon': 'shield',
          'expReward': 50,
          'conditionType': 'level',
          'conditionValue': 2,
          'sortOrder': 1,
        },
        {
          'id': 'level_4_learner',
          'title': 'Зуутын ноён',
          'description': 'Level 4-д хүрлээ',
          'icon': 'medal',
          'expReward': 100,
          'conditionType': 'level',
          'conditionValue': 4,
          'sortOrder': 2,
        },
        {
          'id': 'level_7_hero',
          'title': 'Мянгатын ноён',
          'description': 'Level 7-д хүрлээ',
          'icon': 'star',
          'expReward': 200,
          'conditionType': 'level',
          'conditionValue': 7,
          'sortOrder': 3,
        },
        {
          'id': 'level_10_king',
          'title': 'Түмтийн ноён',
          'description': 'Level 10-д хүрлээ',
          'icon': 'trophy',
          'expReward': 500,
          'conditionType': 'level',
          'conditionValue': 10,
          'sortOrder': 4,
        },
      ];

      final batch = db.batch();
      for (final achievement in achievements) {
        final docRef =
            db.collection('achievements').doc(achievement['id'] as String);
        batch.set(docRef, achievement);
      }
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('✅ ${achievements.length} амжилт амжилттай үүсгэгдлээ!'),
          backgroundColor: const Color(0xFF34D399),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Алдаа гарлаа: $e'),
          backgroundColor: AppTheme.crimson,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Widget _buildSeedAchievementsTile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        14,
        AppTheme.pagePadding,
        0,
      ),
      child: GestureDetector(
        onTap: _isSeeding ? null : _seedAchievements,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          borderRadius: AppTheme.radiusMd,
          opacity: _isSeeding ? 0.5 : 1.0,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.25),
                  ),
                ),
                child: _isSeeding
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.accentGold,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.emoji_events_rounded,
                        color: AppTheme.accentGold,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seed Achievements',
                      style: AppTheme.captionBold.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Level амжилтууд үүсгэх (нэг удаа)',
                      style: AppTheme.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        14,
        AppTheme.pagePadding,
        0,
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProgressListScreen()),
        ),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          borderRadius: AppTheme.radiusMd,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF34D399).withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF34D399),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress',
                      style: AppTheme.captionBold.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Хэрэглэгчийн ахиц харах',
                      style: AppTheme.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  BOTTOM NAVIGATION
  // ════════════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Нүүр', 0),
              _navItem(Icons.explore_rounded, 'Судлах', 1),
              _navItem(Icons.map_rounded, 'Газрын зураг', 2),
              _navItem(
                Icons.admin_panel_settings_rounded,
                'Админ',
                3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    const activeIndex = 3; // Admin tab is always active on this screen
    final isActive = index == activeIndex;
    return GestureDetector(
      onTap: () {
        if (index == activeIndex) return; // already here
        switch (index) {
          case 0:
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonsScreen()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            );
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppTheme.accentGold : AppTheme.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTheme.chip.copyWith(
                fontSize: 10,
                color: isActive ? AppTheme.accentGold : AppTheme.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper class for grid items ─────────────────────────────────
class _GridItem {
  final String key;
  final String subtitle;
  const _GridItem(this.key, this.subtitle);
}
