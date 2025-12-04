import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// Imports dos Models
import 'package:prova/models/exam_model.dart';
import 'package:prova/models/course_model.dart';
import 'package:prova/models/discipline_model.dart';
import 'package:prova/models/content_model.dart';
import 'package:prova/models/exam_question_link_model.dart';

// Imports dos Services
import 'package:prova/services/exam_service.dart';
import 'package:prova/services/course_service.dart';
import 'package:prova/services/subject_service.dart';
import 'package:prova/services/content_service.dart';

// Imports de UI e Utils
import 'package:prova/utils/message_utils.dart';
import 'package:prova/core/app_colors.dart';
import 'package:prova/core/app_constants.dart';
import 'package:prova/screens/professor/criar_prova/selecionar_questoes_screen.dart';

class EditarProvaScreen extends StatefulWidget {
  // Recebe a prova que será editada
  final Exam prova;

  const EditarProvaScreen({super.key, required this.prova});

  @override
  State<EditarProvaScreen> createState() => _EditarProvaScreenState();
}

class _EditarProvaScreenState extends State<EditarProvaScreen> {
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
  String? _disciplinaSelecionada;
  List<String> _conteudosSelecionados = [];

  // Guarda o ID original para lógica de seleção de questões
  late String _disciplinaOriginalId;

  // Listas de dados (models)
  List<Course> _cursos = [];
  List<Discipline> _disciplinas = [];
  List<Content> _conteudos = [];

