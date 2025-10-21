import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';

/// Serviço responsável por operações com cursos
class CourseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SecurityService _securityService = SecurityService();

  // ========== MÉTODOS DE CURSO ==========

  /// Cria um novo curso
  Future<String?> criarCurso(String nome, String descricao) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Validar entrada
      if (!_securityService.validarTexto(nome, maxLength: 100)) {
        throw Exception('Nome do curso inválido');
      }

      if (!_securityService.validarTexto(descricao, maxLength: 500)) {
        throw Exception('Descrição do curso inválida');
      }

      final nomeSanitizado = _securityService.sanitizarEntrada(nome);
      final descricaoSanitizada = _securityService.sanitizarEntrada(descricao);
      final cursoId = nomeSanitizado.toLowerCase().replaceAll(' ', '_');

      // Verificar se já existe um curso com esse ID
      final snapshot = await _database.ref('cursos/$cursoId').get();
      if (snapshot.exists) {
        throw Exception('Já existe um curso com esse nome');
      }

      final cursoRef = _database.ref('cursos/$cursoId');
      await cursoRef.set({
        'nome': nomeSanitizado,
        'descricao': descricaoSanitizada,
        'dataCriacao': ServerValue.timestamp,
        'criadoPor': user.uid,
        'status': 'ativo',
        'duracao': 0, // em semestres
        'codigo': cursoId,
      });

      await _securityService.registrarAtividadeSeguranca(
        'criar_curso',
        'Curso criado: $nome',
        sucesso: true,
      );

      return cursoId;
    } catch (e) {
      print('Erro ao criar curso: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_criar_curso',
        'Erro ao criar curso: $e',
        sucesso: false,
      );
      return null;
    }
  }

  /// Lista todos os cursos
  Stream<DatabaseEvent> listarCursos() {
    return _database.ref('cursos').onValue;
  }

  /// Busca um curso específico
  Future<DataSnapshot?> buscarCurso(String cursoId) async {
    try {
      return await _database.ref('cursos/$cursoId').get();
    } catch (e) {
      print('Erro ao buscar curso: $e');
      return null;
    }
  }

  /// Atualiza um curso
  Future<bool> atualizarCurso(
    String cursoId,
    Map<String, dynamic> dados,
  ) async {
    try {
      // Validar dados se necessário
      if (dados.containsKey('nome')) {
        if (!_securityService.validarTexto(dados['nome'], maxLength: 100)) {
          throw Exception('Nome do curso inválido');
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
          throw Exception('Descrição do curso inválida');
        }
        dados['descricao'] = _securityService.sanitizarEntrada(
          dados['descricao'],
        );
      }

      // Adicionar timestamp de atualização
      dados['dataAtualizacao'] = ServerValue.timestamp;

      await _database.ref('cursos/$cursoId').update(dados);

      await _securityService.registrarAtividadeSeguranca(
        'atualizar_curso',
        'Curso atualizado: $cursoId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao atualizar curso: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_atualizar_curso',
        'Erro ao atualizar curso: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Remove um curso (soft delete)
  Future<bool> removerCurso(String cursoId) async {
    try {
      await _database.ref('cursos/$cursoId').update({
        'status': 'inativo',
        'dataRemocao': ServerValue.timestamp,
      });

      await _securityService.registrarAtividadeSeguranca(
        'remover_curso',
        'Curso removido: $cursoId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao remover curso: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_remover_curso',
        'Erro ao remover curso: $e',
        sucesso: false,
      );
      return false;
    }
  }
}
