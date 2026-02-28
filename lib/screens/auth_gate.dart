import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';

// Forward-import targets (the actual home screens in your app)
import '../main.dart' show HomeScreen;
import '../screens/admin_dashboard_screen.dart';

/// AuthGate sits at the root of the widget tree.
/// It listens to [AuthProvider] and routes the user accordingly:
///
///   - Loading  → splash / spinner
///   - Signed out → LoginScreen
///   - Signed in + admin → AdminDashboardScreen
///   - Signed in + user  → HomeScreen (the main user app)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // 1) Still resolving auth state
        if (auth.isLoading) {
          return const _SplashView();
        }

        // 2) Not signed in → auth flow
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        // 3) Signed in → route by role
        if (auth.isAdmin) {
          return const AdminDashboardScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

/// Minimal splash screen shown while Firebase Auth initialises.
class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.accentGold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ачааллаж байна...',
              style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
