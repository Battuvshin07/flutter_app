import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../data/models/culture_model.dart';

/// Dribbble-level Culture Detail Screen.
/// Hero banner → tabs (Тойм / Агуулга) → gold CTA button.
class CultureDetailScreen extends StatefulWidget {
  final CultureModel item;
  final Color accentColor;
  final IconData icon;
  final double progress;
  final VoidCallback? onCompleted;

  const CultureDetailScreen({
    super.key,
    required this.item,
    required this.accentColor,
    required this.icon,
    this.progress = 0.0,
    this.onCompleted,
  });

  @override
  State<CultureDetailScreen> createState() => _CultureDetailScreenState();
}

class _CultureDetailScreenState extends State<CultureDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildHeroSliver(context),
              SliverToBoxAdapter(child: _buildTabBar()),
              SliverFillRemaining(
                hasScrollBody: true,
                child: _buildTabViews(),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCTA(context),
          ),
        ],
      ),
    );
  }

  // ── Hero sliver ────────────────────────────────────────────────
  Widget _buildHeroSliver(BuildContext context) {
    final title = widget.item.title;

    return SliverAppBar(
      expandedHeight: 264,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.background,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.45),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 17),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.45),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
            child: const Icon(Icons.bookmark_border_rounded,
                color: Colors.white, size: 19),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        titlePadding: EdgeInsets.zero,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient hero background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.accentColor.withValues(alpha: 0.18),
                    AppTheme.surface.withValues(alpha: 0.6),
                    AppTheme.background,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accentColor.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: -50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accentColor.withValues(alpha: 0.04),
                ),
              ),
            ),
            // Hero image or glowing icon
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: _buildHeroVisual(),
              ),
            ),
            // Title + badges pinned to bottom
            Positioned(
              bottom: 16,
              left: AppTheme.pagePadding,
              right: AppTheme.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTheme.h2.copyWith(fontSize: 23)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _badge('XP +20', AppTheme.accentGold,
                          AppTheme.accentGold.withValues(alpha: 0.14)),
                      const SizedBox(width: 8),
                      _badge('● Хялбар', AppTheme.xpGreen,
                          AppTheme.xpGreen.withValues(alpha: 0.12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroVisual() {
    final hasImage = widget.item.coverImageUrl != null &&
        widget.item.coverImageUrl!.trim().isNotEmpty;
    if (hasImage) {
      return Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withValues(alpha: 0.32),
              blurRadius: 36,
              spreadRadius: 6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            widget.item.coverImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _glowingIcon(),
          ),
        ),
      );
    }
    return _glowingIcon();
  }

  Widget _glowingIcon() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.accentColor.withValues(alpha: 0.12),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.28),
            blurRadius: 36,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Icon(widget.icon, color: widget.accentColor, size: 52),
    );
  }

  Widget _badge(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: textColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: AppTheme.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding, 8, AppTheme.pagePadding, 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: TabBar(
        controller: _tabs,
        labelColor: widget.accentColor,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle:
            AppTheme.chip.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle:
            AppTheme.chip.copyWith(fontWeight: FontWeight.w500, fontSize: 12),
        indicator: BoxDecoration(
          color: widget.accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd - 2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Тойм'),
          Tab(text: 'Агуулга'),
        ],
      ),
    );
  }

  // ── Tab views ──────────────────────────────────────────────────
  Widget _buildTabViews() {
    return TabBarView(
      controller: _tabs,
      children: [
        _ToymTab(item: widget.item, accentColor: widget.accentColor),
        _AguurlagTab(item: widget.item, accentColor: widget.accentColor),
      ],
    );
  }

  // ── Golden CTA ─────────────────────────────────────────────────
  Widget _buildBottomCTA(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppTheme.pagePadding, 14, AppTheme.pagePadding, bottomPad + 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.background.withValues(alpha: 0.0),
            AppTheme.background.withValues(alpha: 0.96),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          widget.onCompleted?.call();
          Navigator.pop(context);
        },
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFDAAB28),
                Color(0xFFF4C84A),
                Color(0xFFFFD97D),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGold.withValues(alpha: 0.38),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Судалж дуусгах',
                style: AppTheme.button.copyWith(
                  fontSize: 16,
                  color: AppTheme.background,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppTheme.background, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Тойм tab ──────────────────────────────────────────────────────
class _ToymTab extends StatelessWidget {
  final CultureModel item;
  final Color accentColor;

  const _ToymTab({required this.item, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final bullets = _bullets(item.order);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding, 12, AppTheme.pagePadding, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            glowColor: accentColor,
            glowIntensity: 0.05,
            padding: const EdgeInsets.all(18),
            child: Text(
              item.description,
              style: AppTheme.body.copyWith(height: 1.8),
            ),
          ),
          const SizedBox(height: 18),
          Text('Онцлог мэдээлэл', style: AppTheme.sectionTitle),
          const SizedBox(height: 12),
          ...bullets.map((b) =>
              _BulletItem(icon: b.$1, label: b.$2, accentColor: accentColor)),
        ],
      ),
    );
  }

  static List<(IconData, String)> _bullets(int id) {
    switch (id) {
      case 1:
        return [
          (Icons.swap_horiz_rounded, '4–8 удаа нүүдэллэх'),
          (Icons.pets_rounded, 'Мал аж ахуй — тавин хошуу мал'),
          (Icons.home_rounded, 'Гэр, дулаан аюулгүй амьдрал'),
        ];
      case 2:
        return [
          (Icons.format_list_numbered_rounded, 'Аравтын систем'),
          (Icons.flash_on_rounded, 'Хурдан морин довтолгоо'),
          (Icons.visibility_rounded, 'Тагнуулын сүлжээ'),
        ];
      case 3:
        return [
          (Icons.route_rounded, '6,500 км урт худалдааны зам'),
          (Icons.currency_exchange_rounded, 'Дорно–Өрнийн худалдаа'),
          (Icons.person_rounded, 'Марко Поло энэ замаар аялсан'),
        ];
      case 4:
        return [
          (Icons.balance_rounded, 'Бүх шашны эрх чөлөө'),
          (Icons.church_rounded, 'Олон шашныг хүлээн зөвшөөрсөн'),
          (Icons.shield_rounded, 'Сүм хийдийг татвараас чөлөөлсөн'),
        ];
      case 5:
        return [
          (Icons.edit_rounded, 'Уйгур бичгийг үндэслэсэн'),
          (Icons.menu_book_rounded, 'Монголын нууц товчоо — 1240 он'),
          (Icons.translate_rounded, 'Олон хэлний бичиг'),
        ];
      case 6:
        return [
          (Icons.local_dining_rounded, 'Мах, сүүн бүтээгдэхүүн суурилсан'),
          (Icons.local_bar_rounded, 'Айраг — гүүний сүүнээс хийсэн'),
          (Icons.inventory_2_rounded, 'Борц — уяжийн хатаасан мах'),
        ];
      default:
        return [
          (Icons.star_rounded, 'Онцлог мэдээлэл 1'),
          (Icons.star_rounded, 'Онцлог мэдээлэл 2'),
          (Icons.star_rounded, 'Онцлог мэдээлэл 3'),
        ];
    }
  }
}

class _BulletItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;

  const _BulletItem(
      {required this.icon, required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: accentColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTheme.body
                  .copyWith(color: AppTheme.textPrimary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Агуулга tab ────────────────────────────────────────────────────
class _AguurlagTab extends StatelessWidget {
  final CultureModel item;
  final Color accentColor;

  const _AguurlagTab({required this.item, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding, 12, AppTheme.pagePadding, 100),
      child: GlassCard(
        glowColor: accentColor,
        glowIntensity: 0.04,
        padding: const EdgeInsets.all(20),
        child: Text(
          item.details ?? item.description,
          style: AppTheme.body.copyWith(height: 1.85),
        ),
      ),
    );
  }
}