  // Listas filtradas para os dropdowns
  List<Content> _conteudosFiltrados = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _preencherDadosIniciais();
    _carregarDados();
  }

  /// Pré-preenche os campos com os dados da prova existente
  void _preencherDadosIniciais() {
    final prova = widget.prova;
    _tituloController.text = prova.title;
    _instrucoesController.text = prova.instructions;
    _cursoSelecionado = prova.courseId;
    _disciplinaSelecionada = prova.subjectId;
    _conteudosSelecionados = List<String>.from(prova.contentIds);

    // Salva o ID original
    _disciplinaOriginalId = prova.subjectId;
  }

  /// Helper para processar o DatabaseEvent
  List<T> _processarSnapshot<T>(
    DataSnapshot snapshot,
    T Function(DataSnapshot) fromSnapshot,
  ) {
    final list = <T>[];
    if (snapshot.exists && snapshot.value != null) {
      final data = snapshot.value;
      if (data is Map) {
        for (final childSnapshot in snapshot.children) {
          try {
            list.add(fromSnapshot(childSnapshot));
          } catch (e) {
            print('Erro ao processar item ${childSnapshot.key}: $e');
          }
        }
      }
    }
    return list;
  }

  /// Carrega Cursos, Disciplinas e Conteúdos do Firebase
  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final cursosStream = _courseService.getCoursesStream();
      final disciplinasStream = _subjectService.getSubjectsStream();
      final conteudosStream = _contentService.getContentStream();

      final results = await Future.wait([
        cursosStream.first,
        disciplinasStream.first,
        conteudosStream.first,
      ]);

      final DatabaseEvent courseEvent = results[0];
      final DatabaseEvent subjectEvent = results[1];
      final DatabaseEvent contentEvent = results[2];

      final List<Course> cursos = _processarSnapshot(
        courseEvent.snapshot,
        Course.fromSnapshot,
      );
      final List<Discipline> disciplinas = _processarSnapshot(
        subjectEvent.snapshot,
        Discipline.fromSnapshot,
      );
      final List<Content> conteudos = _processarSnapshot(
        contentEvent.snapshot,
        Content.fromSnapshot,
      );

      if (mounted) {
        setState(() {
          _cursos = cursos;
          _disciplinas = disciplinas;
          _conteudos = conteudos;
          _isLoading = false;
        });
        // Atualiza a lista de conteúdos com base na disciplina já selecionada
        _atualizarConteudos(_disciplinaSelecionada, manterSelecao: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  /// Filtra a lista de Conteúdos com base na Disciplina
  void _atualizarConteudos(
    String? novoIdDisciplina, {
    bool manterSelecao = false,
  }) {
    setState(() {
      _disciplinaSelecionada = novoIdDisciplina;

      // Se a disciplina mudou (e não é a carga inicial), limpa os conteúdos
      if (!manterSelecao) {
        _conteudosSelecionados.clear();
      }

      if (novoIdDisciplina == null) {
        _conteudosFiltrados = [];
      } else {
        _conteudosFiltrados = _conteudos
            .where((conteudo) => conteudo.subjectId == novoIdDisciplina)
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
    if (_disciplinaSelecionada == null) {
      MessageUtils.mostrarErro(context, 'Selecione uma disciplina');
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

  /// Navega para a tela de seleção de questões (modo edição)
  Future<void> _editarQuestoes() async {
    if (!_validarFormulario()) return;

    // Verifica se a disciplina foi alterada
    final bool disciplinaMudou =
        _disciplinaSelecionada != _disciplinaOriginalId;

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarQuestoesScreen(
          subjectId: _disciplinaSelecionada!,
          contentIds: _conteudosSelecionados.isEmpty
              ? null
              : List.from(_conteudosSelecionados),
          tituloProva: _tituloController.text.trim(),
          instrucoesProva: _instrucoesController.text.trim(),

          // Se a disciplina mudou, passa uma lista vazia para forçar nova seleção
          // Se não mudou, passa as questões originais
          questoesIniciais: disciplinaMudou
              ? []
              : List<ExamQuestionLink>.from(widget.prova.questions),
        ),
      ),
    );

    // Se o usuário concluiu a seleção (resultado != null)
    if (resultado != null && resultado is Map<String, dynamic>) {
      await _salvarAlteracoes(resultado);
    }
  }

  /// Salva as alterações da prova no Firebase
  Future<void> _salvarAlteracoes(Map<String, dynamic> dados) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final questoesMaps = dados['questoes'] as List<Map<String, dynamic>>;

      // ETAPA 1: Criar o mapa de dados para atualização
      final Map<String, dynamic> updateData = {
        'title': dados['titulo'],
        'instructions': dados['instrucoes'],
        'subjectId': _disciplinaSelecionada,
        'courseId': _cursoSelecionado,
        'contentIds': _conteudosSelecionados,
      };

      // ETAPA 2: Processar a nova lista de questões
      final Map<String, dynamic> novasQuestoesMap = {};
      for (int i = 0; i < questoesMaps.length; i++) {
        final questaoMap = questoesMaps[i];
        final String questionId = questaoMap['id'];
        final int order = i + 1;
        final double peso = questaoMap['peso'] ?? 0.0;

        novasQuestoesMap[questionId] = {
          'number': order,
          'peso': peso,
          'suggestedLines': null, // (ou pegar de questaoMap se existir)
        };
      }

      updateData['questions'] = novasQuestoesMap;

      // ETAPA 3: Chamar o serviço de atualização
      await _examService.updateExam(widget.prova.id!, updateData);

      // Se a disciplina mudou, atualiza o ID original para a próxima edição
      _disciplinaOriginalId = _disciplinaSelecionada!;

      // Retorna 'true' para a tela anterior (ProvasGeradasScreen)
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErroFormatado(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Construtor de Container (copiado de criar_prova_screen)
  Widget _buildContainer({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height,
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
                    child: CircularProgressIndicator(color: _primaryColor),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Editar Prova', // *** TÍTULO ALTERADO ***
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
                            controller: _tituloController, // Pré-preenchido
                            decoration: const InputDecoration(
                              hintText: 'Digite o título da prova',
                              hintStyle: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
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
                            controller: _instrucoesController, // Pré-preenchido
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
                          height: 50, // Altura fixa para dropdown
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              // Tipo anulável
                              isExpanded: true,
                              value: _cursoSelecionado, // Pré-preenchido
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
                                return DropdownMenuItem<String?>(
                                  // Tipo anulável
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
                          'Disciplina (Obrigatório)',
                          style: TextStyle(
                            color: _textColor,
                            fontFamily: 'Inter-Bold',
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildContainer(
                          height: 50, // Altura fixa para dropdown
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              // Tipo anulável
                              isExpanded: true,
                              value: _disciplinaSelecionada, // Pré-preenchido
                              hint: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Selecione a disciplina',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                              items: _disciplinas.map((Discipline disciplina) {
                                return DropdownMenuItem<String?>(
                                  // Tipo anulável
                                  value: disciplina.id,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(disciplina.name),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                // Atualiza os conteúdos (sem manter a seleção, pois a disciplina mudou)
                                _atualizarConteudos(
                                  newValue,
                                  manterSelecao: false,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // *** CAMPO CONTEÚDO (MÚLTIPLA SELEÇÃO) ***
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
                          // A altura agora é nula (automática) para o ExpansionTile
                          height: null,
                          child: ExpansionTile(
                            title: Text(
                              _conteudosSelecionados.isEmpty
                                  ? (_disciplinaSelecionada == null
                                        ? 'Selecione uma disciplina primeiro'
                                        : 'Selecione os conteúdos (opcional)')
                                  : '${_conteudosSelecionados.length} conteúdo(s) selecionado(s)',
                              style: TextStyle(
                                color:
                                    _conteudosSelecionados.isEmpty &&
                                        _disciplinaSelecionada != null
                                    ? Colors.black54
                                    : (_disciplinaSelecionada == null
                                          ? Colors.grey
                                          : _textColor),
                                fontSize: 16,
                                fontWeight: _conteudosSelecionados.isEmpty
                                    ? FontWeight.w300
                                    : FontWeight.normal,
                              ),
                            ),

                            children: _disciplinaSelecionada == null
                                ? []
                                : _conteudosFiltrados
                                      .where((c) => c.id != null)
                                      .map((Content conteudo) {
                                        final String contentId = conteudo.id!;

                                        return CheckboxListTile(
                                          title: Text(conteudo.description),
                                          value: _conteudosSelecionados
                                              .contains(
                                                contentId,
                                              ), // Pré-preenchido
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                _conteudosSelecionados.add(
                                                  contentId,
                                                );
                                              } else {
                                                _conteudosSelecionados.remove(
                                                  contentId,
                                                );
                                              }
                                            });
                                          },
                                        );
                                      })
                                      .toList(),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Botão de Ação
                        Center(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : _editarQuestoes, // Chama _editarQuestoes
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
                              'Editar Questões Selecionadas', // *** TEXTO ALTERADO ***
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
