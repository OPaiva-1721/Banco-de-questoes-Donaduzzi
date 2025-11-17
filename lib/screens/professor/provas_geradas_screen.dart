import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

// Imports do projeto
import 'package:prova/services/exam_service.dart';
import 'package:prova/services/pdf_service.dart';
import 'package:prova/models/exam_model.dart';
import 'package:prova/utils/message_utils.dart';
import 'package:prova/core/app_colors.dart';
import 'package:prova/core/exceptions/app_exceptions.dart';
import 'package:prova/services/course_service.dart';
import 'package:prova/models/course_model.dart';
import 'package:prova/services/subject_service.dart';
import 'package:prova/models/discipline_model.dart';

// Imports para o filtro de conteúdo
import 'package:prova/services/content_service.dart';
import 'package:prova/models/content_model.dart';

import 'package:prova/screens/professor/editar_prova_screen.dart';

class ProvasGeradasScreen extends StatefulWidget {
  const ProvasGeradasScreen({super.key});

  @override
  State<ProvasGeradasScreen> createState() => _ProvasGeradasScreenState();
}

class _ProvasGeradasScreenState extends State<ProvasGeradasScreen> {
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

  bool _isLoading = true;

  // Listas Master e Filtrada
  List<Exam> _provasMaster = []; // Guarda todas as provas
  List<Exam> _provasFiltradas = []; // Guarda as provas para exibição

  // Mapas para consulta de nomes (para o PDF e Filtros)
  Map<String, Course> _cursosMap = {};
  Map<String, Discipline> _disciplinasMap = {};
  Map<String, Content> _conteudosMap = {};

  // Listas de dados para popular os filtros
  List<Course> _todosCursos = [];
  List<Discipline> _todasDisciplinas = [];
  List<Content> _todosConteudos = [];

