import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/image_upload_service.dart';

/// Shared confirm-delete dialog used by all admin CRUD screens.
Future<bool> showDeleteConfirmDialog(
  BuildContext context, {
  required String itemName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      title: Text('Устгах уу?', style: AppTheme.sectionTitle),
      content: Text(
        '"$itemName" устгахдаа итгэлтэй байна уу?',
        style: AppTheme.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Цуцлах',
            style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Устгах',
            style: AppTheme.caption.copyWith(color: AppTheme.crimson),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Shared admin app bar builder used across CRUD screens.
PreferredSizeWidget buildAdminAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: AppTheme.background,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      color: AppTheme.textPrimary,
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(title, style: AppTheme.sectionTitle),
    actions: actions,
  );
}

/// Shared search field widget for admin list screens.
class AdminSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const AdminSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: TextField(
        onChanged: onChanged,
        style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.caption,
          border: InputBorder.none,
          icon: const Icon(
            Icons.search_rounded,
            color: AppTheme.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Shared empty state widget.
class AdminEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const AdminEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTheme.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown while the Firestore stream hasn't fired its first event yet.
class AdminLoadingState extends StatelessWidget {
  const AdminLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppTheme.accentGold,
      ),
    );
  }
}

/// Shared form field decorator that matches the dark theme.
InputDecoration adminInputDecoration({
  required String label,
  String? hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: AppTheme.caption.copyWith(color: AppTheme.accentGold),
    hintStyle: AppTheme.caption,
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
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

/// Gold gradient save button.
class AdminSaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const AdminSaveButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Хадгалах',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentGold,
          foregroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.background,
                ),
              )
            : Text(label, style: AppTheme.button),
      ),
    );
  }
}

/// Red delete button.
class AdminDeleteButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AdminDeleteButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
        label: Text('Устгах',
            style: AppTheme.button.copyWith(color: AppTheme.crimson)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.crimson,
          side: const BorderSide(color: AppTheme.crimson),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// Image picker field that replaces the plain-text URL input.
/// Shows a preview of the current/picked image and lets the user
/// pick from gallery or camera, uploading to Firebase Storage.
class ImagePickerField extends StatefulWidget {
  /// Label shown above the field.
  final String label;

  /// Current image URL (from Firestore). Shown as preview when no new image
  /// has been picked.
  final String? currentUrl;

  /// Firebase Storage path to upload to (e.g. 'persons/{id}/avatar.jpg').
  final String storagePath;

  /// Called with the new download URL after successful upload,
  /// or with null if the user clears the image.
  final ValueChanged<String?> onChanged;

  const ImagePickerField({
    super.key,
    required this.label,
    required this.storagePath,
    required this.onChanged,
    this.currentUrl,
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  Uint8List? _pickedBytes;
  bool _uploading = false;
  String? _uploadedUrl;

  String? get _displayUrl => _uploadedUrl ?? widget.currentUrl;

  Future<void> _pick(ImageSource source) async {
    final bytes = await ImageUploadService.pickImage(source: source);
    if (bytes == null || !mounted) return;

    setState(() {
      _pickedBytes = bytes;
      _uploading = true;
    });

    final url = await ImageUploadService.uploadImage(
      bytes: bytes,
      storagePath: widget.storagePath,
    );

    if (!mounted) return;

    setState(() {
      _uploading = false;
      if (url != null) _uploadedUrl = url;
    });

    if (url != null) widget.onChanged(url);
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Зураг сонгох', style: AppTheme.sectionTitle),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppTheme.accentGold),
                title: Text('Галерейгаас сонгох',
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppTheme.accentGold),
                title: Text('Камераар зургийг авах',
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.camera);
                },
              ),
              if (_displayUrl != null || _pickedBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.crimson),
                  title: Text('Зураг устгах',
                      style: AppTheme.body.copyWith(color: AppTheme.crimson)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedBytes = null;
                      _uploadedUrl = null;
                    });
                    widget.onChanged(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTheme.caption.copyWith(color: AppTheme.accentGold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _uploading ? null : _showSourcePicker,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _uploadedUrl != null
                    ? AppTheme.accentGold.withValues(alpha: 0.5)
                    : AppTheme.cardBorder,
              ),
            ),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_uploading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.accentGold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Зураг байршуулж байна...',
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_pickedBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(_pickedBytes!, fit: BoxFit.cover),
            _editOverlay(),
          ],
        ),
      );
    }

    if (_displayUrl != null && _displayUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _displayUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
            _editOverlay(),
          ],
        ),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: AppTheme.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Зураг оруулах',
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editOverlay() {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.background.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.edit_rounded,
          color: AppTheme.accentGold,
          size: 18,
        ),
      ),
    );
  }
}
