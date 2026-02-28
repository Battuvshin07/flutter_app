import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../components/person_card.dart';
import 'person_detail_screen.dart';
import 'familyTree.dart';

/// FR-01 + FR-06: Түүхэн хүмүүсийн дэлгэц
/// Dark + gold gamified design with list / family tree toggle.
class PersonsScreen extends StatefulWidget {
  const PersonsScreen({super.key});

  @override
  State<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends State<PersonsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, Color(0xFF0D1628)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPersonsList(),
                    const FamilyTreeScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.accentGold,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Түүхэн хүмүүс',
              textAlign: TextAlign.center,
              style: AppTheme.h2.copyWith(fontSize: 19),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: AppTheme.accentGold,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicator: BoxDecoration(
          color: AppTheme.accentGold,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.background,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: AppTheme.chip.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: AppTheme.chip.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: const [
          Tab(child: Center(child: Text('Жагсаалт'))),
          Tab(child: Center(child: Text('Гэр бүлийн мод'))),
        ],
      ),
    );
  }

  Widget _buildPersonsList() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.accentGold,
              strokeWidth: 2.5,
            ),
          );
        }
        final persons = provider.persons;
        if (persons.isEmpty) {
          return Center(
            child: Text(
              'Хүмүүс олдсонгүй',
              style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.pagePadding,
            vertical: 12,
          ),
          itemCount: persons.length,
          itemBuilder: (context, index) {
            final person = persons[index];
            final eventCount = person.personId != null
                ? provider.getEventsForPerson(person.personId!).length
                : 0;
            return PersonCard(
              person: person,
              eventCount: eventCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PersonDetailScreen(person: person),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
