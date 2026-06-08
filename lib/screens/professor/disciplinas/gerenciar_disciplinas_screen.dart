import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../models/discipline_model.dart';
import '../../../services/subject_service.dart';
import '../../../utils/message_utils.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/confirm_delete_dialog.dart';
import '../../../widgets/empty_state_widget.dart';
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
  final SubjectService _subjectService = SubjectService();

  List<Discipline> _disciplinas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDisciplinas();
  }

  Future<void> _carregarDisciplinas() async {
    setState(() => _isLoading = true);
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
        if (mounted) setState(() { _disciplinas = []; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  Future<void> _deletarDisciplina(Discipline disciplina) async {
    final confirmado = await showConfirmDeleteDialog(context, itemName: disciplina.name);
    if (confirmado && disciplina.id != null) {
      try {
        await _subjectService.deleteSubject(disciplina.id!);
        if (mounted) {
          MessageUtils.mostrarSucesso(context, 'Disciplina apagada com sucesso!');
          await _carregarDisciplinas();
        }
      } catch (e) {
        if (mounted) MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  Future<void> _navegarParaAdicionar() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdicionarDisciplinaScreen()),
    );
    if (resultado == true) await _carregarDisciplinas();
  }

  Future<void> _navegarParaEditar(Discipline disciplina) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarDisciplinaScreen(disciplina: disciplina),
      ),
    );
    if (resultado == true) await _carregarDisciplinas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gerenciar Disciplinas'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_disciplinas.length} disciplina(s)',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _navegarParaAdicionar,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nova Disciplina'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        ? EmptyStateWidget(
                            icon: Icons.book_outlined,
                            message: 'Nenhuma disciplina cadastrada',
                            actionLabel: 'Adicionar primeira disciplina',
                            onAction: _navegarParaAdicionar,
                          )
                        : ListView.builder(
                            itemCount: _disciplinas.length,
                            itemBuilder: (context, index) {
                              final disciplina = _disciplinas[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AppCard(
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.book_outlined,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                    title: Text(
                                      disciplina.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${disciplina.semester}º Semestre',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: AppColors.primary,
                                          onPressed: () => _navegarParaEditar(disciplina),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () => _deletarDisciplina(disciplina),
                                        ),
                                      ],
                                    ),
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
