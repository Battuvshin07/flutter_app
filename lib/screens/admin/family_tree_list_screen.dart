import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../components/admin/glass_card.dart';
import '../../providers/admin_provider.dart';
import '../../data/models/family_tree_model.dart';
import 'shared_admin_widgets.dart';
import 'family_tree_edit_screen.dart';

/// List screen for Family Trees with search, sort, add.
class FamilyTreeListScreen extends StatefulWidget {
  const FamilyTreeListScreen({super.key});

  @override
  State<FamilyTreeListScreen> createState() => _FamilyTreeListScreenState();
}

class _FamilyTreeListScreenState extends State<FamilyTreeListScreen> {
  String _searchQuery = '';

  List<FamilyTreeModel> _filtered(List<FamilyTreeModel> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((t) => t.title.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(context, title: 'Family Tree'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentGold,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FamilyTreeEditScreen()),
        ),
        child: const Icon(Icons.add_rounded, color: AppTheme.background),
      ),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'Хайх... (гарчиг)',
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, admin, _) {
                if (!admin.familyTreesLoaded) return const AdminLoadingState();
                final items = _filtered(admin.familyTrees);
                if (items.isEmpty) {
                  return const AdminEmptyState(
                    message: 'Удмын мод олдсонгүй.\nШинээр нэмнэ үү.',
                    icon: Icons.account_tree_rounded,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.pagePadding),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _FamilyTreeTile(
                      item: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FamilyTreeEditScreen(familyTree: item),
                        ),
                      ),
                      onDelete: () async {
                        final confirmed = await showDeleteConfirmDialog(
                          context,
                          itemName: item.title,
                        );
                        if (confirmed && context.mounted) {
                          await admin.deleteFamilyTree(item.id!);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyTreeTile extends StatelessWidget {
  final FamilyTreeModel item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FamilyTreeTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_tree_rounded,
                color: Color(0xFF4ADE80),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTheme.captionBold.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.nodes.length} nodes, ${item.edges.length} edges',
                    style: AppTheme.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppTheme.crimson,
              onPressed: onDelete,
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
