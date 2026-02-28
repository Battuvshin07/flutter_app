import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/admin/glass_card.dart';
import '../components/admin/admin_stat_card.dart';
import '../components/admin/admin_widgets.dart';

// ══════════════════════════════════════════════════════════════════
//  ADMIN DASHBOARD SCREEN
//  Production-ready admin panel for Mongolian History App
//  Dark + Gold glassmorphism design
// ══════════════════════════════════════════════════════════════════

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _chartAnimController;
  late final Animation<double> _chartAnimation;

  bool _analyticsExpanded = true;
  bool _contentExpanded = true;
  bool _usersExpanded = true;

  // Mock data — replace with real backend data
  final List<_MockUser> _users = [
    _MockUser('Хаатар', 'Lv. 20', 'User', 'assets/images/pic_2.png', false),
    _MockUser('Хаатар', 'Lv. 20', 'Admin', 'assets/images/pic_2.png', false),
    _MockUser('Лараа', 'Lv. 20', 'Admin', 'assets/images/pic_2.png', false),
  ];

  @override
  void initState() {
    super.initState();
    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimController,
      curve: Curves.easeOutCubic,
    );
    _chartAnimController.forward();
  }

  @override
  void dispose() {
    _chartAnimController.dispose();
    super.dispose();
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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Top Bar ──
              SliverToBoxAdapter(child: _buildTopBar()),

              // ── Admin Avatar Section ──
              SliverToBoxAdapter(child: _buildAdminHeader()),

              // ── Quick Stats ──
              SliverToBoxAdapter(child: _buildQuickStats()),

              // ── Analytics Section ──
              SliverToBoxAdapter(child: _buildAnalyticsSection()),

              // ── Content Management ──
              SliverToBoxAdapter(child: _buildContentManagement()),

              // ── User Management ──
              SliverToBoxAdapter(child: _buildUserManagement()),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      // ── Bottom Navigation ──
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  TOP BAR
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
          const SizedBox(width: 14),
          // Side nav icons (vertical strip from screenshot)
          ..._buildSideNavIcons(),
          const Spacer(),
          // Notification bell
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.crimson,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSideNavIcons() {
    return [
      _sideNavIcon(Icons.home_rounded, true),
      _sideNavIcon(Icons.search_rounded, false),
      _sideNavIcon(Icons.mail_outline_rounded, false),
      _sideNavIcon(Icons.grid_view_rounded, false),
    ];
  }

  Widget _sideNavIcon(IconData icon, bool active) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active
              ? AppTheme.accentGold.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppTheme.accentGold : AppTheme.textSecondary,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  ADMIN HEADER — Avatar + Name + Role Badge
  // ════════════════════════════════════════════════════════════════
  Widget _buildAdminHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Avatar with gold ring
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF4C84A),
                      Color(0xFFD4A017),
                      Color(0xFFF4C84A),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withOpacity(0.35),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3.5),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/pic_2.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.surfaceLight,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 52,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              // ADMIN badge overlapping bottom
              Transform.translate(
                offset: const Offset(0, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ADE80).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Холд Өэнээ', style: AppTheme.h2.copyWith(fontSize: 24)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.accentGold.withOpacity(0.3),
              ),
            ),
            child: Text(
              'Super Admin',
              style: AppTheme.chip.copyWith(
                color: AppTheme.accentGold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  QUICK STATS ROW
  // ════════════════════════════════════════════════════════════════
  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(title: 'Quick Stats'),
          const SizedBox(height: 14),
          Row(
            children: const [
              AdminStatCard(
                icon: Icons.people_alt_rounded,
                value: '12.4K',
                label: 'Total Users',
                iconColor: Color(0xFF60A5FA),
              ),
              SizedBox(width: 10),
              AdminStatCard(
                icon: Icons.trending_up_rounded,
                value: '2,847',
                label: 'Active Today',
                iconColor: AppTheme.xpGreen,
              ),
              SizedBox(width: 10),
              AdminStatCard(
                icon: Icons.stars_rounded,
                value: '1.2M',
                label: 'Total XP',
                iconColor: AppTheme.streakOrange,
              ),
              SizedBox(width: 10),
              AdminStatCard(
                icon: Icons.quiz_rounded,
                value: '458',
                label: 'Total Quizzes',
                iconColor: AppTheme.accentGold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  ANALYTICS SECTION
  // ════════════════════════════════════════════════════════════════
  Widget _buildAnalyticsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        28,
        AppTheme.pagePadding,
        0,
      ),
      child: Column(
        children: [
          AdminSectionHeader(
            title: 'Analytics',
            trailing: AnimatedRotation(
              turns: _analyticsExpanded ? 0 : 0.5,
              duration: const Duration(milliseconds: 250),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
            onTap: () =>
                setState(() => _analyticsExpanded = !_analyticsExpanded),
          ),
          AnimatedCrossFade(
            firstChild: _buildAnalyticsContent(),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _analyticsExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line chart
          Expanded(
            flex: 5,
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Growth (30 days)',
                    style: AppTheme.captionBold.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 140,
                    child: AnimatedBuilder(
                      animation: _chartAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size.infinite,
                          painter: _LineChartPainter(
                            progress: _chartAnimation.value,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _chartLegend('Үйлс', AppTheme.accentGold),
                      const SizedBox(width: 14),
                      _chartLegend('Аулаан', AppTheme.crimson),
                      const SizedBox(width: 14),
                      _chartLegend('Quiz', const Color(0xFF60A5FA)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Bar chart + Donut chart stacked
          Expanded(
            flex: 4,
            child: Column(
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Most Studied Topics',
                        style: AppTheme.captionBold.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 100,
                        child: AnimatedBuilder(
                          animation: _chartAnimation,
                          builder: (context, _) {
                            return CustomPaint(
                              size: Size.infinite,
                              painter: _BarChartPainter(
                                progress: _chartAnimation.value,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _chartLegend('Аулаан', AppTheme.accentGold),
                          const SizedBox(width: 8),
                          _chartLegend('Найды хүрэй', AppTheme.crimson),
                          const SizedBox(width: 8),
                          _chartLegend('Quiz', const Color(0xFF60A5FA)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Donut / Quiz Performance
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Text(
                        'Quiz Performance',
                        style: AppTheme.captionBold.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: AnimatedBuilder(
                          animation: _chartAnimation,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size(90, 90),
                              painter: _DonutChartPainter(
                                progress: _chartAnimation.value,
                                percentage: 0.85,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(85 * _chartAnimation.value).toInt()}%',
                                      style: AppTheme.h2.copyWith(
                                        fontSize: 18,
                                        color: AppTheme.xpGreen,
                                      ),
                                    ),
                                    Text(
                                      'Pass',
                                      style: AppTheme.caption.copyWith(
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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

  Widget _chartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.caption.copyWith(fontSize: 9),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  CONTENT MANAGEMENT SECTION
  // ════════════════════════════════════════════════════════════════
  Widget _buildContentManagement() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        28,
        AppTheme.pagePadding,
        0,
      ),
      child: Column(
        children: [
          AdminSectionHeader(
            title: 'Content Management',
            trailing: AnimatedRotation(
              turns: _contentExpanded ? 0 : 0.5,
              duration: const Duration(milliseconds: 250),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
            onTap: () => setState(() => _contentExpanded = !_contentExpanded),
          ),
          AnimatedCrossFade(
            firstChild: _buildContentGrid(),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _contentExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildContentGrid() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
        children: [
          AdminActionCard(
            icon: Icons.add_rounded,
            title: 'Add New Content',
            subtitle: 'Күнгг контент нэмэ',
            iconColor: AppTheme.accentGold,
            onTap: () {},
          ),
          AdminActionCard(
            icon: Icons.edit_note_rounded,
            title: 'Edit Topics',
            subtitle: 'Одыв басварлай',
            iconColor: const Color(0xFF60A5FA),
            onTap: () {},
          ),
          AdminActionCard(
            icon: Icons.groups_rounded,
            title: 'Manage Users',
            subtitle: 'Эрээлгид удирдай',
            iconColor: const Color(0xFF4ADE80),
            onTap: () {},
          ),
          AdminActionCard(
            icon: Icons.check_circle_rounded,
            title: 'Approve Quizzes',
            subtitle: 'балгалт жатлай',
            iconColor: const Color(0xFFA78BFA),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  USER MANAGEMENT SECTION
  // ════════════════════════════════════════════════════════════════
  Widget _buildUserManagement() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        28,
        AppTheme.pagePadding,
        0,
      ),
      child: Column(
        children: [
          AdminSectionHeader(
            title: 'User Management',
            trailing: AnimatedRotation(
              turns: _usersExpanded ? 0 : 0.5,
              duration: const Duration(milliseconds: 250),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
            onTap: () => setState(() => _usersExpanded = !_usersExpanded),
          ),
          AnimatedCrossFade(
            firstChild: _buildUserList(),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _usersExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: _users.map((u) {
          return AdminUserTile(
            name: u.name,
            level: u.level,
            role: u.role,
            avatarAsset: u.avatar,
            isSuspended: u.suspended,
            onSuspend: () {
              setState(() => u.suspended = !u.suspended);
            },
            onDelete: () {
              _showDeleteDialog(u);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showDeleteDialog(_MockUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.cardBorder),
        ),
        title: Text(
          'Delete User',
          style: AppTheme.sectionTitle,
        ),
        content: Text(
          'Are you sure you want to delete "${user.name}"?',
          style: AppTheme.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _users.remove(user));
              Navigator.pop(ctx);
            },
            child: Text(
              'Delete',
              style: AppTheme.caption.copyWith(color: AppTheme.crimson),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  BOTTOM NAVIGATION BAR
  // ════════════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    int selected = 3; // Profile/Admin tab
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.95),
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Өзөр', 0, selected),
              _navItem(Icons.explore_rounded, 'Будлай', 1, selected),
              _navItem(Icons.map_rounded, 'Уурай', 2, selected),
              _navItem(
                  Icons.admin_panel_settings_rounded, 'Апрофайл', 3, selected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, int selected) {
    final isActive = index == selected;
    return GestureDetector(
      onTap: () {
        if (index != selected) Navigator.maybePop(context);
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

// ══════════════════════════════════════════════════════════════════
//  MOCK DATA CLASS
// ══════════════════════════════════════════════════════════════════

class _MockUser {
  final String name;
  final String level;
  final String role;
  final String? avatar;
  bool suspended;

  _MockUser(this.name, this.level, this.role, this.avatar, this.suspended);
}

// ══════════════════════════════════════════════════════════════════
//  CUSTOM PAINTERS — Charts
// ══════════════════════════════════════════════════════════════════

// ── Line Chart Painter ─────────────────────────────────────────────
class _LineChartPainter extends CustomPainter {
  final double progress;

  _LineChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid lines
    final gridPaint = Paint()
      ..color = AppTheme.cardBorder.withOpacity(0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = h * i / 4;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Y-axis labels
    final labels = ['40k', '30k', '20k', '10k', '0'];
    for (int i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: AppTheme.textSecondary.withOpacity(0.5),
            fontSize: 8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-2, h * i / 4 - 4));
    }

    // Data points (exponential growth curve)
    final points = <Offset>[
      Offset(0, h * 0.95),
      Offset(w * 0.15, h * 0.88),
      Offset(w * 0.25, h * 0.82),
      Offset(w * 0.4, h * 0.7),
      Offset(w * 0.55, h * 0.55),
      Offset(w * 0.65, h * 0.42),
      Offset(w * 0.75, h * 0.3),
      Offset(w * 0.85, h * 0.18),
      Offset(w * 0.95, h * 0.08),
    ];

    // Animate: only draw up to progress
    final animatedCount =
        (points.length * progress).ceil().clamp(0, points.length);
    if (animatedCount < 2) return;

    final visiblePoints = points.sublist(0, animatedCount);

    // Area fill
    final areaPath = Path()..moveTo(visiblePoints.first.dx, h);
    for (final p in visiblePoints) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(visiblePoints.last.dx, h);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.accentGold.withOpacity(0.25),
          AppTheme.accentGold.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(areaPath, areaPaint);

    // Line
    final linePath = Path()
      ..moveTo(visiblePoints.first.dx, visiblePoints.first.dy);
    for (int i = 1; i < visiblePoints.length; i++) {
      final prev = visiblePoints[i - 1];
      final curr = visiblePoints[i];
      final cpX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }

    final linePaint = Paint()
      ..color = AppTheme.accentGold
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Dot at last visible point
    final lastPt = visiblePoints.last;
    canvas.drawCircle(
      lastPt,
      4,
      Paint()..color = AppTheme.accentGold,
    );
    canvas.drawCircle(
      lastPt,
      6,
      Paint()
        ..color = AppTheme.accentGold.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Bar Chart Painter ──────────────────────────────────────────────
class _BarChartPainter extends CustomPainter {
  final double progress;

  _BarChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final barData = [0.6, 0.85, 0.45, 0.95, 0.7];
    final barColors = [
      AppTheme.accentGold,
      AppTheme.accentGold,
      const Color(0xFF60A5FA),
      AppTheme.accentGold,
      const Color(0xFF60A5FA),
    ];
    final barLabels = ['', '', '', '', ''];

    final totalBars = barData.length;
    final barWidth = (w - (totalBars + 1) * 8) / totalBars;

    // Y-axis labels
    final yLabels = ['100k', '80k', '60k', '40k', '20k', '0'];
    for (int i = 0; i < yLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: yLabels[i],
          style: TextStyle(
            color: AppTheme.textSecondary.withOpacity(0.4),
            fontSize: 7,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-2, h * i / (yLabels.length - 1) - 4));
    }

    for (int i = 0; i < totalBars; i++) {
      final x = 8.0 + i * (barWidth + 8);
      final barHeight = h * barData[i] * progress;
      final y = h - barHeight;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            barColors[i],
            barColors[i].withOpacity(0.5),
          ],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Donut Chart Painter ────────────────────────────────────────────
class _DonutChartPainter extends CustomPainter {
  final double progress;
  final double percentage;

  _DonutChartPainter({
    required this.progress,
    required this.percentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const strokeWidth = 10.0;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.surfaceLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Animated progress arc
    final sweepAngle = 2 * math.pi * percentage * progress;
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          AppTheme.xpGreen,
          const Color(0xFF4ADE80),
          AppTheme.accentGold,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // Remaining segment (smaller, grayed)
    final remainAngle = 2 * math.pi * (1 - percentage) * progress;
    final remainPaint = Paint()
      ..color = AppTheme.accentGold.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + sweepAngle,
      remainAngle,
      false,
      remainPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
