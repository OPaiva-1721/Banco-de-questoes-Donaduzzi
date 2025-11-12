import 'package:flutter/material.dart';
import '/services/question_service.dart';
import '/models/question_model.dart';
import '/utils/message_utils.dart';
import '/core/app_colors.dart';
import 'package:flutter/services.dart'; 

class SelecionarQuestoesScreen extends StatefulWidget {
  // Recebe os IDs que correspondem aos models
  final String subjectId; // ID da Matéria
  final String? contentId; // ID da Conteúdo
  final String tituloProva;
  final String instrucoesProva;

  const SelecionarQuestoesScreen({
    super.key,
    required this.subjectId,
    this.contentId,
    required this.tituloProva,
    required this.instrucoesProva,
  });

  @override
  State<SelecionarQuestoesScreen> createState() =>
      _SelecionarQuestoesScreenState();
}

class _SelecionarQuestoesScreenState extends State<SelecionarQuestoesScreen> {
  // Constantes de cores
  static const Color _primaryColor = AppColors.primary;
  static const Color _backgroundColor = AppColors.background;
  static const Color _textColor = AppColors.text;
  static const Color _whiteColor = Colors.white;

  // Serviços
  final QuestionService _questionService = QuestionService();

  // Estados
  List<Question> _questoesFiltradas = [];
  Set<String> _questoesSelecionadas = {};
  bool _isLoading = true;

  // *** NOVOS ESTADOS PARA O PESO ***
  final Map<String, double> _pesos = {};
  final Map<String, TextEditingController> _pesoControllers = {};
  double _pesoTotal = 0.0;
  final double _pesoMaximo = 100.0;

