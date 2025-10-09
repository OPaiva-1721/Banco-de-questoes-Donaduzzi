import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'user_service.dart';
import 'question_service.dart';
import 'exam_service.dart';
import 'discipline_service.dart';
import 'security_service.dart';

/// Serviço principal que orquestra todos os outros serviços do Firebase
///
/// Este serviço atua como uma fachada (facade) que centraliza o acesso
/// a todos os serviços especializados, mantendo a compatibilidade
/// com o código existente.
class FirebaseService {
  // Instâncias dos serviços especializados
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final QuestionService _questionService = QuestionService();
  final ExamService _examService = ExamService();
  final DisciplineService _disciplineService = DisciplineService();
  final SecurityService _securityService = SecurityService();

  // Instâncias do Firebase para compatibilidade
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========== CONSTANTES ==========
  static const String tipoProfessor = 'professor';
  static const String tipoCoordenador = 'coordenador';

  // ========== AUTENTICAÇÃO (DELEGAÇÃO PARA AuthService) ==========

  /// Registra um novo usuário no sistema
  Future<UserCredential?> registrarUsuario(
    String email,
    String senha,
    String nome,
  ) async {
    return await _authService.registrarUsuario(email, senha, nome);
  }

  /// Fazer login usando Firebase Auth
  Future<UserCredential?> fazerLogin(String email, String senha) async {
    return await _authService.fazerLogin(email, senha);
  }

  /// Fazer login com Google
  Future<UserCredential?> fazerLoginComGoogle() async {
    return await _authService.fazerLoginComGoogle();
  }

  /// Fazer logout
  Future<void> fazerLogout() async {
    return await _authService.fazerLogout();
  }

  /// Reenviar verificação de email
  Future<void> reenviarVerificacaoEmail() async {
    return await _authService.reenviarVerificacaoEmail();
  }

  /// Recuperar senha
  Future<void> recuperarSenha(String email) async {
    return await _authService.recuperarSenha(email);
  }

  /// Verificar se a sessão é válida
  Future<bool> verificarSessaoValida() async {
    return await _authService.verificarSessaoValida();
  }

  // ========== USUÁRIOS (DELEGAÇÃO PARA UserService) ==========

  /// Stream dos dados do usuário atual
  Stream<DatabaseEvent> streamDadosUsuario() {
    return _userService.streamDadosUsuario();
  }

  /// Atualizar dados do usuário
  Future<bool> atualizarDadosUsuario(Map<String, dynamic> dados) async {
    return await _userService.atualizarDadosUsuario(dados);
  }

  /// Configurar "Lembrar-me"
  Future<void> configurarLembrarMe(bool lembrar) async {
    return await _userService.configurarLembrarMe(lembrar);
  }

  /// Atualizar última atividade
  Future<void> atualizarUltimaAtividade() async {
    return await _userService.atualizarUltimaAtividade();
  }

  /// Obter tipo de usuário
  Future<String> obterTipoUsuario() async {
    return await _userService.obterTipoUsuario();
  }

  /// Buscar dados do usuário
  Stream<DatabaseEvent> buscarDadosUsuario() {
    return _userService.buscarDadosUsuario();
  }

  /// Listar todos os usuários
  Stream<DatabaseEvent> listarTodosUsuarios() {
    return _userService.listarTodosUsuarios();
  }

  /// Alterar tipo de usuário
  Future<bool> alterarTipoUsuario(String userId, String novoTipo) async {
    return await _userService.alterarTipoUsuario(userId, novoTipo);
  }

  /// Promove um professor a coordenador
  Future<bool> promoverACoordenador(String userId) async {
    return await _userService.promoverACoordenador(userId);
  }

  /// Rebaixa um coordenador a professor
  Future<bool> rebaixarAProfessor(String userId) async {
    return await _userService.rebaixarAProfessor(userId);
  }

  /// Lista todos os coordenadores
  Stream<DatabaseEvent> listarCoordenadores() {
    return _userService.listarCoordenadores();
  }

  /// Lista todos os professores (não coordenadores)
  Stream<DatabaseEvent> listarProfessores() {
    return _userService.listarProfessores();
  }

  /// Criar grupo de professores
  Future<bool> criarGrupoProfessores(String nome, String descricao) async {
    return await _userService.criarGrupoProfessores(nome, descricao);
  }

  // ========== DISCIPLINAS (DELEGAÇÃO PARA DisciplineService) ==========

  /// Cria uma nova disciplina
  Future<String?> criarDisciplina(String nome, int semestre) async {
    return await _disciplineService.criarDisciplina(nome, semestre);
  }

  /// Lista todas as disciplinas
  Stream<DatabaseEvent> listarDisciplinas() {
    return _disciplineService.listarDisciplinas();
  }

  /// Busca disciplinas por semestre
  Stream<DatabaseEvent> buscarDisciplinasPorSemestre(int semestre) {
    return _disciplineService.buscarDisciplinasPorSemestre(semestre);
  }

  /// Busca uma disciplina específica
  Future<DataSnapshot?> buscarDisciplina(String disciplinaId) async {
    return await _disciplineService.buscarDisciplina(disciplinaId);
  }

  /// Atualiza uma disciplina
  Future<bool> atualizarDisciplina(
    String disciplinaId,
    Map<String, dynamic> dados,
  ) async {
    return await _disciplineService.atualizarDisciplina(disciplinaId, dados);
  }

