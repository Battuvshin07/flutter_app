import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../components/admin/glass_card.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/content_model.dart';
import 'shared_admin_widgets.dart';

const _contentTypes = ['article', 'video', 'gallery', 'audio', 'other'];

/// Create / Edit screen for a Content item.
class ContentEditScreen extends StatefulWidget {
  final ContentModel? content;

  const ContentEditScreen({super.key, this.content});

  @override
  State<ContentEditScreen> createState() => _ContentEditScreenState();
}

class _ContentEditScreenState extends State<ContentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _orderCtrl;

  String _type = 'article';
  bool _isPublished = false;

  bool get _isEditing => widget.content != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.content?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.content?.body ?? '');
    _imageUrlCtrl =
        TextEditingController(text: widget.content?.coverImageUrl ?? '');
    _orderCtrl = TextEditingController(text: '${widget.content?.order ?? 0}');
    _type = widget.content?.type ?? 'article';
    _isPublished = widget.content?.isPublished ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageUrlCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    final model = ContentModel(
      id: widget.content?.id,
      title: _titleCtrl.text.trim(),
      type: _type,
      body: _bodyCtrl.text.trim(),
      coverImageUrl:
          _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim(),
      isPublished: _isPublished,
      order: int.tryParse(_orderCtrl.text.trim()) ?? 0,
      updatedBy: uid,
    );

    final success = _isEditing
        ? await admin.updateContent(model)
        : await admin.createContent(model);
    if (success && mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed =
        await showDeleteConfirmDialog(context, itemName: _titleCtrl.text);
    if (!confirmed || !mounted) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final success = await admin.deleteContent(widget.content!.id!);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(
        context,
        title: _isEditing ? 'Content засах' : 'Content нэмэх',
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          if (admin.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(admin.error!),
                  backgroundColor: AppTheme.crimson,
                ),
              );
              admin.clearError();
            });
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.pagePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Гарчиг *'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Гарчиг оруулна уу'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Type dropdown
                  Text('Төрөл', style: AppTheme.caption),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _type,
                    dropdownColor: AppTheme.surface,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Төрөл'),
                    items: _contentTypes
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v ?? 'article'),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _bodyCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration:
                        adminInputDecoration(label: 'Агуулга / Тайлбар'),
                    maxLines: 8,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _imageUrlCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration:
                        adminInputDecoration(label: 'Зургийн URL (optional)'),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _orderCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Дараалал (order)'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v != null &&
                          v.isNotEmpty &&
                          int.tryParse(v) == null) {
                        return 'Тоо оруулна уу';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Published toggle
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Нийтлэгдсэн', style: AppTheme.body),
                        Switch(
                          value: _isPublished,
                          onChanged: (v) => setState(() => _isPublished = v),
                          activeColor: AppTheme.accentGold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  AdminSaveButton(
                    onPressed: _save,
                    isLoading: admin.isLoading,
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    AdminDeleteButton(
                        onPressed: admin.isLoading ? null : _delete),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
