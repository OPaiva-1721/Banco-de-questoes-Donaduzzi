import 'package:flutter/material.dart';
import '../../../models/question_model.dart';
import '../../../models/option_model.dart';
import '../../../models/enums.dart';
import '../../../models/discipline_model.dart';
import '../../../models/content_model.dart';
import '../../../services/question_service.dart';
import '../../../services/subject_service.dart';
import '../../../services/content_service.dart';
import '../../../utils/message_utils.dart';
import '../../../core/exceptions/app_exceptions.dart';

class EditarQuestaoScreen extends StatefulWidget {
  final Question questao;

  const EditarQuestaoScreen({super.key, required this.questao});

  @override
  State<EditarQuestaoScreen> createState() => _EditarQuestaoScreenState();
}

class _EditarQuestaoScreenState extends State<EditarQuestaoScreen> {
  static const Color _primaryColor = Color(0xFF541822);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _whiteColor = Colors.white;

  final QuestionService _questionService = QuestionService();
  final SubjectService _subjectService = SubjectService();
  final ContentService _contentService = ContentService();

  late final TextEditingController _enunciadoController;
  late final TextEditingController _explicacaoController;
  late final List<TextEditingController> _opcoesControllers;

  late String _disciplinaSelecionada;
  late String _conteudoSelecionado;
  late QuestionDifficulty _dificuldadeSelecionada;

  List<Discipline> _disciplinas = [];
  List<Content> _conteudos = [];
  List<bool> _opcoesCorretas = List.filled(5, false);
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
    _carregarDisciplinas();
  }

  void _inicializarControladores() {
    _enunciadoController = TextEditingController(
      text: widget.questao.questionText,
    );
    _explicacaoController = TextEditingController(
      text: widget.questao.explanation ?? '',
    );

    _disciplinaSelecionada = widget.questao.subjectId;
    _conteudoSelecionado = widget.questao.contentId;
    _dificuldadeSelecionada = widget.questao.difficulty;

    _opcoesControllers = [];
    for (int i = 0; i < 5; i++) {
      if (i < widget.questao.options.length) {
        _opcoesControllers.add(
          TextEditingController(text: widget.questao.options[i].text),
        );
        _opcoesCorretas[i] = widget.questao.options[i].isCorrect;
      } else {
        _opcoesControllers.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    _enunciadoController.dispose();
    _explicacaoController.dispose();
    for (var controller in _opcoesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarDisciplinas() async {
    setState(() {
      _isLoading = true;
    });

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
          await _carregarConteudos(_disciplinaSelecionada);
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  Future<void> _carregarConteudos(String disciplinaId) async {
    try {
      final conteudos = await _contentService
          .getContentBySubjectStream(disciplinaId)
          .first;

      if (mounted) {
        setState(() {
          _conteudos = conteudos;
        });
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  bool _validarFormulario() {
    if (_enunciadoController.text.trim().isEmpty) {
      MessageUtils.mostrarErro(context, 'Digite o enunciado da questão');
      return false;
    }

    for (int i = 0; i < _opcoesControllers.length; i++) {
      if (_opcoesControllers[i].text.trim().isEmpty) {
        MessageUtils.mostrarErro(
          context,
          'Todas as 5 opções devem ser preenchidas',
        );
        return false;
      }
    }

    int totalCorretas = _opcoesCorretas.where((c) => c).length;
    if (totalCorretas != 1) {
      MessageUtils.mostrarErro(
        context,
        'Exatamente uma opção deve ser marcada como correta',
      );
      return false;
    }

    return true;
  }

  Future<void> _salvarAlteracoes() async {
    if (!_validarFormulario()) return;
    if (widget.questao.id == null) {
      MessageUtils.mostrarErro(context, 'Erro: ID da questão não encontrado.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final opcoes = <Option>[];
      final letras = ['A', 'B', 'C', 'D', 'E'];

      for (int i = 0; i < _opcoesControllers.length; i++) {
        opcoes.add(
          Option(
            letter: letras[i],
            text: _opcoesControllers[i].text.trim(),
            isCorrect: _opcoesCorretas[i],
            order: i + 1,
          ),
        );
      }

      final questaoAtualizada = Question(
        id: widget.questao.id,
        questionText: _enunciadoController.text.trim(),
        subjectId: _disciplinaSelecionada,
        contentId: _conteudoSelecionado,
        difficulty: _dificuldadeSelecionada,
        createdBy: widget.questao.createdBy,
        createdAt: widget.questao.createdAt,
        options: opcoes,
        explanation: _explicacaoController.text.trim().isEmpty
            ? null
            : _explicacaoController.text.trim(),
      );

      await _questionService.updateQuestion(questaoAtualizada);

      if (mounted) {
        MessageUtils.mostrarSucesso(
          context,
          'Questão atualizada com sucesso!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErroFormatado(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Editar Questão'),
        backgroundColor: _primaryColor,
        elevation: 0,
        foregroundColor: _whiteColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disciplina',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _disciplinaSelecionada,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          items: _disciplinas.map((disciplina) {
                            return DropdownMenuItem(
                              value: disciplina.id,
                              child: Text(disciplina.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _disciplinaSelecionada = value;
                                _conteudos = [];
                              });
                              _carregarConteudos(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conteúdo',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _conteudoSelecionado,
                          decoration: InputDecoration(
                            hintText: 'Selecione o conteúdo',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          items: _conteudos.map((conteudo) {
                            return DropdownMenuItem(
                              value: conteudo.id,
                              child: Text(
                                conteudo.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _conteudoSelecionado = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dificuldade',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<QuestionDifficulty>(
                          value: _dificuldadeSelecionada,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: QuestionDifficulty.easy,
                              child: Text('Fácil'),
                            ),
                            DropdownMenuItem(
                              value: QuestionDifficulty.medium,
                              child: Text('Médio'),
                            ),
                            DropdownMenuItem(
                              value: QuestionDifficulty.hard,
                              child: Text('Difícil'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _dificuldadeSelecionada = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enunciado',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _enunciadoController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Digite o enunciado da questão...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Opções (5 obrigatórias)',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...List.generate(5, (index) {
                          final letras = ['A', 'B', 'C', 'D', 'E'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _opcoesCorretas[index],
                                  onChanged: (value) {
                                    setState(() {
                                      _opcoesCorretas = List.filled(5, false);
                                      _opcoesCorretas[index] = value ?? false;
                                    });
                                  },
                                  activeColor: _primaryColor,
                                ),
                                Container(
                                  width: 35,
                                  height: 35,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    letras[index],
                                    style: const TextStyle(
                                      color: _whiteColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _opcoesControllers[index],
                                    decoration: InputDecoration(
                                      hintText:
                                          'Digite a opção ${letras[index]}',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explicação (Opcional)',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _explicacaoController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Digite a explicação da resposta...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _salvarAlteracoes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _whiteColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _whiteColor,
                              ),
                            ),
                          )
                        : const Text(
                            'Salvar Alterações',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
