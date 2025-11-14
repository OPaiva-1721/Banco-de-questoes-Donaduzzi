import 'package:flutter/material.dart';
import '../../../models/question_model.dart';
import '../../../models/discipline_model.dart';
import '../../../models/content_model.dart';
import '../../../services/question_service.dart';
import '../../../services/subject_service.dart';
import '../../../services/content_service.dart';
import '../../../utils/message_utils.dart';
import '../../../core/exceptions/app_exceptions.dart';
import 'adicionar_questao_screen.dart';
import 'editar_questao_screen.dart';

class GerenciarQuestoesScreen extends StatefulWidget {
  const GerenciarQuestoesScreen({super.key});

  @override
  State<GerenciarQuestoesScreen> createState() =>
      _GerenciarQuestoesScreenState();
}

class _GerenciarQuestoesScreenState extends State<GerenciarQuestoesScreen> {
  static const Color _primaryColor = Color(0xFF541822);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _whiteColor = Colors.white;

  final QuestionService _questionService = QuestionService();
  final SubjectService _subjectService = SubjectService();
  final ContentService _contentService = ContentService();

  List<Question> _questoes = [];
  List<Discipline> _disciplinas = [];
  List<Content> _conteudos = [];
  String? _disciplinaFiltro;
  String? _conteudoFiltro;
  String _dificuldadeFiltro = 'todas';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([_carregarDisciplinas(), _carregarQuestoes()]);
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

  Future<void> _carregarDisciplinas() async {
    try {
      final event = await _subjectService.listarDisciplinas().first;

      if (event.snapshot.exists && event.snapshot.value != null) {
        final disciplinas = <Discipline>[];
        for (final child in event.snapshot.children) {
          disciplinas.add(Discipline.fromSnapshot(child));
        }
        if (mounted) {
          setState(() {
            _disciplinas = disciplinas;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  Future<void> _carregarConteudos(String? disciplinaId) async {
    if (disciplinaId == null) {
      setState(() {
        _conteudos = [];
        _conteudoFiltro = null;
      });
      return;
    }

    try {
      final conteudos = await _contentService
          .getContentBySubjectStream(disciplinaId)
          .first;

      if (mounted) {
        setState(() {
          _conteudos = conteudos;
          _conteudoFiltro = null;
        });
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  Future<void> _carregarQuestoes() async {
    try {
      final questoes = await _questionService.getQuestionsStream().first;

      if (mounted) {
        setState(() {
          _questoes = questoes;
        });
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  List<Question> _getQuestoesFiltradas() {
    return _questoes.where((questao) {
      if (_disciplinaFiltro != null && questao.subjectId != _disciplinaFiltro) {
        return false;
      }

      if (_conteudoFiltro != null && questao.contentId != _conteudoFiltro) {
        return false;
      }

      if (_dificuldadeFiltro != 'todas' &&
          questao.difficulty.name != _dificuldadeFiltro) {
        return false;
      }

      return true;
    }).toList();
  }

  String _getNomeDisciplina(String? disciplinaId) {
    if (disciplinaId == null) return 'Desconhecida';
    final disciplina = _disciplinas.firstWhere(
      (d) => d.id == disciplinaId,
      orElse: () => Discipline(name: 'Desconhecida', semester: 0),
    );
    return disciplina.name;
  }

  String _getNomeConteudo(String? conteudoId) {
    if (conteudoId == null) return 'Desconhecido';
    final conteudo = _conteudos.firstWhere(
      (c) => c.id == conteudoId,
      orElse: () => Content(description: 'Desconhecido', subjectId: ''),
    );
    return conteudo.description;
  }

  String _getDificuldadeLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Fácil';
      case 'medium':
        return 'Médio';
      case 'hard':
        return 'Difícil';
      default:
        return difficulty;
    }
  }

  Color _getDificuldadeColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _deletarQuestao(Question questao) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text(
          'Tem certeza que deseja APAGAR esta questão?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmacao == true && questao.id != null) {
      try {
        await _questionService.deleteQuestion(questao.id!);
        if (mounted) {
          MessageUtils.mostrarSucesso(
            context,
            'Questão apagada com sucesso!',
          );
          await _carregarQuestoes();
        }
      } catch (e) {
        if (mounted) {
          MessageUtils.mostrarErroFormatado(context, e);
        }
      }
    }
  }

  Future<void> _navegarParaAdicionar() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdicionarQuestaoScreen()),
    );

    if (resultado == true) {
      await _carregarQuestoes();
    }
  }

  Future<void> _navegarParaEditar(Question questao) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarQuestaoScreen(questao: questao),
      ),
    );

    if (resultado == true) {
      await _carregarQuestoes();
    }
  }

  Widget _buildContainer({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _whiteColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final questoesFiltradas = _getQuestoesFiltradas();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Banco de Questões'),
        backgroundColor: _primaryColor,
        elevation: 0,
        foregroundColor: _whiteColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Disciplina',
                                    style: TextStyle(
                                      color: _textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String?>(
                                    value: _disciplinaFiltro,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Todas'),
                                      ),
                                      ..._disciplinas.map((disciplina) {
                                        return DropdownMenuItem(
                                          value: disciplina.id,
                                          child: Text(disciplina.name),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _disciplinaFiltro = value;
                                      });
                                      _carregarConteudos(value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dificuldade',
                                    style: TextStyle(
                                      color: _textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _dificuldadeFiltro,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'todas',
                                        child: Text('Todas'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'easy',
                                        child: Text('Fácil'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'medium',
                                        child: Text('Médio'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'hard',
                                        child: Text('Difícil'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _dificuldadeFiltro = value;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conteúdo',
                              style: TextStyle(
                                color: _textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String?>(
                              value: _conteudoFiltro,
                              decoration: InputDecoration(
                                hintText: _disciplinaFiltro == null
                                    ? 'Selecione uma disciplina primeiro'
                                    : 'Todos os conteúdos',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Todos'),
                                ),
                                ..._conteudos.map((conteudo) {
                                  return DropdownMenuItem(
                                    value: conteudo.id,
                                    child: Text(
                                      conteudo.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                              onChanged: _disciplinaFiltro == null
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _conteudoFiltro = value;
                                      });
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildContainer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: ${questoesFiltradas.length} questão(ões)',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _navegarParaAdicionar,
                          icon: const Icon(Icons.add),
                          label: const Text('Nova Questão'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: _whiteColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: questoesFiltradas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma questão cadastrada',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _navegarParaAdicionar,
                                  icon: const Icon(Icons.add),
                                  label: const Text(
                                    'Adicionar primeira questão',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: questoesFiltradas.length,
                            itemBuilder: (context, index) {
                              final questao = questoesFiltradas[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: _buildContainer(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              questao.questionText,
                                              style: TextStyle(
                                                color: _textColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                color: _primaryColor,
                                                onPressed: () =>
                                                    _navegarParaEditar(questao),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                color: Colors.red,
                                                onPressed: () =>
                                                    _deletarQuestao(questao),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getDificuldadeColor(
                                                questao.difficulty.name,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getDificuldadeColor(
                                                  questao.difficulty.name,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              _getDificuldadeLabel(
                                                questao.difficulty.name,
                                              ),
                                              style: TextStyle(
                                                color: _getDificuldadeColor(
                                                  questao.difficulty.name,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _getNomeDisciplina(
                                                questao.subjectId,
                                              ),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
