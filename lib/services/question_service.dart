import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';
import '../models/question_model.dart';
import '../models/option_model.dart';
import '../models/enums.dart';
import 'dart:async';

class QuestionService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseReference _questionsRef;
  late final DatabaseReference _subjectsRef;
  late final DatabaseReference _contentsRef; 
  late final DatabaseReference _examsRef;
  final SecurityService _securityService = SecurityService();

  QuestionService() {
    _questionsRef = _database.ref('questions');
    _subjectsRef = _database.ref('subjects');
    _contentsRef = _database.ref('contents');
    _examsRef = _database.ref('exams');
  }

  void _validateQuestion(Question question) {
    if (question.options.length != 5) {
      throw Exception('As questões devem ter exatamente 5 opções.');
    }

    final correctCount = question.options
        .where((option) => option.isCorrect)
        .length;
    if (correctCount != 1) {
      throw Exception('Exatamente uma opção deve ser marcada como correta.');
    }

    for (var option in question.options) {
      if (!_securityService.validateText(option.text, maxLength: 500)) {
        throw Exception('Texto da opção inválido.');
      }
      if (!_securityService.validateText(option.letter, maxLength: 1)) {
        throw Exception('Letra da opção inválida.');
      }
    }
  }

  Future<String?> createQuestion(Question newQuestion) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      if (!_securityService.validateText(
        newQuestion.questionText,
        maxLength: 1000,
      )) {
        throw Exception('Enunciado da questão inválido.');
      }
      if (newQuestion.explanation != null &&
          !_securityService.validateText(
            newQuestion.explanation,
            maxLength: 1000,
          )) {
        throw Exception('Texto da explicação inválido.');
      }

      final subjectSnapshot = await _subjectsRef
          .child(newQuestion.subjectId)
          .get();
      if (!subjectSnapshot.exists) {
        throw Exception('Disciplina não encontrada.');
      }

      // NOVO: Validar se o conteúdo existe
      final contentSnapshot = await _contentsRef
          .child(newQuestion.contentId)
          .get();
      if (!contentSnapshot.exists) {
        throw Exception('Conteúdo não encontrado.');
      }

      _validateQuestion(newQuestion);

      final newQuestionRef = _questionsRef.push();
      await newQuestionRef.set(newQuestion.toJson());

      await _securityService.logSecurityActivity(
        'create_question',
        'Question created.',
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

  Stream<List<Question>> getQuestionsStream() {
    return _questionsRef.onValue.map((event) {
      final questionsList = <Question>[];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value;
        if (data is Map) {
          for (final childSnapshot in event.snapshot.children) {
            questionsList.add(Question.fromSnapshot(childSnapshot));
          }
        }
      }
      return questionsList;
    });
  }

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

  // NOVO: Buscar questões por conteúdo
  Stream<List<Question>> getQuestionsByContentStream(String contentId) {
    final query = _questionsRef.orderByChild('contentId').equalTo(contentId);

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

  Future<bool> updateQuestion(Question updatedQuestion) async {
    if (updatedQuestion.id == null) {
      throw Exception('ID da questão não pode ser nulo para uma atualização.');
    }

    try {
      if (!_securityService.validateText(
        updatedQuestion.questionText,
        maxLength: 1000,
      )) {
        throw Exception('Enunciado da questão inválido.');
      }
      if (updatedQuestion.explanation != null &&
          !_securityService.validateText(
            updatedQuestion.explanation,
            maxLength: 1000,
          )) {
        throw Exception('Texto da explicação inválido.');
      }

      final subjectSnapshot = await _subjectsRef
          .child(updatedQuestion.subjectId)
          .get();
      if (!subjectSnapshot.exists) {
        throw Exception('Disciplina não encontrada.');
      }

      // NOVO: Validar se o conteúdo existe
      final contentSnapshot = await _contentsRef
          .child(updatedQuestion.contentId)
          .get();
      if (!contentSnapshot.exists) {
        throw Exception('Conteúdo não encontrado.');
      }

      _validateQuestion(updatedQuestion);

      await _questionsRef
          .child(updatedQuestion.id!)
          .update(updatedQuestion.toJson());

      await _securityService.logSecurityActivity(
        'update_question',
        'Question ${updatedQuestion.id} updated.',
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

  Future<bool> deleteQuestion(String questionId) async {
    try {
      final query = _examsRef
          .orderByChild('questions/$questionId')
          .limitToFirst(1);
      final snapshot = await query.get();

      if (snapshot.exists) {
        throw Exception(
          'Não é possível deletar: Questão está sendo usada em uma prova.',
        );
      }

      await _questionsRef.child(questionId).remove();

      await _securityService.logSecurityActivity(
        'delete_question',
        'Question $questionId deleted.',
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

  Future<bool> toggleQuestionActive(String questionId, bool isActive) async {
    try {
      await _questionsRef.child(questionId).update({'isActive': isActive});

      await _securityService.logSecurityActivity(
        'toggle_question_active',
        'Question $questionId set to ${isActive ? "active" : "inactive"}.',
        success: true,
      );
      return true;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_toggle_question_active',
        'Error: ${e.toString()}',
        success: false,
      );
      return false;
    }
  }
}
