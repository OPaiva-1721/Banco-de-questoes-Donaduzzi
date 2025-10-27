import 'package:firebase_database/firebase_database.dart';
import 'option_model.dart'; // Importa o modelo de Option

/// Modelo para `Question` (Questão)
class Question {
  final String? id;
  final String questionText;
  final String disciplineId; // FK para Discipline (antiga KnowledgeAreaId)
  final String? imageUrl;
  final String levelOfQuestion;
  final DateTime dateCreated;
  final int? amountLines;
  final String contentId; // FK para Content
  final List<Option> options; // Lista de opções aninhada

  Question({
    this.id,
    required this.questionText,
    required this.disciplineId,
    this.imageUrl,
    required this.levelOfQuestion,
    required this.dateCreated,
    this.amountLines,
    required this.contentId,
    required this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'disciplineId': disciplineId,
      'imageUrl': imageUrl,
      'levelOfQuestion': levelOfQuestion,
      // Salva data como String ISO 8601 (padrão) ou timestamp
      'dateCreated': dateCreated.millisecondsSinceEpoch,
      'amountLines': amountLines,
      'contentId': contentId,
      // Mapeia a lista de objetos Option para uma lista de Maps
      'options': options.map((option) => option.toJson()).toList(),
    };
  }

  static Map<String, dynamic> _dataToMap(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is Map) {
      return Map<String, dynamic>.from(value.cast<dynamic, dynamic>());
    }
    return {};
  }

  factory Question.fromSnapshot(DataSnapshot snapshot) {
    final data = _dataToMap(snapshot);

    // Converte a lista de Maps (do RTDB) para uma lista de Options
    final optionsList = (data['options'] as List<dynamic>? ?? [])
        .map(
          (optionJson) =>
              Option.fromJson(Map<String, dynamic>.from(optionJson)),
        )
        .toList();

    // Converte o timestamp (int) de volta para DateTime
    final timestamp =
        (data['dateCreated'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;

    return Question(
      id: snapshot.key,
      questionText: data['questionText'] ?? '',
      disciplineId: data['disciplineId'] ?? '',
      imageUrl: data['imageUrl'],
      levelOfQuestion: data['levelOfQuestion'] ?? 'Fácil',
      dateCreated: DateTime.fromMillisecondsSinceEpoch(timestamp),
      amountLines: (data['amountLines'] as num?)?.toInt(),
      contentId: data['contentId'] ?? '',
      options: optionsList,
    );
  }
}
