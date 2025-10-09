import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';

/// Serviço responsável por operações com exames
class ExamService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SecurityService _securityService = SecurityService();

  // ========== MÉTODOS DE EXAME ==========

  /// Cria um novo exame
  Future<String?> criarExame({
    required String titulo,
    required String instrucoes,
    Map<String, dynamic>? configuracoes,
    String? disciplinaId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Validar entrada
      if (!_securityService.validarEntrada(titulo, maxLength: 200)) {
        throw Exception('Título do exame inválido');
      }
      if (!_securityService.validarEntrada(instrucoes, maxLength: 1000)) {
        throw Exception('Instruções do exame inválidas');
      }

      final tituloSanitizado = _securityService.sanitizarEntrada(titulo);
      final instrucoesSanitizadas = _securityService.sanitizarEntrada(
        instrucoes,
      );

      final exameRef = _database.ref('exames').push();
      final exameId = exameRef.key!;

      await exameRef.set({
        'titulo': tituloSanitizado,
        'instrucoes': instrucoesSanitizadas,
        'disciplinaId': disciplinaId,
        'professorId': user.uid,
        'dataCriacao': ServerValue.timestamp,
        'status': 'rascunho',
        'configuracoes':
            configuracoes ??
            {
              'tempoLimite': 3600, // 1 hora em segundos
              'permiteVoltar': true,
              'mostraRespostas': false,
              'pesoTotal': 10.0,
              'permiteConsultarMaterial': false,
              'ordemQuestoes': 'sequencial',
              'mostraProgresso': true,
            },
        'questoes': {}, // Será preenchido quando adicionar questões
        'estatisticas': {
          'totalQuestoes': 0,
          'pesoTotal': 0.0,
          'tempoEstimado': 0,
        },
      });

      await _securityService.registrarAtividadeSeguranca(
        'criar_exame',
        'Exame criado: $tituloSanitizado',
        sucesso: true,
      );

      return exameId;
    } catch (e) {
      print('Erro ao criar exame: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_criar_exame',
        'Erro ao criar exame: $e',
        sucesso: false,
      );
      return null;
    }
  }

  /// Adiciona uma questão a um exame
  Future<bool> adicionarQuestaoAoExame({
    required String exameId,
    required String questaoId,
    required int numero,
    double peso = 1.0,
    int? linhasResposta,
  }) async {
    try {
      // Verificar se a questão existe
      final questaoSnapshot = await _database.ref('questoes/$questaoId').get();
      if (!questaoSnapshot.exists) {
        throw Exception('Questão não encontrada');
      }

      // Verificar se o exame existe
      final exameSnapshot = await _database.ref('exames/$exameId').get();
      if (!exameSnapshot.exists) {
        throw Exception('Exame não encontrado');
      }

      final questaoRef = _database.ref('exames/$exameId/questoes/$questaoId');
      await questaoRef.set({
        'numero': numero,
        'peso': peso,
        'linhasResposta': linhasResposta,
        'ordem': numero,
        'adicionadaEm': ServerValue.timestamp,
        'adicionadaPor': _auth.currentUser?.uid,
      });

      // Atualizar estatísticas do exame
      await _atualizarEstatisticasExame(exameId);

      await _securityService.registrarAtividadeSeguranca(
        'adicionar_questao_exame',
        'Questão $questaoId adicionada ao exame $exameId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao adicionar questão ao exame: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_adicionar_questao_exame',
        'Erro ao adicionar questão ao exame: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Lista todos os exames
  Stream<DatabaseEvent> listarExames() {
    return _database.ref('exames').onValue;
  }

  /// Busca exames por professor
  Stream<DatabaseEvent> buscarExamesPorProfessor(String professorId) {
    return _database
        .ref('exames')
        .orderByChild('professorId')
        .equalTo(professorId)
        .onValue;
  }

  /// Busca exames por disciplina
  Stream<DatabaseEvent> buscarExamesPorDisciplina(String disciplinaId) {
    return _database
        .ref('exames')
        .orderByChild('disciplinaId')
        .equalTo(disciplinaId)
        .onValue;
  }

  /// Busca um exame específico
  Future<DataSnapshot?> buscarExame(String exameId) async {
    try {
      return await _database.ref('exames/$exameId').get();
    } catch (e) {
      print('Erro ao buscar exame: $e');
      return null;
    }
  }

  /// Atualiza um exame
  Future<bool> atualizarExame(
    String exameId,
    Map<String, dynamic> dados,
  ) async {
    try {
      // Sanitizar dados se necessário
      if (dados.containsKey('titulo')) {
        dados['titulo'] = _securityService.sanitizarEntrada(dados['titulo']);
      }
      if (dados.containsKey('instrucoes')) {
        dados['instrucoes'] = _securityService.sanitizarEntrada(
          dados['instrucoes'],
        );
      }

      // Adicionar timestamp de atualização
      dados['atualizadoEm'] = ServerValue.timestamp;
      dados['atualizadoPor'] = _auth.currentUser?.uid;

      await _database.ref('exames/$exameId').update(dados);

      await _securityService.registrarAtividadeSeguranca(
        'atualizar_exame',
        'Exame atualizado: $exameId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao atualizar exame: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_atualizar_exame',
        'Erro ao atualizar exame: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Remove uma questão de um exame
  Future<bool> removerQuestaoDoExame(String exameId, String questaoId) async {
    try {
      await _database.ref('exames/$exameId/questoes/$questaoId').remove();

      // Atualizar estatísticas do exame
      await _atualizarEstatisticasExame(exameId);

      await _securityService.registrarAtividadeSeguranca(
        'remover_questao_exame',
        'Questão $questaoId removida do exame $exameId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao remover questão do exame: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_remover_questao_exame',
        'Erro ao remover questão do exame: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Deleta um exame
  Future<bool> deletarExame(String exameId) async {
    try {
      await _database.ref('exames/$exameId').remove();

      await _securityService.registrarAtividadeSeguranca(
        'deletar_exame',
        'Exame deletado: $exameId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao deletar exame: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_deletar_exame',
        'Erro ao deletar exame: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Altera o status de um exame
  Future<bool> alterarStatusExame(String exameId, String status) async {
    try {
      if (![
        'rascunho',
        'publicado',
        'ativo',
        'finalizado',
        'arquivado',
      ].contains(status)) {
        throw Exception('Status inválido');
      }

      await _database.ref('exames/$exameId').update({
        'status': status,
        'alteradoEm': ServerValue.timestamp,
        'alteradoPor': _auth.currentUser?.uid,
      });

      await _securityService.registrarAtividadeSeguranca(
        'alterar_status_exame',
        'Status do exame $exameId alterado para $status',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao alterar status do exame: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_alterar_status_exame',
        'Erro ao alterar status do exame: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Lista exames por status
  Stream<DatabaseEvent> listarExamesPorStatus(String status) {
    return _database
        .ref('exames')
        .orderByChild('status')
        .equalTo(status)
        .onValue;
  }

  /// Busca exames por texto (busca parcial no título)
  Stream<DatabaseEvent> buscarExamesPorTexto(String texto) {
    final textoSanitizado = _securityService.sanitizarEntrada(texto);
    return _database
        .ref('exames')
        .orderByChild('titulo')
        .startAt(textoSanitizado)
        .endAt('$textoSanitizado\uf8ff')
        .onValue;
  }

  /// Duplica um exame
  Future<String?> duplicarExame(String exameId) async {
    try {
      final exameSnapshot = await _database.ref('exames/$exameId').get();
      if (!exameSnapshot.exists) {
        throw Exception('Exame não encontrado');
      }

      final exameData = exameSnapshot.value as Map<dynamic, dynamic>;

      // Criar novo exame com dados modificados
      final novoExameRef = _database.ref('exames').push();
      final novoExameId = novoExameRef.key!;

      // Remover campos que não devem ser duplicados
      exameData.remove('dataCriacao');
      exameData.remove('professorId');

      // Adicionar novos campos
      exameData['titulo'] = '${exameData['titulo']} (Cópia)';
      exameData['dataCriacao'] = ServerValue.timestamp;
      exameData['professorId'] = _auth.currentUser?.uid;
      exameData['status'] = 'rascunho';

      await novoExameRef.set(exameData);

      await _securityService.registrarAtividadeSeguranca(
        'duplicar_exame',
        'Exame $exameId duplicado como $novoExameId',
        sucesso: true,
      );

      return novoExameId;
    } catch (e) {
      print('Erro ao duplicar exame: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_duplicar_exame',
        'Erro ao duplicar exame: $e',
        sucesso: false,
      );
      return null;
    }
  }

  /// Reordena questões de um exame
  Future<bool> reordenarQuestoesExame(
    String exameId,
    Map<String, int> novaOrdem,
  ) async {
    try {
      final updates = <String, dynamic>{};

      for (var entry in novaOrdem.entries) {
        updates['exames/$exameId/questoes/${entry.key}/ordem'] = entry.value;
        updates['exames/$exameId/questoes/${entry.key}/numero'] = entry.value;
      }

      await _database.ref().update(updates);

      await _securityService.registrarAtividadeSeguranca(
        'reordenar_questoes_exame',
        'Questões do exame $exameId reordenadas',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao reordenar questões do exame: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_reordenar_questoes_exame',
        'Erro ao reordenar questões do exame: $e',
        sucesso: false,
      );
      return false;
    }
  }

  // ========== MÉTODOS PRIVADOS ==========

  /// Atualiza as estatísticas de um exame
  Future<void> _atualizarEstatisticasExame(String exameId) async {
    try {
      final questoesSnapshot = await _database
          .ref('exames/$exameId/questoes')
          .get();

      int totalQuestoes = 0;
      double pesoTotal = 0.0;
      int tempoEstimado = 0;

      if (questoesSnapshot.exists) {
        totalQuestoes = questoesSnapshot.children.length;

        for (var questao in questoesSnapshot.children) {
          final questaoData = questao.value as Map<dynamic, dynamic>;
          pesoTotal += (questaoData['peso'] ?? 1.0).toDouble();
          tempoEstimado += 2; // Estimativa de 2 minutos por questão
        }
      }

      await _database.ref('exames/$exameId/estatisticas').update({
        'totalQuestoes': totalQuestoes,
        'pesoTotal': pesoTotal,
        'tempoEstimado': tempoEstimado,
        'atualizadoEm': ServerValue.timestamp,
      });
    } catch (e) {
      print('Erro ao atualizar estatísticas do exame: $e');
    }
  }
}
