import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';
import 'dart:async';

class ExamService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseReference _examsRef;
  final SecurityService _securityService = SecurityService();

  ExamService() {
    _examsRef = _database.ref('exams');
  }

  Future<String?> createExam({
    required String title,
    required String instructions,
    String? subjectId, // Changed from 'disciplinaId'
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    if (!_securityService.validateText(title, maxLength: 150)) {
      throw Exception('Invalid exam title.');
    }
    if (!_securityService.validateText(instructions, maxLength: 1000)) {
      throw Exception('Invalid exam instructions.');
    }

    try {
      final examData = {
        'title': _securityService.sanitizeInput(title),
        'instructions': _securityService.sanitizeInput(instructions),
        'subjectId': subjectId,
        'teacherId': userId,
        'createdAt': ServerValue.timestamp,
        'questions': {}, 
      };

      final newExamRef = _examsRef.push();
      await newExamRef.set(examData);

      await _securityService.logSecurityActivity(
        'create_exam',
        'Exam created: $title',
        success: true,
      );
      return newExamRef.key;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_create_exam',
        'Error: ${e.toString()}',
        success: false,
      );
      return null;
    }
  }

  Future<bool> addQuestionToExam({
  required String examId,
  required String questionId,
  required int number,
  double peso = 0.0,
  int? suggestedLines,
}) async {
  try {
    final questionInExamRef =
        _examsRef.child(examId).child('questions').child(questionId);

    await questionInExamRef.set({
      'number': number,
      'peso': peso,
      'suggestedLines': suggestedLines,
    });

    return true;
  } catch (e) {
    print('Erro ao adicionar questão à prova: $e');
    return false;
  }
}

  Future<bool> removeQuestionFromExam(String examId, String questionId) async {
    try {
      final questionInExamRef = _examsRef
          .child(examId)
          .child('questions')
          .child(questionId);
      await questionInExamRef.remove();
      return true;
    } catch (e) {
      print('Error removing question from exam: $e');
      return false;
    }
  }

  Stream<DatabaseEvent> getExamsStream() {
    return _examsRef.onValue;
  }

  Stream<DatabaseEvent> getExamsByTeacherStream(String teacherId) {
    final query = _examsRef.orderByChild('teacherId').equalTo(teacherId);
    return query.onValue;
  }

  Future<DataSnapshot?> getExam(String examId) async {
    try {
      return await _examsRef.child(examId).get();
    } catch (e) {
      print('Error fetching exam: $e');
      return null;
    }
  }

  Future<bool> updateExam(
    String examId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _examsRef.child(examId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating exam: $e');
      return false;
    }
  }

  Future<bool> deleteExam(String examId) async {
    try {
      await _examsRef.child(examId).remove();
      await _securityService.logSecurityActivity(
        'delete_exam',
        'Exam $examId deleted',
        success: true,
      );
      return true;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_delete_exam',
        'Error: ${e.toString()}',
        success: false,
      );
      return false;
    }
  }
}
