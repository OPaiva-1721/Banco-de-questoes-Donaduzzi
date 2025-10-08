/// Configurações centralizadas da aplicação
///
/// Este arquivo contém todas as configurações importantes do sistema,
/// facilitando manutenção e customização.
class AppConfig {
  // Configurações de Segurança
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxLoginAttempts = 5;
  static const Duration sessionTimeout = Duration(days: 30);
  static const Duration inactivityTimeout = Duration(days: 5);

  // Configurações de UI
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration messageDuration = Duration(seconds: 3);

  // Configurações de Validação
  static const int maxNameLength = 100;
  static const int maxEmailLength = 100;
  static const int maxQuestionTextLength = 500;
  static const int maxOptionTextLength = 200;

  // Configurações de Firebase
  static const String usersCollection = 'usuarios';
  static const String groupsCollection = 'grupos';
  static const String securityLogsCollection = 'logs_seguranca';
  static const String tasksCollection = 'tarefas';

  // Configurações de Tipos de Usuário
  static const String professorType = 'professor';
  static const String coordenadorType = 'coordenador';

  // Configurações de Status
  static const String activeStatus = 'ativo';
  static const String inactiveStatus = 'inativo';

  // Configurações de Permissões
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

  // Configurações de Mensagens
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

  // Configurações de Erro
  static const Map<String, String> errorMessages = {
    'invalidEmail': 'Email inválido',
    'invalidPassword': 'Senha inválida',
    'invalidName': 'Nome inválido',
    'userNotFound': 'Usuário não encontrado',
    'permissionDenied': 'Permissão negada',
    'networkError': 'Erro de conexão',
    'unknownError': 'Erro desconhecido',
  };

  // Configurações de Desenvolvimento
  static const bool enableDebugLogs = true;
  static const bool enableSecurityLogs = true;
  static const bool enablePerformanceMonitoring = true;

  // Configurações de Produção
  static const bool isProduction = false; // Alterar para true em produção

  /// Retorna as permissões baseadas no tipo de usuário
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

  /// Verifica se está em modo de desenvolvimento
  static bool get isDevelopment => !isProduction;

  /// Retorna a mensagem padrão para uma chave
  static String getMessage(String key) {
    return defaultMessages[key] ?? 'Mensagem não encontrada';
  }

  /// Retorna a mensagem de erro para uma chave
  static String getErrorMessage(String key) {
    return errorMessages[key] ?? 'Erro desconhecido';
  }
}
