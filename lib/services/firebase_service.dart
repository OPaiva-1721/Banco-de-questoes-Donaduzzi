import 'package:firebase_auth/firebase_auth.dart'; // Precisa do User do Auth
import 'package:firebase_database/firebase_database.dart';
import 'auth_service.dart'; // Importa o AuthService correto
import 'user_service.dart';
import 'question_service.dart';
import 'exam_service.dart';
import 'subject_service.dart';
import 'course_service.dart';
import 'content_service.dart';
import 'security_service.dart';
import '../models/question_model.dart'; // Importa os modelos
// Removido: import '../models/app_user_model.dart'; // Não precisa mais aqui

/// Main service that orchestrates all other Firebase services.
///
/// This service acts as a Facade, centralizing access to all
/// specialized services. (Correct version using FirebaseAuth)
class FirebaseService {
  // Instances of specialized services
  final SecurityService _securityService = SecurityService();
  final UserService _userService = UserService(); // Cria o UserService
  final CourseService _courseService = CourseService();
  final SubjectService _subjectService = SubjectService();
  final ContentService _contentService = ContentService();
  final QuestionService _questionService = QuestionService();
  final ExamService _examService = ExamService();

  // AuthService precisa do UserService
  late final AuthService _authService;

  FirebaseService() {
    // Injeta o UserService no AuthService quando o FirebaseService é criado
    _authService = AuthService(_userService);
  }

  // ========== AUTHENTICATION (Delegation to AuthService - CORRECT) ==========

  /// Stream para ouvir o estado de login/logout do Firebase Auth
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Pega o usuário ATUALMENTE logado no Firebase Auth
  User? get currentUser => _authService.currentUser;

  /// Registra um novo usuário usando Firebase Auth e salva dados no DB
  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String name,
  }) {
    // Delega a chamada para o AuthService
    return _authService.registerUser(
      email: email,
      password: password,
      name: name,
    );
  }

  /// Faz login usando Firebase Auth
  Future<UserCredential> signIn(String email, String password) {
    // Delega a chamada para o AuthService
    return _authService.signIn(email: email, password: password);
  }

  /// Faz login/registro com Google usando Firebase Auth
  Future<UserCredential> signInWithGoogle() {
    // Delega a chamada para o AuthService
    return _authService.signInWithGoogle();
  }

  /// Faz logout do Firebase Auth
  Future<void> signOut() {
    // Delega a chamada para o AuthService
    return _authService.signOut();
  }

  /// Envia e-mail de redefinição de senha via Firebase Auth
  Future<void> sendPasswordResetEmail(String email) {
    // Delega a chamada para o AuthService
    return _authService.sendPasswordResetEmail(email);
  }

  // ========== USERS (Delegation to UserService - Data related to Auth User) ==========

  /// Pega o stream de dados do usuário LOGADO no Realtime DB
  Stream<DatabaseEvent> getCurrentUserStream() {
    // Delega a chamada para o UserService
    return _userService.getCurrentUserStream();
  }

  /// Atualiza os dados do usuário LOGADO no Realtime DB
  Future<bool> updateCurrentUser(Map<String, dynamic> data) {
    // Delega a chamada para o UserService
    return _userService.updateCurrentUser(data);
  }

  /// Pega o tipo ('professor'/'coordinator') do usuário LOGADO
  Future<String> getCurrentUserType() {
    // Delega a chamada para o UserService
    return _userService.getCurrentUserType();
  }

  /// Pega o stream de TODOS os usuários (Admin)
  Stream<DatabaseEvent> getAllUsersStream() {
    // Delega a chamada para o UserService
    return _userService.getAllUsersStream();
  }

  /// Altera o tipo de um usuário específico (Admin)
  Future<bool> setUserType(String userId, String newUserType) {
    // Delega a chamada para o UserService
    return _userService.setUserType(userId, newUserType);
  }

  // ========== COURSES (Delegation to CourseService) ==========
  // (Esta parte permanece igual)
  Future<String?> createCourse(String name, String description) {
    return _courseService.createCourse(name, description);
  }

  Stream<DatabaseEvent> getCoursesStream() {
    return _courseService.getCoursesStream();
  }
  // ...

  // ========== SUBJECTS (Delegation to SubjectService) ==========
  // (Esta parte permanece igual)
  Future<String?> createSubject(String name, int semester) {
    return _subjectService.createSubject(name, semester);
  }

  Stream<DatabaseEvent> getSubjectsStream() {
    return _subjectService.listarDisciplinas();
  }

  Stream<DatabaseEvent> getSubjectsBySemesterStream(int semester) {
    return _subjectService.getSubjectsBySemesterStream(semester);
  }
  // ...

  // ========== QUESTIONS (Delegation to QuestionService) ==========
  // (Esta parte permanece igual)
  Future<String?> createQuestion(Question newQuestion) {
    return _questionService.createQuestion(newQuestion);
  }

  Stream<List<Question>> getQuestionsStream() {
    return _questionService.getQuestionsStream();
  }

  Stream<List<Question>> getQuestionsBySubjectStream(String subjectId) {
    return _questionService.getQuestionsBySubjectStream(subjectId);
  }

  Future<bool> deleteQuestion(String questionId) {
    return _questionService.deleteQuestion(questionId);
  }
  // ...

  // ========== EXAMS (Delegation to ExamService) ==========
  // (Esta parte permanece igual)
  Future<String?> createExam({
    required String title,
    required String instructions,
    String? subjectId,
  }) {
    return _examService.createExam(
      title: title,
      instructions: instructions,
      subjectId: subjectId,
    );
  }

  Future<bool> addQuestionToExam({
    required String examId,
    required String questionId,
    required int number,
    int? suggestedLines,
  }) {
    return _examService.addQuestionToExam(
      examId: examId,
      questionId: questionId,
      number: number,
      suggestedLines: suggestedLines,
    );
  }

  Stream<DatabaseEvent> getExamsStream() {
    return _examService.getExamsStream();
  }

  // ...
}
