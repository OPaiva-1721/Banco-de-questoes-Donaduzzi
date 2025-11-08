import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../models/course_model.dart';
import '../../../services/course_service.dart';
import '../../../utils/message_utils.dart';
import 'adicionar_curso_screen.dart';
import 'editar_curso_screen.dart';

class GerenciarCursosScreen extends StatefulWidget {
  const GerenciarCursosScreen({super.key});

  @override
  State<GerenciarCursosScreen> createState() => _GerenciarCursosScreenState();
}

class _GerenciarCursosScreenState extends State<GerenciarCursosScreen> {
  static const Color _primaryColor = Color(0xFF541822);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _whiteColor = Colors.white;

  final CourseService _courseService = CourseService();

  List<Course> _cursos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarCursos();
  }

  Future<void> _carregarCursos() async {
    setState(() {
      _isLoading = true;
    });

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
        if (mounted) {
          setState(() {
            _cursos = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        MessageUtils.mostrarErro(context, 'Erro ao carregar cursos: $e');
      }
    }
  }

  Future<void> _deletarCurso(Course curso) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Tem certeza que deseja APAGAR o curso:\n"${curso.name}"?\n\nEsta ação não pode ser desfeita.',
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

    if (confirmacao == true && curso.id != null) {
      try {
        final sucesso = await _courseService.deleteCourse(curso.id!);
        if (mounted) {
          if (sucesso) {
            MessageUtils.mostrarSucesso(context, 'Curso apagado com sucesso!');
            await _carregarCursos();
          } else {
            MessageUtils.mostrarErro(
              context,
              'Erro ao apagar curso. Pode estar em uso.',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          MessageUtils.mostrarErro(context, 'Erro ao apagar curso: $e');
        }
      }
    }
  }

  Future<void> _navegarParaAdicionar() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdicionarCursoScreen()),
    );

    if (resultado == true) {
      await _carregarCursos();
    }
  }

  Future<void> _navegarParaEditar(Course curso) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarCursoScreen(curso: curso)),
    );

    if (resultado == true) {
      await _carregarCursos();
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
        title: const Text('Gerenciar Cursos'),
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
                          'Total: ${_cursos.length} curso(s)',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _navegarParaAdicionar,
                          icon: const Icon(Icons.add),
                          label: const Text('Novo Curso'),
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
                    child: _cursos.isEmpty
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
                                  'Nenhum curso cadastrado',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _navegarParaAdicionar,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Adicionar primeiro curso'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _cursos.length,
                            itemBuilder: (context, index) {
                              final curso = _cursos[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: _buildContainer(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          curso.name,
                                          style: TextStyle(
                                            color: _textColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            color: _primaryColor,
                                            onPressed: () =>
                                                _navegarParaEditar(curso),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            color: Colors.red,
                                            onPressed: () =>
                                                _deletarCurso(curso),
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
