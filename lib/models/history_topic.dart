/// Data model for a single history topic in the train journey.
class HistoryTopic {
  final int id;
  final String title;
  final String year;
  final int xp;
  bool isCompleted;
  bool isLocked;

  HistoryTopic({
    required this.id,
    required this.title,
    required this.year,
    required this.xp,
    this.isCompleted = false,
    this.isLocked = true,
  });

  HistoryTopic copyWith({
    int? id,
    String? title,
    String? year,
    int? xp,
    bool? isCompleted,
    bool? isLocked,
  }) {
    return HistoryTopic(
      id: id ?? this.id,
      title: title ?? this.title,
      year: year ?? this.year,
      xp: xp ?? this.xp,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
