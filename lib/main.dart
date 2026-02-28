import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'services/ai_service.dart';
import 'screens/auth_gate.dart';

import 'components/home_top_bar.dart';
import 'components/hero_banner.dart';
import 'components/daily_fact_card.dart';
import 'components/streak_strip.dart';
import 'components/explore_grid.dart';
import 'components/featured_list.dart';
import 'components/home_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InsightService()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Scrollable content ──
          const CustomScrollView(
            slivers: [
              // Top bar takes space
              SliverToBoxAdapter(child: HomeTopBar()),
              SliverToBoxAdapter(child: SizedBox(height: 8)),
              // B) Hero banner
              SliverToBoxAdapter(child: HeroBanner()),
              SliverToBoxAdapter(child: SizedBox(height: 20)),
              // C) Daily fact
              SliverToBoxAdapter(child: DailyFactCard()),
              SliverToBoxAdapter(child: SizedBox(height: 16)),
              // D) Streak strip
              SliverToBoxAdapter(child: StreakStrip()),
              SliverToBoxAdapter(child: SizedBox(height: 20)),
              // E) Explore grid
              SliverToBoxAdapter(child: ExploreGrid()),
              SliverToBoxAdapter(child: SizedBox(height: 20)),
              // F) Featured list
              SliverToBoxAdapter(child: FeaturedList()),
              // Bottom spacing for nav
              SliverToBoxAdapter(child: SizedBox(height: 100)),
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
