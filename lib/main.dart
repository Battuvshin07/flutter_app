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
import 'components/home_top_bar.dart';
import 'components/hero_banner.dart';
import 'components/daily_fact_card.dart';
import 'components/featured_list.dart';
import 'components/home_bottom_nav.dart';
import 'components/quiz_journey_card.dart';

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
      home: const AuthGate(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  HOME SCREEN – clean architecture, composing reusable widgets
// ══════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).loadAllData();
      Provider.of<JourneyProvider>(context, listen: false).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Scrollable content ──
          CustomScrollView(
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
              // Bottom spacing for nav
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // ── G) Floating bottom nav ──
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HomeBottomNav(),
          ),
        ],
      ),
    );
  }
}
