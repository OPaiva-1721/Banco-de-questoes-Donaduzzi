import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';

/// Serviço responsável por operações com disciplinas
class DisciplineService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SecurityService _securityService = SecurityService();

  // ========== MÉTODOS DE DISCIPLINA ==========

  /// Cria uma nova disciplina
  Future<String?> criarDisciplina(
    String nome,
    int semestre, {
    String? cursoId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Validar entrada
      if (!_securityService.validarTexto(nome, maxLength: 100)) {
        throw Exception('Nome da disciplina inválido');
      }

      if (semestre < 1 || semestre > 20) {
        throw Exception('Semestre deve estar entre 1 e 20');
      }

      final nomeSanitizado = _securityService.sanitizarEntrada(nome);
      final disciplinaId =
          '${nomeSanitizado.toLowerCase().replaceAll(' ', '_')}_$semestre';

      // Verificar se já existe uma disciplina com esse ID
      final snapshot = await _database.ref('disciplinas/$disciplinaId').get();
      if (snapshot.exists) {
        throw Exception('Já existe uma disciplina com esse nome e semestre');
      }

      final disciplinaRef = _database.ref('disciplinas/$disciplinaId');
      await disciplinaRef.set({
        'nome': nomeSanitizado,
        'semestre': semestre,
        'cursoId': cursoId,
        'dataCriacao': ServerValue.timestamp,
        'criadoPor': user.uid,
        'status': 'ativo',
        'descricao': '',
        'cargaHoraria': 0,
        'codigo': disciplinaId,
      });

      await _securityService.registrarAtividadeSeguranca(
        'criar_disciplina',
        'Disciplina criada: $nome (Semestre $semestre)',
        sucesso: true,
      );

      return disciplinaId;
    } catch (e) {
      print('Erro ao criar disciplina: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_criar_disciplina',
        'Erro ao criar disciplina: $e',
        sucesso: false,
      );
      return null;
    }
  }

  /// Lista todas as disciplinas
  Stream<DatabaseEvent> listarDisciplinas() {
    return _database.ref('disciplinas').onValue;
  }

  /// Busca disciplinas por semestre
  Stream<DatabaseEvent> buscarDisciplinasPorSemestre(int semestre) {
    return _database
        .ref('disciplinas')
        .orderByChild('semestre')
        .equalTo(semestre)
        .onValue;
  }

  /// Busca disciplinas por curso
  Stream<DatabaseEvent> buscarDisciplinasPorCurso(String cursoId) {
    return _database
        .ref('disciplinas')
        .orderByChild('cursoId')
        .equalTo(cursoId)
        .onValue;
  }

  /// Busca uma disciplina específica
  Future<DataSnapshot?> buscarDisciplina(String disciplinaId) async {
    try {
      return await _database.ref('disciplinas/$disciplinaId').get();
    } catch (e) {
      print('Erro ao buscar disciplina: $e');
      return null;
    }
  }

  /// Atualiza uma disciplina
  Future<bool> atualizarDisciplina(
    String disciplinaId,
    Map<String, dynamic> dados,
  ) async {
    try {
      // Validar dados se necessário
      if (dados.containsKey('nome')) {
        if (!_securityService.validarTexto(dados['nome'], maxLength: 100)) {
          throw Exception('Nome da disciplina inválido');
        }
        dados['nome'] = _securityService.sanitizarEntrada(dados['nome']);
      }
      if (dados.containsKey('descricao') &&
          dados['descricao'] != null &&
          dados['descricao'].toString().trim().isNotEmpty) {
        if (!_securityService.validarTexto(
          dados['descricao'],
          maxLength: 500,
        )) {
          throw Exception('Descrição da disciplina inválida');
        }
        dados['descricao'] = _securityService.sanitizarEntrada(
          dados['descricao'],
        );
      }

      // Adicionar timestamp de atualização
      dados['atualizadoEm'] = ServerValue.timestamp;
      dados['atualizadoPor'] = _auth.currentUser?.uid;

      await _database.ref('disciplinas/$disciplinaId').update(dados);

      await _securityService.registrarAtividadeSeguranca(
        'atualizar_disciplina',
        'Disciplina atualizada: $disciplinaId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao atualizar disciplina: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_atualizar_disciplina',
        'Erro ao atualizar disciplina: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Deleta uma disciplina
  Future<bool> deletarDisciplina(String disciplinaId) async {
    try {
      // Verificar se há questões associadas à disciplina
      final questoesSnapshot = await _database
          .ref('questoes')
          .orderByChild('disciplinaId')
          .equalTo(disciplinaId)
          .get();

      if (questoesSnapshot.exists) {
        throw Exception(
          'Não é possível deletar disciplina que possui questões associadas',
        );
      }

      await _database.ref('disciplinas/$disciplinaId').remove();

      await _securityService.registrarAtividadeSeguranca(
        'deletar_disciplina',
        'Disciplina deletada: $disciplinaId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao deletar disciplina: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_deletar_disciplina',
        'Erro ao deletar disciplina: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Busca disciplinas por nome (busca parcial)
  Stream<DatabaseEvent> buscarDisciplinasPorNome(String nome) {
    final nomeSanitizado = _securityService.sanitizarEntrada(nome);
    return _database
        .ref('disciplinas')
        .orderByChild('nome')
        .startAt(nomeSanitizado)
        .endAt('$nomeSanitizado\uf8ff')
        .onValue;
  }

  /// Lista disciplinas por status
  Stream<DatabaseEvent> listarDisciplinasPorStatus(String status) {
    return _database
        .ref('disciplinas')
        .orderByChild('status')
        .equalTo(status)
        .onValue;
  }

  /// Ativa/desativa uma disciplina
  Future<bool> alterarStatusDisciplina(
    String disciplinaId,
    String status,
  ) async {
    try {
      if (status != 'ativo' && status != 'inativo') {
        throw Exception('Status deve ser "ativo" ou "inativo"');
      }

      await _database.ref('disciplinas/$disciplinaId').update({
        'status': status,
        'alteradoEm': ServerValue.timestamp,
        'alteradoPor': _auth.currentUser?.uid,
      });

      await _securityService.registrarAtividadeSeguranca(
        'alterar_status_disciplina',
        'Status da disciplina $disciplinaId alterado para $status',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao alterar status da disciplina: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_alterar_status_disciplina',
        'Erro ao alterar status da disciplina: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Conta o número de questões por disciplina
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

  /// Lista disciplinas com contagem de questões
  Stream<DatabaseEvent> listarDisciplinasComContagem() {
    return _database.ref('disciplinas').onValue;
  }
}
