import 'package:firebase_database/firebase_database.dart';
import 'exam_question_link_model.dart';

/// Modelo para `Exam` (Prova)
class Exam {
  final String? id;
  final String title;
  final String instructions;
  final String teacherId; // FK para User (Auth UID)
  final String courseId; // FK para Course
  final DateTime dateCreated;
  final List<ExamQuestionLink> questions; // Lista de questões aninhada

  Exam({
    this.id,
    required this.title,
    required this.instructions,
    required this.teacherId,
    required this.courseId,
    required this.dateCreated,
    required this.questions,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'instructions': instructions,
    'teacherId': teacherId,
    'courseId': courseId,
    'dateCreated': dateCreated.millisecondsSinceEpoch,
    'questions': questions.map((q) => q.toJson()).toList(),
  };

  static Map<String, dynamic> _dataToMap(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is Map) {
      return Map<String, dynamic>.from(value.cast<dynamic, dynamic>());
    }
    return {};
  }

  factory Exam.fromSnapshot(DataSnapshot snapshot) {
    final data = _dataToMap(snapshot);
    final questionsList = (data['questions'] as List<dynamic>? ?? [])
        .map((q) => ExamQuestionLink.fromJson(Map<String, dynamic>.from(q)))
        .toList();

    final timestamp =
        (data['dateCreated'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;

    return Exam(
      id: snapshot.key,
      title: data['title'] ?? '',
      instructions: data['instructions'] ?? '',
      teacherId: data['teacherId'] ?? '',
      courseId: data['courseId'] ?? '',
      dateCreated: DateTime.fromMillisecondsSinceEpoch(timestamp),
      questions: questionsList,
    );
  }
}
