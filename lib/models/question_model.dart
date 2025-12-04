import 'package:firebase_database/firebase_database.dart';
import 'package:prova/models/enums.dart';
import 'option_model.dart';

class Question {
  final String? id;
  final String questionText;
  final String subjectId;
  final String contentId; // NOVO: referência ao conteúdo
  final QuestionDifficulty difficulty;
  final bool isActive;
  final List<Option> options;
  final String? imageUrl;
  final String? explanation;
  final String createdBy;
  final int createdAt;

  Question({
    this.id,
    required this.questionText,
    required this.subjectId,
    required this.contentId, // NOVO
    required this.difficulty,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
    required this.options,
    this.imageUrl,
    this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'subjectId': subjectId,
      'contentId': contentId, // NOVO
      'difficulty': difficulty.name,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'imageUrl': imageUrl,
      'explanation': explanation,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }

  static QuestionDifficulty _difficultyFromString(String? diffString) {
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

  factory Question.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    List<Option> optionsList;
    if (data['options'] != null) {
      final rawList = data['options'] as List;
      optionsList = rawList
          .map((item) => Option.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } else {
      optionsList = [];
    }

    return Question(
      id: snapshot.key,
      questionText: data['questionText'] ?? '',
      subjectId: data['subjectId'] ?? '',
      contentId: data['contentId'] ?? '', // NOVO
      difficulty: _difficultyFromString(data['difficulty']),
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'],
      explanation: data['explanation'],
      options: optionsList,
    );
  }
}
