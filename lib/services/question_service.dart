import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';
import '../models/question_model.dart';
import '../models/option_model.dart';
import '../models/enums.dart';
import '../core/exceptions/app_exceptions.dart';
import '../utils/error_messages.dart';
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
      throw ValidationException(ErrorMessages.questionMustHaveFiveOptions);
    }

    final correctCount = question.options
        .where((option) => option.isCorrect)
        .length;
    if (correctCount != 1) {
      throw ValidationException(ErrorMessages.questionMustHaveOneCorrectOption);
    }

    for (var option in question.options) {
      if (option.text.trim().isEmpty) {
        throw ValidationException(ErrorMessages.questionOptionTextRequired);
      }
      if (!_securityService.validateText(option.text, maxLength: 500)) {
        throw ValidationException(ErrorMessages.invalidOptionText);
      }
      if (!_securityService.validateText(option.letter, maxLength: 1)) {
        throw ValidationException(ErrorMessages.questionOptionLetterInvalid);
      }
    }
  }

  /// Cria uma nova questão
  /// 
  /// Retorna o ID da questão criada ou lança uma exceção em caso de erro.
  /// 
  /// Exceções possíveis:
  /// - [ValidationException]: Dados inválidos
  /// - [NotFoundException]: Disciplina ou conteúdo não encontrado
  /// - [AppFirebaseException]: Erro ao salvar no Firebase
  /// - [NetworkException]: Erro de conexão
  Future<String> createQuestion(Question newQuestion) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw AuthenticationException(ErrorMessages.userNotLoggedIn);
    }

    try {
      // Validação do enunciado
      if (!_securityService.validateText(
        newQuestion.questionText,
        maxLength: 1000,
      )) {
        throw ValidationException(ErrorMessages.invalidQuestionText);
      }

      // Validação da explicação (opcional)
      if (newQuestion.explanation != null &&
          !_securityService.validateText(
            newQuestion.explanation,
            maxLength: 1000,
          )) {
        throw ValidationException(ErrorMessages.invalidQuestionText);
      }

      // Verificar se a disciplina existe
      final subjectSnapshot = await _subjectsRef
          .child(newQuestion.subjectId)
          .get();
      if (!subjectSnapshot.exists) {
        throw NotFoundException(ErrorMessages.subjectNotFound);
      }

      // Verificar se o conteúdo existe
      final contentSnapshot = await _contentsRef
          .child(newQuestion.contentId)
          .get();
      if (!contentSnapshot.exists) {
        throw NotFoundException(ErrorMessages.contentNotFound);
      }

      // Validar estrutura da questão
      _validateQuestion(newQuestion);

      // Criar questão
      final newQuestionRef = _questionsRef.push();
      await newQuestionRef.set(newQuestion.toJson());

      await _securityService.logSecurityActivity(
        'create_question',
        'Question created: ${newQuestionRef.key}',
        success: true,
      );

      return newQuestionRef.key!;
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      await _securityService.logSecurityActivity(
        'error_create_question',
        'Firebase database error: ${e.message}',
        success: false,
      );
      throw NetworkException(
        ErrorMessages.networkError,
        originalError: e,
      );
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_create_question',
        'Unexpected error: ${e.toString()}',
        success: false,
      );
      throw UnexpectedException(
        ErrorMessages.unexpectedError,
        originalError: e,
      );
    }
  }

  /// Retorna stream de todas as questões ATIVAS
  /// 
  /// Otimizado: Filtra apenas questões ativas para melhor performance
  Stream<List<Question>> getQuestionsStream() {
    // Query otimizada: apenas questões ativas, ordenadas por data de criação
    final query = _questionsRef
        .orderByChild('isActive')
        .equalTo(true);

    return query.onValue.map((event) {
      final questionsList = <Question>[];
      if (event.snapshot.exists && event.snapshot.value != null) {
        for (final childSnapshot in event.snapshot.children) {
          try {
            questionsList.add(Question.fromSnapshot(childSnapshot));
          } catch (e) {
            // Ignora questões com dados inválidos, mas continua processando
            continue;
          }
        }
      }
      return questionsList;
    }).handleError((error) {
      throw NetworkException(
        ErrorMessages.fetchFailed,
        originalError: error,
      );
    });
  }

  /// Retorna stream de TODAS as questões (ativas e inativas)
  /// 
  /// Use apenas quando necessário ver questões inativas
  Stream<List<Question>> getAllQuestionsStream() {
    return _questionsRef.onValue.map((event) {
      final questionsList = <Question>[];
      if (event.snapshot.exists && event.snapshot.value != null) {
        for (final childSnapshot in event.snapshot.children) {
          try {
            questionsList.add(Question.fromSnapshot(childSnapshot));
          } catch (e) {
            continue;
          }
        }
      }
      return questionsList;
    }).handleError((error) {
      throw NetworkException(
        ErrorMessages.fetchFailed,
        originalError: error,
      );
    });
  }

  /// Retorna stream de questões de uma disciplina específica (apenas ativas)
  /// 
  /// Otimizado: Filtra por disciplina E status ativo
  Stream<List<Question>> getQuestionsBySubjectStream(String subjectId) {
    // Query otimizada: filtra por subjectId e isActive
    // Nota: Firebase não suporta múltiplos orderByChild, então filtramos manualmente
    final query = _questionsRef.orderByChild('subjectId').equalTo(subjectId);

    return query.onValue.map((event) {
      final questionsList = <Question>[];
      if (event.snapshot.exists && event.snapshot.value != null) {
        for (final childSnapshot in event.snapshot.children) {
          try {
            final question = Question.fromSnapshot(childSnapshot);
            // Filtro adicional: apenas questões ativas
            if (question.isActive) {
              questionsList.add(question);
            }
          } catch (e) {
            continue;
          }
        }
      }
      return questionsList;
    }).handleError((error) {
      throw NetworkException(
        ErrorMessages.fetchFailed,
        originalError: error,
      );
    });
  }

  /// Retorna stream de questões de um conteúdo específico (apenas ativas)
  Stream<List<Question>> getQuestionsByContentStream(String contentId) {
    final query = _questionsRef.orderByChild('contentId').equalTo(contentId);

    return query.onValue.map((event) {
      final questionsList = <Question>[];
      if (event.snapshot.exists && event.snapshot.value != null) {
        for (final childSnapshot in event.snapshot.children) {
          try {
            final question = Question.fromSnapshot(childSnapshot);
            // Filtro adicional: apenas questões ativas
            if (question.isActive) {
              questionsList.add(question);
            }
          } catch (e) {
            continue;
          }
        }
      }
      return questionsList;
    }).handleError((error) {
      throw NetworkException(
        ErrorMessages.fetchFailed,
        originalError: error,
      );
    });
  }

  /// Busca uma questão específica pelo ID
  /// 
  /// Retorna a questão ou lança [NotFoundException] se não encontrada
  Future<Question> getQuestion(String questionId) async {
    try {
      final snapshot = await _questionsRef.child(questionId).get();
      if (snapshot.exists) {
        return Question.fromSnapshot(snapshot);
      }
      throw NotFoundException(ErrorMessages.questionNotFound);
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw NetworkException(
        ErrorMessages.fetchFailed,
        originalError: e,
      );
    } catch (e) {
      throw UnexpectedException(
        ErrorMessages.unexpectedError,
        originalError: e,
      );
    }
  }

  /// Atualiza uma questão existente
  /// 
  /// Exceções possíveis:
  /// - [ValidationException]: Dados inválidos ou ID nulo
  /// - [NotFoundException]: Questão, disciplina ou conteúdo não encontrado
  /// - [AppFirebaseException]: Erro ao atualizar no Firebase
  Future<void> updateQuestion(Question updatedQuestion) async {
    if (updatedQuestion.id == null) {
      throw ValidationException(ErrorMessages.questionIdRequired);
    }

    try {
      // Validação do enunciado
      if (!_securityService.validateText(
        updatedQuestion.questionText,
        maxLength: 1000,
      )) {
        throw ValidationException(ErrorMessages.invalidQuestionText);
      }

      // Validação da explicação (opcional)
      if (updatedQuestion.explanation != null &&
          !_securityService.validateText(
            updatedQuestion.explanation,
            maxLength: 1000,
          )) {
        throw ValidationException(ErrorMessages.invalidQuestionText);
      }

      // Verificar se a questão existe
      final questionSnapshot = await _questionsRef
          .child(updatedQuestion.id!)
          .get();
      if (!questionSnapshot.exists) {
        throw NotFoundException(ErrorMessages.questionNotFound);
      }

      // Verificar se a disciplina existe
      final subjectSnapshot = await _subjectsRef
          .child(updatedQuestion.subjectId)
          .get();
      if (!subjectSnapshot.exists) {
        throw NotFoundException(ErrorMessages.subjectNotFound);
      }

      // Verificar se o conteúdo existe
      final contentSnapshot = await _contentsRef
          .child(updatedQuestion.contentId)
          .get();
      if (!contentSnapshot.exists) {
        throw NotFoundException(ErrorMessages.contentNotFound);
      }

      // Validar estrutura da questão
      _validateQuestion(updatedQuestion);

      // Atualizar questão
      await _questionsRef
          .child(updatedQuestion.id!)
          .update(updatedQuestion.toJson());

      await _securityService.logSecurityActivity(
        'update_question',
        'Question ${updatedQuestion.id} updated.',
        success: true,
      );
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      await _securityService.logSecurityActivity(
        'error_update_question',
        'Firebase error: ${e.message}',
        success: false,
      );
      throw NetworkException(
        ErrorMessages.updateFailed,
        originalError: e,
      );
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_update_question',
        'Unexpected error: ${e.toString()}',
        success: false,
      );
      throw UnexpectedException(
        ErrorMessages.unexpectedError,
        originalError: e,
      );
    }
  }

  /// Deleta uma questão
  /// 
  /// Exceções possíveis:
  /// - [NotFoundException]: Questão não encontrada
  /// - [ResourceInUseException]: Questão está sendo usada em uma prova
  /// - [AppFirebaseException]: Erro ao deletar no Firebase
  /// 
  /// Nota: A query original estava incorreta. Agora busca todas as provas
  /// e verifica manualmente se a questão está em uso.
  Future<void> deleteQuestion(String questionId) async {
    try {
      // Verificar se a questão existe
      final questionSnapshot = await _questionsRef.child(questionId).get();
      if (!questionSnapshot.exists) {
        throw NotFoundException(ErrorMessages.questionNotFound);
      }

      // CORREÇÃO: Buscar todas as provas e verificar se a questão está em uso
      // A query anterior (orderByChild('questions/$questionId')) não funciona
      // porque Firebase não suporta orderByChild com paths aninhados assim
      final examsSnapshot = await _examsRef.get();
      
      if (examsSnapshot.exists && examsSnapshot.value != null) {
        final examsData = examsSnapshot.value as Map<dynamic, dynamic>;
        
        for (final examEntry in examsData.entries) {
          final examData = examEntry.value as Map<dynamic, dynamic>;
          final questions = examData['questions'];
          
          if (questions != null && questions is Map) {
            // Verificar se a questão está na lista de questões da prova
            if (questions.containsKey(questionId)) {
              throw ResourceInUseException(ErrorMessages.questionInUse);
            }
          }
        }
      }

      // Se não está em uso, deletar
      await _questionsRef.child(questionId).remove();

      await _securityService.logSecurityActivity(
        'delete_question',
        'Question $questionId deleted.',
        success: true,
      );
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      await _securityService.logSecurityActivity(
        'error_delete_question',
        'Firebase error: ${e.message}',
        success: false,
      );
      throw NetworkException(
        ErrorMessages.deleteFailed,
        originalError: e,
      );
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_delete_question',
        'Unexpected error: ${e.toString()}',
        success: false,
      );
      throw UnexpectedException(
        ErrorMessages.unexpectedError,
        originalError: e,
      );
    }
  }

  /// Ativa ou desativa uma questão
  /// 
  /// Exceções possíveis:
  /// - [NotFoundException]: Questão não encontrada
  /// - [AppFirebaseException]: Erro ao atualizar no Firebase
  Future<void> toggleQuestionActive(String questionId, bool isActive) async {
    try {
      // Verificar se a questão existe
      final questionSnapshot = await _questionsRef.child(questionId).get();
      if (!questionSnapshot.exists) {
        throw NotFoundException(ErrorMessages.questionNotFound);
      }

      await _questionsRef.child(questionId).update({'isActive': isActive});

      await _securityService.logSecurityActivity(
        'toggle_question_active',
        'Question $questionId set to ${isActive ? "active" : "inactive"}.',
        success: true,
      );
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      await _securityService.logSecurityActivity(
        'error_toggle_question_active',
        'Firebase error: ${e.message}',
        success: false,
      );
      throw NetworkException(
        ErrorMessages.updateFailed,
        originalError: e,
      );
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_toggle_question_active',
        'Unexpected error: ${e.toString()}',
        success: false,
      );
      throw UnexpectedException(
        ErrorMessages.unexpectedError,
        originalError: e,
      );
    }
  }
}
