import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/person.dart';
import 'person_detail_screen.dart';
import 'familyTree.dart';

/// FR-01 + FR-06: Түүхэн хүмүүсийн дэлгэц
/// "Гэр бүлийн мод шиг бүтэцтэй дизайн (Family Tree design)"
/// Provides both list view and family tree toggle
class PersonsScreen extends StatefulWidget {
  const PersonsScreen({super.key});

  @override
  State<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends State<PersonsScreen>
    with SingleTickerProviderStateMixin {
  static const _brown = Color(0xFF3B2F2F);
  static const _parchment = Color(0xFFF2DFC3);
  static const _parchmentDark = Color(0xFFE8D0A8);
  static const _cardBg = Color(0xFFFFFBF5);

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

  static const _personColors = [
    Color(0xFF8B4513),
    Color(0xFFA0522D),
    Color(0xFFD2691E),
    Color(0xFF6B8E23),
    Color(0xFF4682B4),
    Color(0xFF8B0000),
    Color(0xFF2E4057),
    Color(0xFF556B2F),
    Color(0xFF708090),
    Color(0xFFB8860B),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_parchment, _parchmentDark],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child:
                const Icon(Icons.arrow_back_ios_new, color: _brown, size: 24),
          ),
          const Expanded(
            child: Text(
              'Түүхэн хүмүүс',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _brown,
              ),
            ),
          ),
          const Icon(Icons.people_outline, color: _brown, size: 24),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: _parchment, // Light beige background for inactive tabs
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false, // Ensures tabs take equal width (50/50)
        indicator: BoxDecoration(
          color: _brown, // Dark brown for active tab
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white, // White text for active tab
        unselectedLabelColor: _brown, // Dark brown text for inactive tab
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: const [
          Tab(
            child: Center(
              child: Text('Жагсаалт'),
            ),
          ),
          Tab(
            child: Center(
              child: Text('Гэр бүлийн мод'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonsList() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final persons = provider.persons;
        if (persons.isEmpty) {
          return const Center(child: Text('Хүмүүс олдсонгүй'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: persons.length,
          itemBuilder: (context, index) => _buildPersonCard(
            context,
            persons[index],
            _personColors[index % _personColors.length],
            provider,
          ),
        );
      },
    );
  }

  Widget _buildPersonCard(
      BuildContext context, Person person, Color color, AppProvider provider) {
    final initials = person.name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();

    final hasImage = person.imageUrl != null && person.imageUrl!.isNotEmpty;
    final eventCount = person.personId != null
        ? provider.getEventsForPerson(person.personId!).length
        : 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PersonDetailScreen(person: person),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                    color: const Color(0xFFB8860B).withOpacity(0.5), width: 2),
              ),
              child: ClipOval(
                child: hasImage
                    ? Image.asset(person.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                              child: Text(initials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ))
                    : Center(
                        child: Text(initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _brown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (person.birthDate != null)
                        Text(
                          '${person.birthDate}${person.deathDate != null ? ' - ${person.deathDate}' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _brown.withOpacity(0.6),
                          ),
                        ),
                      if (eventCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$eventCount үйл явдал',
                            style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    person.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: _brown.withOpacity(0.6),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _brown.withOpacity(0.4), size: 20),
          ],
        ),
      ),
    );
  }
}
