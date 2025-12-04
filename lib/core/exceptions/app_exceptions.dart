/// Exceções customizadas da aplicação
/// 
/// Este arquivo define todas as exceções específicas do domínio,
/// permitindo tratamento de erro consistente e tipado.

/// Exceção base para todas as exceções da aplicação
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
  ValidationException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exceção para erros de autenticação
class AuthenticationException extends AppException {
  AuthenticationException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exceção para erros de autorização (permissões)
class AuthorizationException extends AppException {
  AuthorizationException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exceção para erros de rede/conectividade
class NetworkException extends AppException {
  NetworkException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exceção para recursos não encontrados
class NotFoundException extends AppException {
  NotFoundException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exceção para recursos em uso (não podem ser deletados)
class ResourceInUseException extends AppException {
  ResourceInUseException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exceção para operações que falharam no Firebase
/// 
/// Nota: Renomeada para evitar conflito com FirebaseException do Firebase SDK
class AppFirebaseException extends AppException {
  AppFirebaseException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exceção genérica para erros inesperados
class UnexpectedException extends AppException {
  UnexpectedException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

