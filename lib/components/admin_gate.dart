import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Route guard for admin-only screens.
///
/// Wrap any admin screen with this widget to enforce role-based access:
/// ```dart
/// MaterialPageRoute(
///   builder: (_) => const AdminGate(child: AdminDashboardScreen()),
/// )
/// ```
///
/// If the user is not an admin/superAdmin, they see a "403 Access Denied"
/// view and cannot interact with the protected child.
class AdminGate extends StatelessWidget {
  final Widget child;

  const AdminGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Still loading auth / role
        if (auth.isLoading) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            ),
          );
        }

        // Not authenticated or not admin → block
        if (!auth.isAuthenticated || !auth.isAdmin) {
          return _AccessDeniedView(
            onBack: () => Navigator.maybePop(context),
          );
        }

        // Authorised → render the protected screen
        return child;
      },
    );
  }
}

/// Full-screen "Access Denied" placeholder.
class _AccessDeniedView extends StatelessWidget {
  final VoidCallback onBack;

  const _AccessDeniedView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.crimson.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppTheme.crimson,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Хандах эрхгүй',
                  style: AppTheme.h2.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  'Энэ хуудсыг зөвхөн админ хэрэглэгч үзэх боломжтой.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 200,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onBack,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.background,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: Text('Буцах', style: AppTheme.button),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
