import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/journey_provider.dart';
import 'providers/story_quiz_provider.dart';
import 'providers/language_provider.dart';
import 'services/ai_service.dart';
import 'screens/auth_gate.dart';

import 'screens/history_video_screen.dart';
import 'screens/persons_screen.dart';
import 'screens/history_journey_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'components/home_top_bar.dart';
import 'components/hero_banner.dart';
import 'components/daily_fact_card.dart';
import 'components/featured_list.dart';
import 'components/premium_bottom_nav.dart';
import 'components/quiz_journey_card.dart';

// Global navigator key for showing dialogs from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint('Firebase init error: $e');
      _initError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const _BootstrapShell(child: _StartupLoadingScreen());
    }

    if (_initError != null) {
      return _BootstrapShell(
        child: StartupFailureScreen(
          errorMessage: _initError!,
          onRetry: _initializeFirebase,
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InsightService()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => JourneyProvider()),
        ChangeNotifierProvider(create: (_) => StoryQuizProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    );
  }
}

class _BootstrapShell extends StatelessWidget {
  final Widget child;

  const _BootstrapShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: child,
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.accentGold),
      ),
    );
  }
}

class StartupFailureScreen extends StatelessWidget {
  final String errorMessage;
  final Future<void> Function() onRetry;

  const StartupFailureScreen({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppTheme.textSecondary,
                size: 56,
              ),
              const SizedBox(height: 14),
              Text(
                'Апп эхлүүлэхэд алдаа гарлаа',
                style: AppTheme.sectionTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Firebase холболт амжилтгүй боллоо. Интернэтээ шалгаад дахин оролдоно уу.',
                style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage,
                style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.background,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text('Дахин оролдох', style: AppTheme.button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: navigatorKey,
      home: const AuthGate(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  HOME SCREEN – clean architecture, composing reusable widgets
// ══════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  List<NavItem> _getNavItems(LanguageProvider lang) {
    return [
      NavItem(icon: Icons.home_rounded, label: lang.tr('nav_home')),
      NavItem(icon: Icons.military_tech_rounded, label: lang.tr('nav_people')),
      NavItem(icon: Icons.menu_book_rounded, label: lang.tr('nav_learn')),
      NavItem(icon: Icons.public_rounded, label: lang.tr('nav_map')),
      NavItem(icon: Icons.person_rounded, label: lang.tr('nav_profile')),
    ];
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).loadAllData();
      Provider.of<JourneyProvider>(context, listen: false).init();
    });
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        // Top bar takes space
        const SliverToBoxAdapter(child: HomeTopBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        // B) Hero banner
        SliverToBoxAdapter(
          child: HeroBanner(
            onStartExploring: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HistoryVideoScreen(),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        // C) Daily fact
        const SliverToBoxAdapter(child: DailyFactCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        // F) Current journey quiz card
        const SliverToBoxAdapter(child: QuizJourneyCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        // G) Featured list
        const SliverToBoxAdapter(child: FeaturedList()),
        // No extra spacing needed - navbarReserved handles it
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // navbar height(58) + rise(16) + safe area + small gap(8)
    final navbarReserved = 58.0 + 16.0 + bottomPadding + 8.0;
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Screen content with IndexedStack ──
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: navbarReserved),
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHomeContent(),
                  const PersonsScreen(),
                  const HistoryJourneyScreen(),
                  const MapScreen(),
                  const ProfileScreen(),
                ],
              ),
            ),
          ),

          // ── Premium floating bottom nav ──
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 8,
            child: PremiumBottomNav(
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
              items: _getNavItems(lang),
              activeColor: AppTheme.accentGold,
              inactiveColor: AppTheme.textSecondary,
              navbarColor: AppTheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}
