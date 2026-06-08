import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../models/course_model.dart';
import '../../../services/course_service.dart';
import '../../../utils/message_utils.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/confirm_delete_dialog.dart';
import '../../../widgets/empty_state_widget.dart';
import 'adicionar_curso_screen.dart';
import 'editar_curso_screen.dart';

class GerenciarCursosScreen extends StatefulWidget {
  const GerenciarCursosScreen({super.key});

  @override
  State<GerenciarCursosScreen> createState() => _GerenciarCursosScreenState();
}

class _GerenciarCursosScreenState extends State<GerenciarCursosScreen> {
  final CourseService _courseService = CourseService();

  List<Course> _cursos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarCursos();
  }

  Future<void> _carregarCursos() async {
    setState(() => _isLoading = true);
    try {
      final event = await _courseService.getCoursesStream().first;
      if (event.snapshot.exists && event.snapshot.value != null) {
        final cursos = <Course>[];
        for (final child in event.snapshot.children) {
          cursos.add(Course.fromSnapshot(child));
        }
        if (mounted) {
          setState(() {
            cursos.sort((a, b) => a.name.compareTo(b.name));
            _cursos = cursos;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _cursos = []; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  Future<void> _deletarCurso(Course curso) async {
    final confirmado = await showConfirmDeleteDialog(context, itemName: curso.name);
    if (confirmado && curso.id != null) {
      try {
        await _courseService.deleteCourse(curso.id!);
        if (mounted) {
          MessageUtils.mostrarSucesso(context, 'Curso apagado com sucesso!');
          await _carregarCursos();
        }
      } catch (e) {
        if (mounted) MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  Future<void> _navegarParaAdicionar() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdicionarCursoScreen()),
    );
    if (resultado == true) await _carregarCursos();
  }

  Future<void> _navegarParaEditar(Course curso) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarCursoScreen(curso: curso)),
    );
    if (resultado == true) await _carregarCursos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gerenciar Cursos'),
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
                          '${_cursos.length} curso(s)',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _navegarParaAdicionar,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Novo Curso'),
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
                    child: _cursos.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.school_outlined,
                            message: 'Nenhum curso cadastrado',
                            actionLabel: 'Adicionar primeiro curso',
                            onAction: _navegarParaAdicionar,
                          )
                        : ListView.builder(
                            itemCount: _cursos.length,
                            itemBuilder: (context, index) {
                              final curso = _cursos[index];
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
                                        Icons.school_outlined,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                    title: Text(
                                      curso.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: AppColors.primary,
                                          onPressed: () => _navegarParaEditar(curso),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () => _deletarCurso(curso),
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
