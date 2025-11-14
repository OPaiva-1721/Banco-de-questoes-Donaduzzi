import '../core/exceptions/app_exceptions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_error_utils.dart';

/// Centralizador de mensagens de erro da aplicação
/// 
/// Todas as mensagens de erro exibidas ao usuário devem vir daqui,
/// garantindo consistência e facilitando tradução futura.

class ErrorMessages {
  // Mensagens de validação
  static const String invalidEmail = 'O email fornecido não é válido.';
  static const String invalidPassword = 'A senha deve ter pelo menos 6 caracteres.';
  static const String invalidName = 'O nome fornecido não é válido.';
  static const String invalidTitle = 'O título fornecido não é válido.';
  static const String invalidInstructions = 'As instruções fornecidas não são válidas.';
  static const String invalidQuestionText = 'O enunciado da questão não é válido.';
  static const String invalidOptionText = 'O texto da opção não é válido.';
  static const String invalidSubjectName = 'O nome da disciplina não é válido.';
  static const String invalidSemester = 'O semestre deve ser um número entre 1 e 20.';
  static const String invalidContentDescription = 'A descrição do conteúdo não é válida.';
  static const String invalidCourseName = 'O nome do curso não é válido.';

  // Mensagens de não encontrado
  static const String userNotFound = 'Usuário não encontrado.';
  static const String questionNotFound = 'Questão não encontrada.';
  static const String examNotFound = 'Prova não encontrada.';
  static const String subjectNotFound = 'Disciplina não encontrada.';
  static const String contentNotFound = 'Conteúdo não encontrado.';
  static const String courseNotFound = 'Curso não encontrado.';

  // Mensagens de validação de regras de negócio
  static const String questionMustHaveFiveOptions = 'As questões devem ter exatamente 5 opções.';
  static const String questionMustHaveOneCorrectOption = 'Exatamente uma opção deve ser marcada como correta.';
  static const String questionOptionTextRequired = 'O texto da opção não pode estar vazio.';
  static const String questionOptionLetterInvalid = 'A letra da opção não é válida.';
  static const String questionIdRequired = 'ID da questão não pode ser nulo para uma atualização.';
  static const String subjectIdRequired = 'ID da disciplina não pode ser nulo.';
  static const String contentIdRequired = 'ID do conteúdo não pode ser nulo.';

  // Mensagens de recursos em uso
  static const String questionInUse = 'Não é possível deletar: Questão está sendo usada em uma prova.';
  static const String subjectInUse = 'Não é possível deletar: Disciplina está sendo usada por questões existentes.';
  static const String contentInUse = 'Não é possível deletar: Conteúdo está sendo usado por questões existentes.';

  // Mensagens de autorização
  static const String unauthorized = 'Você não tem permissão para realizar esta operação.';
  static const String unauthorizedUserTypeChange = 'Apenas coordenadores podem alterar tipos de usuário.';
  static const String unauthorizedViewAllUsers = 'Apenas coordenadores podem visualizar todos os usuários.';
  static const String userNotLoggedIn = 'Usuário não está logado.';

  // Mensagens de rede
  static const String networkError = 'Erro de conexão. Verifique sua internet e tente novamente.';
  static const String timeoutError = 'Tempo limite excedido. Tente novamente.';
  static const String connectionTimeout = 'Não foi possível conectar ao servidor. Verifique sua conexão.';

  // Mensagens de operação
  static const String operationFailed = 'A operação falhou. Tente novamente.';
  static const String createFailed = 'Não foi possível criar o registro.';
  static const String updateFailed = 'Não foi possível atualizar o registro.';
  static const String deleteFailed = 'Não foi possível deletar o registro.';
  static const String fetchFailed = 'Não foi possível buscar os dados.';

  // Mensagens de Firebase específicas
  static const String firebaseError = 'Erro ao comunicar com o servidor.';
  static const String firebasePermissionDenied = 'Permissão negada pelo servidor.';
  static const String firebaseDataError = 'Erro ao processar os dados do servidor.';

  // Mensagens genéricas
  static const String unexpectedError = 'Ocorreu um erro inesperado. Tente novamente.';
  static const String unknownError = 'Erro desconhecido. Entre em contato com o suporte.';

  /// Converte uma exceção genérica em mensagem amigável
  static String fromException(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    
    // Trata erros do Firebase Auth
    if (error is FirebaseAuthException) {
      return AuthErrorUtils.getErrorMessage(error);
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return networkError;
    }
    
    if (errorString.contains('timeout')) {
      return timeoutError;
    }
    
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return unauthorized;
    }
    
    if (errorString.contains('not found')) {
      return 'Recurso não encontrado.';
    }
    
    return unexpectedError;
  }
}

/// Mensagens de sucesso (para consistência)
class SuccessMessages {
  static const String questionCreated = 'Questão criada com sucesso!';
  static const String questionUpdated = 'Questão atualizada com sucesso!';
  static const String questionDeleted = 'Questão deletada com sucesso!';
  static const String examCreated = 'Prova criada com sucesso!';
  static const String examUpdated = 'Prova atualizada com sucesso!';
  static const String examDeleted = 'Prova deletada com sucesso!';
  static const String subjectCreated = 'Disciplina criada com sucesso!';
  static const String subjectUpdated = 'Disciplina atualizada com sucesso!';
  static const String subjectDeleted = 'Disciplina deletada com sucesso!';
  static const String contentCreated = 'Conteúdo criado com sucesso!';
  static const String contentUpdated = 'Conteúdo atualizado com sucesso!';
  static const String contentDeleted = 'Conteúdo deletado com sucesso!';
  static const String courseCreated = 'Curso criado com sucesso!';
  static const String courseUpdated = 'Curso atualizado com sucesso!';
  static const String courseDeleted = 'Curso deletado com sucesso!';
  static const String userUpdated = 'Usuário atualizado com sucesso!';
  static const String userTypeChanged = 'Tipo de usuário alterado com sucesso!';
}

