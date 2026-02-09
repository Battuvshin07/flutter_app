import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/event.dart';
import 'person_detail_screen.dart';

/// FR-03: Үйл явдлуудын интерактив цагийн хэлхээс
/// "Timeline widget: Үйл явдлуудыг цаг хугацааны дарааллаар харуулах"
class EventsTimelineScreen extends StatelessWidget {
  const EventsTimelineScreen({super.key});

  static const _brown = Color(0xFF3B2F2F);
  static const _parchment = Color(0xFFF2DFC3);
  static const _parchmentDark = Color(0xFFE8D0A8);

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
              Expanded(
                child: Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final events = List<Event>.from(provider.events);
                    if (events.isEmpty) {
                      return const Center(
                        child: Text('Үйл явдал олдсонгүй'),
                      );
                    }
                    // Sort by date
                    events.sort((a, b) => a.date.compareTo(b.date));
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      itemCount: events.length,
                      itemBuilder: (context, index) => _buildTimelineItem(
                          context,
                          events[index],
                          index,
                          index == events.length - 1,
                          provider),
                    );
                  },
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
              'Цагийн хэлхээс',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _brown,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const Icon(Icons.timeline, color: _brown, size: 24),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, Event event, int index,
      bool isLast, AppProvider provider) {
    final colors = [
      const Color(0xFF8B4513),
      const Color(0xFFD2691E),
      const Color(0xFF4682B4),
      const Color(0xFF6B8E23),
      const Color(0xFF8B0000),
      const Color(0xFFB8860B),
    ];
    final color = colors[index % colors.length];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _brown.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          // Event card
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (event.personId != null) {
                  final person = provider.getPersonById(event.personId!);
                  if (person != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonDetailScreen(person: person),
                      ),
                    );
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF5),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.date,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _brown,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: _brown.withOpacity(0.75),
                        height: 1.4,
                      ),
                    ),
                    if (event.personId != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 14, color: color.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            provider.getPersonById(event.personId!)?.name ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right,
                              size: 16, color: _brown.withOpacity(0.4)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
