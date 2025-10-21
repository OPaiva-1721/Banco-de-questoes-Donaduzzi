import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';

/// Serviço responsável por operações com questões
class QuestionService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SecurityService _securityService = SecurityService();

  // ========== MÉTODOS DE QUESTÃO ==========

  /// Cria uma nova questão com opções
  Future<String?> criarQuestao({
    required String enunciado,
    required String disciplinaId,
    required Map<String, Map<String, dynamic>> opcoes,
    String? imagemUrl,
    String? explicacao,
    double? peso,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Validar entrada
      if (!_securityService.validarTexto(enunciado, maxLength: 1000)) {
        throw Exception('Enunciado da questão inválido');
      }

      // Validar explicação se fornecida
      if (explicacao != null && explicacao.isNotEmpty) {
        if (!_securityService.validarTexto(explicacao, maxLength: 1000)) {
          throw Exception('Explicação da questão inválida');
        }
      }

      // Validar opções
      if (opcoes.length < 2) {
        throw Exception('Questão deve ter pelo menos 2 opções');
      }

      if (opcoes.length > 10) {
        throw Exception('Questão não pode ter mais de 10 opções');
      }

      // Validar texto das opções
      for (var opcao in opcoes.values) {
        if (!_securityService.validarTexto(opcao['texto'], maxLength: 500)) {
          throw Exception('Texto da opção inválido');
        }
      }

      // Verificar se pelo menos uma opção está marcada como correta
      bool temOpcaoCorreta = false;
      for (var opcao in opcoes.values) {
        if (opcao['correta'] == true) {
          temOpcaoCorreta = true;
          break;
        }
      }
      if (!temOpcaoCorreta) {
        throw Exception('Pelo menos uma opção deve estar marcada como correta');
      }

      // Verificar se a disciplina existe
      final disciplinaSnapshot = await _database
          .ref('disciplinas/$disciplinaId')
          .get();
      if (!disciplinaSnapshot.exists) {
        throw Exception('Disciplina não encontrada');
      }

      final enunciadoSanitizado = _securityService.sanitizarEntrada(enunciado);
      final questaoRef = _database.ref('questoes').push();
      final questaoId = questaoRef.key!;

      // Sanitizar opções
      Map<String, Map<String, dynamic>> opcoesSanitizadas = {};
      for (var entry in opcoes.entries) {
        final texto = entry.value['texto'] as String?;
        if (texto != null && texto.isNotEmpty) {
          opcoesSanitizadas[entry.key] = {
            'texto': _securityService.sanitizarEntrada(texto),
            'correta': entry.value['correta'],
            'ordem': entry.value['ordem'] ?? 1,
          };
        }
      }

      await questaoRef.set({
        'enunciado': enunciadoSanitizado,
        'disciplinaId': disciplinaId,
        'imagemUrl': imagemUrl,
        'explicacao': explicacao != null
            ? _securityService.sanitizarEntrada(explicacao)
            : null,
        'peso': peso ?? 1.0,
        'dataCriacao': ServerValue.timestamp,
        'criadoPor': user.uid,
        'status': 'ativo',
        'opcoes': opcoesSanitizadas,
        'dificuldade': 'media', // padrão
        'tags': [],
        'versao': 1,
      });

      await _securityService.registrarAtividadeSeguranca(
        'criar_questao',
        'Questão criada: ${enunciadoSanitizado.length > 50 ? enunciadoSanitizado.substring(0, 50) + '...' : enunciadoSanitizado}',
        sucesso: true,
      );

      return questaoId;
    } catch (e) {
      print('Erro ao criar questão: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_criar_questao',
        'Erro ao criar questão: $e',
        sucesso: false,
      );
      return null;
    }
  }

  /// Lista todas as questões
  Stream<DatabaseEvent> listarQuestoes() {
    return _database.ref('questoes').onValue;
  }

  /// Busca questões por disciplina
  Stream<DatabaseEvent> buscarQuestoesPorDisciplina(String disciplinaId) {
    return _database
        .ref('questoes')
        .orderByChild('disciplinaId')
        .equalTo(disciplinaId)
        .onValue;
  }

  /// Busca uma questão específica
  Future<DataSnapshot?> buscarQuestao(String questaoId) async {
    try {
      return await _database.ref('questoes/$questaoId').get();
    } catch (e) {
      print('Erro ao buscar questão: $e');
      return null;
    }
  }

  /// Atualiza uma questão
  Future<bool> atualizarQuestao(
    String questaoId,
    Map<String, dynamic> dados,
  ) async {
    try {
      // Sanitizar dados se necessário
      if (dados.containsKey('enunciado') && dados['enunciado'] != null) {
        dados['enunciado'] = _securityService.sanitizarEntrada(
          dados['enunciado'],
        );
      }
      if (dados.containsKey('explicacao') && dados['explicacao'] != null) {
        dados['explicacao'] = _securityService.sanitizarEntrada(
          dados['explicacao'],
        );
      }

      // Incrementar versão
      dados['versao'] = ServerValue.increment(1);
      dados['atualizadoEm'] = ServerValue.timestamp;
      dados['atualizadoPor'] = _auth.currentUser?.uid;

      await _database.ref('questoes/$questaoId').update(dados);

      await _securityService.registrarAtividadeSeguranca(
        'atualizar_questao',
        'Questão atualizada: $questaoId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao atualizar questão: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_atualizar_questao',
        'Erro ao atualizar questão: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Deleta uma questão
  Future<bool> deletarQuestao(String questaoId) async {
    try {
      // Verificar se a questão está sendo usada em algum exame
      final examesSnapshot = await _database.ref('exames').get();

      if (examesSnapshot.exists) {
        for (final child in examesSnapshot.children) {
          final exame = child.value as Map<dynamic, dynamic>;
          if (exame['questoes'] != null) {
            final questoes = exame['questoes'] as Map<dynamic, dynamic>;
            if (questoes.containsKey(questaoId)) {
              throw Exception(
                'Não é possível deletar questão que está sendo usada em exames',
              );
            }
          }
        }
      }

      await _database.ref('questoes/$questaoId').remove();

      await _securityService.registrarAtividadeSeguranca(
        'deletar_questao',
        'Questão deletada: $questaoId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao deletar questão: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_deletar_questao',
        'Erro ao deletar questão: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Busca questões por dificuldade
  Stream<DatabaseEvent> buscarQuestoesPorDificuldade(String dificuldade) {
    return _database
        .ref('questoes')
        .orderByChild('dificuldade')
        .equalTo(dificuldade)
        .onValue;
  }

  /// Busca questões por tags
  Stream<DatabaseEvent> buscarQuestoesPorTag(String tag) {
    // Como tags é um array, vamos buscar todas as questões e filtrar no cliente
    return _database.ref('questoes').onValue;
  }

  /// Lista questões por status
  Stream<DatabaseEvent> listarQuestoesPorStatus(String status) {
    return _database
        .ref('questoes')
        .orderByChild('status')
        .equalTo(status)
        .onValue;
  }

  /// Ativa/desativa uma questão
  Future<bool> alterarStatusQuestao(String questaoId, String status) async {
    try {
      if (status != 'ativo' && status != 'inativo') {
        throw Exception('Status deve ser "ativo" ou "inativo"');
      }

      await _database.ref('questoes/$questaoId').update({
        'status': status,
        'alteradoEm': ServerValue.timestamp,
        'alteradoPor': _auth.currentUser?.uid,
      });

      await _securityService.registrarAtividadeSeguranca(
        'alterar_status_questao',
        'Status da questão $questaoId alterado para $status',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao alterar status da questão: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_alterar_status_questao',
        'Erro ao alterar status da questão: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Adiciona tags a uma questão
  Future<bool> adicionarTagsQuestao(String questaoId, List<String> tags) async {
    try {
      // Sanitizar tags
      final tagsSanitizadas = tags
          .map((tag) => _securityService.sanitizarEntrada(tag))
          .where((tag) => tag.isNotEmpty)
          .toList();

      await _database.ref('questoes/$questaoId').update({
        'tags': tagsSanitizadas,
        'atualizadoEm': ServerValue.timestamp,
        'atualizadoPor': _auth.currentUser?.uid,
      });

      await _securityService.registrarAtividadeSeguranca(
        'adicionar_tags_questao',
        'Tags adicionadas à questão $questaoId: ${tagsSanitizadas.join(', ')}',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao adicionar tags à questão: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_adicionar_tags_questao',
        'Erro ao adicionar tags à questão: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Conta questões por disciplina
  Future<int> contarQuestoesPorDisciplina(String disciplinaId) async {
    try {
      final snapshot = await _database
          .ref('questoes')
          .orderByChild('disciplinaId')
          .equalTo(disciplinaId)
          .get();

      return snapshot.children.length;
    } catch (e) {
      print('Erro ao contar questões da disciplina: $e');
      return 0;
    }
  }

  /// Busca questões por texto (busca parcial no enunciado)
  Stream<DatabaseEvent> buscarQuestoesPorTexto(String texto) {
    final textoSanitizado = _securityService.sanitizarEntrada(texto);
    return _database
        .ref('questoes')
        .orderByChild('enunciado')
        .startAt(textoSanitizado)
        .endAt('$textoSanitizado\uf8ff')
        .onValue;
  }

  /// Duplica uma questão
  Future<String?> duplicarQuestao(String questaoId) async {
    try {
      final questaoSnapshot = await _database.ref('questoes/$questaoId').get();
      if (!questaoSnapshot.exists) {
        throw Exception('Questão não encontrada');
      }

      final questaoData = questaoSnapshot.value as Map<dynamic, dynamic>;

      // Criar nova questão com dados modificados
      final novaQuestaoRef = _database.ref('questoes').push();
      final novaQuestaoId = novaQuestaoRef.key!;

      // Remover campos que não devem ser duplicados
      questaoData.remove('dataCriacao');
      questaoData.remove('criadoPor');
      questaoData.remove('versao');

      // Adicionar novos campos
      questaoData['enunciado'] = '${questaoData['enunciado']} (Cópia)';
      questaoData['dataCriacao'] = ServerValue.timestamp;
      questaoData['criadoPor'] = _auth.currentUser?.uid;
      questaoData['versao'] = 1;
      questaoData['status'] = 'ativo';

      await novaQuestaoRef.set(questaoData);

      await _securityService.registrarAtividadeSeguranca(
        'duplicar_questao',
        'Questão $questaoId duplicada como $novaQuestaoId',
        sucesso: true,
      );

      return novaQuestaoId;
    } catch (e) {
      print('Erro ao duplicar questão: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_duplicar_questao',
        'Erro ao duplicar questão: $e',
        sucesso: false,
      );
      return null;
    }
  }
}
