import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';
import '../core/exceptions/app_exceptions.dart';
import '../utils/error_messages.dart';
import 'user_service.dart';
import '../models/user_model.dart';
import 'dart:async';

class ExamService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseReference _examsRef;
  final SecurityService _securityService = SecurityService();

  // Esta inicialização agora deve funcionar
  final UserService _userService = UserService();

  ExamService() {
    _examsRef = _database.ref('exams');
  }

  /// Cria uma nova prova
  /// 
  /// Retorna o ID da prova criada ou lança uma exceção em caso de erro.
  /// 
  /// Exceções possíveis:
  /// - [AuthenticationException]: Usuário não logado
  /// - [ValidationException]: Dados inválidos
  /// - [NetworkException]: Erro de conexão ou timeout
  /// - [AppFirebaseException]: Erro ao salvar no Firebase
  Future<String> createExam({
    required String title,
    required String instructions,
    required String? subjectId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw AuthenticationException(ErrorMessages.userNotLoggedIn);
    }

    // Validações
    if (!_securityService.validateText(title, maxLength: 150)) {
      throw ValidationException(ErrorMessages.invalidTitle);
    }
    if (!_securityService.validateText(instructions, maxLength: 1000)) {
      throw ValidationException(ErrorMessages.invalidInstructions);
    }
    if (subjectId == null || subjectId.isEmpty) {
      throw ValidationException(ErrorMessages.subjectIdRequired);
    }

    // Buscar nome do usuário com timeout para evitar race condition
    String createdByName;
    try {
      final DatabaseEvent userEvent = await _userService
          .getCurrentUserStream()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: (sink) {
              throw TimeoutException('Timeout ao buscar dados do usuário');
            },
          )
          .first;

      if (userEvent.snapshot.exists) {
        final AppUser currentUser = AppUser.fromSnapshot(userEvent.snapshot);
        createdByName = currentUser.name ?? 'Professor';
      } else {
        createdByName = 'Professor';
      }
    } on TimeoutException {
      // Se timeout, usar nome padrão mas continuar
      createdByName = 'Professor';
      await _securityService.logSecurityActivity(
        'warning_create_exam',
        'Timeout ao buscar nome do usuário, usando nome padrão',
        success: true,
      );
    } catch (e) {
      // Se erro, usar nome padrão mas continuar
      createdByName = 'Professor';
      await _securityService.logSecurityActivity(
        'warning_create_exam',
        'Erro ao buscar nome do usuário: ${e.toString()}',
        success: true,
      );
    }

    final sanitizedTitle = _securityService.sanitizeInput(title);
    final sanitizedInstructions = _securityService.sanitizeInput(instructions);

    try {
      final examData = {
        'title': sanitizedTitle,
        'instructions': sanitizedInstructions,
        'subjectId': subjectId,
        'createdAt': ServerValue.timestamp,
        'createdBy': createdByName,
        'timeLimit': 3600,
        'shuffleQuestions': false,
        'isActive': true,
      };

      final newExamRef = _examsRef.push();
      await newExamRef.set(examData);

      await _securityService.logSecurityActivity(
        'create_exam',
        'Exam created: $sanitizedTitle (ID: ${newExamRef.key})',
        success: true,
      );

      return newExamRef.key!;
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      await _securityService.logSecurityActivity(
        'error_create_exam',
        'Firebase database error: ${e.message}',
        success: false,
      );
      throw NetworkException(
        ErrorMessages.createFailed,
        originalError: e,
      );
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_create_exam',
        'Unexpected error: ${e.toString()}',
        success: false,
      );
      throw UnexpectedException(
        ErrorMessages.unexpectedError,
        originalError: e,
      );
    }
  }

  /// Retorna stream de todas as provas
  /// 
  /// Otimizado: Filtra apenas provas ativas
  Stream<DatabaseEvent> getExamsStream() {
    final query = _examsRef.orderByChild('isActive').equalTo(true);
    return query.onValue.handleError((error) {
      throw NetworkException(
        ErrorMessages.fetchFailed,
        originalError: error,
      );
    });
  }

  /// Retorna stream de TODAS as provas (ativas e inativas)
  Stream<DatabaseEvent> getAllExamsStream() {
    return _examsRef.onValue.handleError((error) {
      throw NetworkException(
        ErrorMessages.fetchFailed,
        originalError: error,
      );
    });
  }

  /// Atualiza uma prova existente
  /// 
  /// Exceções possíveis:
  /// - [NotFoundException]: Prova não encontrada
  /// - [NetworkException]: Erro de conexão
  Future<void> updateExam(
    String examId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      // Verificar se a prova existe
      final examSnapshot = await _examsRef.child(examId).get();
      if (!examSnapshot.exists) {
        throw NotFoundException(ErrorMessages.examNotFound);
      }

      updateData['lastUpdatedAt'] = ServerValue.timestamp;
      await _examsRef.child(examId).update(updateData);

      await _securityService.logSecurityActivity(
        'update_exam',
        'Exam $examId updated',
        success: true,
      );
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      await _securityService.logSecurityActivity(
        'error_update_exam',
        'Firebase database error: ${e.message}',
        success: false,
      );
      throw NetworkException(
        ErrorMessages.updateFailed,
        originalError: e,
      );
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_update_exam',
        'Unexpected error: ${e.toString()}',
        success: false,
      );
      throw UnexpectedException(
        ErrorMessages.unexpectedError,
        originalError: e,
      );
    }
  }

  /// Deleta uma prova
  /// 
  /// Exceções possíveis:
  /// - [NotFoundException]: Prova não encontrada
  /// - [NetworkException]: Erro de conexão
  Future<void> deleteExam(String examId) async {
    try {
      // Verificar se a prova existe
      final examSnapshot = await _examsRef.child(examId).get();
      if (!examSnapshot.exists) {
        throw NotFoundException(ErrorMessages.examNotFound);
      }

      await _examsRef.child(examId).remove();

      await _securityService.logSecurityActivity(
        'delete_exam',
        'Exam $examId deleted',
        success: true,
      );
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      await _securityService.logSecurityActivity(
        'error_delete_exam',
        'Firebase database error: ${e.message}',
        success: false,
      );
      throw NetworkException(
        ErrorMessages.deleteFailed,
        originalError: e,
      );
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_delete_exam',
        'Unexpected error: ${e.toString()}',
        success: false,
      );
      throw UnexpectedException(
        ErrorMessages.unexpectedError,
        originalError: e,
      );
    }
  }

  /// Adiciona uma questão a uma prova
  /// 
  /// Exceções possíveis:
  /// - [NotFoundException]: Prova não encontrada
  /// - [NetworkException]: Erro de conexão
  Future<void> addQuestionToExam({
    required String examId,
    required String questionId,
    required int number,
    required double peso,
    int? suggestedLines,
  }) async {
    try {
      // Verificar se a prova existe
      final examSnapshot = await _examsRef.child(examId).get();
      if (!examSnapshot.exists) {
        throw NotFoundException(ErrorMessages.examNotFound);
      }

      final questionLinkData = {
        'number': number,
        'peso': peso,
        'suggestedLines': suggestedLines,
      };

      await _examsRef
          .child(examId)
          .child('questions')
          .child(questionId)
          .set(questionLinkData);

      await _securityService.logSecurityActivity(
        'add_question_to_exam',
        'Question $questionId added to exam $examId',
        success: true,
      );
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      await _securityService.logSecurityActivity(
        'error_add_question_to_exam',
        'Firebase database error: ${e.message}',
        success: false,
      );
      throw NetworkException(
        ErrorMessages.operationFailed,
        originalError: e,
      );
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_add_question_to_exam',
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