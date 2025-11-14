import 'package:flutter/material.dart';
import '/services/exam_service.dart';
import '/models/course_model.dart';
import '/models/discipline_model.dart';
import '/models/content_model.dart';
import '/services/course_service.dart';
import '/services/subject_service.dart';
import '/services/content_service.dart';
import '/utils/message_utils.dart';
import '/core/app_colors.dart';
import '/core/app_constants.dart';
import 'selecionar_questoes_screen.dart';
import 'package:firebase_database/firebase_database.dart';

class CriarProvaScreen extends StatefulWidget {
  const CriarProvaScreen({super.key});

  @override
  State<CriarProvaScreen> createState() => _CriarProvaScreenState();
}

class _CriarProvaScreenState extends State<CriarProvaScreen> {
  // Constantes de cores
  static const Color _primaryColor = AppColors.primary;
  static const Color _backgroundColor = AppColors.background;
  static const Color _textColor = AppColors.text;
  static const Color _whiteColor = AppColors.white;

  // Serviços
  final ExamService _examService = ExamService();
  final CourseService _courseService = CourseService();
  final SubjectService _subjectService = SubjectService(); 
  final ContentService _contentService = ContentService(); 

  // Controladores
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _instrucoesController = TextEditingController();

  // Estados dos dropdowns (IDs)
  String? _cursoSelecionado;
  String? _disciplinaSelecionada; // <-- CORRIGIDO
  String? _conteudoSelecionado; 

  // Listas de dados (agora usam models)
  List<Course> _cursos = [];
  List<Discipline> _disciplinas = []; // <-- CORRIGIDO
  List<Content> _conteudos = [];

  // Listas filtradas para os dropdowns
  List<Content> _conteudosFiltrados = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  /// **NOVO HELPER** para processar o DatabaseEvent
  List<T> _processarSnapshot<T>(
      DataSnapshot snapshot, T Function(DataSnapshot) fromSnapshot) {
    final list = <T>[];
    if (snapshot.exists && snapshot.value != null) {
      final data = snapshot.value;
      if (data is Map) {
        for (final childSnapshot in snapshot.children) {
          list.add(fromSnapshot(childSnapshot));
        }
      }
    }
    return list;
  }

  /// Carrega Cursos, Disciplinas e Conteúdos do Firebase
  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      // 1. Pega os streams
      final cursosStream = _courseService.getCoursesStream();
      final disciplinasStream = _subjectService.getSubjectsStream(); // <-- CORRIGIDO (nome variável)
      final conteudosStream = _contentService.getContentStream(); 

      // 2. Espera pelo primeiro 'DatabaseEvent' de cada um
      final results = await Future.wait([
        cursosStream.first,
        disciplinasStream.first, // <-- CORRIGIDO (nome variável)
        conteudosStream.first,
      ]);

      // 3. Processa o 'snapshot' de cada 'DatabaseEvent'
      final DatabaseEvent courseEvent = results[0];
      final DatabaseEvent subjectEvent = results[1]; // O service ainda retorna o 'subjectEvent'
      final DatabaseEvent contentEvent = results[2];

      final List<Course> cursos =
          _processarSnapshot(courseEvent.snapshot, Course.fromSnapshot);
      final List<Discipline> disciplinas = // <-- CORRIGIDO
          _processarSnapshot(subjectEvent.snapshot, Discipline.fromSnapshot);
      final List<Content> conteudos =
          _processarSnapshot(contentEvent.snapshot, Content.fromSnapshot);

      if (mounted) {
        setState(() {
          _cursos = cursos;
          _disciplinas = disciplinas; // <-- CORRIGIDO
          _conteudos = conteudos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MessageUtils.mostrarErro(context, 'Erro ao carregar dados: $e');
        print('Erro detalhado ao carregar dados: $e'); // Para depuração
      }
    }
  }

