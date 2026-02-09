import 'package:flutter/foundation.dart';

class InsightService extends ChangeNotifier {
  String _insight =
      "Discover fascinating historical facts from the Mongol Empire";
  bool _isLoading = false;

  String get insight => _insight;
  bool get isLoading => _isLoading;

  Future<void> fetchInsight() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate fetching from Firebase or API
      await Future.delayed(const Duration(seconds: 2));

      // You can replace this with actual Firestore query
      // Example:
      // final doc = await FirebaseFirestore.instance
      //     .collection('insights')
      //     .doc('random')
      //     .get();
      // _insight = doc.data()?['text'] ?? 'No insight available';

      // Sample insights for demonstration
      final insights = [
        "The Mongol Empire was the largest contiguous land empire in history, spanning over 24 million square kilometers.",
        "Genghis Khan established the first international postal system called the Yam.",
        "The Mongols promoted religious tolerance and freedom of worship across their vast empire.",
        "Mongol warriors could ride for days without stopping, sleeping in their saddles.",
        "The Silk Road flourished under Mongol protection, enabling unprecedented cultural exchange.",
      ];

      insights.shuffle();
      _insight = insights.first;
    } catch (e) {
      _insight =
          "Unable to fetch insight at this time. Please try again later.";
      debugPrint('Error fetching insight: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
