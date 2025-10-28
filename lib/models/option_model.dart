/// Model for a single multiple-choice option.
class Option {
  final String letter; // e.g., 'A', 'B', 'C'
  final String text;
  final bool isCorrect;
  final int order;

  Option({
    required this.letter,
    required this.text,
    required this.isCorrect,
    required this.order,
  });

  /// Converts the Option object to a Map (JSON) for Firebase.
  Map<String, dynamic> toJson() {
    return {
      'letter': letter,
      'text': text,
      'isCorrect': isCorrect,
      'order': order,
    };
  }

  /// Creates an Option object from a Map (JSON) from Firebase.
  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      letter: json['letter'] ?? '',
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}
