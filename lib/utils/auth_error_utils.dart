import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorUtils {
  /// Converte erros do Firebase Auth para mensagens amigáveis em português
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nenhum usuário encontrado com este email.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado por outra conta.';
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'O email fornecido não é válido.';
      case 'user-disabled':
        return 'Esta conta foi desabilitada. Entre em contato com o suporte.';
      case 'too-many-requests':
        return 'Muitas tentativas de login. Tente novamente mais tarde.';
      case 'operation-not-allowed':
        return 'Esta operação não é permitida.';
      case 'invalid-credential':
        return 'As credenciais fornecidas são inválidas.';
      case 'account-exists-with-different-credential':
        return 'Já existe uma conta com este email usando um método de login diferente.';
      case 'requires-recent-login':
        return 'Esta operação requer um login recente. Faça login novamente.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet e tente novamente.';
      case 'invalid-verification-code':
        return 'Código de verificação inválido.';
      case 'invalid-verification-id':
        return 'ID de verificação inválido.';
      case 'missing-verification-code':
        return 'Código de verificação não fornecido.';
      case 'missing-verification-id':
        return 'ID de verificação não fornecido.';
      case 'quota-exceeded':
        return 'Limite de cota excedido. Tente novamente mais tarde.';
      case 'credential-already-in-use':
        return 'Esta credencial já está sendo usada por outra conta.';
      case 'timeout':
        return 'Tempo limite excedido. Tente novamente.';
      default:
        return 'Erro inesperado: ${e.message ?? 'Tente novamente.'}';
    }
  }

  /// Verifica se o erro é relacionado à rede
  static bool isNetworkError(FirebaseAuthException e) {
    return e.code == 'network-request-failed' || e.code == 'timeout';
  }

  /// Verifica se o erro é relacionado a credenciais inválidas
  static bool isCredentialError(FirebaseAuthException e) {
    return e.code == 'user-not-found' ||
        e.code == 'wrong-password' ||
        e.code == 'invalid-credential' ||
        e.code == 'invalid-email';
  }

  /// Verifica se o erro é relacionado a tentativas excessivas
  static bool isRateLimitError(FirebaseAuthException e) {
    return e.code == 'too-many-requests' || e.code == 'quota-exceeded';
  }
}
