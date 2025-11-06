import 'package:flutter/material.dart';
import '../../../models/question_model.dart'; // Importa o modelo de questão
import '../../../services/question_service.dart';
import '../../../services/subject_service.dart'; // Corrigido de DisciplineService
import '../../../utils/message_utils.dart';

class BancoQuestoesMenuScreen extends StatefulWidget {
  const BancoQuestoesMenuScreen({super.key});

  @override
  State<BancoQuestoesMenuScreen> createState() =>
      _BancoQuestoesMenuScreenState();
}

class _BancoQuestoesMenuScreenState extends State<BancoQuestoesMenuScreen> {
  // Constantes de cores
  static const Color _primaryColor = Color(0xFF541822);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _whiteColor = Colors.white;

  // Serviços
  final QuestionService _questionService = QuestionService();
  final SubjectService _subjectService = SubjectService(); // Corrigido

  // Estados
  List<Question> _questoes = []; // MUDANÇA: Usa o modelo Question
  List<Map<String, dynamic>> _disciplinas = [];
  bool _isLoading = true;
  String? _disciplinaFiltro;
  String _dificuldadeFiltro = 'todas';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  /// Carrega questões e disciplinas do Firebase
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar disciplinas e questões em paralelo
      await Future.wait([_carregarDisciplinas(), _carregarQuestoes()]);
    } catch (e) {
      print('Erro ao carregar dados: $e');
      if (mounted) {
        MessageUtils.mostrarErro(context, 'Erro ao carregar dados: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Carrega disciplinas do Firebase
  Future<void> _carregarDisciplinas() async {
    try {
      final stream = _subjectService.listarDisciplinas(); // Corrigido
      final event = await stream.first;

      if (event.snapshot.exists) {
        final disciplinas = <Map<String, dynamic>>[];
        for (final child in event.snapshot.children) {
          final disciplina = {
            'id': child.key,
            ...Map<String, dynamic>.from(child.value as Map),
          };
          disciplinas.add(disciplina);
        }
        if (mounted) {
          setState(() {
            _disciplinas = disciplinas;
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar disciplinas: $e');
      if (mounted) {
        MessageUtils.mostrarErro(context, 'Erro ao carregar disciplinas: $e');
      }
    }
  }

  /// Carrega questões do Firebase
  Future<void> _carregarQuestoes() async {
    // MUDANÇA: Lógica de carregamento atualizada
    try {
      // O novo service retorna diretamente a lista de Questões
      final List<Question> questoes = await _questionService
          .getQuestionsStream()
          .first;

      if (mounted) {
        setState(() {
          _questoes = questoes;
        });
      }
    } catch (e) {
      print('Erro ao carregar questões: $e');
      if (mounted) {
        MessageUtils.mostrarErro(context, 'Erro ao carregar questões: $e');
      }
    }
  }

  /// Filtra questões baseado nos filtros selecionados
  List<Question> _getQuestoesFiltradas() {
    // MUDANÇA: Retorna List<Question>
    return _questoes.where((questao) {
      // Filtro por disciplina
      // MUDANÇA: usa questao.subjectId
      if (_disciplinaFiltro != null && questao.subjectId != _disciplinaFiltro) {
        return false;
      }

      // Filtro por dificuldade
      // MUDANÇA: usa questao.difficulty.name
      if (_dificuldadeFiltro != 'todas' &&
          questao.difficulty.name != _dificuldadeFiltro) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Obtém o nome da disciplina pelo ID
  String _getNomeDisciplina(String? disciplinaId) {
    if (disciplinaId == null) return 'Disciplina não encontrada';

    final disciplina = _disciplinas.firstWhere(
      (d) => d['id'] == disciplinaId,
      orElse: () => {'nome': 'Disciplina não encontrada'},
    );

    return disciplina['nome'] ?? 'Disciplina não encontrada';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          // Header com logo e botão voltar
          Container(
            width: double.infinity,
            height: 120,
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
                // Logo centralizado
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
                // Botão voltar
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
                      style: IconButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: const CircleBorder(),
                      ),
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
                // Título e botão na mesma linha
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Título
                      const Text(
                        'Banco de Questões',
                        style: TextStyle(
                          color: _textColor,
                          fontFamily: 'Inter-Bold',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Botão adicionar
                      ElevatedButton(
                        onPressed: () async {
                          // GAO
                          // final resultado = await Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) =>
                          //         const AdicionarQuestaoScreen(),
                          //   ),
                          // );
                          // if (resultado == true) {
                          //   _carregarDados(); // Recarregar se adicionou
                          // }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: _whiteColor,
                          padding: const EdgeInsets.all(12),
                          shape: const CircleBorder(),
                          elevation: 4,
                        ),
                        child: const Icon(Icons.add, size: 24),
                      ),
                    ],
                  ),
                ),
                // Filtros
                _buildFiltros(),
                // Lista de questões
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _primaryColor,
                          ),
                        )
                      : _getQuestoesFiltradas().isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _carregarDados,
                          color: _primaryColor,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _getQuestoesFiltradas().length,
                            itemBuilder: (context, index) {
                              // MUDANÇA: 'questao' agora é um objeto Question
                              final questao = _getQuestoesFiltradas()[index];
                              return _buildQuestaoCard(questao);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Cria o estado vazio quando não há questões
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
          Text(
            'Clique no botão + para adicionar uma questão',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Cria os filtros de busca
  Widget _buildFiltros() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Filtro por disciplina
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _disciplinaFiltro,
              decoration: const InputDecoration(
                labelText: 'Disciplina',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todas'),
                ),
                ..._disciplinas.map(
                  (disciplina) => DropdownMenuItem<String?>(
                    value: disciplina['id'],
                    child: Text(
                      disciplina['nome'] ?? 'Disciplina sem nome',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _disciplinaFiltro = value;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // Filtro por dificuldade
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _dificuldadeFiltro,
              decoration: const InputDecoration(
                labelText: 'Dificuldade',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem<String>(value: 'todas', child: Text('Todas')),
                DropdownMenuItem<String>(
                  value: 'easy',
                  child: Text('Fácil'),
                ), // MUDANÇA
                DropdownMenuItem<String>(
                  value: 'medium',
                  child: Text('Média'),
                ), // MUDANÇA
                DropdownMenuItem<String>(
                  value: 'hard',
                  child: Text('Difícil'),
                ), // MUDANÇA
              ],
              onChanged: (value) {
                setState(() {
                  _dificuldadeFiltro = value ?? 'todas';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Cria um card para cada questão
  Widget _buildQuestaoCard(Question questao) {
    // MUDANÇA: Recebe um objeto Question
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com dificuldade e botão editar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // MUDANÇA: usa questao.difficulty.name
                _buildDificuldadeChip(questao.difficulty.name),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _deletarQuestao(questao), // MUDANÇA
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Deletar questão',
                    ),
                    IconButton(
                      onPressed: () => _editarQuestao(questao), // MUDANÇA
                      icon: const Icon(Icons.edit),
                      color: _primaryColor,
                      tooltip: 'Editar questão',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Enunciado
            Text(
              questao.questionText, // MUDANÇA: usa questao.questionText
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Informações da questão
            Row(
              children: [
                _buildInfoChip(
                  Icons.school,
                  _getNomeDisciplina(
                    questao.subjectId,
                  ), // MUDANÇA: usa questao.subjectId
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.access_time,
                  _formatarData(
                    questao.createdAt,
                  ), // MUDANÇA: usa questao.createdAt
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Cria um chip de dificuldade
  Widget _buildDificuldadeChip(String dificuldade) {
    Color color;
    String texto;
    switch (dificuldade.toLowerCase()) {
      case 'easy': // MUDANÇA
        color = Colors.green;
        texto = 'Fácil';
        break;
      case 'medium': // MUDANÇA
        color = Colors.orange;
        texto = 'Média';
        break;
      case 'hard': // MUDANÇA
        color = Colors.red;
        texto = 'Difícil';
        break;
      default:
        color = Colors.grey;
        texto = 'Indefinida';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Cria um chip de informação
  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
          ),
        ],
      ),
    );
  }

  /// Formata a data de criação
  String _formatarData(dynamic timestamp) {
    // MUDANÇA: 'timestamp' agora é o 'createdAt' (int)
    if (timestamp == null || timestamp == 0) return 'Data não disponível';

    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  /// Deleta uma questão
  Future<void> _deletarQuestao(Question questao) async {
    // MUDANÇA: Recebe Question
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          // MUDANÇA: usa questao.questionText
          'Tem certeza que deseja deletar a questão:\n"${questao.questionText}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      try {
        // MUDANÇA: usa questao.id!
        final sucesso = await _questionService.deleteQuestion(questao.id!);
        if (mounted) {
          if (sucesso) {
            MessageUtils.mostrarSucesso(
              context,
              'Questão deletada com sucesso!',
            );
            _carregarDados(); // Recarregar dados
          } else {
            MessageUtils.mostrarErro(
              context,
              'Erro ao deletar questão. Pode estar em uso em uma prova.',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          MessageUtils.mostrarErro(context, 'Erro ao deletar questão: $e');
        }
      }
    }
  }

  /// Navega para a tela de editar questão
  void _editarQuestao(Question questao) async {
    // MUDANÇA: Recebe Question
    // final resultado = await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     // MUDANÇA: Passa o objeto Question convertido para Map
    //     builder: (context) => EditarQuestaoScreen(questao: questao.toMap()),
    //   ),
    // );
    // if (resultado == true) {
    //   _carregarDados(); // Recarregar se editou
    // }
  }
}
