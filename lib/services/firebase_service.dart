import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ========== AUTENTICAÇÃO ==========

  /// Registra um novo usuário no sistema
  ///
  /// [email] Email do usuário (deve ser válido)
  /// [senha] Senha do usuário (deve atender aos critérios de segurança)
  /// [nome] Nome completo do usuário
  ///
  /// Retorna [UserCredential] se bem-sucedido, null caso contrário
  ///
  /// Lança [FirebaseAuthException] em caso de erro de autenticação
  /// Lança [Exception] se as validações falharem
  Future<UserCredential?> registrarUsuario(
    String email,
    String senha,
    String nome,
  ) async {
    try {
      // Validar entradas
      if (!validarEntrada(email, maxLength: 100)) {
        throw Exception('Email inválido');
      }
      if (!validarEntrada(nome, maxLength: 100)) {
        throw Exception('Nome inválido');
      }
      if (senha.length < 6) {
        throw Exception('Senha deve ter pelo menos 6 caracteres');
      }

      // Criar usuário no Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: senha);

      // Atualizar o perfil do usuário
      await userCredential.user?.updateDisplayName(nome);

      // Sanitizar dados antes de salvar
      final nomeSanitizado = sanitizarEntrada(nome);
      final emailSanitizado = sanitizarEntrada(email);

      // Salvar dados adicionais no Realtime Database
      final userRef = _database.ref('usuarios/${userCredential.user!.uid}');
      await userRef.set({
        'nome': nomeSanitizado,
        'email': emailSanitizado,
        'dataCriacao': ServerValue.timestamp,
        'tipo': tipoProfessor,
        'status': 'ativo',
        'emailVerificado': false,
        'grupoId': null,
        'permissoes': {
          'gerenciarProfessores': false,
          'gerenciarCoordenadores': false,
          'visualizarTodasProvas': false,
          'criarProvas': true,
          'editarProvas': true,
          'deletarProvas': true,
        },
      });

      // Enviar email de verificação
      await userCredential.user?.sendEmailVerification();

      // Registrar atividade de segurança
      await registrarAtividadeSeguranca(
        'registro_usuario',
        'Novo usuário registrado: $email',
        sucesso: true,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Erro de autenticação: ${e.code} - ${e.message}');
      await registrarAtividadeSeguranca(
        'erro_registro',
        'Erro ao registrar usuário: ${e.code}',
        sucesso: false,
      );
      rethrow;
    } catch (e) {
      print('Erro ao registrar usuário: $e');
      await registrarAtividadeSeguranca(
        'erro_registro',
        'Erro geral ao registrar usuário: $e',
        sucesso: false,
      );
      rethrow;
    }
  }

  // Fazer login usando Firebase Auth
  Future<UserCredential?> fazerLogin(String email, String senha) async {
    try {
      // Fazer login no Firebase Auth
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: senha);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Erro de autenticação: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Erro ao fazer login: $e');
      rethrow;
    }
  }

  // Fazer login com Google
  Future<UserCredential?> fazerLoginComGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );

      // Salvar dados do usuário se for novo
      if (result.additionalUserInfo?.isNewUser == true) {
        // Todos os novos usuários são professores por padrão

        // Sanitizar dados
        final nome = sanitizarEntrada(result.user!.displayName ?? '');
        final email = sanitizarEntrada(result.user!.email ?? '');

        // Criar documento completo do usuário no Realtime Database
        final userRef = _database.ref('usuarios/${result.user!.uid}');
        await userRef.set({
          'nome': nome,
          'email': email,
          'dataCriacao': ServerValue.timestamp,
          'tipo': tipoProfessor,
          'status': 'ativo',
          'emailVerificado': true, // Google já verifica o email
          'grupoId': null,
          'permissoes': {
            'gerenciarProfessores': false,
            'gerenciarCoordenadores': false,
            'visualizarTodasProvas': false,
            'criarProvas': true,
            'editarProvas': true,
            'deletarProvas': true,
          },
        });

        // Registrar atividade de segurança
        await registrarAtividadeSeguranca(
          'registro_usuario_google',
          'Novo usuário Google registrado: $email (professor)',
          sucesso: true,
        );
      } else {
        // Registrar atividade de login
        await registrarAtividadeSeguranca(
          'login_google',
          'Login com Google realizado: ${result.user!.email}',
          sucesso: true,
        );
      }

      return result;
    } catch (e) {
      print('Erro ao fazer login com Google: $e');
      await registrarAtividadeSeguranca(
        'erro_login_google',
        'Erro ao fazer login com Google: $e',
        sucesso: false,
      );
      return null;
    }
  }

  // Fazer logout
  Future<void> fazerLogout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Erro ao fazer logout: $e');
      rethrow;
    }
  }

  // ========== SISTEMA DE TIPOS DE USUÁRIO ==========

  // Enum para tipos de usuário
  static const String tipoProfessor = 'professor';
  static const String tipoCoordenador = 'coordenador';

  // Verificar se já existem usuários no sistema

  // ========== MÉTODOS DE SEGURANÇA ==========

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

  // ========== EXEMPLO: TAREFAS ==========

  // Adicionar tarefa
  Future<bool> adicionarTarefa(String titulo, String descricao) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final tarefaRef = _database.ref('tarefas').push();
      await tarefaRef.set({
        'titulo': titulo,
        'descricao': descricao,
        'concluida': false,
        'usuarioId': user.uid,
        'dataCriacao': ServerValue.timestamp,
      });
      return true;
    } catch (e) {
      print('Erro ao adicionar tarefa: $e');
      return false;
    }
  }

  // Buscar tarefas do usuário
  Stream<DatabaseEvent> buscarTarefas() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _database
        .ref('tarefas')
        .orderByChild('usuarioId')
        .equalTo(user.uid)
        .onValue;
  }

  // Atualizar tarefa
  Future<bool> atualizarTarefa(
    String tarefaId,
    Map<String, dynamic> dados,
  ) async {
    try {
      await _database.ref('tarefas/$tarefaId').update(dados);
      return true;
    } catch (e) {
      print('Erro ao atualizar tarefa: $e');
      return false;
    }
  }

  // Deletar tarefa
  Future<bool> deletarTarefa(String tarefaId) async {
    try {
      await _database.ref('tarefas/$tarefaId').remove();
      return true;
    } catch (e) {
      print('Erro ao deletar tarefa: $e');
      return false;
    }
  }

  // ========== MÉTODOS AUXILIARES ==========

  // Usuário atual
  User? get usuarioAtual => _auth.currentUser;

  // Stream dos dados do usuário atual
  Stream<DatabaseEvent> streamDadosUsuario() {
    if (usuarioAtual == null) return const Stream.empty();

    return _database.ref('usuarios/${usuarioAtual!.uid}').onValue;
  }

  // Atualizar dados do usuário
  Future<bool> atualizarDadosUsuario(Map<String, dynamic> dados) async {
    if (usuarioAtual == null) return false;

    try {
      await _database.ref('usuarios/${usuarioAtual!.uid}').update(dados);
      return true;
    } catch (e) {
      print('Erro ao atualizar dados do usuário: $e');
      return false;
    }
  }

  // ========== MÉTODOS ADICIONAIS NECESSÁRIOS ==========

  // Verificar se a sessão é válida
  Future<bool> verificarSessaoValida() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Verificar se o usuário ainda existe no banco
      final snapshot = await _database.ref('usuarios/${user.uid}').get();
      if (!snapshot.exists) return false;

      final userData = snapshot.value as Map<dynamic, dynamic>;
      return userData['status'] == 'ativo';
    } catch (e) {
      print('Erro ao verificar sessão: $e');
      return false;
    }
  }

  // Configurar "Lembrar-me"
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

  // Atualizar última atividade
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

  // Reenviar verificação de email
  Future<void> reenviarVerificacaoEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Recuperar senha
  Future<void> recuperarSenha(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Obter tipo de usuário
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

  // Buscar dados do usuário
  Stream<DatabaseEvent> buscarDadosUsuario() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _database.ref('usuarios/${user.uid}').onValue;
  }

  // Listar todos os usuários
  Stream<DatabaseEvent> listarTodosUsuarios() {
    return _database.ref('usuarios').onValue;
  }

  // Alterar tipo de usuário
  Future<bool> alterarTipoUsuario(String userId, String novoTipo) async {
    try {
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

      await registrarAtividadeSeguranca(
        'alterar_tipo_usuario',
        'Usuário $userId alterado para $novoTipo',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao alterar tipo de usuário: $e');
      await registrarAtividadeSeguranca(
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
      final temPermissao = await verificarPermissao('gerenciarCoordenadores');
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
        await registrarAtividadeSeguranca(
          'promover_coordenador',
          'Professor $userId promovido a coordenador',
          sucesso: true,
        );
      }

      return sucesso;
    } catch (e) {
      print('Erro ao promover a coordenador: $e');
      await registrarAtividadeSeguranca(
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
      final temPermissao = await verificarPermissao('gerenciarCoordenadores');
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
        await registrarAtividadeSeguranca(
          'rebaixar_coordenador',
          'Coordenador $userId rebaixado a professor',
          sucesso: true,
        );
      }

      return sucesso;
    } catch (e) {
      print('Erro ao rebaixar a professor: $e');
      await registrarAtividadeSeguranca(
        'erro_rebaixar_coordenador',
        'Erro ao rebaixar a professor: $e',
        sucesso: false,
      );
      return false;
    }
  }

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

  // Criar grupo de professores
  Future<bool> criarGrupoProfessores(String nome, String descricao) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final grupoRef = _database.ref('grupos').push();
      await grupoRef.set({
        'nome': nome,
        'descricao': descricao,
        'coordenadorId': user.uid,
        'dataCriacao': ServerValue.timestamp,
        'status': 'ativo',
        'membros': [user.uid],
        'configuracoes': {'maxMembros': 50, 'permissoesEspeciais': true},
      });
      return true;
    } catch (e) {
      print('Erro ao criar grupo: $e');
      return false;
    }
  }

  // ========== SISTEMA DE DISCIPLINAS ==========

  /// Cria uma nova disciplina
  Future<String?> criarDisciplina(String nome, int semestre) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Validar entrada
      if (!validarEntrada(nome, maxLength: 100)) {
        throw Exception('Nome da disciplina inválido');
      }

      final nomeSanitizado = sanitizarEntrada(nome);
      final disciplinaId =
          '${nomeSanitizado.toLowerCase().replaceAll(' ', '_')}_${semestre}';

      final disciplinaRef = _database.ref('disciplinas/$disciplinaId');
      await disciplinaRef.set({
        'nome': nomeSanitizado,
        'semestre': semestre,
        'dataCriacao': ServerValue.timestamp,
        'criadoPor': user.uid,
        'status': 'ativo',
      });

      await registrarAtividadeSeguranca(
        'criar_disciplina',
        'Disciplina criada: $nome (Semestre $semestre)',
        sucesso: true,
      );

      return disciplinaId;
    } catch (e) {
      print('Erro ao criar disciplina: $e');
      await registrarAtividadeSeguranca(
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

  // ========== SISTEMA DE QUESTÕES ==========

  /// Cria uma nova questão com opções
  Future<String?> criarQuestao({
    required String enunciado,
    required String disciplinaId,
    required Map<String, Map<String, dynamic>> opcoes,
    String? imagemUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Validar entrada
      if (!validarEntrada(enunciado, maxLength: 1000)) {
        throw Exception('Enunciado da questão inválido');
      }

      // Validar opções
      if (opcoes.length < 2) {
        throw Exception('Questão deve ter pelo menos 2 opções');
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

      final enunciadoSanitizado = sanitizarEntrada(enunciado);
      final questaoRef = _database.ref('questoes').push();
      final questaoId = questaoRef.key!;

      // Sanitizar opções
      Map<String, Map<String, dynamic>> opcoesSanitizadas = {};
      for (var entry in opcoes.entries) {
        opcoesSanitizadas[entry.key] = {
          'texto': sanitizarEntrada(entry.value['texto']),
          'correta': entry.value['correta'],
          'ordem': entry.value['ordem'] ?? 1,
        };
      }

      await questaoRef.set({
        'enunciado': enunciadoSanitizado,
        'disciplinaId': disciplinaId,
        'imagemUrl': imagemUrl,
        'dataCriacao': ServerValue.timestamp,
        'criadoPor': user.uid,
        'status': 'ativo',
        'opcoes': opcoesSanitizadas,
      });

      await registrarAtividadeSeguranca(
        'criar_questao',
        'Questão criada: ${enunciadoSanitizado.substring(0, 50)}...',
        sucesso: true,
      );

      return questaoId;
    } catch (e) {
      print('Erro ao criar questão: $e');
      await registrarAtividadeSeguranca(
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
      if (dados.containsKey('enunciado')) {
        dados['enunciado'] = sanitizarEntrada(dados['enunciado']);
      }

      await _database.ref('questoes/$questaoId').update(dados);

      await registrarAtividadeSeguranca(
        'atualizar_questao',
        'Questão atualizada: $questaoId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao atualizar questão: $e');
      await registrarAtividadeSeguranca(
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
      await _database.ref('questoes/$questaoId').remove();

      await registrarAtividadeSeguranca(
        'deletar_questao',
        'Questão deletada: $questaoId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao deletar questão: $e');
      await registrarAtividadeSeguranca(
        'erro_deletar_questao',
        'Erro ao deletar questão: $e',
        sucesso: false,
      );
      return false;
    }
  }

  // ========== SISTEMA DE EXAMES ==========

  /// Cria um novo exame
  Future<String?> criarExame({
    required String titulo,
    required String instrucoes,
    Map<String, dynamic>? configuracoes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Validar entrada
      if (!validarEntrada(titulo, maxLength: 200)) {
        throw Exception('Título do exame inválido');
      }
      if (!validarEntrada(instrucoes, maxLength: 1000)) {
        throw Exception('Instruções do exame inválidas');
      }

      final tituloSanitizado = sanitizarEntrada(titulo);
      final instrucoesSanitizadas = sanitizarEntrada(instrucoes);

      final exameRef = _database.ref('exames').push();
      final exameId = exameRef.key!;

      await exameRef.set({
        'titulo': tituloSanitizado,
        'instrucoes': instrucoesSanitizadas,
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
            },
        'questoes': {}, // Será preenchido quando adicionar questões
      });

      await registrarAtividadeSeguranca(
        'criar_exame',
        'Exame criado: $tituloSanitizado',
        sucesso: true,
      );

      return exameId;
    } catch (e) {
      print('Erro ao criar exame: $e');
      await registrarAtividadeSeguranca(
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
      final questaoRef = _database.ref('exames/$exameId/questoes/$questaoId');
      await questaoRef.set({
        'numero': numero,
        'peso': peso,
        'linhasResposta': linhasResposta,
        'ordem': numero,
        'adicionadaEm': ServerValue.timestamp,
      });

      await registrarAtividadeSeguranca(
        'adicionar_questao_exame',
        'Questão $questaoId adicionada ao exame $exameId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao adicionar questão ao exame: $e');
      await registrarAtividadeSeguranca(
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
        dados['titulo'] = sanitizarEntrada(dados['titulo']);
      }
      if (dados.containsKey('instrucoes')) {
        dados['instrucoes'] = sanitizarEntrada(dados['instrucoes']);
      }

      await _database.ref('exames/$exameId').update(dados);

      await registrarAtividadeSeguranca(
        'atualizar_exame',
        'Exame atualizado: $exameId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao atualizar exame: $e');
      await registrarAtividadeSeguranca(
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

      await registrarAtividadeSeguranca(
        'remover_questao_exame',
        'Questão $questaoId removida do exame $exameId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao remover questão do exame: $e');
      await registrarAtividadeSeguranca(
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

      await registrarAtividadeSeguranca(
        'deletar_exame',
        'Exame deletado: $exameId',
        sucesso: true,
      );

      return true;
    } catch (e) {
      print('Erro ao deletar exame: $e');
      await registrarAtividadeSeguranca(
        'erro_deletar_exame',
        'Erro ao deletar exame: $e',
        sucesso: false,
      );
      return false;
    }
  }
}
