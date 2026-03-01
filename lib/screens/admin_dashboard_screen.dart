import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../components/admin/glass_card.dart';
import '../components/admin/admin_widgets.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart' show HomeScreen;
import 'admin/culture_list_screen.dart';
import 'admin/persons_list_screen.dart';
import 'admin/family_tree_list_screen.dart';
import 'admin/quizzes_list_screen.dart';

// ══════════════════════════════════════════════════════════════════
//  ADMIN DASHBOARD SCREEN — Simplified
//  Shows only Total Users count + Content Manager navigation
// ══════════════════════════════════════════════════════════════════

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadTotalUsers();
    });
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
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildTopBar()),
              SliverToBoxAdapter(child: _buildAdminHeader()),
              SliverToBoxAdapter(child: _buildTotalUsersCard()),
              SliverToBoxAdapter(child: _buildContentManager()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
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
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
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
          Text('Admin Panel', style: AppTheme.sectionTitle),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  ADMIN HEADER — Avatar + Name + Role Badge
  // ════════════════════════════════════════════════════════════════
  Widget _buildAdminHeader() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final displayName = auth.user?.displayName ?? 'Admin';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 100,
                height: 100,
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
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: Container(
                    color: AppTheme.surfaceLight,
                    child: const Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
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
          Text(displayName, style: AppTheme.h2.copyWith(fontSize: 22)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  TOTAL USERS CARD — single stat from Firestore
  //  Uses Firestore count() aggregation (no full-doc reads).
  // ════════════════════════════════════════════════════════════════
  Widget _buildTotalUsersCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          return GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A5FA).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF60A5FA).withOpacity(0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: Color(0xFF60A5FA),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Нийт хэрэглэгчийн тоо',
                      style: AppTheme.caption.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${admin.totalUsers}',
                      style: AppTheme.h2.copyWith(
                        fontSize: 32,
                        color: const Color(0xFF60A5FA),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => admin.loadTotalUsers(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  CONTENT MANAGER — navigation tiles
  // ════════════════════════════════════════════════════════════════
  Widget _buildContentManager() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        28,
        AppTheme.pagePadding,
        0,
      ),
      child: Column(
        children: [
          const AdminSectionHeader(title: 'Content Manager'),
          const SizedBox(height: 16),
          _contentTile(
            icon: Icons.theater_comedy_rounded,
            title: 'Culture',
            subtitle: 'Соёлын контент удирдах',
            color: AppTheme.accentGold,
            onTap: () => _push(const CultureListScreen()),
          ),
          _contentTile(
            icon: Icons.person_search_rounded,
            title: 'Persons',
            subtitle: 'Түүхэн хүмүүс удирдах',
            color: const Color(0xFF60A5FA),
            onTap: () => _push(const PersonsListScreen()),
          ),
          _contentTile(
            icon: Icons.account_tree_rounded,
            title: 'Family Tree',
            subtitle: 'Удмын мод удирдах',
            color: const Color(0xFF4ADE80),
            onTap: () => _push(const FamilyTreeListScreen()),
          ),
          _contentTile(
            icon: Icons.quiz_rounded,
            title: 'Quizzes',
            subtitle: 'Тест, асуулт удирдах',
            color: const Color(0xFFA78BFA),
            onTap: () => _push(const QuizzesListScreen()),
          ),
        ],
      ),
    );
  }

  Widget _contentTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.captionBold.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
    );
  }

  void _push(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  BOTTOM NAVIGATION
  // ════════════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    const selected = 3;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.95),
        border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Нүүр', 0, selected),
              _navItem(Icons.explore_rounded, 'Судлах', 1, selected),
              _navItem(Icons.map_rounded, 'Газрын зураг', 2, selected),
              _navItem(
                Icons.admin_panel_settings_rounded,
                'Админ',
                3,
                selected,
              ),
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
        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
          );
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
