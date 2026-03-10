import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/event_model.dart';
import '../../data/models/person_model.dart';
import 'shared_admin_widgets.dart';

/// Create / Edit screen for a historical Event.
class EventEditScreen extends StatefulWidget {
  final EventModel? event;

  const EventEditScreen({super.key, this.event});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _imageUrlCtrl;

  String? _selectedPersonId;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.event?.title ?? '');
    _dateCtrl = TextEditingController(text: widget.event?.date ?? '');
    _descCtrl = TextEditingController(text: widget.event?.description ?? '');
    _locationCtrl = TextEditingController(text: widget.event?.location ?? '');
    _imageUrlCtrl =
        TextEditingController(text: widget.event?.coverImageUrl ?? '');
    _selectedPersonId = widget.event?.personId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    final model = EventModel(
      id: widget.event?.id,
      title: _titleCtrl.text.trim(),
      date: _dateCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      personId: _selectedPersonId,
      location:
          _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      coverImageUrl:
          _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim(),
      updatedBy: uid,
    );

    final success = _isEditing
        ? await admin.updateEvent(model)
        : await admin.createEvent(model);
    if (success && mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed =
        await showDeleteConfirmDialog(context, itemName: _titleCtrl.text);
    if (!confirmed || !mounted) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final success = await admin.deleteEvent(widget.event!.id!);
    if (success && mounted) Navigator.pop(context);
  }

  /// Opens a bottom sheet to pick a person from the streamed persons list.
  Future<void> _pickPerson(List<PersonModel> persons) async {
    // Local search state inside the sheet
    final TextEditingController searchCtrl = TextEditingController();
    List<PersonModel> filtered = List.from(persons);

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.92,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollCtrl) {
                return Column(
                  children: [
                    // Handle bar
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              color: AppTheme.accentGold, size: 20),
                          const SizedBox(width: 8),
                          Text('Хүн сонгох', style: AppTheme.sectionTitle),
                          const Spacer(),
                          if (_selectedPersonId != null)
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedPersonId = null);
                                Navigator.pop(sheetCtx);
                              },
                              child: Text(
                                'Арилгах',
                                style: AppTheme.caption
                                    .copyWith(color: AppTheme.crimson),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchCtrl,
                        style:
                            AppTheme.body.copyWith(color: AppTheme.textPrimary),
                        decoration: adminInputDecoration(
                          label: 'Хайх...',
                        ).copyWith(
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppTheme.textSecondary, size: 20),
                        ),
                        onChanged: (q) {
                          setSheetState(() {
                            filtered = persons
                                .where((p) => p.name
                                    .toLowerCase()
                                    .contains(q.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Person list
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text('Олдсонгүй', style: AppTheme.caption),
                            )
                          : ListView.builder(
                              controller: scrollCtrl,
                              itemCount: filtered.length,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              itemBuilder: (_, i) {
                                final p = filtered[i];
                                final isSelected = p.id == _selectedPersonId;
                                return Material(
                                  color: isSelected
                                      ? AppTheme.accentGold.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setState(() => _selectedPersonId = p.id);
                                      Navigator.pop(sheetCtx);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      child: Row(
                                        children: [
                                          // Avatar circle
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppTheme.surfaceLight,
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppTheme.accentGold
                                                    : AppTheme.cardBorder,
                                              ),
                                            ),
                                            child: p.avatarUrl != null
                                                ? ClipOval(
                                                    child: Image.network(
                                                      p.avatarUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (_, __, ___) =>
                                                              _personIcon(),
                                                    ),
                                                  )
                                                : _personIcon(),
                                          ),
                                          const SizedBox(width: 12),

                                          // Name + birth/death
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.name,
                                                  style: AppTheme.captionBold
                                                      .copyWith(
                                                    fontSize: 14,
                                                    color: isSelected
                                                        ? AppTheme.accentGold
                                                        : AppTheme.textPrimary,
                                                  ),
                                                ),
                                                if (p.birthYear != null)
                                                  Text(
                                                    [
                                                      if (p.birthYear != null)
                                                        '${p.birthYear}',
                                                      if (p.deathYear != null)
                                                        '${p.deathYear}',
                                                    ].join(' – '),
                                                    style: AppTheme.caption
                                                        .copyWith(fontSize: 11),
                                                  ),
                                              ],
                                            ),
                                          ),

                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: AppTheme.accentGold,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(sheetCtx).padding.bottom + 8),
                  ],
                );
              },
            );
          },
        );
      },
    );
    searchCtrl.dispose();
  }

  Widget _personIcon() => const Icon(
        Icons.person_rounded,
        color: AppTheme.textSecondary,
        size: 20,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(
        context,
        title: _isEditing ? 'Event засах' : 'Event нэмэх',
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

          // Find the currently selected person name for the field label
          final selectedPerson = _selectedPersonId == null
              ? null
              : admin.persons
                  .where((p) => p.id == _selectedPersonId)
                  .firstOrNull;

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
                    controller: _dateCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(
                      label: 'Он, огноо *',
                      hint: 'e.g. 1206, 1227-03-25',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Он/огноо оруулна уу'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Тайлбар'),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),

                  // ── Person picker ──────────────────────────────────────
                  GestureDetector(
                    onTap: () => _pickPerson(admin.persons),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: _selectedPersonId != null
                              ? AppTheme.accentGold.withValues(alpha: 0.5)
                              : AppTheme.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                            color: _selectedPersonId != null
                                ? AppTheme.accentGold
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Холбоотой хүн (optional)',
                                  style: AppTheme.caption.copyWith(
                                    fontSize: 11,
                                    color: _selectedPersonId != null
                                        ? AppTheme.accentGold.withValues(alpha: 0.8)
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedPerson?.name ?? 'Хүн сонгох...',
                                  style: AppTheme.body.copyWith(
                                    color: selectedPerson != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary
                                            .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── End person picker ──────────────────────────────────

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration:
                        adminInputDecoration(label: 'Байршил (optional)'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imageUrlCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration:
                        adminInputDecoration(label: 'Зургийн URL (optional)'),
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
