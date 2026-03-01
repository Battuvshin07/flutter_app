import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/culture_model.dart';
import 'shared_admin_widgets.dart';

/// Create / Edit screen for a single Culture item.
class CultureEditScreen extends StatefulWidget {
  final CultureModel? culture;

  const CultureEditScreen({super.key, this.culture});

  @override
  State<CultureEditScreen> createState() => _CultureEditScreenState();
}

class _CultureEditScreenState extends State<CultureEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _orderCtrl;

  bool get _isEditing => widget.culture != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.culture?.title ?? '');
    _descCtrl = TextEditingController(text: widget.culture?.description ?? '');
    _imageUrlCtrl =
        TextEditingController(text: widget.culture?.coverImageUrl ?? '');
    _orderCtrl = TextEditingController(text: '${widget.culture?.order ?? 0}');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    final model = CultureModel(
      id: widget.culture?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      coverImageUrl:
          _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim(),
      order: int.tryParse(_orderCtrl.text.trim()) ?? 0,
      updatedBy: uid,
    );

    bool success;
    if (_isEditing) {
      success = await admin.updateCulture(model);
    } else {
      success = await admin.createCulture(model);
    }

    if (success && mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed =
        await showDeleteConfirmDialog(context, itemName: _titleCtrl.text);
    if (!confirmed || !mounted) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final success = await admin.deleteCulture(widget.culture!.id!);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(
        context,
        title: _isEditing ? 'Culture засах' : 'Culture нэмэх',
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
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
                  TextFormField(
                    controller: _descCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Тайлбар'),
                    maxLines: 4,
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
                    decoration: adminInputDecoration(label: 'Эрэмбэ (order)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  AdminSaveButton(
                    onPressed: _save,
                    isLoading: admin.isLoading,
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    AdminDeleteButton(onPressed: _delete),
                  ],
                  if (admin.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      admin.error!,
                      style: AppTheme.caption.copyWith(color: AppTheme.crimson),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
