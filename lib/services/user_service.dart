import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';

/// Serviço responsável por gerenciamento de usuários e permissões
class UserService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SecurityService _securityService = SecurityService();

  // ========== CONSTANTES ==========
  static const String tipoProfessor = 'professor';
  static const String tipoCoordenador = 'coordenador';

  // ========== MÉTODOS DE USUÁRIO ==========

  /// Stream dos dados do usuário atual
  Stream<DatabaseEvent> streamDadosUsuario() {
    if (_auth.currentUser == null) return const Stream.empty();

    return _database.ref('usuarios/${_auth.currentUser!.uid}').onValue;
  }

  /// Atualizar dados do usuário
  Future<bool> atualizarDadosUsuario(Map<String, dynamic> dados) async {
    if (_auth.currentUser == null) return false;

    try {
      // Sanitizar dados se necessário
      if (dados.containsKey('nome')) {
        dados['nome'] = _securityService.sanitizarEntrada(dados['nome']);
      }
      if (dados.containsKey('email')) {
        dados['email'] = _securityService.sanitizarEntrada(dados['email']);
      }

      await _database.ref('usuarios/${_auth.currentUser!.uid}').update(dados);

      await _securityService.registrarAtividadeSeguranca(
        'atualizar_dados_usuario',
        'Dados do usuário atualizados',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao atualizar dados do usuário: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_atualizar_dados_usuario',
        'Erro ao atualizar dados do usuário: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Configurar "Lembrar-me"
  Future<void> configurarLembrarMe(bool lembrar) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _database.ref('usuarios/${user.uid}').update({
        'lembrarMe': lembrar,
        'configuradoEm': ServerValue.timestamp,
      });
    } catch (e) {
      print('Erro ao configurar lembrar-me: $e');
    }
  }

  /// Atualizar última atividade
  Future<void> atualizarUltimaAtividade() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _database.ref('usuarios/${user.uid}').update({
        'ultimaAtividade': ServerValue.timestamp,
      });
    } catch (e) {
      print('Erro ao atualizar última atividade: $e');
    }
  }

  /// Obter tipo de usuário
  Future<String> obterTipoUsuario() async {
    final user = _auth.currentUser;
    if (user == null) return 'professor';

    try {
      // Tentar obter do banco com timeout
      final snapshot = await _database
          .ref('usuarios/${user.uid}/tipo')
          .get()
          .timeout(const Duration(seconds: 5));

      if (snapshot.exists) {
        return snapshot.value as String;
      }
    } catch (e) {
      print('Erro ao obter tipo de usuário: $e');
    }
    return 'professor';
  }

  /// Buscar dados do usuário
  Stream<DatabaseEvent> buscarDadosUsuario() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _database.ref('usuarios/${user.uid}').onValue;
  }

  /// Listar todos os usuários
  Stream<DatabaseEvent> listarTodosUsuarios() {
    return _database.ref('usuarios').onValue;
  }

  // ========== GERENCIAMENTO DE PERMISSÕES ==========

  /// Alterar tipo de usuário
  Future<bool> alterarTipoUsuario(String userId, String novoTipo) async {
    try {
      // Verificar permissão
      final temPermissao = await _securityService.verificarPermissaoComLog(
        'gerenciarCoordenadores',
      );
      if (!temPermissao) {
        throw Exception(
          'Usuário não tem permissão para alterar tipos de usuário',
        );
      }

      Map<String, bool> permissoes;
      if (novoTipo == tipoCoordenador) {
        permissoes = {
          'gerenciarProfessores': true,
          'gerenciarCoordenadores': false,
          'visualizarTodasProvas': true,
          'criarProvas': true,
          'editarProvas': true,
          'deletarProvas': true,
        };
      } else {
        permissoes = {
          'gerenciarProfessores': false,
          'gerenciarCoordenadores': false,
          'visualizarTodasProvas': false,
          'criarProvas': true,
          'editarProvas': true,
          'deletarProvas': true,
        };
      }

      await _database.ref('usuarios/$userId').update({
        'tipo': novoTipo,
        'permissoes': permissoes,
        'alteradoEm': ServerValue.timestamp,
        'alteradoPor': _auth.currentUser?.uid,
      });

      await _securityService.registrarAtividadeSeguranca(
        'alterar_tipo_usuario',
        'Usuário $userId alterado para $novoTipo',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao alterar tipo de usuário: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_alterar_tipo_usuario',
        'Erro ao alterar tipo de usuário: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Promove um professor a coordenador
  Future<bool> promoverACoordenador(String userId) async {
    try {
      // Verificar se o usuário atual tem permissão
      final temPermissao = await _securityService.verificarPermissaoComLog(
        'gerenciarCoordenadores',
      );
      if (!temPermissao) {
        throw Exception(
          'Usuário não tem permissão para promover coordenadores',
        );
      }

      // Verificar se o usuário existe e é professor
      final snapshot = await _database.ref('usuarios/$userId').get();
      if (!snapshot.exists) {
        throw Exception('Usuário não encontrado');
      }

      final userData = snapshot.value as Map<dynamic, dynamic>;
      final tipoAtual = userData['tipo'] ?? 'professor';

      if (tipoAtual != tipoProfessor) {
        throw Exception(
          'Apenas professores podem ser promovidos a coordenador',
        );
      }

      // Promover a coordenador
      final sucesso = await alterarTipoUsuario(userId, tipoCoordenador);

      if (sucesso) {
        await _securityService.registrarAtividadeSeguranca(
          'promover_coordenador',
          'Professor $userId promovido a coordenador',
          sucesso: true,
        );
      }

      return sucesso;
    } catch (e) {
      print('Erro ao promover a coordenador: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_promover_coordenador',
        'Erro ao promover a coordenador: $e',
        sucesso: false,
      );
      return false;
    }
  }

  /// Rebaixa um coordenador a professor
  Future<bool> rebaixarAProfessor(String userId) async {
    try {
      // Verificar se o usuário atual tem permissão
      final temPermissao = await _securityService.verificarPermissaoComLog(
        'gerenciarCoordenadores',
      );
      if (!temPermissao) {
        throw Exception(
          'Usuário não tem permissão para rebaixar coordenadores',
        );
      }

      // Verificar se o usuário existe e é coordenador
      final snapshot = await _database.ref('usuarios/$userId').get();
      if (!snapshot.exists) {
        throw Exception('Usuário não encontrado');
      }

      final userData = snapshot.value as Map<dynamic, dynamic>;
      final tipoAtual = userData['tipo'] ?? 'professor';

      if (tipoAtual != tipoCoordenador) {
        throw Exception(
          'Apenas coordenadores podem ser rebaixados a professor',
        );
      }

      // Rebaixar a professor
      final sucesso = await alterarTipoUsuario(userId, tipoProfessor);

      if (sucesso) {
        await _securityService.registrarAtividadeSeguranca(
          'rebaixar_coordenador',
          'Coordenador $userId rebaixado a professor',
          sucesso: true,
        );
      }

      return sucesso;
    } catch (e) {
      print('Erro ao rebaixar a professor: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_rebaixar_coordenador',
        'Erro ao rebaixar a professor: $e',
        sucesso: false,
      );
      return false;
    }
  }

  // ========== LISTAGEM DE USUÁRIOS ==========

  /// Lista todos os coordenadores
  Stream<DatabaseEvent> listarCoordenadores() {
    return _database
        .ref('usuarios')
        .orderByChild('tipo')
        .equalTo(tipoCoordenador)
        .onValue;
  }

  /// Lista todos os professores (não coordenadores)
  Stream<DatabaseEvent> listarProfessores() {
    return _database
        .ref('usuarios')
        .orderByChild('tipo')
        .equalTo(tipoProfessor)
        .onValue;
  }

  // ========== GRUPOS ==========

  /// Criar grupo de professores
  Future<bool> criarGrupoProfessores(String nome, String descricao) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Validar entrada
      if (!_securityService.validarEntrada(nome, maxLength: 100)) {
        throw Exception('Nome do grupo inválido');
      }
      if (!_securityService.validarEntrada(descricao, maxLength: 500)) {
        throw Exception('Descrição do grupo inválida');
      }

      final nomeSanitizado = _securityService.sanitizarEntrada(nome);
      final descricaoSanitizada = _securityService.sanitizarEntrada(descricao);

      final grupoRef = _database.ref('grupos').push();
      await grupoRef.set({
        'nome': nomeSanitizado,
        'descricao': descricaoSanitizada,
        'coordenadorId': user.uid,
        'dataCriacao': ServerValue.timestamp,
        'status': 'ativo',
        'membros': [user.uid],
        'configuracoes': {'maxMembros': 50, 'permissoesEspeciais': true},
      });

      await _securityService.registrarAtividadeSeguranca(
        'criar_grupo',
        'Grupo criado: $nomeSanitizado',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao criar grupo: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_criar_grupo',
        'Erro ao criar grupo: $e',
        sucesso: false,
      );
      return false;
    }
  }
}
