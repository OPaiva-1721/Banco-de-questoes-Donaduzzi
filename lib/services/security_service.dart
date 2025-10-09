import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço responsável por validações de segurança e logs
class SecurityService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========== VALIDAÇÕES DE SEGURANÇA ==========

  /// Valida entrada de dados para prevenir ataques
  bool validarEntrada(String entrada, {int? maxLength}) {
    if (entrada.isEmpty) return false;
    if (maxLength != null && entrada.length > maxLength) return false;

    // Verificar caracteres perigosos
    final caracteresPerigosos = ['<', '>', '"', "'", '&', ';', '(', ')'];
    for (var char in caracteresPerigosos) {
      if (entrada.contains(char)) return false;
    }

    return true;
  }

  /// Sanitiza entrada de dados
  String sanitizarEntrada(String entrada) {
    return entrada
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('&', '&amp;')
        .trim();
  }

  // ========== LOGS DE SEGURANÇA ==========

  /// Registra atividade de segurança
  Future<void> registrarAtividadeSeguranca(
    String acao,
    String detalhes, {
    bool sucesso = true,
  }) async {
    try {
      final logRef = _database.ref('logs_seguranca').push();
      await logRef.set({
        'acao': acao,
        'detalhes': detalhes,
        'usuarioId': _auth.currentUser?.uid,
        'timestamp': ServerValue.timestamp,
        'sucesso': sucesso,
        'severidade': sucesso ? 'info' : 'warning',
      });
    } catch (e) {
      print('Erro ao registrar atividade de segurança: $e');
    }
  }

  /// Registra tentativa de acesso não autorizado
  Future<void> registrarAcessoNaoAutorizado(
    String acao,
    String detalhes,
  ) async {
    await registrarAtividadeSeguranca(
      'acesso_nao_autorizado',
      'Tentativa de acesso não autorizado: $acao - $detalhes',
      sucesso: false,
    );
  }

  /// Registra erro de validação
  Future<void> registrarErroValidacao(
    String campo,
    String valor,
    String motivo,
  ) async {
    await registrarAtividadeSeguranca(
      'erro_validacao',
      'Erro de validação no campo $campo: $motivo (valor: $valor)',
      sucesso: false,
    );
  }

  // ========== VERIFICAÇÕES DE PERMISSÃO ==========

  /// Verifica se o usuário atual tem permissão para executar uma ação
  Future<bool> verificarPermissao(String acao) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final snapshot = await _database
          .ref('usuarios/${user.uid}/permissoes')
          .get();
      if (!snapshot.exists) return false;

      final permissoes = snapshot.value as Map<dynamic, dynamic>;
      return permissoes[acao] == true;
    } catch (e) {
      print('Erro ao verificar permissão: $e');
      return false;
    }
  }

  /// Verifica se o usuário atual tem permissão e registra tentativa de acesso
  Future<bool> verificarPermissaoComLog(String acao) async {
    final temPermissao = await verificarPermissao(acao);

    if (!temPermissao) {
      await registrarAcessoNaoAutorizado(
        acao,
        'Usuário ${_auth.currentUser?.uid} tentou executar ação sem permissão',
      );
    }

    return temPermissao;
  }

  // ========== VALIDAÇÕES ESPECÍFICAS ==========

  /// Valida email
  bool validarEmail(String email) {
    if (!validarEntrada(email, maxLength: 100)) return false;

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Valida senha
  bool validarSenha(String senha) {
    if (senha.length < 6) return false;
    if (senha.length > 128) return false;

    // Verificar se contém pelo menos um número
    if (!RegExp(r'\d').hasMatch(senha)) return false;

    // Verificar se contém pelo menos uma letra
    if (!RegExp(r'[a-zA-Z]').hasMatch(senha)) return false;

    return true;
  }

  /// Valida nome
  bool validarNome(String nome) {
    if (!validarEntrada(nome, maxLength: 100)) return false;
    if (nome.length < 2) return false;

    // Verificar se contém apenas letras, espaços e acentos
    final nomeRegex = RegExp(r'^[a-zA-ZÀ-ÿ\s]+$');
    return nomeRegex.hasMatch(nome);
  }

  // ========== UTILITÁRIOS ==========

  /// Gera ID único para logs
  String gerarIdLog() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Formata timestamp para logs
  String formatarTimestamp(DateTime timestamp) {
    return timestamp.toIso8601String();
  }
}
