import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';
import '../models/question_model.dart'; // Importa o modelo atualizado (com enums)
import '../models/option_model.dart';
import '../models/enums.dart'; // Importa os enums

import 'dart:async';

class QuestionService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseReference _questionsRef;
  late final DatabaseReference _subjectsRef;
  late final DatabaseReference _examsRef;
  final SecurityService _securityService = SecurityService();

  QuestionService() {
    _questionsRef = _database.ref('questions');
    _subjectsRef = _database.ref('subjects');
    _examsRef = _database.ref('exams');
  }

  /// Private helper to run type-specific validation.
  void _validateQuestion(Question question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        if (question.options == null ||
            question.options!.length < 2 ||
            question.options!.length > 5) {
          throw Exception(
            'Multiple choice questions must have between 2 and 5 options.',
          );
        }
        bool hasCorrect = question.options!.any(
          (option) => option.isCorrect == true,
        );
        if (!hasCorrect) {
          throw Exception('At least one option must be marked as correct.');
        }
        for (var option in question.options!) {
          if (!_securityService.validateText(option.text, maxLength: 500)) {
            throw Exception('Invalid option text.');
          }
          if (!_securityService.validateText(option.letter, maxLength: 1)) {
            throw Exception('Invalid option letter.');
          }
        }
        break;

      case QuestionType.trueFalse:
        if (question.trueFalseAnswer == null) {
          throw Exception('A True/False answer must be provided.');
        }
        break;

      case QuestionType.essay:
        // No specific validation needed.
        break;
    }
  }

  /// Creates a new question in the database.
  Future<String?> createQuestion(Question newQuestion) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      // 1. General Validation
      if (!_securityService.validateText(
        newQuestion.questionText,
        maxLength: 1000,
      )) {
        throw Exception('Invalid question statement.');
      }
      if (newQuestion.explanation != null &&
          !_securityService.validateText(
            newQuestion.explanation,
            maxLength: 1000,
          )) {
        throw Exception('Invalid explanation text.');
      }

      // 2. External Validation: Check if subject exists
      final subjectSnapshot = await _subjectsRef
          .child(newQuestion.subjectId)
          .get();
      if (!subjectSnapshot.exists) {
        throw Exception('Subject not found.');
      }

      // 3. Type-Specific Validation
      _validateQuestion(newQuestion);

      // 4. Save to Firebase
      final newQuestionRef = _questionsRef.push();

      // The model's toJson() method now automatically handles
      // 'difficulty' and 'isActive'. No change needed here.
      await newQuestionRef.set(newQuestion.toJson());

      await _securityService.logSecurityActivity(
        'create_question',
        'Question (${newQuestion.type.name}) created.',
        success: true,
      );
      return newQuestionRef.key;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_create_question',
        'Error: ${e.toString()}',
        success: false,
      );
      return null;
    }
  }

  /// Returns a Stream of the list of Question objects.
  Stream<List<Question>> getQuestionsStream() {
    return _questionsRef.onValue.map((event) {
      final questionsList = <Question>[];
      if (event.snapshot.exists && event.snapshot.value != null) {
        for (final childSnapshot in event.snapshot.children) {
          questionsList.add(Question.fromSnapshot(childSnapshot));
        }
      }
      return questionsList;
    });
  }

  /// Returns a Stream of Question objects filtered by subjectId.
  Stream<List<Question>> getQuestionsBySubjectStream(String subjectId) {
    final query = _questionsRef.orderByChild('subjectId').equalTo(subjectId);

    return query.onValue.map((event) {
      final questionsList = <Question>[];
      if (event.snapshot.exists && event.snapshot.value != null) {
        for (final childSnapshot in event.snapshot.children) {
          questionsList.add(Question.fromSnapshot(childSnapshot));
        }
      }
      return questionsList;
    });
  }

  /// Fetches a single Question object by its ID.
  Future<Question?> getQuestion(String questionId) async {
    try {
      final snapshot = await _questionsRef.child(questionId).get();
      if (snapshot.exists) {
        return Question.fromSnapshot(snapshot);
      }
      return null;
    } catch (e) {
      print('Error fetching question: $e');
      return null;
    }
  }

  /// Updates an existing question.
  Future<bool> updateQuestion(Question updatedQuestion) async {
    if (updatedQuestion.id == null) {
      throw Exception('Question ID cannot be null for an update.');
    }

    try {
      _validateQuestion(updatedQuestion);

      final updateData = updatedQuestion.toJson();
      updateData['lastUpdatedAt'] = ServerValue.timestamp;

      await _questionsRef.child(updatedQuestion.id!).update(updateData);

      await _securityService.logSecurityActivity(
        'update_question',
        'Question ${updatedQuestion.id} updated',
        success: true,
      );
      return true;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_update_question',
        'Error: ${e.toString()}',
        success: false,
      );
      return false;
    }
  }

  /// Deletes a question, checking for exam dependencies first.
  Future<bool> deleteQuestion(String questionId) async {
    try {
      // 1. Check if the question is used in any exams
      final examsSnapshot = await _examsRef.get();

      if (examsSnapshot.exists && examsSnapshot.value != null) {
        final allExams = Map<String, dynamic>.from(
          examsSnapshot.value as Map<dynamic, dynamic>,
        );

        for (var examData in allExams.values) {
          if (examData['questions'] != null) {
            final questionsInExam = Map<String, dynamic>.from(
              examData['questions'],
            );
            if (questionsInExam.containsKey(questionId)) {
              throw Exception('Cannot delete: Question is used in an exam.');
            }
          }
        }
      }

      // 2. If not used, delete the question
      await _questionsRef.child(questionId).remove();

      await _securityService.logSecurityActivity(
        'delete_question',
        'Question $questionId deleted',
        success: true,
      );
      return true;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_delete_question',
        'Error: ${e.toString()}',
        success: false,
      );
      return false;
    }
  }
}
