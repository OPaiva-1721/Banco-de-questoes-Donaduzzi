/// Modelo para `Option` (Opção de uma Questão)
/// Não é uma coleção, mas um sub-objeto dentro de Question.
class Option {
  final String letter;
  final String description;
  final bool isCorrect;
  final int order;

  Option({
    required this.letter,
    required this.description,
    required this.isCorrect,
    required this.order,
  });

  /// De Objeto Dart para Map (para aninhar no Realtime Database)
  Map<String, dynamic> toJson() {
    return {
      'letter': letter,
      'description': description,
      'isCorrect': isCorrect,
      'order': order,
    };
  }

  /// De Map (lido do Realtime Database) para Objeto Dart
  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      letter: json['letter'] ?? '',
      description: json['description'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}
