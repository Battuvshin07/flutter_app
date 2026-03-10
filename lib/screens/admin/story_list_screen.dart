import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../components/admin/glass_card.dart';
import '../../providers/admin_provider.dart';
import '../../data/models/story_model.dart';
import 'shared_admin_widgets.dart';
import 'story_edit_screen.dart';

/// List screen for Stories (ordered by order field), with search and CRUD.
class StoryListScreen extends StatefulWidget {
  const StoryListScreen({super.key});

  @override
  State<StoryListScreen> createState() => _StoryListScreenState();
}

class _StoryListScreenState extends State<StoryListScreen> {
  String _searchQuery = '';

  List<StoryModel> _filtered(List<StoryModel> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.subtitle.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(context, title: 'Stories'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentGold,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StoryEditScreen()),
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
                if (!admin.storiesLoaded) return const AdminLoadingState();
                final items = _filtered(admin.stories);
                if (items.isEmpty) {
                  return const AdminEmptyState(
                    message: 'Түүх олдсонгүй.\nШинээр нэмнэ үү.',
                    icon: Icons.menu_book_rounded,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.pagePadding),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _StoryTile(
                      item: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoryEditScreen(story: item),
                        ),
                      ),
                      onDelete: () async {
                        final confirmed = await showDeleteConfirmDialog(
                          context,
                          itemName: item.title,
                        );
                        if (confirmed && context.mounted) {
                          await Provider.of<AdminProvider>(context,
                                  listen: false)
                              .deleteStory(item.id!);
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

class _StoryTile extends StatelessWidget {
  final StoryModel item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _StoryTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final publishColor =
        item.isPublished ? const Color(0xFF4ADE80) : AppTheme.textSecondary;
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
                color: const Color(0xFFA78BFA).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFFA78BFA),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.order}. ${item.title}',
                    style: AppTheme.captionBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${item.xpReward} XP',
                        style: AppTheme.chip.copyWith(
                          fontSize: 10,
                          color: AppTheme.accentGold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.isPublished ? 'Нийтлэгдсэн' : 'Ноорог',
                        style: AppTheme.chip
                            .copyWith(fontSize: 10, color: publishColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: AppTheme.crimson),
              onPressed: onDelete,
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