  /// Filtra a lista de Conteúdos com base na Disciplina (Discipline)
  void _atualizarConteudos(String? novoIdDisciplina) { // <-- CORRIGIDO
    setState(() {
      _disciplinaSelecionada = novoIdDisciplina; // <-- CORRIGIDO
      _conteudoSelecionado = null; 
      if (novoIdDisciplina == null) { // <-- CORRIGIDO
        _conteudosFiltrados = [];
      } else {
        // Filtra Conteúdos pelo 'subjectId' (ID da Disciplina)
        _conteudosFiltrados = _conteudos
            .where((conteudo) => conteudo.subjectId == novoIdDisciplina) // <-- CORRIGIDO
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _instrucoesController.dispose();
    super.dispose();
  }

  /// Valida se todos os campos obrigatórios foram preenchidos
  bool _validarFormulario() {
    if (_cursoSelecionado == null) {
      MessageUtils.mostrarErro(context, 'Selecione um curso');
      return false;
    }
    if (_disciplinaSelecionada == null) { // <-- CORRIGIDO
      MessageUtils.mostrarErro(context, 'Selecione uma disciplina'); // <-- CORRIGIDO
      return false;
    }
    if (_tituloController.text.trim().isEmpty) {
      MessageUtils.mostrarErro(context, 'Digite um título para a prova');
      return false;
    }
    if (_instrucoesController.text.trim().isEmpty) {
      MessageUtils.mostrarErro(context, 'Digite as instruções da prova');
      return false;
    }
    return true;
  }

  /// Navega para a tela de seleção de questões
  Future<void> _selecionarQuestoes() async {
    if (!_validarFormulario()) return;

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarQuestoesScreen(
          // Passa os IDs com os nomes corretos dos models:
          subjectId: _disciplinaSelecionada!, // <-- CORRIGIDO
          contentId: _conteudoSelecionado, 
          tituloProva: _tituloController.text.trim(),
          instrucoesProva: _instrucoesController.text.trim(),
        ),
      ),
    );

    if (resultado != null && resultado is Map<String, dynamic>) {
      await _criarProvaComQuestoes(resultado);
    }
  }

  /// Cria a prova com as questões selecionadas
  Future<void> _criarProvaComQuestoes(Map<String, dynamic> dados) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final questoesMaps = dados['questoes'] as List<Map<String, dynamic>>;

      // ETAPA 1: Criar a "casca" da prova
      final String? exameId = await _examService.createExam(
        title: dados['titulo'],
        instructions: dados['instrucoes'],
        subjectId: _disciplinaSelecionada, // 'subjectId' é o ID da Disciplina
      );

      if (exameId == null) {
        throw Exception('Não foi possível obter o ID da nova prova.');
      }

      // ETAPA 2: Salvar o ID do curso na prova (como pedido)
      await _examService.updateExam(exameId, {
        'courseId': _cursoSelecionado,
      });

      // ETAPA 3: Adicionar as questões à prova, uma por uma
      bool allQuestionsAdded = true;
      for (int i = 0; i < questoesMaps.length; i++) {
        final questaoMap = questoesMaps[i];
        final String questionId = questaoMap['id'];
        final int order = i + 1;
        final double peso =
            questaoMap['peso'] ?? 0.0; // Pega o peso do map

        // Chama o service com o 'peso'
        final bool success = await _examService.addQuestionToExam(
          examId: exameId,
          questionId: questionId,
          number: order,
          peso: peso, 
          suggestedLines: null,
        );

        if (!success) {
          allQuestionsAdded = false;
        }
      }

      if (allQuestionsAdded) {
        MessageUtils.mostrarSucesso(
          context,
          'Prova criada com sucesso com ${questoesMaps.length} questões!',
        );
      } else {
        MessageUtils.mostrarErro(
          context,
          'Prova criada, mas algumas questões falharam ao ser adicionadas.',
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      MessageUtils.mostrarErro(context, 'Erro ao criar prova: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildContainer({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height ?? 50,
      decoration: BoxDecoration(
        color: _whiteColor,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: 100,
            decoration: const BoxDecoration(
              color: _primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 8),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 196,
                    height: 67,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 196,
                        height: 67,
                        decoration: BoxDecoration(
                          color: _whiteColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'LOGO',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: _whiteColor,
                        size: 28,
                      ),
                      tooltip: 'Voltar',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Conteúdo principal
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryColor))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Criar Nova Prova',
                            style: TextStyle(
                              color: _textColor,
                              fontFamily: 'Inter-Bold',
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Campo Título da Prova
                        const Text(
                          'Título da Prova',
                          style: TextStyle(
                            color: _textColor,
                            fontFamily: 'Inter-Bold',
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildContainer(
                          height: 50,
                          child: TextField(
                            controller: _tituloController,
                            decoration: const InputDecoration(
                              hintText: 'Digite o título da prova',
                              hintStyle: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Campo de instruções
                        const Text(
                          'Instruções',
                          style: TextStyle(
                            color: _textColor,
                            fontFamily: 'Inter-Bold',
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildContainer(
                          height: 100,
                          child: TextField(
                            controller: _instrucoesController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Digite as instruções da prova',
                              hintStyle: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // *** CAMPO CURSO ***
                        const Text(
                          'Curso (Obrigatório)',
                          style: TextStyle(
                            color: _textColor,
                            fontFamily: 'Inter-Bold',
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildContainer(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _cursoSelecionado,
                              hint: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Selecione o curso',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                              items: _cursos.map((Course curso) {
                                return DropdownMenuItem<String>(
                                  value: curso.id,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(curso.name),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                // CORREÇÃO: Apenas define o estado
                                setState(() {
                                  _cursoSelecionado = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // *** CAMPO DISCIPLINA ***
                        const Text(
                          'Disciplina (Obrigatório)', // <-- CORRIGIDO
                          style: TextStyle(
                            color: _textColor,
                            fontFamily: 'Inter-Bold',
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildContainer(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _disciplinaSelecionada, // <-- CORRIGIDO
                              hint: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Selecione a disciplina', // <-- CORRIGIDO
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                              // CORREÇÃO: Popula com a lista completa de disciplinas
                              items: _disciplinas.map((Discipline disciplina) { // <-- CORRIGIDO
                                return DropdownMenuItem<String>(
                                  value: disciplina.id, // <-- CORRIGIDO
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(disciplina.name), // <-- CORRIGIDO
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                _atualizarConteudos(newValue);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // *** CAMPO CONTEÚDO ***
                        const Text(
                          'Conteúdo (Opcional)',
                          style: TextStyle(
                            color: _textColor,
                            fontFamily: 'Inter-Bold',
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildContainer(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _conteudoSelecionado,
                              hint: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  _disciplinaSelecionada == null // <-- CORRIGIDO
                                      ? 'Selecione uma disciplina primeiro' // <-- CORRIGIDO
                                      : 'Selecione o conteúdo (se houver)',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                              // Popula com a lista de conteúdos filtrados
                              items:
                                  _conteudosFiltrados.map((Content conteudo) {
                                return DropdownMenuItem<String>(
                                  value: conteudo.id,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(conteudo.description),
                                  ),
                                );
                              }).toList(),
                              onChanged: _disciplinaSelecionada != null // <-- CORRIGIDO
                                  ? (String? newValue) {
                                      setState(() {
                                        _conteudoSelecionado = newValue;
                                      });
                                    }
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Botão de Ação
                        Center(
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _selecionarQuestoes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: _whiteColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'Selecionar Questões',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}