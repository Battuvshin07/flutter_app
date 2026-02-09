import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';

import 'components/HeaderCarousel.dart';
import 'components/QuickActions.dart';
import 'components/FeaturedContent.dart';
import 'components/BottomNav.dart';
import 'services/ai_service.dart';
import 'providers/app_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
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
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load all offline data on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                HeaderCarousel(),
                QuickActions(),
                HistoryInsightCard(),
                FeaturedContent(),
                SizedBox(height: 100), // Space for the bottom nav
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: TopActionBar(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomNav(),
          ),
        ],
      ),
    );
  }
}

class TopActionBar extends StatelessWidget {
  const TopActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 18),
              onPressed: () {},
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none,
                  color: Colors.white, size: 18),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryInsightCard extends StatefulWidget {
  const HistoryInsightCard({super.key});

  @override
  State<HistoryInsightCard> createState() => _HistoryInsightCardState();
}

class _HistoryInsightCardState extends State<HistoryInsightCard> {
  @override
  void initState() {
    super.initState();
    // Fetch insight when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InsightService>(context, listen: false).fetchInsight();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InsightService>(
      builder: (context, insightService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.shade500,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: insightService.isLoading
                      ? const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 18)
                      : const Text(
                          "GK",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Түүхийн мэдлэг",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade400,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insightService.isLoading
                          ? "Их хааны архиваас хайж байна..."
                          : insightService.insight,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
