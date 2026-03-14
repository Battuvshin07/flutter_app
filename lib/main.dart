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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InsightService()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => JourneyProvider()),
        ChangeNotifierProvider(create: (_) => StoryQuizProvider()),
      ],
      child: const MyApp(),
    ),
  );
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

  static const List<NavItem> _navItems = [
    NavItem(icon: Icons.home_rounded, label: 'Нүүр'),
    NavItem(icon: Icons.military_tech_rounded, label: 'Хүмүүс'),
    NavItem(icon: Icons.menu_book_rounded, label: 'Судлах'),
    NavItem(icon: Icons.public_rounded, label: 'Зураг'),
    NavItem(icon: Icons.person_rounded, label: 'Профайл'),
  ];

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
              items: _navItems,
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
