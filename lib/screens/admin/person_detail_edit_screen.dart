import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/person_detail_model.dart';
import 'shared_admin_widgets.dart';

/// Edit screen for Person Detail (1:1 with persons).
class PersonDetailEditScreen extends StatefulWidget {
  final String personId;

  const PersonDetailEditScreen({super.key, required this.personId});

  @override
  State<PersonDetailEditScreen> createState() => _PersonDetailEditScreenState();
}

class _PersonDetailEditScreenState extends State<PersonDetailEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _longBioCtrl;
  late final TextEditingController _achievementsCtrl;

  // Timeline entries managed as a dynamic list.
  List<_TimelineRow> _timelineRows = [];
  // Sources managed as a dynamic list.
  List<_SourceRow> _sourceRows = [];

  bool _isLoading = true;
  PersonDetailModel? _existing;

  @override
  void initState() {
    super.initState();
    _longBioCtrl = TextEditingController();
    _achievementsCtrl = TextEditingController();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final detail = await admin.getPersonDetail(widget.personId);
    if (detail != null) {
      _existing = detail;
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
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
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

    final model = PersonDetailModel(
      id: widget.personId,
      longBio: _longBioCtrl.text.trim(),
      achievements: achievements,
      timeline: timeline,
      sources: sources,
      updatedBy: uid,
    );

    final success = await admin.savePersonDetail(model);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(context, title: 'Person Detail'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            )
          : Consumer<AdminProvider>(
              builder: (context, admin, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.pagePadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _longBioCtrl,
                          style: AppTheme.body
                              .copyWith(color: AppTheme.textPrimary),
                          decoration:
                              adminInputDecoration(label: 'Дэлгэрэнгүй намтар'),
                          maxLines: 6,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _achievementsCtrl,
                          style: AppTheme.body
                              .copyWith(color: AppTheme.textPrimary),
                          decoration: adminInputDecoration(
                            label: 'Амжилтууд (мөр бүрд нэг)',
                          ),
                          maxLines: 4,
                        ),

                        // ── Timeline ──
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text('Timeline',
                                style: AppTheme.sectionTitle
                                    .copyWith(fontSize: 14)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: AppTheme.accentGold),
                              onPressed: () {
                                setState(() {
                                  _timelineRows.add(_TimelineRow(
                                    yearCtrl: TextEditingController(),
                                    textCtrl: TextEditingController(),
                                  ));
                                });
                              },
                            ),
                          ],
                        ),
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
                                    decoration:
                                        adminInputDecoration(label: 'Он'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: r.textCtrl,
                                    style: AppTheme.body
                                        .copyWith(color: AppTheme.textPrimary),
                                    decoration: adminInputDecoration(
                                        label: 'Үйл явдал'),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: AppTheme.crimson, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _timelineRows.removeAt(i);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),

                        // ── Sources ──
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text('Sources',
                                style: AppTheme.sectionTitle
                                    .copyWith(fontSize: 14)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: AppTheme.accentGold),
                              onPressed: () {
                                setState(() {
                                  _sourceRows.add(_SourceRow(
                                    titleCtrl: TextEditingController(),
                                    urlCtrl: TextEditingController(),
                                  ));
                                });
                              },
                            ),
                          ],
                        ),
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
                                    decoration:
                                        adminInputDecoration(label: 'Нэр'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: r.urlCtrl,
                                    style: AppTheme.body
                                        .copyWith(color: AppTheme.textPrimary),
                                    decoration:
                                        adminInputDecoration(label: 'URL'),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: AppTheme.crimson, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _sourceRows.removeAt(i);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 24),
                        AdminSaveButton(
                          onPressed: _save,
                          isLoading: admin.isLoading,
                        ),
                        if (admin.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            admin.error!,
                            style: AppTheme.caption
                                .copyWith(color: AppTheme.crimson),
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
