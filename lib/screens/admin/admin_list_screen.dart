import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../components/admin/glass_card.dart';
import '../../providers/admin_provider.dart';
import 'shared_admin_widgets.dart';
import 'admin_collection_config.dart';

// ══════════════════════════════════════════════════════════════════
//  REUSABLE ADMIN LIST SCREEN
//  A single screen that renders any admin collection by looking up
//  its AdminCollectionConfig.  Supports search, delete, edit, add.
// ══════════════════════════════════════════════════════════════════

class AdminListScreen extends StatefulWidget {
  /// Key into [adminCollections] map — e.g. 'cultures', 'persons'.
  final String collectionKey;

  const AdminListScreen({super.key, required this.collectionKey});

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  String _searchQuery = '';

  AdminCollectionConfig get _config => adminCollections[widget.collectionKey]!;

  List<dynamic> _filtered(List<dynamic> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((item) => _config.searchMatcher(item, q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;

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
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────
              _buildHeader(config),

              // ── Search ───────────────────────────────────────
              _buildSearchBar(config),

              // ── List ─────────────────────────────────────────
              Expanded(
                child: Consumer<AdminProvider>(
                  builder: (context, admin, _) {
                    if (!config.isLoaded(admin)) {
                      return const AdminLoadingState();
                    }

                    final allItems = config.getItems(admin);
                    final items = _filtered(allItems);

                    if (items.isEmpty) {
                      return AdminEmptyState(
                        message: _searchQuery.isNotEmpty
                            ? 'Хайлтын үр дүн олдсонгүй.'
                            : config.emptyMessage,
                        icon: config.icon,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.pagePadding,
                        4,
                        AppTheme.pagePadding,
                        100,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _buildItemTile(
                          context,
                          config,
                          items[index],
                          admin,
                          index,
                          items.length,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // ── FAB ──────────────────────────────────────────────────
      floatingActionButton: _buildFab(config),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  HEADER
  // ════════════════════════════════════════════════════════════════
  Widget _buildHeader(AdminCollectionConfig config) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        4,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
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

          // Collection icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: config.color.withOpacity(0.25)),
            ),
            child: Icon(config.icon, color: config.color, size: 20),
          ),
          const SizedBox(width: 12),

          // Title + count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(config.title, style: AppTheme.sectionTitle),
                Consumer<AdminProvider>(
                  builder: (context, admin, _) {
                    final count = config.getItems(admin).length;
                    return Text(
                      '$count зүйл',
                      style: AppTheme.caption.copyWith(fontSize: 11),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SEARCH BAR
  // ════════════════════════════════════════════════════════════════
  Widget _buildSearchBar(AdminCollectionConfig config) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 10,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: config.searchHint,
          hintStyle: AppTheme.caption,
          border: InputBorder.none,
          icon: Icon(
            Icons.search_rounded,
            color: config.color.withOpacity(0.7),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () => setState(() => _searchQuery = ''),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  ITEM TILE
  // ════════════════════════════════════════════════════════════════
  Widget _buildItemTile(
    BuildContext context,
    AdminCollectionConfig config,
    dynamic item,
    AdminProvider admin,
    int index,
    int total,
  ) {
    final title = config.getItemTitle(item);
    final subtitle = config.getItemSubtitle(item);
    final badges = config.badgeBuilder?.call(item);
    final extraActions = config.extraActionsBuilder?.call(context, item);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => config.editScreenBuilder(item)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          borderRadius: AppTheme.radiusMd,
          child: Row(
            children: [
              // ── Icon ──
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: config.color.withOpacity(0.2)),
                ),
                child: Icon(config.icon, color: config.color, size: 22),
              ),
              const SizedBox(width: 14),

              // ── Title + subtitle/badges ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.captionBold.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (badges != null && badges.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: badges,
                      ),
                    ] else if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTheme.caption.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // ── Extra actions ──
              if (extraActions != null) ...extraActions,

              // ── Delete button ──
              GestureDetector(
                onTap: () => _handleDelete(context, config, item, admin),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.crimson,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // ── Chevron ──
              Icon(
                Icons.chevron_right_rounded,
                color: config.color.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  DELETE HANDLER
  // ════════════════════════════════════════════════════════════════
  Future<void> _handleDelete(
    BuildContext context,
    AdminCollectionConfig config,
    dynamic item,
    AdminProvider admin,
  ) async {
    final name = config.getItemTitle(item);
    final confirmed = await showDeleteConfirmDialog(context, itemName: name);
    if (confirmed && context.mounted) {
      final id = config.getItemId(item);
      if (id != null) {
        await config.deleteItem(admin, id);
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  FAB
  // ════════════════════════════════════════════════════════════════
  Widget _buildFab(AdminCollectionConfig config) {
    return FloatingActionButton.extended(
      backgroundColor: config.color,
      foregroundColor: AppTheme.background,
      icon: const Icon(Icons.add_rounded, size: 22),
      label: Text('Нэмэх', style: AppTheme.button),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => config.createScreenBuilder()),
      ),
    );
  }
}
