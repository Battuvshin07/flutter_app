import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../components/admin/glass_card.dart';
import '../../providers/admin_provider.dart';
import '../../data/models/person_model.dart';
import 'shared_admin_widgets.dart';
import 'person_edit_screen.dart';
import 'person_detail_edit_screen.dart';

/// List screen for Persons with search, sort, add.
class PersonsListScreen extends StatefulWidget {
  const PersonsListScreen({super.key});

  @override
  State<PersonsListScreen> createState() => _PersonsListScreenState();
}

class _PersonsListScreenState extends State<PersonsListScreen> {
  String _searchQuery = '';

  List<PersonModel> _filtered(List<PersonModel> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(context, title: 'Persons'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentGold,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PersonEditScreen()),
        ),
        child: const Icon(Icons.add_rounded, color: AppTheme.background),
      ),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'Хайх... (нэр)',
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, admin, _) {
                final items = _filtered(admin.persons);
                if (items.isEmpty) {
                  return const AdminEmptyState(
                    message: 'Түүхэн хүн олдсонгүй.\nШинээр нэмнэ үү.',
                    icon: Icons.person_search_rounded,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.pagePadding),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _PersonTile(
                      item: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PersonEditScreen(person: item),
                        ),
                      ),
                      onDetailTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PersonDetailEditScreen(personId: item.id!),
                        ),
                      ),
                      onDelete: () async {
                        final confirmed = await showDeleteConfirmDialog(
                          context,
                          itemName: item.name,
                        );
                        if (confirmed && context.mounted) {
                          await admin.deletePerson(item.id!);
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

class _PersonTile extends StatelessWidget {
  final PersonModel item;
  final VoidCallback onTap;
  final VoidCallback onDetailTap;
  final VoidCallback onDelete;

  const _PersonTile({
    required this.item,
    required this.onTap,
    required this.onDetailTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final years = [
      if (item.birthYear != null) '${item.birthYear}',
      if (item.deathYear != null) '${item.deathYear}',
    ].join(' – ');

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
                color: const Color(0xFF60A5FA).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF60A5FA),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTheme.captionBold.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (years.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      years,
                      style: AppTheme.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.article_outlined, size: 20),
              color: AppTheme.accentGold,
              tooltip: 'Person Detail',
              onPressed: onDetailTap,
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
