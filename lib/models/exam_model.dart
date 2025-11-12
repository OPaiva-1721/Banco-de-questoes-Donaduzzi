// lib/models/exam_model.dart
import 'package:firebase_database/firebase_database.dart';
import 'exam_question_link_model.dart';

class Exam {
  final String? id;
  final String title;
  final String instructions;
  final String subjectId; 
  final String? courseId; 
  final String createdBy;
  final DateTime createdAt;
  final int timeLimit;
  final bool shuffleQuestions;
  final bool isActive;
  final List<ExamQuestionLink> questions;

  Exam({
    this.id,
    required this.title,
    required this.instructions,
    required this.subjectId,
    this.courseId,
    required this.createdBy,
    required this.createdAt,
    required this.timeLimit,
    required this.shuffleQuestions,
    required this.isActive,
    required this.questions,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'instructions': instructions,
      'subjectId': subjectId,
      'courseId': courseId,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'timeLimit': timeLimit,
      'shuffleQuestions': shuffleQuestions,
      'isActive': isActive,
      // Converte a lista de volta para um Map para o Firebase
      'questions': Map.fromEntries(questions.map((q) => MapEntry(q.questionId, {
            'number': q.order,
            'peso': q.weight,
            'suggestedLines': q.suggestedLines,
          }))),
    };
  }

  static Map<String, dynamic> _dataToMap(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is Map) {
      return Map<String, dynamic>.from(value.cast<dynamic, dynamic>());
    }
    return {};
  }

  factory Exam.fromSnapshot(DataSnapshot snapshot) {
    final data = _dataToMap(snapshot);

    final List<ExamQuestionLink> questionsList = [];
    if (data['questions'] is Map) {
      final questionsMap =
          Map<String, dynamic>.from(data['questions'] as Map);
      questionsMap.forEach((questionId, questionData) {
        if (questionData is Map) {
          questionsList.add(ExamQuestionLink(
            examId: snapshot.key ?? '',
            questionId: questionId,
            order: (questionData['number'] as num?)?.toInt() ?? 0,
            // Lê o peso que guardámos!
            weight: (questionData['peso'] as num?)?.toDouble() ?? 0.0,
            suggestedLines: (questionData['suggestedLines'] as num?)?.toInt(),
          ));
        }
      });
      // Ordena pela ordem ('number')
      questionsList.sort((a, b) => a.order.compareTo(b.order));
    }

    return Exam(
      id: snapshot.key,
      title: data['title'] ?? '',
      instructions: data['instructions'] ?? '',
      subjectId: data['subjectId'] ?? '',
      courseId: data['courseId'], 
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
      timeLimit: (data['timeLimit'] as num?)?.toInt() ?? 3600,
      shuffleQuestions: data['shuffleQuestions'] ?? false,
      isActive: data['isActive'] ?? true,
      questions: questionsList, 
    );
  }
}