import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'exam_question_link_model.dart'; 

class Exam {
  final String? id;
  final String title;
  final String instructions;
  final String subjectId; 
  final String courseId; 
  final String createdBy; 
  final DateTime createdAt;
  final List<ExamQuestionLink> questions;
  final List<String> contentIds; 

  Exam({
    this.id,
    required this.title,
    required this.instructions,
    required this.subjectId,
    required this.courseId,
    required this.createdBy,
    required this.createdAt,
    List<ExamQuestionLink>? questions,
    List<String>? contentIds,
  })  : this.questions = questions ?? [],
        this.contentIds = contentIds ?? [];

  String get formattedCreatedAt {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'instructions': instructions,
      'subjectId': subjectId,
      'courseId': courseId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(), 
      'questions': {
        for (var q in questions)
          q.questionId: {
            'number': q.order,
            'peso': q.weight,
            'suggestedLines': q.suggestedLines,
          }
      },
      'contentIds': contentIds,
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
    final questionsMap = data['questions'];
    List<ExamQuestionLink> parsedQuestions = [];
    final String examId = snapshot.key ?? ''; 

    if (questionsMap is Map) {
      questionsMap.forEach((key, value) { 
        if (value is Map) {
          parsedQuestions.add(
            ExamQuestionLink.fromJson(
              examId, 
              key,    
              Map<String, dynamic>.from(value), 
            ),
          );
        }
      });
      parsedQuestions.sort((a, b) => a.order.compareTo(b.order));
    }

    List<String> parsedContentIds = [];
    final dynamic rawContentIds = data['contentIds'];
    if (rawContentIds != null) { 
      if (rawContentIds is List) {
        try {
          parsedContentIds = rawContentIds
              .where((item) => item != null) 
              .map((item) => item.toString()) 
              .toList();
        } catch (e) {
          print("===== ERRO EM EXAM_MODEL (LIST): Falha ao converter contentIds. $e =====");
        }
      } else if (rawContentIds is Map) {
        try {
          parsedContentIds = rawContentIds.values 
              .where((item) => item != null) 
              .map((item) => item.toString()) 
              .toList();
        } catch (e) {
          print("===== ERRO EM EXAM_MODEL (MAP): Falha ao converter contentIds. $e =====");
        }
      }
    }

    DateTime parsedCreatedAt;
    final dynamic rawDate = data['createdAt'];
    if (rawDate is String) {
      parsedCreatedAt = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return Exam(
      id: snapshot.key, 
      title: data['title']?.toString() ?? 'Título Padrão',
      instructions: data['instructions']?.toString() ?? '',
      subjectId: data['subjectId']?.toString() ?? '',
      courseId: data['courseId']?.toString() ?? '',
      createdBy: data['createdBy']?.toString() ?? '',
      createdAt: parsedCreatedAt, 
      questions: parsedQuestions,
      contentIds: parsedContentIds, 
    );
  }
}