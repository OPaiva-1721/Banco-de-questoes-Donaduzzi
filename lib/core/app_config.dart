import 'package:flutter/foundation.dart';

class AppConfig {
  // Security
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxLoginAttempts = 5;
  static const Duration sessionTimeout = Duration(days: 30);
  static const Duration inactivityTimeout = Duration(days: 5);

  // UI
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration messageDuration = Duration(seconds: 3);

  // Validation
  static const int maxNameLength = 100;
  static const int maxEmailLength = 100;
  static const int maxQuestionTextLength = 500;
  static const int maxOptionTextLength = 200;

  // Firebase node names — source of truth for all services
  static const String usersCollection = 'users';
  static const String securityLogsCollection = 'security_logs';
  static const String questionsCollection = 'questions';
  static const String examsCollection = 'exams';
  static const String subjectsCollection = 'subjects';
  static const String coursesCollection = 'courses';
  static const String contentsCollection = 'contents';
  static const String groupsCollection = 'grupos';
  static const String tasksCollection = 'tarefas';

  // User types
  static const String professorType = 'professor';
  static const String coordenadorType = 'coordenador';

  // Status
  static const String activeStatus = 'ativo';
  static const String inactiveStatus = 'inativo';

  // Permissions
  static const Map<String, bool> professorPermissions = {
    'gerenciarProfessores': false,
    'gerenciarCoordenadores': false,
    'visualizarTodasProvas': false,
    'criarProvas': true,
    'editarProvas': true,
    'deletarProvas': true,
  };

  static const Map<String, bool> coordenadorPermissions = {
    'gerenciarProfessores': true,
    'gerenciarCoordenadores': false,
    'visualizarTodasProvas': true,
    'criarProvas': true,
    'editarProvas': true,
    'deletarProvas': true,
  };

  // Messages
  static const Map<String, String> defaultMessages = {
    'loginSuccess': 'Login realizado com sucesso!',
    'registerSuccess': 'Conta criada com sucesso!',
    'logoutSuccess': 'Logout realizado com sucesso!',
    'emailVerificationSent': 'Email de verificação enviado!',
    'passwordResetSent': 'Email de recuperação enviado!',
    'userPromoted': 'Usuário promovido a administrador!',
    'userTypeChanged': 'Tipo de usuário alterado com sucesso!',
    'groupCreated': 'Grupo criado com sucesso!',
    'reportGenerated': 'Relatório gerado com sucesso!',
    'backupCompleted': 'Backup realizado com sucesso!',
  };

  // Errors
  static const Map<String, String> errorMessages = {
    'invalidEmail': 'Email inválido',
    'invalidPassword': 'Senha inválida',
    'invalidName': 'Nome inválido',
    'userNotFound': 'Usuário não encontrado',
    'permissionDenied': 'Permissão negada',
    'networkError': 'Erro de conexão',
    'unknownError': 'Erro desconhecido',
  };

  // Env flags — derived from build mode, never hardcoded
  static bool get isProduction => !kDebugMode;
  static bool get isDevelopment => kDebugMode;
  static bool get enableDebugLogs => kDebugMode;
  static const bool enableSecurityLogs = true;
  static const bool enablePerformanceMonitoring = true;

  static Map<String, bool> getPermissionsForUserType(String userType) {
    switch (userType) {
      case coordenadorType:
        return Map.from(coordenadorPermissions);
      case professorType:
        return Map.from(professorPermissions);
      default:
        return Map.from(professorPermissions);
    }
  }

  static String getMessage(String key) {
    return defaultMessages[key] ?? 'Mensagem não encontrada';
  }

  static String getErrorMessage(String key) {
    return errorMessages[key] ?? 'Erro desconhecido';
  }
}
