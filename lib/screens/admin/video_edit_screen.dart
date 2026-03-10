import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/video_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'shared_admin_widgets.dart';

class VideoEditScreen extends StatefulWidget {
  final VideoModel? video;

  const VideoEditScreen({super.key, this.video});

  @override
  State<VideoEditScreen> createState() => _VideoEditScreenState();
}

class _VideoEditScreenState extends State<VideoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _youtubeIdCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _orderCtrl;
  late String _selectedIcon;
  late String _selectedAccent;
  late bool _isPublished;

  static const _iconOptions = [
    'shield',
    'route',
    'landscape',
    'swap_horiz',
    'history_edu',
    'museum',
    'play_circle',
    'star',
    'anchor',
    'temple',
  ];

  static const _accentOptions = [
    ('F4C84A', 'Алтан (Gold)'),
    ('64B5F6', 'Цэнхэр (Blue)'),
    ('4ADE80', 'Ногоон (Green)'),
    ('FF9F43', 'Улбар шар (Orange)'),
    ('A78BFA', 'Ягаан (Purple)'),
    ('F87171', 'Улаан (Red)'),
  ];

  bool get _isEditing => widget.video != null;

  @override
  void initState() {
    super.initState();
    _youtubeIdCtrl = TextEditingController(text: widget.video?.youtubeId ?? '');
    _titleCtrl = TextEditingController(text: widget.video?.title ?? '');
    _subtitleCtrl = TextEditingController(text: widget.video?.subtitle ?? '');
    _durationCtrl = TextEditingController(text: widget.video?.duration ?? '');
    _orderCtrl = TextEditingController(text: '${widget.video?.order ?? 0}');
    _selectedIcon = widget.video?.iconName ?? 'shield';
    _selectedAccent = widget.video?.accentHex ?? 'F4C84A';
    _isPublished = widget.video?.isPublished ?? true;
  }

  @override
  void dispose() {
    _youtubeIdCtrl.dispose();
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _durationCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    final model = VideoModel(
      id: widget.video?.id,
      youtubeId: _youtubeIdCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      subtitle: _subtitleCtrl.text.trim(),
      duration: _durationCtrl.text.trim(),
      iconName: _selectedIcon,
      accentHex: _selectedAccent,
      order: int.tryParse(_orderCtrl.text.trim()) ?? 0,
      isPublished: _isPublished,
      updatedBy: uid,
    );

    bool success;
    if (_isEditing) {
      success = await admin.updateVideo(model);
    } else {
      success = await admin.createVideo(model);
    }

    if (success && mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed =
        await showDeleteConfirmDialog(context, itemName: _titleCtrl.text);
    if (!confirmed || !mounted) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final success = await admin.deleteVideo(widget.video!.id!);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(
        context,
        title: _isEditing ? 'Видео засах' : 'Видео нэмэх',
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
                  // ── YouTube ID ────────────────────────────
                  TextFormField(
                    controller: _youtubeIdCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration:
                        adminInputDecoration(label: 'YouTube Video ID *'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'YouTube ID оруулна уу'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Title ─────────────────────────────────
                  TextFormField(
                    controller: _titleCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Гарчиг *'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Гарчиг оруулна уу'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Subtitle ──────────────────────────────
                  TextFormField(
                    controller: _subtitleCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Дэд гарчиг'),
                  ),
                  const SizedBox(height: 16),

                  // ── Duration ──────────────────────────────
                  TextFormField(
                    controller: _durationCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(
                        label: 'Үргэлжлэх хугацаа (мм:сс)'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Хугацаа оруулна уу (жнь: 12:30)'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Order ─────────────────────────────────
                  TextFormField(
                    controller: _orderCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Эрэмбэ (order)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // ── Icon dropdown ─────────────────────────
                  DropdownButtonFormField<String>(
                    initialValue: _selectedIcon,
                    dropdownColor: AppTheme.surface,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Дүрс (icon)'),
                    items: _iconOptions
                        .map((ic) => DropdownMenuItem(
                              value: ic,
                              child: Row(
                                children: [
                                  Icon(VideoModel.iconFromName(ic),
                                      color: AppTheme.accentGold, size: 18),
                                  const SizedBox(width: 8),
                                  Text(ic,
                                      style: AppTheme.body.copyWith(
                                          color: AppTheme.textPrimary)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedIcon = v ?? _selectedIcon),
                  ),
                  const SizedBox(height: 16),

                  // ── Accent color dropdown ─────────────────
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAccent,
                    dropdownColor: AppTheme.surface,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration:
                        adminInputDecoration(label: 'Өнгө (accent color)'),
                    items: _accentOptions
                        .map((pair) => DropdownMenuItem(
                              value: pair.$1,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: VideoModel.colorFromHex(pair.$1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(pair.$2,
                                      style: AppTheme.body.copyWith(
                                          color: AppTheme.textPrimary)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedAccent = v ?? _selectedAccent),
                  ),
                  const SizedBox(height: 16),

                  // ── Published toggle ──────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: SwitchListTile(
                      value: _isPublished,
                      activeThumbColor: AppTheme.accentGold,
                      title: Text('Нийтлэх',
                          style: AppTheme.body
                              .copyWith(color: AppTheme.textPrimary)),
                      subtitle: Text(
                          _isPublished ? 'Нийтэд харагдана' : 'Нуусан (draft)',
                          style: AppTheme.caption),
                      onChanged: (v) => setState(() => _isPublished = v),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Save ──────────────────────────────────
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
