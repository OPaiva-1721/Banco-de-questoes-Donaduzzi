// Importe apenas o que você precisa (QuestionDifficulty)
import 'package:firebase_database/firebase_database.dart';
import 'package:prova/models/enums.dart'; // Mantenha isso para QuestionDifficulty
import 'option_model.dart';

class Question {
  final String? id;
  final String questionText;
  final String subjectId;
  // final QuestionType type; // REMOVA ISSO

  final QuestionDifficulty difficulty;
  final bool isActive;

  // --- Campos Específicos ---
  final List<Option> options; // MUDE DE List<Option>? PARA List<Option>
  // final bool? trueFalseAnswer; // REMOVA ISSO
  // final int? suggestedLines; // REMOVA ISSO

  // --- Campos de Metadados ---
  final String? imageUrl;
  final String? explanation;
  final String createdBy;
  final int createdAt;

  Question({
    this.id,
    required this.questionText,
    required this.subjectId,
    // required this.type, // REMOVA ISSO
    required this.difficulty,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
    required this.options, // MUDE DE this.options PARA required this.options
    // this.trueFalseAnswer, // REMOVA ISSO
    // this.suggestedLines, // REMOVA ISSO
    this.imageUrl,
    this.explanation,
  });

  /// Converte o Question para Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'subjectId': subjectId,
      // 'type': type.name, // REMOVA ISSO
      'difficulty': difficulty.name,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'imageUrl': imageUrl,
      'explanation': explanation,

      // Mude de 'options?.' para 'options.'
      'options': options.map((o) => o.toJson()).toList(),
      // 'trueFalseAnswer': trueFalseAnswer, // REMOVA ISSO
      // 'suggestedLines': suggestedLines, // REMOVA ISSO
    };
  }

  // REMOVA O MÉTODO _typeFromString INTEIRO
  /*
  static QuestionType _typeFromString(String? typeString) {
    ...
  }
  */

  /// Helper para converter string (e.g., 'easy') de volta para o enum.
  static QuestionDifficulty _difficultyFromString(String? diffString) {
    // Este método continua igual
    switch (diffString) {
      case 'medium':
        return QuestionDifficulty.medium;
      case 'hard':
        return QuestionDifficulty.hard;
      case 'easy':
      default:
        return QuestionDifficulty.easy;
    }
  }

  /// Cria um Question a partir de um Firebase DataSnapshot.
  factory Question.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    // Converta 'options' para List<Option>
    // Esta lógica agora deve garantir que a lista não seja nula.
    List<Option> optionsList;
    if (data['options'] != null) {
      final rawList = data['options'] as List;
      optionsList = rawList
          .map((item) => Option.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } else {
      optionsList = []; // Ou lance um erro se 'options' for sempre esperado
    }

    return Question(
      id: snapshot.key,
      questionText: data['questionText'] ?? '',
      subjectId: data['subjectId'] ?? '',
      // type: _typeFromString(data['type']), // REMOVA ISSO
      difficulty: _difficultyFromString(data['difficulty']),
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'],
      explanation: data['explanation'],

      // Atribua a lista não nula
      options: optionsList,
      // trueFalseAnswer: data['trueFalseAnswer'], // REMOVA ISSO
      // suggestedLines: (data['suggestedLines'] as num?)?.toInt(), // REMOVA ISSO
    );
  }
}
