import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../providers/profile_provider.dart';

/// Edit Profile screen – updates users/{uid} in Firestore.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  String _language = 'mn';
  Uint8List? _pickedImageBytes;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    _nameCtrl = TextEditingController(text: profile.displayName ?? '');
    _bioCtrl = TextEditingController(text: profile.bio ?? '');
    _language = profile.preferredLanguage ?? 'mn';
    _currentPhotoUrl = profile.photoUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (xFile != null) {
      final bytes = await xFile.readAsBytes();
      setState(() => _pickedImageBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final success = await profile.updateProfile(
      displayName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      preferredLanguage: _language,
      avatarBytes: _pickedImageBytes,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Амжилттай хадгаллаа'),
          backgroundColor: Color(0xFF4ADE80),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Алдаа гарлаа. Дахин оролдоно уу.'),
          backgroundColor: AppTheme.crimson,
        ),
      );
    }
  }

  InputDecoration _inputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.accentGold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.crimson),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.crimson, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Профайл засах', style: AppTheme.sectionTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profile, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.pagePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Avatar ─────────────────────────
                  _buildAvatarPicker(),
                  const SizedBox(height: 28),

                  // ── Name ───────────────────────────
                  TextFormField(
                    controller: _nameCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: _inputDecoration(label: 'Нэр *'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Нэр оруулна уу'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Bio ────────────────────────────
                  TextFormField(
                    controller: _bioCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: _inputDecoration(label: 'Товч танилцуулга'),
                    maxLength: 120,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // ── Language ───────────────────────
                  _buildLanguageSelector(),
                  const SizedBox(height: 36),

                  // ── Save Button ────────────────────
                  SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accentGold, Color(0xFFFFE08A)],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentGold.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: profile.isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        child: profile.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.background,
                                ),
                              )
                            : Text(
                                'Хадгалах',
                                style: AppTheme.captionBold.copyWith(
                                  color: AppTheme.background,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentGold, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(child: _avatarContent()),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.accentGold,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.background, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: AppTheme.background, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarContent() {
    if (_pickedImageBytes != null) {
      return Image.memory(_pickedImageBytes!, fit: BoxFit.cover);
    }
    if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      return Image.network(
        _currentPhotoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultAvatar(),
      );
    }
    return Image.asset(
      'assets/images/pic_2.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _defaultAvatar(),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppTheme.surfaceLight,
      child: const Icon(
        Icons.person_rounded,
        size: 48,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Сонгосон хэл',
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LanguageOption(
                  label: 'Монгол',
                  value: 'mn',
                  groupValue: _language,
                  onChanged: (v) => setState(() => _language = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LanguageOption(
                  label: 'English',
                  value: 'en',
                  groupValue: _language,
                  onChanged: (v) => setState(() => _language = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _LanguageOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentGold.withValues(alpha: 0.15)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.accentGold : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.captionBold.copyWith(
              color: isSelected ? AppTheme.accentGold : AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
