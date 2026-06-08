/// Exceção base para todas as exceções da aplicação
///
/// Exceções customizadas da aplicação.
/// Este arquivo define todas as exceções específicas do domínio,
/// permitindo tratamento de erro consistente e tipado.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Exceção para erros de validação
class ValidationException extends AppException {
  ValidationException(super.message, {super.code, super.originalError});
}

/// Exceção para erros de autenticação
class AuthenticationException extends AppException {
  AuthenticationException(super.message, {super.code, super.originalError});
}

/// Exceção para erros de autorização (permissões)
class AuthorizationException extends AppException {
  AuthorizationException(super.message, {super.code, super.originalError});
}

/// Exceção para erros de rede/conectividade
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}

/// Exceção para recursos não encontrados
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.code, super.originalError});
}

/// Exceção para recursos em uso (não podem ser deletados)
class ResourceInUseException extends AppException {
  ResourceInUseException(super.message, {super.code, super.originalError});
}

/// Exceção para operações que falharam no Firebase
///
/// Nota: Renomeada para evitar conflito com FirebaseException do Firebase SDK
class AppFirebaseException extends AppException {
  AppFirebaseException(super.message, {super.code, super.originalError});
}

/// Exceção genérica para erros inesperados
class UnexpectedException extends AppException {
  UnexpectedException(super.message, {super.code, super.originalError});
}

