import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/person_model.dart';
import 'shared_admin_widgets.dart';

/// Create / Edit screen for a single Person.
class PersonEditScreen extends StatefulWidget {
  final PersonModel? person;

  const PersonEditScreen({super.key, this.person});

  @override
  State<PersonEditScreen> createState() => _PersonEditScreenState();
}

class _PersonEditScreenState extends State<PersonEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _birthYearCtrl;
  late final TextEditingController _deathYearCtrl;
  late final TextEditingController _shortBioCtrl;
  late final TextEditingController _avatarUrlCtrl;
  late final TextEditingController _tagsCtrl;

  bool get _isEditing => widget.person != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.person?.name ?? '');
    _birthYearCtrl =
        TextEditingController(text: widget.person?.birthYear?.toString() ?? '');
    _deathYearCtrl =
        TextEditingController(text: widget.person?.deathYear?.toString() ?? '');
    _shortBioCtrl = TextEditingController(text: widget.person?.shortBio ?? '');
    _avatarUrlCtrl =
        TextEditingController(text: widget.person?.avatarUrl ?? '');
    _tagsCtrl =
        TextEditingController(text: widget.person?.tags.join(', ') ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthYearCtrl.dispose();
    _deathYearCtrl.dispose();
    _shortBioCtrl.dispose();
    _avatarUrlCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final model = PersonModel(
      id: widget.person?.id,
      name: _nameCtrl.text.trim(),
      birthYear: int.tryParse(_birthYearCtrl.text.trim()),
      deathYear: int.tryParse(_deathYearCtrl.text.trim()),
      shortBio: _shortBioCtrl.text.trim(),
      avatarUrl: _avatarUrlCtrl.text.trim().isEmpty
          ? null
          : _avatarUrlCtrl.text.trim(),
      tags: tags,
      updatedBy: uid,
    );

    bool success;
    if (_isEditing) {
      success = await admin.updatePerson(model);
    } else {
      success = await admin.createPerson(model);
    }

    if (success && mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed =
        await showDeleteConfirmDialog(context, itemName: _nameCtrl.text);
    if (!confirmed || !mounted) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final success = await admin.deletePerson(widget.person!.id!);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(
        context,
        title: _isEditing ? 'Person засах' : 'Person нэмэх',
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
                    controller: _nameCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Нэр *'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Нэр оруулна уу'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _birthYearCtrl,
                          style: AppTheme.body
                              .copyWith(color: AppTheme.textPrimary),
                          decoration: adminInputDecoration(label: 'Төрсөн он'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _deathYearCtrl,
                          style: AppTheme.body
                              .copyWith(color: AppTheme.textPrimary),
                          decoration:
                              adminInputDecoration(label: 'Нас барсан он'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _shortBioCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Товч намтар *'),
                    maxLines: 4,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Намтар оруулна уу'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _avatarUrlCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration:
                        adminInputDecoration(label: 'Avatar URL (optional)'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tagsCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(
                      label: 'Tags (таслалаар тусгаарлах)',
                      hint: 'хаан, байлдагч, ...',
                    ),
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
