import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../components/admin/glass_card.dart';
import '../../providers/admin_provider.dart';
import '../../data/models/culture_model.dart';
import 'shared_admin_widgets.dart';
import 'culture_edit_screen.dart';

/// List screen for Culture items with search, sort, add.
class CultureListScreen extends StatefulWidget {
  const CultureListScreen({super.key});

  @override
  State<CultureListScreen> createState() => _CultureListScreenState();
}

class _CultureListScreenState extends State<CultureListScreen> {
  String _searchQuery = '';

  List<CultureModel> _filtered(List<CultureModel> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((c) => c.title.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(context, title: 'Culture'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentGold,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CultureEditScreen()),
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
                final items = _filtered(admin.cultures);
                if (items.isEmpty) {
                  return const AdminEmptyState(
                    message: 'Соёлын контент олдсонгүй.\nШинээр нэмнэ үү.',
                    icon: Icons.theater_comedy_rounded,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.pagePadding),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _CultureTile(
                      item: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CultureEditScreen(culture: item),
                        ),
                      ),
                      onDelete: () async {
                        final confirmed = await showDeleteConfirmDialog(
                          context,
                          itemName: item.title,
                        );
                        if (confirmed && context.mounted) {
                          await admin.deleteCulture(item.id!);
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

class _CultureTile extends StatelessWidget {
  final CultureModel item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CultureTile({
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
                color: AppTheme.accentGold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.theater_comedy_rounded,
                color: AppTheme.accentGold,
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
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: AppTheme.caption.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
