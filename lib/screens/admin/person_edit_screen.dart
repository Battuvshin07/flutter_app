import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/person_model.dart';
import '../../data/models/person_detail_model.dart';
import 'shared_admin_widgets.dart';

/// Create / Edit screen for a Person + their PersonDetail in one place.
class PersonEditScreen extends StatefulWidget {
  final PersonModel? person;

  const PersonEditScreen({super.key, this.person});

  @override
  State<PersonEditScreen> createState() => _PersonEditScreenState();
}

class _PersonEditScreenState extends State<PersonEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Person base fields ─────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _birthYearCtrl;
  late final TextEditingController _deathYearCtrl;
  late final TextEditingController _shortBioCtrl;
  late final TextEditingController _avatarUrlCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _tagsCtrl;
  String? _fatherId;

  // ── Person detail fields ───────────────────────────────────────
  late final TextEditingController _longBioCtrl;
  late final TextEditingController _achievementsCtrl;
  List<_TimelineRow> _timelineRows = [];
  List<_SourceRow> _sourceRows = [];
  bool _detailLoading = false;

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
    _titleCtrl = TextEditingController(text: widget.person?.title ?? '');
    _fatherId = widget.person?.fatherId;
    _tagsCtrl =
        TextEditingController(text: widget.person?.tags.join(', ') ?? '');
    _longBioCtrl = TextEditingController();
    _achievementsCtrl = TextEditingController();

    if (_isEditing) {
      _detailLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
    }
  }

  Future<void> _loadDetail() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final detail = await admin.getPersonDetail(widget.person!.id!);
    if (detail != null && mounted) {
      _longBioCtrl.text = detail.longBio;
      _achievementsCtrl.text = detail.achievements.join('\n');
      _timelineRows = detail.timeline
          .map((t) => _TimelineRow(
                yearCtrl: TextEditingController(text: '${t.year}'),
                textCtrl: TextEditingController(text: t.text),
              ))
          .toList();
      _sourceRows = detail.sources
          .map((s) => _SourceRow(
                titleCtrl: TextEditingController(text: s.title),
                urlCtrl: TextEditingController(text: s.url),
              ))
          .toList();
    }
    if (mounted) setState(() => _detailLoading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthYearCtrl.dispose();
    _deathYearCtrl.dispose();
    _shortBioCtrl.dispose();
    _avatarUrlCtrl.dispose();
    _titleCtrl.dispose();
    _tagsCtrl.dispose();
    _longBioCtrl.dispose();
    _achievementsCtrl.dispose();
    for (final r in _timelineRows) {
      r.yearCtrl.dispose();
      r.textCtrl.dispose();
    }
    for (final r in _sourceRows) {
      r.titleCtrl.dispose();
      r.urlCtrl.dispose();
    }
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

    final personModel = PersonModel(
      id: widget.person?.id,
      name: _nameCtrl.text.trim(),
      birthYear: int.tryParse(_birthYearCtrl.text.trim()),
      deathYear: int.tryParse(_deathYearCtrl.text.trim()),
      shortBio: _shortBioCtrl.text.trim(),
      avatarUrl: _avatarUrlCtrl.text.trim().isEmpty
          ? null
          : _avatarUrlCtrl.text.trim(),
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      fatherId: _fatherId,
      motherId: widget.person?.motherId,
      tags: tags,
      updatedBy: uid,
    );

    String? personId;
    if (_isEditing) {
      final ok = await admin.updatePerson(personModel);
      if (!ok || !mounted) return;
      personId = widget.person!.id!;
    } else {
      personId = await admin.createPersonAndGetId(personModel);
      if (personId == null || !mounted) return;
    }

    await _saveDetail(admin, personId, uid);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveDetail(
      AdminProvider admin, String personId, String? uid) async {
    final achievements = _achievementsCtrl.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final timeline = _timelineRows
        .where((r) => r.textCtrl.text.trim().isNotEmpty)
        .map((r) => TimelineEntry(
              year: int.tryParse(r.yearCtrl.text.trim()) ?? 0,
              text: r.textCtrl.text.trim(),
            ))
        .toList();

    final sources = _sourceRows
        .where((r) => r.titleCtrl.text.trim().isNotEmpty)
        .map((r) => SourceRef(
              title: r.titleCtrl.text.trim(),
              url: r.urlCtrl.text.trim(),
            ))
        .toList();

    await admin.savePersonDetail(PersonDetailModel(
      id: personId,
      longBio: _longBioCtrl.text.trim(),
      achievements: achievements,
      timeline: timeline,
      sources: sources,
      updatedBy: uid,
    ));
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
                  // ── Base info ────────────────────────────────
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
                    controller: _titleCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(
                      label: 'Цол / Title (optional)',
                      hint: 'Монголын Их Хаан',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPersonDropdown(
                    label: 'Эцэг / Father',
                    value: _fatherId,
                    persons: admin.persons,
                    currentPersonId: widget.person?.id,
                    onChanged: (v) => setState(() => _fatherId = v),
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

                  // ── Detail section ───────────────────────────
                  const SizedBox(height: 28),
                  _buildSectionDivider('Дэлгэрэнгүй мэдээлэл'),
                  const SizedBox(height: 16),

                  if (_detailLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(
                          color: AppTheme.accentGold,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else ...[
                    TextFormField(
                      controller: _longBioCtrl,
                      style:
                          AppTheme.body.copyWith(color: AppTheme.textPrimary),
                      decoration:
                          adminInputDecoration(label: 'Дэлгэрэнгүй намтар'),
                      maxLines: 6,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _achievementsCtrl,
                      style:
                          AppTheme.body.copyWith(color: AppTheme.textPrimary),
                      decoration: adminInputDecoration(
                          label: 'Амжилтууд (мөр бүрд нэг)'),
                      maxLines: 4,
                    ),

                    // Timeline
                    const SizedBox(height: 20),
                    _buildSubSectionHeader('Timeline', onAdd: () {
                      setState(() {
                        _timelineRows.add(_TimelineRow(
                          yearCtrl: TextEditingController(),
                          textCtrl: TextEditingController(),
                        ));
                      });
                    }),
                    ..._timelineRows.asMap().entries.map((e) {
                      final i = e.key;
                      final r = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: r.yearCtrl,
                                style: AppTheme.body
                                    .copyWith(color: AppTheme.textPrimary),
                                decoration: adminInputDecoration(label: 'Он'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: r.textCtrl,
                                style: AppTheme.body
                                    .copyWith(color: AppTheme.textPrimary),
                                decoration:
                                    adminInputDecoration(label: 'Үйл явдал'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: AppTheme.crimson, size: 20),
                              onPressed: () =>
                                  setState(() => _timelineRows.removeAt(i)),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Sources
                    const SizedBox(height: 20),
                    _buildSubSectionHeader('Эх сурвалж', onAdd: () {
                      setState(() {
                        _sourceRows.add(_SourceRow(
                          titleCtrl: TextEditingController(),
                          urlCtrl: TextEditingController(),
                        ));
                      });
                    }),
                    ..._sourceRows.asMap().entries.map((e) {
                      final i = e.key;
                      final r = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: r.titleCtrl,
                                style: AppTheme.body
                                    .copyWith(color: AppTheme.textPrimary),
                                decoration: adminInputDecoration(label: 'Нэр'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: r.urlCtrl,
                                style: AppTheme.body
                                    .copyWith(color: AppTheme.textPrimary),
                                decoration: adminInputDecoration(label: 'URL'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: AppTheme.crimson, size: 20),
                              onPressed: () =>
                                  setState(() => _sourceRows.removeAt(i)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),
                  AdminSaveButton(
                    onPressed: _save,
                    isLoading: admin.isLoading,
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    AdminDeleteButton(onPressed: _delete),
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

  Widget _buildSectionDivider(String label) {
    return Row(
      children: [
        Expanded(
          child: Divider(
              color: AppTheme.accentGold.withValues(alpha: 0.25), thickness: 1),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: AppTheme.captionBold
                .copyWith(color: AppTheme.accentGold, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
              color: AppTheme.accentGold.withValues(alpha: 0.25), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildSubSectionHeader(String label, {required VoidCallback onAdd}) {
    return Row(
      children: [
        Text(label, style: AppTheme.sectionTitle.copyWith(fontSize: 14)),
        const Spacer(),
        IconButton(
          icon:
              const Icon(Icons.add_circle_outline, color: AppTheme.accentGold),
          onPressed: onAdd,
        ),
      ],
    );
  }

  Widget _buildPersonDropdown({
    required String label,
    required String? value,
    required List<PersonModel> persons,
    required String? currentPersonId,
    required ValueChanged<String?> onChanged,
  }) {
    final options =
        persons.where((p) => p.id != null && p.id != currentPersonId).toList();

    return DropdownButtonFormField<String?>(
      value: value,
      dropdownColor: AppTheme.surface,
      style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
      decoration: adminInputDecoration(label: label),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('— Сонгоогүй —'),
        ),
        ...options.map((p) => DropdownMenuItem<String?>(
              value: p.id,
              child: Text(p.name),
            )),
      ],
      onChanged: onChanged,
    );
  }
}

class _TimelineRow {
  final TextEditingController yearCtrl;
  final TextEditingController textCtrl;
  _TimelineRow({required this.yearCtrl, required this.textCtrl});
}

class _SourceRow {
  final TextEditingController titleCtrl;
  final TextEditingController urlCtrl;
  _SourceRow({required this.titleCtrl, required this.urlCtrl});
}