  // Limite máximo de questões
  final int _limiteQuestoes = 10;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    // Limpa os controllers para evitar memory leaks
    for (var controller in _pesoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Carrega questões JÁ FILTRADAS
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _questoesFiltradas = [];
      _questoesSelecionadas.clear();
      _pesos.clear();
      _pesoControllers.forEach((_, controller) => controller.dispose());
      _pesoControllers.clear();
      _pesoTotal = 0.0;
    });

    try {
      // 1. Buscamos as questões pela MATÉRIA (subjectId)
      // Este service já retorna Stream<List<Question>>
      final stream =
          _questionService.getQuestionsBySubjectStream(widget.subjectId);

      // 2. Pegamos a lista de objetos Question
      final List<Question> questoesDaMateria = await stream.first;

      // 3. Filtramos pelo CONTEÚDO (contentId)
      if (widget.contentId != null) {
        _questoesFiltradas = questoesDaMateria.where((question) {
          return question.contentId == widget.contentId;
        }).toList();
      } else {
        // Se nenhum conteúdo foi selecionado, usamos todas da matéria
        _questoesFiltradas = questoesDaMateria;
      }

      // 4. Inicializa os controllers de peso
      for (var questao in _questoesFiltradas) {
        _pesoControllers[questao.id!] = TextEditingController();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar questões: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        MessageUtils.mostrarErro(context, 'Erro ao carregar questões: $e');
      }
    }
  }

  /// Alterna seleção de uma questão com limite
  void _alternarSelecaoQuestao(String questaoId) {
    setState(() {
      if (_questoesSelecionadas.contains(questaoId)) {
        _questoesSelecionadas.remove(questaoId);
        _pesos.remove(questaoId);
        _pesoControllers[questaoId]?.text = '';
      } else {
        if (_questoesSelecionadas.length < _limiteQuestoes) {
          _questoesSelecionadas.add(questaoId);
          _pesos[questaoId] = 0.0;
          _pesoControllers[questaoId]?.text = '0';
        } else {
          MessageUtils.mostrarErro(
            context,
            'Você pode selecionar no máximo $_limiteQuestoes questões.',
          );
        }
      }
      _calcularPesoTotal(); // Recalcula o total
    });
  }

  /// **NOVA FUNÇÃO** - Atualiza o peso de uma questão
  void _atualizarPeso(String questaoId, String valor) {
    double peso = double.tryParse(valor) ?? 0.0;
    setState(() {
      _pesos[questaoId] = peso;
      _calcularPesoTotal();
    });
  }

  /// **NOVA FUNÇÃO** - Calcula o peso total
  void _calcularPesoTotal() {
    double total = 0.0;
    for (String id in _questoesSelecionadas) {
      total += _pesos[id] ?? 0.0;
    }
    setState(() {
      _pesoTotal = total;
    });
  }

  /// Finaliza a seleção e retorna as questões selecionadas
  void _finalizarSelecao() {
    if (_questoesSelecionadas.isEmpty) {
      MessageUtils.mostrarErro(context, 'Selecione pelo menos uma questão');
      return;
    }

    // **NOVA VALIDAÇÃO DE PESO**
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

    final List<Question> questoesSelecionadas = _questoesFiltradas
        .where((question) => _questoesSelecionadas.contains(question.id))
        .toList();

    // Adiciona o peso ao map que será retornado
    final List<Map<String, dynamic>> questoesMap = [];
    for (var questao in questoesSelecionadas) {
      final map = questao.toJson();
      map['id'] = questao.id;
      map['peso'] = _pesos[questao.id] ?? 0.0; 
      questoesMap.add(map);
    }

    Navigator.pop(context, {
      'questoes': questoesMap,
      'titulo': widget.tituloProva,
      'instrucoes': widget.instrucoesProva,
    });
  }

  /// Cria um card para cada questão
  Widget _buildQuestaoCard(Question questao) {
    final isSelecionada = _questoesSelecionadas.contains(questao.id);
    final controller = _pesoControllers[questao.id!];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelecionada ? _primaryColor : Colors.grey[300]!,
          width: isSelecionada ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _alternarSelecaoQuestao(questao.id!),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: isSelecionada,
                        onChanged: (value) =>
                            _alternarSelecaoQuestao(questao.id!),
                        activeColor: _primaryColor,
                      ),
                      _buildDificuldadeChip(questao.difficulty.name),
                    ],
                  ),
                  if (isSelecionada)
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Peso',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          isDense: true,
                        ),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,1}')),
                        ],
                        onChanged: (value) =>
                            _atualizarPeso(questao.id!, value),
                      ),
                    )
                ],
              ),
              const SizedBox(height: 12),
              Text(
                questao.questionText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.quiz,
                    '${questao.options.length} opções',
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDificuldadeChip(String dificuldade) {
    Color color;
    String label;
    switch (dificuldade) {
      case 'facil':
        color = Colors.green;
        label = 'Fácil';
        break;
      case 'medio':
        color = Colors.orange;
        label = 'Médio';
        break;
      case 'dificil':
        color = Colors.red;
        label = 'Difícil';
        break;
      default:
        color = Colors.grey;
        label = 'N/A';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Nenhuma questão encontrada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Não há questões para esta Matéria/Conteúdo. Verifique os filtros ou adicione questões ao banco.',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color pesoColor =
        _pesoTotal > _pesoMaximo ? Colors.red : _whiteColor;

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
            child: Column(
              children: [
                // Título e contadores
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Selecionar Questões',
                          style: TextStyle(
                            color: _textColor,
                            fontFamily: 'Inter-Bold',
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _questoesSelecionadas.length == _limiteQuestoes
                                  ? Colors.red.shade700
                                  : _primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_questoesSelecionadas.length} / $_limiteQuestoes',
                          style: const TextStyle(
                            color: _whiteColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _pesoTotal > _pesoMaximo
                              ? Colors.red.shade700
                              : _primaryColor,
                          borderRadius: BorderRadius.circular(20),
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
                // Lista de questões
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _primaryColor))
                      : _questoesFiltradas.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _carregarDados,
                              color: _primaryColor,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _questoesFiltradas.length,
                                itemBuilder: (context, index) {
                                  final questao = _questoesFiltradas[index];
                                  return _buildQuestaoCard(questao);
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
          // Botão finalizar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _whiteColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finalizarSelecao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: _whiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Concluir Seleção (${_questoesSelecionadas.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}