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
  late final TextEditingController _didYouKnowCtrl;

  bool _isPublished = false;
  String? _selectedQuizId;
  String? _imageUrl;

  // Quick facts – dynamic list of controllers
  late List<TextEditingController> _quickFactCtrls;

  // Timeline – dynamic list of (year, event) controller pairs
  late List<(TextEditingController, TextEditingController)> _timelineCtrls;

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
    _didYouKnowCtrl =
        TextEditingController(text: widget.story?.didYouKnow ?? '');
    _isPublished = widget.story?.isPublished ?? false;
    _selectedQuizId = widget.story?.quizId;
    _imageUrl = widget.story?.imageUrl;

    // Initialize quick facts controllers
    final facts = widget.story?.quickFacts ?? [];
    _quickFactCtrls = facts.isEmpty
        ? [TextEditingController()]
        : facts.map((f) => TextEditingController(text: f)).toList();

    // Initialize timeline controllers
    final tl = widget.story?.timeline ?? [];
    _timelineCtrls = tl.isEmpty
        ? [(TextEditingController(), TextEditingController())]
        : tl
            .map((m) => (
                  TextEditingController(text: m['year'] ?? ''),
                  TextEditingController(text: m['event'] ?? ''),
                ))
            .toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _contentCtrl.dispose();
    _orderCtrl.dispose();
    _xpCtrl.dispose();
    _imageUrlCtrl.dispose();
    _didYouKnowCtrl.dispose();
    for (final c in _quickFactCtrls) {
      c.dispose();
    }
    for (final (y, e) in _timelineCtrls) {
      y.dispose();
      e.dispose();
    }
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
      quickFacts: _quickFactCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      didYouKnow: _didYouKnowCtrl.text.trim().isEmpty
          ? null
          : _didYouKnowCtrl.text.trim(),
      timeline: _timelineCtrls
          .where((pair) =>
              pair.$1.text.trim().isNotEmpty || pair.$2.text.trim().isNotEmpty)
          .map((pair) => {
                'year': pair.$1.text.trim(),
                'event': pair.$2.text.trim(),
              })
          .toList(),
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

  // ── Section label ─────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: AppTheme.sectionTitle.copyWith(
        color: AppTheme.accentGold,
        fontSize: 14,
      ),
    );
  }

  // ── Quick Facts editor ────────────────────────────────────────
  List<Widget> _buildQuickFactsEditor() {
    final widgets = <Widget>[];
    for (int i = 0; i < _quickFactCtrls.length; i++) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quickFactCtrls[i],
                  style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                  decoration: adminInputDecoration(
                    label: 'Баримт ${i + 1}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_quickFactCtrls.length > 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppTheme.crimson, size: 22),
                  onPressed: () => setState(() {
                    _quickFactCtrls[i].dispose();
                    _quickFactCtrls.removeAt(i);
                  }),
                ),
            ],
          ),
        ),
      );
    }
    widgets.add(
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _quickFactCtrls.add(TextEditingController());
          }),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Баримт нэмэх'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.accentGold),
        ),
      ),
    );
    return widgets;
  }

  // ── Timeline editor ───────────────────────────────────────────
  List<Widget> _buildTimelineEditor() {
    final widgets = <Widget>[];
    for (int i = 0; i < _timelineCtrls.length; i++) {
      final (yearCtrl, eventCtrl) = _timelineCtrls[i];
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: TextFormField(
                  controller: yearCtrl,
                  style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                  decoration: adminInputDecoration(label: 'Он'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: eventCtrl,
                  style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                  decoration: adminInputDecoration(label: 'Үйл явдал'),
                ),
              ),
              const SizedBox(width: 8),
              if (_timelineCtrls.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppTheme.crimson, size: 22),
                    onPressed: () => setState(() {
                      _timelineCtrls[i].$1.dispose();
                      _timelineCtrls[i].$2.dispose();
                      _timelineCtrls.removeAt(i);
                    }),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    widgets.add(
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _timelineCtrls
                .add((TextEditingController(), TextEditingController()));
          }),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Цаг хугацаа нэмэх'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.accentGold),
        ),
      ),
    );
    return widgets;
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
                  ImagePickerField(
                    label: 'Зураг (optional)',
                    currentUrl: _imageUrl,
                    storagePath:
                        'stories/${widget.story?.id ?? 'new_${DateTime.now().millisecondsSinceEpoch}'}/cover.jpg',
                    onChanged: (url) {
                      setState(() {
                        _imageUrl = url;
                        _imageUrlCtrl.text = url ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Did You Know ──────────────────────────────
                  _buildSectionLabel('Мэдэх үү?'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _didYouKnowCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(
                      label: 'Сонирхолтой мэдээлэл (optional)',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // ── Quick Facts ───────────────────────────────
                  _buildSectionLabel('Товч баримтууд'),
                  const SizedBox(height: 8),
                  ..._buildQuickFactsEditor(),
                  const SizedBox(height: 24),

                  // ── Timeline ──────────────────────────────────
                  _buildSectionLabel('Цаг хугацааны шугам'),
                  const SizedBox(height: 8),
                  ..._buildTimelineEditor(),
                  const SizedBox(height: 24),

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
