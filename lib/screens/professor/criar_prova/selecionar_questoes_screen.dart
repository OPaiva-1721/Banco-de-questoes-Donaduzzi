import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // NECESSÁRIO PARA CARREGAR CONTEÚDOS
import '/models/question_model.dart';
import '/models/option_model.dart';
import '/models/enums.dart';
import '/models/content_model.dart'; 
import '/services/question_service.dart';
import '/services/content_service.dart'; 
import '/utils/message_utils.dart';
import '/core/app_colors.dart';
import '/core/app_constants.dart';
import '/models/exam_question_link_model.dart'; 

class SelecionarQuestoesScreen extends StatefulWidget {
  final String subjectId;
  
  // Recebe uma LISTA de IDs de conteúdo, que pode ser nula
  final List<String>? contentIds;
  
  final String tituloProva;
  final String instrucoesProva;

  /// Lista de questões já vinculadas à prova (para edição)
  final List<ExamQuestionLink>? questoesIniciais;

  const SelecionarQuestoesScreen({
    super.key,
    required this.subjectId,
    this.contentIds,
    required this.tituloProva,
    required this.instrucoesProva,
    this.questoesIniciais, 
  });

  @override
  State<SelecionarQuestoesScreen> createState() =>
      _SelecionarQuestoesScreenState();
}

class _SelecionarQuestoesScreenState extends State<SelecionarQuestoesScreen> {
  // Constantes
  static const Color _primaryColor = AppColors.primary;
  static const Color _backgroundColor = AppColors.background;
  static const Color _textColor = AppColors.text;
  static const Color _whiteColor = AppColors.white;

  // Serviços
  final QuestionService _questionService = QuestionService();
  final ContentService _contentService = ContentService(); // NOVO SERVIÇO

  // Listas de Questões
  List<Question> _questoes = []; // Lista principal (master)
  List<Question> _questoesFiltradas = []; // Lista para exibição (filtrada)

  // Estado
  bool _isLoading = true;
  final Map<String, Map<String, dynamic>> _questoesSelecionadas = {};

  // Controladores e estado para filtros
  final TextEditingController _filtroTextoController = TextEditingController();
  QuestionDifficulty? _filtroDificuldade;
  
  // --- NOVOS ESTADOS PARA O FILTRO DE CONTEÚDO ---
  String? _filtroConteudo; // Guarda o ID do conteúdo selecionado no filtro
  List<Content> _conteudosParaFiltro = []; // Lista de conteúdos para popular o dropdown
  // --- FIM DOS NOVOS ESTADOS ---


  // Armazena os controllers de peso
  final Map<String, TextEditingController> _pesoControllers = {};

  // Contadores e Limites
  double _pesoTotal = 0.0;
  final double _pesoMaximo = 100.0;
  final int _limiteQuestoes = 10;

  @override
  void initState() {
    super.initState();
    _carregarQuestoes();
    _filtroTextoController.addListener(_filtrarQuestoes);
  }

