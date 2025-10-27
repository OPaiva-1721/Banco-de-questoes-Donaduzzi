import 'package:firebase_database/firebase_database.dart';
import 'package:prova/models/enums.dart';
import 'option_model.dart';

// Enum to clearly define the question types
class Question {
  final String? id; // The Firebase push-ID (e.g., -Nqg...)
  final String questionText;
  final String subjectId;
  final QuestionType type;

  // --- New Fields You Requested ---
  final QuestionDifficulty difficulty; // e.g., easy, medium, hard
  final bool isActive; // e.g., true (active), false (inactive)

  // --- Type-Specific Fields ---
  final List<Option>? options; // Only for multipleChoice
  final bool? trueFalseAnswer; // Only for trueFalse
  final int? suggestedLines; // Only for essay

  // --- Metadata Fields ---
  final String? imageUrl;
  final String? explanation;
  final String createdBy; // Firebase Auth UID
  final int createdAt; // Saved as timestamp

  Question({
    this.id,
    required this.questionText,
    required this.subjectId,
    required this.type,
    required this.difficulty,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true, // Default to active
    // Type-specific fields are optional
    this.options,
    this.trueFalseAnswer,
    this.suggestedLines,
    this.imageUrl,
    this.explanation,
  });

  /// Converts the Question object to a Map (JSON) for Firebase.
  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'subjectId': subjectId,
      'type': type.name, // Saves the enum as a string (e.g., 'multipleChoice')
      'difficulty':
          difficulty.name, // Saves the enum as a string (e.g., 'easy')
      'isActive': isActive, // Saves the boolean
      'createdBy': createdBy,
      'createdAt': createdAt,
      'imageUrl': imageUrl,
      'explanation': explanation,

      // Save type-specific data only if it's not null
      'options': options?.map((o) => o.toJson()).toList(),
      'trueFalseAnswer': trueFalseAnswer,
      'suggestedLines': suggestedLines,
    };
  }

  /// Helper to convert a string (e.g., 'multipleChoice') back to the enum.
  static QuestionType _typeFromString(String? typeString) {
    switch (typeString) {
      case 'trueFalse':
        return QuestionType.trueFalse;
      case 'essay':
        return QuestionType.essay;
      case 'multipleChoice':
      default:
        return QuestionType.multipleChoice;
    }
  }

  /// Helper to convert a string (e.g., 'easy') back to the enum.
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

  /// Creates a Question object from a Firebase DataSnapshot.
  factory Question.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    // Convert the 'options' list (if it exists) back to List<Option>
    List<Option>? optionsList;
    if (data['options'] != null) {
      final rawList = data['options'] as List;
      optionsList = rawList
          .map((item) => Option.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return Question(
      id: snapshot.key,
      questionText: data['questionText'] ?? '',
      subjectId: data['subjectId'] ?? '',
      type: _typeFromString(data['type']),
      difficulty: _difficultyFromString(data['difficulty']),
      isActive: data['isActive'] ?? true, // Default to true if missing
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'],
      explanation: data['explanation'],

      // Read type-specific data
      options: optionsList,
      trueFalseAnswer: data['trueFalseAnswer'],
      suggestedLines: (data['suggestedLines'] as num?)?.toInt(),
    );
  }
}
