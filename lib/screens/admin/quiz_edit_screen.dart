import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/quiz_model.dart';
import 'shared_admin_widgets.dart';

/// Create / Edit screen for a Quiz with inline question editing.
class QuizEditScreen extends StatefulWidget {
  final QuizModel? quiz;

  const QuizEditScreen({super.key, this.quiz});

  @override
  State<QuizEditScreen> createState() => _QuizEditScreenState();
}

class _QuizEditScreenState extends State<QuizEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _topicCtrl;

  String _difficulty = 'easy';
  bool _isPublished = false;

  // Dynamic question list
  List<_QuestionRow> _questionRows = [];

  bool get _isEditing => widget.quiz != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.quiz?.title ?? '');
    _descCtrl = TextEditingController(text: widget.quiz?.description ?? '');
    _topicCtrl = TextEditingController(text: widget.quiz?.topic ?? '');
    _difficulty = widget.quiz?.difficulty ?? 'easy';
    _isPublished = widget.quiz?.isPublished ?? false;

    if (widget.quiz != null) {
      _questionRows = widget.quiz!.questions
          .map((q) => _QuestionRow(
                idCtrl: TextEditingController(text: q.id),
                questionCtrl: TextEditingController(text: q.question),
                optionCtrls: List.generate(
                  4,
                  (i) => TextEditingController(
                    text: i < q.options.length ? q.options[i] : '',
                  ),
                ),
                correctIndex: q.correctIndex,
                explanationCtrl:
                    TextEditingController(text: q.explanation ?? ''),
              ))
          .toList();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _topicCtrl.dispose();
    for (final r in _questionRows) {
      r.idCtrl.dispose();
      r.questionCtrl.dispose();
      for (final c in r.optionCtrls) {
        c.dispose();
      }
      r.explanationCtrl.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questionRows.add(_QuestionRow(
        idCtrl: TextEditingController(
            text: 'q${DateTime.now().millisecondsSinceEpoch}'),
        questionCtrl: TextEditingController(),
        optionCtrls: List.generate(4, (_) => TextEditingController()),
        correctIndex: 0,
        explanationCtrl: TextEditingController(),
      ));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    final questions = _questionRows.map((r) {
      return QuizQuestion(
        id: r.idCtrl.text.trim(),
        question: r.questionCtrl.text.trim(),
        options: r.optionCtrls.map((c) => c.text.trim()).toList(),
        correctIndex: r.correctIndex,
        explanation: r.explanationCtrl.text.trim().isEmpty
            ? null
            : r.explanationCtrl.text.trim(),
      );
    }).toList();

    final model = QuizModel(
      id: widget.quiz?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      difficulty: _difficulty,
      topic: _topicCtrl.text.trim(),
      isPublished: _isPublished,
      questions: questions,
      updatedBy: uid,
    );

    bool success;
    if (_isEditing) {
      success = await admin.updateQuiz(model);
    } else {
      success = await admin.createQuiz(model);
    }

    if (success && mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed =
        await showDeleteConfirmDialog(context, itemName: _titleCtrl.text);
    if (!confirmed || !mounted) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final success = await admin.deleteQuiz(widget.quiz!.id!);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(
        context,
        title: _isEditing ? 'Quiz засах' : 'Quiz нэмэх',
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
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _topicCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Сэдэв (topic)'),
                  ),
                  const SizedBox(height: 16),

                  // Difficulty selector
                  Text('Түвшин', style: AppTheme.caption),
                  const SizedBox(height: 8),
                  Row(
                    children: ['easy', 'medium', 'hard'].map((d) {
                      final isSelected = d == _difficulty;
                      final color = {
                            'easy': const Color(0xFF4ADE80),
                            'medium': AppTheme.streakOrange,
                            'hard': AppTheme.crimson,
                          }[d] ??
                          AppTheme.textSecondary;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(d),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _difficulty = d),
                          selectedColor: color.withValues(alpha: 0.25),
                          backgroundColor: AppTheme.surface,
                          side: BorderSide(
                            color: isSelected ? color : AppTheme.cardBorder,
                          ),
                          labelStyle: AppTheme.chip.copyWith(
                            color: isSelected ? color : AppTheme.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  // isPublished toggle
                  SwitchListTile(
                    value: _isPublished,
                    onChanged: (v) => setState(() => _isPublished = v),
                    title: Text('Нийтлэх (Published)',
                        style: AppTheme.captionBold),
                    activeColor: AppTheme.accentGold,
                    tileColor: AppTheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppTheme.cardBorder),
                    ),
                  ),

                  // ── Questions ──
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Асуултууд',
                          style: AppTheme.sectionTitle.copyWith(fontSize: 14)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppTheme.accentGold),
                        onPressed: _addQuestion,
                      ),
                    ],
                  ),

                  ..._questionRows.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    return _buildQuestionCard(i, r);
                  }),

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

  Widget _buildQuestionCard(int index, _QuestionRow r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Асуулт ${index + 1}',
                  style: AppTheme.captionBold.copyWith(fontSize: 13)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.crimson, size: 20),
                onPressed: () => setState(() => _questionRows.removeAt(index)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: r.questionCtrl,
            style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
            decoration: adminInputDecoration(label: 'Асуулт'),
          ),
          const SizedBox(height: 12),
          ...List.generate(4, (oi) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Radio<int>(
                    value: oi,
                    groupValue: r.correctIndex,
                    onChanged: (v) => setState(() => r.correctIndex = v ?? 0),
                    activeColor: AppTheme.accentGold,
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: r.optionCtrls[oi],
                      style:
                          AppTheme.body.copyWith(color: AppTheme.textPrimary),
                      decoration:
                          adminInputDecoration(label: 'Хариулт ${oi + 1}'),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          TextFormField(
            controller: r.explanationCtrl,
            style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
            decoration: adminInputDecoration(label: 'Тайлбар (optional)'),
          ),
        ],
      ),
    );
  }
}

class _QuestionRow {
  final TextEditingController idCtrl;
  final TextEditingController questionCtrl;
  final List<TextEditingController> optionCtrls;
  int correctIndex;
  final TextEditingController explanationCtrl;

  _QuestionRow({
    required this.idCtrl,
    required this.questionCtrl,
    required this.optionCtrls,
    required this.correctIndex,
    required this.explanationCtrl,
  });
}
