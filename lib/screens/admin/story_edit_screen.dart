import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../components/admin/glass_card.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/story_model.dart';
import 'shared_admin_widgets.dart';

/// Create / Edit screen for a Story, including quiz link and XP reward.
class StoryEditScreen extends StatefulWidget {
  final StoryModel? story;

  const StoryEditScreen({super.key, this.story});

  @override
  State<StoryEditScreen> createState() => _StoryEditScreenState();
}

class _StoryEditScreenState extends State<StoryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _orderCtrl;
  late final TextEditingController _xpCtrl;
  late final TextEditingController _imageUrlCtrl;

  bool _isPublished = false;
  String? _selectedQuizId;

  bool get _isEditing => widget.story != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.story?.title ?? '');
    _subtitleCtrl = TextEditingController(text: widget.story?.subtitle ?? '');
    _contentCtrl = TextEditingController(text: widget.story?.content ?? '');
    _orderCtrl = TextEditingController(text: '${widget.story?.order ?? 1}');
    _xpCtrl = TextEditingController(text: '${widget.story?.xpReward ?? 100}');
    _imageUrlCtrl = TextEditingController(text: widget.story?.imageUrl ?? '');
    _isPublished = widget.story?.isPublished ?? false;
    _selectedQuizId = widget.story?.quizId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _contentCtrl.dispose();
    _orderCtrl.dispose();
    _xpCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    final model = StoryModel(
      id: widget.story?.id,
      title: _titleCtrl.text.trim(),
      subtitle: _subtitleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      order: int.tryParse(_orderCtrl.text.trim()) ?? 1,
      xpReward: int.tryParse(_xpCtrl.text.trim()) ?? 100,
      quizId: _selectedQuizId,
      isPublished: _isPublished,
      imageUrl:
          _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim(),
      updatedBy: uid,
    );

    final success = _isEditing
        ? await admin.updateStory(model)
        : await admin.createStory(model);
    if (success && mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed =
        await showDeleteConfirmDialog(context, itemName: _titleCtrl.text);
    if (!confirmed || !mounted) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final success = await admin.deleteStory(widget.story!.id!);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(
        context,
        title: _isEditing ? 'Story засах' : 'Story нэмэх',
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

          // Build quiz dropdown items
          final quizItems = [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Quiz байхгүй'),
            ),
            ...admin.quizzes.map(
              (q) => DropdownMenuItem<String>(
                value: q.id,
                child: Text(
                  q.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ];

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
                    controller: _subtitleCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration:
                        adminInputDecoration(label: 'Дэд гарчиг (optional)'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contentCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Агуулга'),
                    maxLines: 10,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _orderCtrl,
                          style: AppTheme.body
                              .copyWith(color: AppTheme.textPrimary),
                          decoration: adminInputDecoration(label: 'Дараалал *'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Оруулна уу';
                            }
                            if (int.tryParse(v.trim()) == null) {
                              return 'Тоо оруулна уу';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _xpCtrl,
                          style: AppTheme.body
                              .copyWith(color: AppTheme.textPrimary),
                          decoration: adminInputDecoration(label: 'XP шагнал'),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imageUrlCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration:
                        adminInputDecoration(label: 'Зургийн URL (optional)'),
                  ),
                  const SizedBox(height: 16),

                  // Quiz selector
                  DropdownButtonFormField<String>(
                    value: _selectedQuizId,
                    dropdownColor: AppTheme.surface,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Холбоотой Quiz'),
                    items: quizItems,
                    onChanged: (v) => setState(() => _selectedQuizId = v),
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