  @override
  void dispose() {
    _filtroTextoController.dispose();
    for (var controller in _pesoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Carrega as questões E os conteúdos do Firebase
  Future<void> _carregarQuestoes() async {
    setState(() => _isLoading = true);
    try {
      // 1. Carregar Questões (lógica existente)
      final stream = _questionService.getQuestionsBySubjectStream(widget.subjectId);
      final List<Question> questoesDaDisciplina = await stream.first;

      // 2. Carregar TODOS os Conteúdos (para pegar as descrições)
      final contentStream = _contentService.getContentStream();
      final DatabaseEvent contentEvent = await contentStream.first;
      
      final List<Content> todosConteudosList = [];
      if (contentEvent.snapshot.exists && contentEvent.snapshot.value != null) {
          final data = contentEvent.snapshot.value;
          if (data is Map) {
              for (final childSnapshot in contentEvent.snapshot.children) {
                  try {
                      todosConteudosList.add(Content.fromSnapshot(childSnapshot));
                  } catch (e) {
                      print('Erro ao processar conteúdo: $e'); // Log de erro
                  }
              }
          }
      }

      // 3. Filtrar Questões (Master List)
      final List<Question> tempQuestoes;
      final Set<String> contentIdSet = (widget.contentIds != null && widget.contentIds!.isNotEmpty)
          ? widget.contentIds!.toSet()
          : {};

      if (contentIdSet.isNotEmpty) {
        // Filtra pelas IDs de conteúdo selecionadas na tela anterior
        tempQuestoes = questoesDaDisciplina
            .where((q) => contentIdSet.contains(q.contentId))
            .toList();
      } else {
        // Se nenhuma ID de conteúdo foi passada, usa todas as questões da disciplina
        tempQuestoes = questoesDaDisciplina;
      }
      
      // 4. Filtrar Conteúdos (Para popular o Dropdown de Filtro)
      // Pega o conjunto de IDs de conteúdo que estão *realmente* presentes nas questões carregadas.
      final Set<String> idsDeConteudosDasQuestoes = tempQuestoes.map((q) => q.contentId).toSet();
      
      final List<Content> tempConteudosParaFiltro = todosConteudosList
          .where((c) => c.id != null && idsDeConteudosDasQuestoes.contains(c.id!))
          .toList();


      // 5. Inicializar Controladores de Peso (lógica existente)
      for (var controller in _pesoControllers.values) {
        controller.dispose();
      }
      _pesoControllers.clear();

      for (var questao in tempQuestoes) {
        if (questao.id != null) {
          _pesoControllers[questao.id!] = TextEditingController(text: '1.0');
        }
      }

      if (mounted) {
        setState(() {
          _questoes = tempQuestoes;
          _conteudosParaFiltro = tempConteudosParaFiltro; // Salva os conteúdos para o filtro
          _filtrarQuestoes();
          _isLoading = false;

          _preencherQuestoesIniciais();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  /// Pré-preenche as questões selecionadas e pesos (modo de edição)
  void _preencherQuestoesIniciais() {
    if (widget.questoesIniciais == null || widget.questoesIniciais!.isEmpty) {
      return;
    }

    // Pega os IDs das questões que foram carregadas nesta tela
    final Set<String> idsQuestoesCarregadas = _questoes.map((q) => q.id!).toSet();

    for (final link in widget.questoesIniciais!) {
      // Verifica se a questão inicial ainda existe e pertence a esta disciplina/conteúdo
      if (idsQuestoesCarregadas.contains(link.questionId)) {
        
        // Adiciona ao mapa de selecionadas
        _questoesSelecionadas[link.questionId] = {
          'id': link.questionId,
          'peso': link.weight,
          // Busca a questão completa na lista carregada
          'questao': _questoes.firstWhere((q) => q.id == link.questionId).toJson(),
        };

        // Atualiza o controlador de peso correspondente
        if (_pesoControllers.containsKey(link.questionId)) {
          _pesoControllers[link.questionId]!.text = link.weight.toString();
        }
      }
    }

    // Recalcula o peso total e atualiza a UI
    setState(() {
      _calcularPesoTotal();
    });
  }

  /// Calcula peso total
  void _calcularPesoTotal() {
    double total = 0.0;
    for (var item in _questoesSelecionadas.values) {
      total += (item['peso'] as num?)?.toDouble() ?? 0.0;
    }
    setState(() {
      _pesoTotal = total;
    });
  }

  /// Lógica de filtragem (AGORA COM FILTRO DE CONTEÚDO)
  void _filtrarQuestoes() {
    List<Question> filtradas = List.from(_questoes);
    final String texto = _filtroTextoController.text.toLowerCase().trim();

    // 1. Filtro por Texto
    if (texto.isNotEmpty) {
      filtradas = filtradas
          .where((q) => q.questionText.toLowerCase().contains(texto))
          .toList();
    }

    // 2. NOVO FILTRO DE CONTEÚDO
    if (_filtroConteudo != null) {
      filtradas = filtradas
          .where((q) => q.contentId == _filtroConteudo)
          .toList();
    }

    // 3. Filtro por Dificuldade
    if (_filtroDificuldade != null) {
      filtradas = filtradas
          .where((q) => q.difficulty == _filtroDificuldade)
          .toList();
    }

    setState(() {
      _questoesFiltradas = filtradas;
    });
  }

  /// Helper para converter enum de dificuldade para String
  String _difficultyToString(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 'Fácil';
      case QuestionDifficulty.medium:
        return 'Média';
      case QuestionDifficulty.hard:
        return 'Difícil';
    }
  }

  /// Helper para construir o Chip de Dificuldade
  Widget _buildDificuldadeChip(QuestionDifficulty difficulty) {
    Color chipColor;
    Color textColor;

    switch (difficulty) {
      case QuestionDifficulty.easy:
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case QuestionDifficulty.medium:
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case QuestionDifficulty.hard:
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
    }
    return Chip(
      label: Text(
        _difficultyToString(difficulty),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: textColor,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      side: BorderSide.none,
    );
  }

  /// Helper para construir o item da alternativa/opção
  Widget _buildOpcaoItem(Option option) {
    final bool isCorreta = option.isCorrect;
    final IconData icon =
        isCorreta ? Icons.check_circle_outline : Icons.radio_button_unchecked;
    final Color color = isCorreta ? Colors.green.shade700 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              option.text,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: isCorreta ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Adiciona ou remove uma questão da lista de selecionadas
  void _toggleQuestao(Question questao) {
    final String questaoId = questao.id!;
    setState(() {
      if (_questoesSelecionadas.containsKey(questaoId)) {
        _questoesSelecionadas.remove(questaoId);
      } else {
        if (_questoesSelecionadas.length >= _limiteQuestoes) {
          MessageUtils.mostrarErro(
            context,
            'Você pode selecionar no máximo $_limiteQuestoes questões.',
          );
          return;
        }

        double peso =
            double.tryParse(_pesoControllers[questaoId]?.text ?? '1.0') ?? 1.0;
        _questoesSelecionadas[questaoId] = {
          'id': questaoId,
          'peso': peso,
          'questao': questao.toJson(),
        };
      }
      _calcularPesoTotal();
    });
  }

  /// Atualiza o peso de uma questão selecionada
  void _atualizarPeso(String questaoId, String valor) {
    final double? peso = double.tryParse(valor);
    if (peso != null && _questoesSelecionadas.containsKey(questaoId)) {
      setState(() {
        _questoesSelecionadas[questaoId]!['peso'] = peso;
        _calcularPesoTotal();
      });
    }
  }

  /// Finaliza a seleção e retorna para a tela anterior
  void _finalizarSelecao() {
    if (_questoesSelecionadas.isEmpty) {
      MessageUtils.mostrarErro(context, 'Selecione pelo menos uma questão');
      return;
    }

    if (_pesoTotal > _pesoMaximo) {
      MessageUtils.mostrarErro(
          context, 'O peso total não pode exceder $_pesoMaximo pontos.');
      return;
    }

    if (_pesoTotal <= 0) {
      MessageUtils.mostrarErro(
          context, 'O peso total da prova deve ser maior que zero.');
      return;
    }

    for (var item in _questoesSelecionadas.values) {
      if (item['peso'] <= 0) {
        MessageUtils.mostrarErro(context,
            'Todas as questões selecionadas devem ter peso maior que zero.');
        return;
      }
    }

    final List<Map<String, dynamic>> questoesList =
        _questoesSelecionadas.values.toList();

    Navigator.pop(context, {
      'titulo': widget.tituloProva,
      'instrucoes': widget.instrucoesProva,
      'questoes': questoesList,
    });
  }

  /// Constrói o card da questão
  Widget _buildItemQuestao(Question questao, bool selecionada) {
    final controller = _pesoControllers[questao.id!];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: BorderSide(
          color: selecionada ? _primaryColor : Colors.grey.shade300,
          width: selecionada ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        questao.questionText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDificuldadeChip(questao.difficulty),
                    ],
                  ),
                ),
                Checkbox(
                  value: selecionada,
                  onChanged: (bool? value) {
                    _toggleQuestao(questao);
                  },
                  activeColor: _primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (questao.options.isNotEmpty) ...[
              const Divider(height: 16, thickness: 0.5),
              const Text(
                'Alternativas:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 4),
              Column(
                children: questao.options
                    .map((opt) => _buildOpcaoItem(opt))
                    .toList(),
              ),
            ],
            if (selecionada) ...[
              const Divider(height: 16, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Peso da questão: ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: TextField(
                      controller: controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: '1.0',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (valor) {
                        _atualizarPeso(questao.id!, valor);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói o widget de Filtros (COM O NOVO DROPDOWN)
  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Filtro de Texto (Existente)
          TextField(
            controller: _filtroTextoController,
            decoration: InputDecoration(
              hintText: 'Buscar por enunciado...',
              prefixIcon: const Icon(Icons.search, color: _primaryColor),
              suffixIcon: _filtroTextoController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () => _filtroTextoController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: _backgroundColor,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.defaultBorderRadius),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 12),

          // 2. NOVO FILTRO DE CONTEÚDO
          // Só mostra o filtro se houver mais de 1 conteúdo para filtrar
          if (_conteudosParaFiltro.length > 1) ...[
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius:
                    BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String?>( // Tipo anulável
                          isExpanded: true,
                          value: _filtroConteudo,
                          hint: const Text('Filtrar por conteúdo',
                              style: TextStyle(color: Colors.black54)),
                          icon: const Icon(Icons.menu_book, // Ícone de "livro"
                              color: _primaryColor,
                              size: 20),
                          items: _conteudosParaFiltro.map((conteudo) {
                            return DropdownMenuItem<String?>(
                              value: conteudo.id,
                              child: Text(conteudo.description,
                                  overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _filtroConteudo = newValue;
                              _filtrarQuestoes();
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_filtroConteudo != null)
                    IconButton(
                      icon:
                          const Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () {
                        setState(() {
                          _filtroConteudo = null;
                          _filtrarQuestoes();
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // --- FIM DO NOVO FILTRO ---

          // 3. Filtro de Dificuldade (Existente)
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            child: Row( 
              children: [
                Expanded( 
                  child: DropdownButtonHideUnderline(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12), 
                      child: DropdownButton<QuestionDifficulty>(
                        isExpanded: true,
                        value: _filtroDificuldade,
                        hint: const Text('Filtrar por dificuldade',
                            style: TextStyle(color: Colors.black54)),
                        icon:
                            const Icon(Icons.filter_list, color: _primaryColor),
                        items: QuestionDifficulty.values.map((difficulty) {
                          return DropdownMenuItem<QuestionDifficulty>(
                            value: difficulty,
                            child: Text(_difficultyToString(difficulty)),
                          );
                        }).toList(),
                        onChanged: (QuestionDifficulty? newValue) {
                          setState(() {
                            _filtroDificuldade = newValue;
                            _filtrarQuestoes();
                          });
                        },
                      ),
                    ),
                  ),
                ),
                if (_filtroDificuldade != null)
                  IconButton(
                    icon:
                        const Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () {
                      setState(() {
                        _filtroDificuldade = null;
                        _filtrarQuestoes();
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Header com Logo e Contadores
  Widget _buildHeader(BuildContext context) {
    final int totalSelecionadas = _questoesSelecionadas.length;
    final Color pesoColor =
        _pesoTotal > _pesoMaximo ? Colors.red.shade300 : _whiteColor;
    final Color questaoColor =
        totalSelecionadas == _limiteQuestoes ? Colors.red.shade300 : _whiteColor;

    return Container(
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
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: questaoColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: questaoColor, width: 1),
                    ),
                    child: Text(
                      '${totalSelecionadas} / $_limiteQuestoes',
                      style: TextStyle(
                        color: questaoColor, 
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pesoColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: pesoColor, width: 1),
                    ),
                    child: Text(
                      'Peso: ${_pesoTotal.toStringAsFixed(1)} / $_pesoMaximo',
                      style: TextStyle(
                        color: pesoColor, 
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildHeader(context),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
                AppConstants.defaultPadding, 16, AppConstants.defaultPadding, 16),
            decoration: BoxDecoration(
              color: _whiteColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecionar Questões',
                  style: TextStyle(
                    color: _textColor,
                    fontFamily: 'Inter-Bold',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFiltros(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryColor))
                : _questoesFiltradas.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            _questoes.isEmpty
                                ? 'Nenhuma questão encontrada para esta disciplina/conteúdo.'
                                : 'Nenhuma questão corresponde aos filtros. Tente uma busca diferente.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, color: _textColor, height: 1.5),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        itemCount: _questoesFiltradas.length,
                        itemBuilder: (context, index) {
                          final questao = _questoesFiltradas[index];
                          final bool selecionada =
                              _questoesSelecionadas.containsKey(questao.id!);
                          return _buildItemQuestao(questao, selecionada);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _finalizarSelecao,
        label: const Text('Concluir Seleção'),
        icon: const Icon(Icons.check),
        backgroundColor: _primaryColor,
        foregroundColor: _whiteColor, 
      ),
    );
  }
}