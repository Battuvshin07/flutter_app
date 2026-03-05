import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

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
