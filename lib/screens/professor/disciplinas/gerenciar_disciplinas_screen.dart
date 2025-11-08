import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../models/discipline_model.dart';
import '../../../services/subject_service.dart';
import '../../../utils/message_utils.dart';
import 'adicionar_disciplina_screen.dart';
import 'editar_disciplina_screen.dart';

class GerenciarDisciplinasScreen extends StatefulWidget {
  const GerenciarDisciplinasScreen({super.key});

  @override
  State<GerenciarDisciplinasScreen> createState() =>
      _GerenciarDisciplinasScreenState();
}

class _GerenciarDisciplinasScreenState
    extends State<GerenciarDisciplinasScreen> {
  static const Color _primaryColor = Color(0xFF541822);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _whiteColor = Colors.white;

  final SubjectService _subjectService = SubjectService();

  List<Discipline> _disciplinas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDisciplinas();
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
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _disciplinas = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        MessageUtils.mostrarErro(context, 'Erro ao carregar disciplinas: $e');
      }
    }
  }

  Future<void> _deletarDisciplina(Discipline disciplina) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Tem certeza que deseja APAGAR a disciplina:\n"${disciplina.name}"?\n\nEsta ação não pode ser desfeita.',
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

    if (confirmacao == true && disciplina.id != null) {
      try {
        final sucesso = await _subjectService.deleteSubject(disciplina.id!);
        if (mounted) {
          if (sucesso) {
            MessageUtils.mostrarSucesso(
              context,
              'Disciplina apagada com sucesso!',
            );
            await _carregarDisciplinas();
          } else {
            MessageUtils.mostrarErro(
              context,
              'Erro ao apagar disciplina. Pode estar em uso.',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          MessageUtils.mostrarErro(context, 'Erro ao apagar disciplina: $e');
        }
      }
    }
  }

  Future<void> _navegarParaAdicionar() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdicionarDisciplinaScreen(),
      ),
    );

    if (resultado == true) {
      await _carregarDisciplinas();
    }
  }

  Future<void> _navegarParaEditar(Discipline disciplina) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarDisciplinaScreen(disciplina: disciplina),
      ),
    );

    if (resultado == true) {
      await _carregarDisciplinas();
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
        title: const Text('Gerenciar Disciplinas'),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: ${_disciplinas.length} disciplina(s)',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _navegarParaAdicionar,
                          icon: const Icon(Icons.add),
                          label: const Text('Nova Disciplina'),
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
                    child: _disciplinas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma disciplina cadastrada',
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
                                    'Adicionar primeira disciplina',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _disciplinas.length,
                            itemBuilder: (context, index) {
                              final disciplina = _disciplinas[index];
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
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  disciplina.name,
                                                  style: TextStyle(
                                                    color: _textColor,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Semestre: ${disciplina.semester}º',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                color: _primaryColor,
                                                onPressed: () =>
                                                    _navegarParaEditar(
                                                      disciplina,
                                                    ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                color: Colors.red,
                                                onPressed: () =>
                                                    _deletarDisciplina(
                                                      disciplina,
                                                    ),
                                              ),
                                            ],
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
