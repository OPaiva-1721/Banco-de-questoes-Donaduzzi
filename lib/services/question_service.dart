import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';
import '../models/question_model.dart'; // Importa o modelo atualizado (sem QuestionType)
import '../models/option_model.dart';
import '../models/enums.dart'; // Importa apenas QuestionDifficulty

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

  /// Helper privado para validar a questão (agora simplificado).
  void _validateQuestion(Question question) {
    // 1. Validar se tem exatamente 5 opções
    if (question.options.length != 5) {
      throw Exception('As questões devem ter exatamente 5 opções.');
    }

    // 2. Validar se *exatamente UMA* opção está correta
    final correctCount = question.options
        .where((option) => option.isCorrect)
        .length;
    if (correctCount != 1) {
      throw Exception('Exatamente uma opção deve ser marcada como correta.');
    }

    // 3. Validar o texto das opções
    for (var option in question.options) {
      if (!_securityService.validateText(option.text, maxLength: 500)) {
        throw Exception('Texto da opção inválido.');
      }
      // Você pode manter a validação da letra se ela ainda for usada (ex: A, B, C, D, E)
      if (!_securityService.validateText(option.letter, maxLength: 1)) {
        throw Exception('Letra da opção inválida.');
      }
    }
  }

  /// Cria uma nova questão no banco de dados.
  Future<String?> createQuestion(Question newQuestion) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      // 1. Validação Geral
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

      // 2. Validação Externa: Checar se a disciplina existe
      final subjectSnapshot = await _subjectsRef
          .child(newQuestion.subjectId)
          .get();
      if (!subjectSnapshot.exists) {
        throw Exception('Disciplina não encontrada.');
      }

      // 3. Validação Específica (agora simplificada)
      _validateQuestion(newQuestion);

      // 4. Salvar no Firebase
      final newQuestionRef = _questionsRef.push();

      // O toJson() do modelo já foi atualizado para não incluir 'type'
      await newQuestionRef.set(newQuestion.toJson());

      // Log de segurança atualizado (sem .type.name)
      await _securityService.logSecurityActivity(
        'create_question',
        'Question created.', // Anteriormente: 'Question (${newQuestion.type.name}) created.'
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

  /// Retorna um Stream da lista de objetos Question.
  Stream<List<Question>> getQuestionsStream() {
    return _questionsRef.onValue.map((event) {
      final questionsList = <Question>[];
      if (event.snapshot.exists && event.snapshot.value != null) {
        // Garantir que o snapshot é um Map
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

  /// Retorna um Stream de objetos Question filtrados por subjectId.
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

  /// Busca um único objeto Question pelo seu ID.
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

  /// Atualiza uma questão existente.
  Future<bool> updateQuestion(Question updatedQuestion) async {
    if (updatedQuestion.id == null) {
      throw Exception('ID da questão não pode ser nulo para uma atualização.');
    }

    try {
      // Usa a nova validação simplificada
      _validateQuestion(updatedQuestion);

      final updateData = updatedQuestion.toJson();
      updateData['lastUpdatedAt'] =
          ServerValue.timestamp; // Opcional: adicionar timestamp de atualização

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

  /// Deleta uma questão, checando dependências em provas primeiro.
  Future<bool> deleteQuestion(String questionId) async {
    try {
      // 1. Checar se a questão está sendo usada em alguma prova
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
              throw Exception(
                'Não pode deletar: Questão está em uso em uma prova.',
              );
            }
          }
        }
      }

      // 2. Se não estiver em uso, deletar a questão
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
