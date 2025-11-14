import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
// O import 'security_service.dart' (relativo) está correto porque é um ficheiro irmão.
import 'security_service.dart'; 
import 'dart:async';

// --- INÍCIO DA CORREÇÃO: Imports Absolutos ---
// Usamos o nome do seu pacote 'prova' para evitar os erros de conflito
import 'package:prova/services/user_service.dart'; //
import 'package:prova/models/user_model.dart';   //
// --- FIM DA CORREÇÃO ---

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

  Future<String?> createExam({
    required String title,
    required String instructions,
    required String? subjectId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    // 1. Buscar os dados do usuário logado
    String createdByName;
    try {
      // 2. Usar a função 'getCurrentUserStream' que EXISTE no seu serviço
      final DatabaseEvent userEvent =
          await _userService.getCurrentUserStream().first;
          
      if (userEvent.snapshot.exists) {
        // 3. Converter para AppUser e pegar o nome
        final AppUser currentUser = AppUser.fromSnapshot(userEvent.snapshot); 
        createdByName = currentUser.name ?? 'Professor (Sem nome)'; 
      } else {
        createdByName = 'Professor (Não encontrado)';
      }
    } catch (e) {
      print('Erro ao buscar nome do usuário: $e');
      createdByName = 'Professor (Erro)';
    }

    if (!_securityService.validateText(title, maxLength: 150)) {
      throw Exception('Título da prova inválido.');
    }
    if (!_securityService.validateText(instructions, maxLength: 1000)) {
      throw Exception('Instruções da prova inválidas.');
    }
    if (subjectId == null) {
      throw Exception('ID da disciplina não pode ser nulo.');
    }

    final sanitizedTitle = _securityService.sanitizeInput(title);
    final sanitizedInstructions = _securityService.sanitizeInput(instructions);

    try {
      final examData = {
        'title': sanitizedTitle,
        'instructions': sanitizedInstructions,
        'subjectId': subjectId,
        'createdAt': ServerValue.timestamp,
        // --- Guardar o NOME, não o UID ---
        'createdBy': createdByName,
        // -------------------------------
        'timeLimit': 3600, 
        'shuffleQuestions': false,
        'isActive': true,
      };

      final newExamRef = _examsRef.push();
      await newExamRef.set(examData);

      await _securityService.logSecurityActivity(
        'create_exam',
        'Exam created: $sanitizedTitle',
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

  Stream<DatabaseEvent> getExamsStream() {
    return _examsRef.onValue;
  }

  Future<bool> updateExam(
    String examId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      updateData['lastUpdatedAt'] = ServerValue.timestamp;
      await _examsRef.child(examId).update(updateData);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteExam(String examId) async {
    try {
      await _examsRef.child(examId).remove();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addQuestionToExam({
    required String examId,
    required String questionId,
    required int number,
    required double peso, 
    int? suggestedLines,
  }) async {
    try {
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
      return true;
    } catch (e) {
      return false;
    }
  }
}