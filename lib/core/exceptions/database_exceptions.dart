/// Exceção base para falhas de serviço.
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}

/// Lançada quando um nó/documento específico não é encontrado.
class DocumentNotFoundException extends DatabaseException {
  DocumentNotFoundException([super.message = 'Documento não encontrado.']);
}

/// Lançada para falhas genéricas de operação do Realtime Database (permissão, rede, etc.).
class DatabaseOperationException extends DatabaseException {
  DatabaseOperationException(String message)
    : super('Falha na operação do Firebase: $message');
}