  // Estados para os Filtros
  String? _filtroCursoId;
  String? _filtroDisciplinaId;
  final TextEditingController _autorController = TextEditingController();
  final TextEditingController _numQuestoesController = TextEditingController();
  List<String> _filtroConteudosSelecionados = []; // Filtro de multi-seleção

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _autorController.dispose();
    _numQuestoesController.dispose();
    super.dispose();
  }

  // Helper para processar dados do Firebase
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
            // Se um item falhar na conversão (ex: erro de tipo), loga e continua
            print('Erro ao processar item ${childSnapshot.key}: $e');
          }
        }
      }
    }
    return list;
  }

  // Carrega todos os dados (Provas, Cursos, Disciplinas, Conteúdos)
  Future<void> _carregarDados() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final examsStream = _examService.getExamsStream();
      final coursesStream = _courseService.getCoursesStream();
      final subjectsStream = _subjectService.getSubjectsStream();
      final contentsStream = _contentService.getContentStream();

      final results = await Future.wait([
        examsStream.first,
        coursesStream.first,
        subjectsStream.first,
        contentsStream.first,
      ]);

      final DatabaseEvent examsEvent = results[0];
      final DatabaseEvent coursesEvent = results[1];
      final DatabaseEvent subjectsEvent = results[2];
      final DatabaseEvent contentsEvent = results[3];

      // Processa com o helper que agora ignora itens com erro
      final List<Exam> tempProvas = _processarSnapshot(
        examsEvent.snapshot,
        Exam.fromSnapshot,
      );
      final List<Course> tempCourses = _processarSnapshot(
        coursesEvent.snapshot,
        Course.fromSnapshot,
      );
      final List<Discipline> tempSubjects = _processarSnapshot(
        subjectsEvent.snapshot,
        Discipline.fromSnapshot,
      );
      final List<Content> tempContents = _processarSnapshot(
        contentsEvent.snapshot,
        Content.fromSnapshot,
      );

      // Cria os mapas de consulta
      final Map<String, Course> tempCursosMap = {
        for (var c in tempCourses.where((c) => c.id != null)) c.id!: c,
      };
      final Map<String, Discipline> tempDisciplinasMap = {
        for (var d in tempSubjects.where((d) => d.id != null)) d.id!: d,
      };
      final Map<String, Content> tempConteudosMap = {
        for (var c in tempContents.where((c) => c.id != null)) c.id!: c,
      };

      // Ordena as provas
      tempProvas.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _provasMaster = tempProvas;
          _cursosMap = tempCursosMap;
          _disciplinasMap = tempDisciplinasMap;
          _conteudosMap = tempConteudosMap;
          _todosCursos = tempCourses;
          _todasDisciplinas = tempSubjects;
          _todosConteudos = tempContents;
          _isLoading = false;
        });
        _aplicarFiltros(); // Aplica os filtros
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MessageUtils.mostrarErroFormatado(context, e);
        print('Erro detalhado ao carregar dados: $e');
      }
    }
  }

  /// Aplica todos os filtros selecionados
  void _aplicarFiltros() {
    List<Exam> filtradas = List.from(_provasMaster);

    final String autor = _autorController.text.trim().toLowerCase();
    final int? numQuestoes = int.tryParse(_numQuestoesController.text.trim());

    if (_filtroCursoId != null) {
      filtradas = filtradas.where((p) => p.courseId == _filtroCursoId).toList();
    }
    if (_filtroDisciplinaId != null) {
      filtradas = filtradas
          .where((p) => p.subjectId == _filtroDisciplinaId)
          .toList();
    }
    if (autor.isNotEmpty) {
      filtradas = filtradas
          .where((p) => p.createdBy.toLowerCase().contains(autor))
          .toList();
    }
    if (numQuestoes != null && numQuestoes > 0) {
      filtradas = filtradas
          .where((p) => p.questions.length == numQuestoes)
          .toList();
    }

    // Filtro de Conteúdo (Multi-Select)
    if (_filtroConteudosSelecionados.isNotEmpty) {
      final Set<String> filtroSet = _filtroConteudosSelecionados.toSet();
      filtradas = filtradas.where((prova) {
        // Mostra a prova se *qualquer* um dos seus contentIds
        // estiver na lista de filtros selecionados.
        return prova.contentIds.any(
          (examContentId) => filtroSet.contains(examContentId),
        );
      }).toList();
    }

    setState(() {
      _provasFiltradas = filtradas;
    });
  }

  /// Limpa todos os filtros e reseta a lista
  void _limparFiltros() {
    setState(() {
      _filtroCursoId = null;
      _filtroDisciplinaId = null;
      _autorController.clear();
      _numQuestoesController.clear();
      _filtroConteudosSelecionados.clear();
      _provasFiltradas = List.from(_provasMaster);
    });
  }

  /// Gera o PDF da prova
  Future<void> _gerarPdf(Exam prova) async {
    final String nomeCurso =
        _cursosMap[prova.courseId]?.name ?? 'Curso não informado';
    final String nomeMateria =
        _disciplinasMap[prova.subjectId]?.name ?? 'Disciplina não informada';

    try {
      await PdfService.gerarProvaPdf(
        prova: prova,
        nomeCurso: nomeCurso,
        nomeMateria: nomeMateria,
      );
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  /// Navega para a tela de edição
  Future<void> _editarProva(Exam prova) async {
    final bool? foiAtualizado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarProvaScreen(prova: prova)),
    );

    // Se a tela de edição retornar 'true', atualiza a lista
    if (foiAtualizado == true && mounted) {
      MessageUtils.mostrarSucesso(context, 'Prova atualizada com sucesso!');
      _carregarDados(); // Recarrega os dados e aplica filtros
    }
  }

  /// Deleta a prova (com confirmação)
  Future<void> _deletarProva(String provaId) async {
    final bool? confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza de que deseja deletar esta prova?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _examService.deleteExam(provaId);
        if (mounted) {
          MessageUtils.mostrarSucesso(context, 'Prova deletada com sucesso');
          _carregarDados(); // Recarrega os dados e aplica filtros
        }
      } catch (e) {
        if (mounted) {
          MessageUtils.mostrarErroFormatado(context, e);
        }
      }
    }
  }

  // Helper para buscar os nomes dos conteúdos
  String _getNomesConteudos(List<String> contentIds) {
    if (contentIds.isEmpty) {
      return 'Não especificado';
    }
    List<String> nomes = [];
    for (String id in contentIds) {
      nomes.add(_conteudosMap[id]?.description ?? 'ID:$id');
    }
    return nomes.join(', ');
  }

  // Card da prova (Mostrando os conteúdos)
  Widget _buildProvaCard(Exam prova) {
    final String nomeAutor = prova.createdBy.isNotEmpty
        ? prova.createdBy
        : 'Autor desconhecido';
    final String nomeCurso = _cursosMap[prova.courseId]?.name ?? '...';
    final String nomeMateria = _disciplinasMap[prova.subjectId]?.name ?? '...';
    final String nomesConteudos = _getNomesConteudos(prova.contentIds);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prova.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Criado por: $nomeAutor',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Curso: $nomeCurso',
                    style: const TextStyle(fontSize: 14, color: _textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Disciplina: $nomeMateria',
                    style: const TextStyle(fontSize: 14, color: _textColor),
                  ),
                  const SizedBox(height: 4),
                  // Mostra os conteúdos
                  Text(
                    'Conteúdos: $nomesConteudos',
                    style: const TextStyle(fontSize: 14, color: _textColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Questões: ${prova.questions.length}',
                    style: const TextStyle(fontSize: 14, color: _textColor),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.picture_as_pdf,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _gerarPdf(prova),
                  tooltip: 'Gerar PDF',
                ),

                // *** BOTÃO DE EDITAR ADICIONADO AQUI ***
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () => _editarProva(prova),
                  tooltip: 'Editar Prova',
                ),

                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deletarProva(prova.id!),
                  tooltip: 'Deletar Prova',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Painel de Filtros (Com Multi-Select de Conteúdo)
  Widget _buildFiltrosWidget() {
    // Filtra a lista de conteúdos para o dropdown
    final List<Content> conteudosParaFiltro = _filtroDisciplinaId == null
        ? _todosConteudos
        : _todosConteudos
              .where((c) => c.subjectId == _filtroDisciplinaId)
              .toList();

    return Container(
      color: _whiteColor,
      child: ExpansionTile(
        title: const Text(
          'Filtros de Busca',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: const Icon(Icons.filter_list),
        children: [
          // --- INÍCIO DA CORREÇÃO (VERTICAL + HORIZONTAL) ---
          Container(
            // 1. Limita a altura da área de filtros
            constraints: const BoxConstraints(
              maxHeight: 350, // Altura máxima de 350px
            ),
            child: SingleChildScrollView(
              // 2. Faz a área de filtros rolar
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize
                      .min, // Importante para o SingleChildScrollView
                  children: [
                    // Filtro Curso
                    DropdownButtonFormField<String?>(
                      value: _filtroCursoId,
                      isExpanded: true,
                      hint: const Text('Filtrar por Curso'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: _todosCursos.map((Course curso) {
                        return DropdownMenuItem<String?>(
                          value: curso.id,
                          child: Text(curso.name),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _filtroCursoId = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Filtro Disciplina
                    DropdownButtonFormField<String?>(
                      value: _filtroDisciplinaId,
                      isExpanded: true,
                      hint: const Text('Filtrar por Disciplina'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: _todasDisciplinas.map((Discipline disciplina) {
                        return DropdownMenuItem<String?>(
                          value: disciplina.id,
                          child: Text(disciplina.name),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _filtroDisciplinaId = newValue;
                          _filtroConteudosSelecionados.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Filtro de Conteúdo (Multi-Select)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          _filtroConteudosSelecionados.isEmpty
                              ? 'Filtrar por Conteúdo (Nenhum)'
                              : 'Filtrar por Conteúdo (${_filtroConteudosSelecionados.length} sel.)',
                          style: TextStyle(
                            color: _filtroDisciplinaId == null
                                ? Colors.grey
                                : _textColor,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: _filtroDisciplinaId == null
                            ? const Text(
                                'Selecione uma disciplina primeiro',
                                style: TextStyle(color: Colors.grey),
                              )
                            : null,
                        children: conteudosParaFiltro.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Nenhum conteúdo para esta disciplina.',
                                  ),
                                ),
                              ]
                            : conteudosParaFiltro.where((c) => c.id != null).map((
                                content,
                              ) {
                                final String contentId = content.id!;

                                return CheckboxListTile(
                                  // 3. Apenas o Text. O ListTile/Column vai
                                  // gerenciar a quebra de linha automaticamente.
                                  title: Text(content.description),
                                  value: _filtroConteudosSelecionados.contains(
                                    contentId,
                                  ),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _filtroConteudosSelecionados.add(
                                          contentId,
                                        );
                                      } else {
                                        _filtroConteudosSelecionados.remove(
                                          contentId,
                                        );
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                        onExpansionChanged: _filtroDisciplinaId == null
                            ? (_) {}
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filtro Autor
                    TextField(
                      controller: _autorController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Filtrar por quem criou',
                        hintText: 'Nome do autor...',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filtro Número de Questões
                    TextField(
                      controller: _numQuestoesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Nº exato de questões',
                        hintText: 'Ex: 10',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botões
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: _limparFiltros,
                          child: const Text('Limpar Filtros'),
                        ),
                        ElevatedButton(
                          onPressed: _aplicarFiltros,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: _whiteColor,
                          ),
                          child: const Text('Aplicar Filtros'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // --- FIM DA CORREÇÃO ---
        ],
      ),
    );
  }

  /// Lógica do corpo da lista
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (_provasMaster.isEmpty) {
      return RefreshIndicator(
        onRefresh: _carregarDados,
        color: _primaryColor,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Text(
                'Nenhuma prova gerada ainda.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    }

    if (_provasFiltradas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Nenhuma prova encontrada para os filtros aplicados.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarDados,
      color: _primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: _provasFiltradas.length,
        itemBuilder: (context, index) {
          final prova = _provasFiltradas[index];
          return _buildProvaCard(prova);
        },
      ),
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

          // Título da Página
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Provas Geradas',
              style: TextStyle(
                color: _textColor,
                fontFamily: 'Inter-Bold',
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Painel de Filtros
          _buildFiltrosWidget(),

          // Conteúdo principal (Lista)
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