  /// Deleta uma disciplina
  Future<bool> deletarDisciplina(String disciplinaId) async {
    return await _disciplineService.deletarDisciplina(disciplinaId);
  }

  // ========== QUESTÕES (DELEGAÇÃO PARA QuestionService) ==========

  /// Cria uma nova questão com opções
  Future<String?> criarQuestao({
    required String enunciado,
    required String disciplinaId,
    required Map<String, Map<String, dynamic>> opcoes,
    String? imagemUrl,
    String? explicacao,
    double? peso,
  }) async {
    return await _questionService.criarQuestao(
      enunciado: enunciado,
      disciplinaId: disciplinaId,
      opcoes: opcoes,
      imagemUrl: imagemUrl,
      explicacao: explicacao,
      peso: peso,
    );
  }

  /// Lista todas as questões
  Stream<DatabaseEvent> listarQuestoes() {
    return _questionService.listarQuestoes();
  }

  /// Busca questões por disciplina
  Stream<DatabaseEvent> buscarQuestoesPorDisciplina(String disciplinaId) {
    return _questionService.buscarQuestoesPorDisciplina(disciplinaId);
  }

  /// Busca uma questão específica
  Future<DataSnapshot?> buscarQuestao(String questaoId) async {
    return await _questionService.buscarQuestao(questaoId);
  }

  /// Atualiza uma questão
  Future<bool> atualizarQuestao(
    String questaoId,
    Map<String, dynamic> dados,
  ) async {
    return await _questionService.atualizarQuestao(questaoId, dados);
  }

  /// Deleta uma questão
  Future<bool> deletarQuestao(String questaoId) async {
    return await _questionService.deletarQuestao(questaoId);
  }

  // ========== EXAMES (DELEGAÇÃO PARA ExamService) ==========

  /// Cria um novo exame
  Future<String?> criarExame({
    required String titulo,
    required String instrucoes,
    Map<String, dynamic>? configuracoes,
    String? disciplinaId,
  }) async {
    return await _examService.criarExame(
      titulo: titulo,
      instrucoes: instrucoes,
      configuracoes: configuracoes,
      disciplinaId: disciplinaId,
    );
  }

  /// Adiciona uma questão a um exame
  Future<bool> adicionarQuestaoAoExame({
    required String exameId,
    required String questaoId,
    required int numero,
    double peso = 1.0,
    int? linhasResposta,
  }) async {
    return await _examService.adicionarQuestaoAoExame(
      exameId: exameId,
      questaoId: questaoId,
      numero: numero,
      peso: peso,
      linhasResposta: linhasResposta,
    );
  }

  /// Lista todos os exames
  Stream<DatabaseEvent> listarExames() {
    return _examService.listarExames();
  }

  /// Busca exames por professor
  Stream<DatabaseEvent> buscarExamesPorProfessor(String professorId) {
    return _examService.buscarExamesPorProfessor(professorId);
  }

  /// Busca um exame específico
  Future<DataSnapshot?> buscarExame(String exameId) async {
    return await _examService.buscarExame(exameId);
  }

  /// Atualiza um exame
  Future<bool> atualizarExame(
    String exameId,
    Map<String, dynamic> dados,
  ) async {
    return await _examService.atualizarExame(exameId, dados);
  }

  /// Remove uma questão de um exame
  Future<bool> removerQuestaoDoExame(String exameId, String questaoId) async {
    return await _examService.removerQuestaoDoExame(exameId, questaoId);
  }

  /// Deleta um exame
  Future<bool> deletarExame(String exameId) async {
    return await _examService.deletarExame(exameId);
  }

  // ========== SEGURANÇA (DELEGAÇÃO PARA SecurityService) ==========

  /// Verifica se o usuário atual tem permissão para executar uma ação
  Future<bool> verificarPermissao(String acao) async {
    return await _securityService.verificarPermissao(acao);
  }

  /// Registra atividade de segurança
  Future<void> registrarAtividadeSeguranca(
    String acao,
    String detalhes, {
    bool sucesso = true,
  }) async {
    return await _securityService.registrarAtividadeSeguranca(
      acao,
      detalhes,
      sucesso: sucesso,
    );
  }

  /// Valida entrada de dados para prevenir ataques
  bool validarEntrada(String entrada, {int? maxLength}) {
    return _securityService.validarEntrada(entrada, maxLength: maxLength);
  }

  /// Sanitiza entrada de dados
  String sanitizarEntrada(String entrada) {
    return _securityService.sanitizarEntrada(entrada);
  }

  // ========== MÉTODOS LEGADOS (MANTIDOS PARA COMPATIBILIDADE) ==========

  /// Usuário atual
  User? get usuarioAtual => _auth.currentUser;

  // ========== EXEMPLO: TAREFAS (MANTIDO PARA COMPATIBILIDADE) ==========

  /// Adicionar tarefa
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

  /// Buscar tarefas do usuário
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

  /// Atualizar tarefa
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

  /// Deletar tarefa
  Future<bool> deletarTarefa(String tarefaId) async {
    try {
      await _database.ref('tarefas/$tarefaId').remove();
      return true;
    } catch (e) {
      print('Erro ao deletar tarefa: $e');
      return false;
    }
  }
}
