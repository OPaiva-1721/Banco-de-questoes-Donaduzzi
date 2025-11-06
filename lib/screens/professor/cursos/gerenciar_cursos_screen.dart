import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_constants.dart';
import '../../../models/course_model.dart'; // Importa o seu modelo (só com 'name')
import '../../../services/course_service.dart';
import '../../../utils/message_utils.dart';
import 'adicionar_curso_screen.dart';
import 'editar_curso_screen.dart'; // Garante que a tela de editar existe

class GerenciarCursosScreen extends StatefulWidget {
  const GerenciarCursosScreen({super.key});

  @override
  State<GerenciarCursosScreen> createState() => _GerenciarCursosScreenState();
}

class _GerenciarCursosScreenState extends State<GerenciarCursosScreen> {
  // Constantes de cores
  static const Color _primaryColor = AppColors.primary;
  static const Color _backgroundColor = AppColors.background;
  static const Color _textColor = AppColors.text;
  static const Color _whiteColor = AppColors.white;

  // Serviços
  final CourseService _courseService = CourseService();

  // Estados
  List<Course> _cursos = []; // Usa o modelo Course
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarCursos();
  }

  /// Carrega cursos do Firebase
  Future<void> _carregarCursos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final event = await _courseService.getCoursesStream().first;

      if (event.snapshot.exists && event.snapshot.value != null) {
        final cursos = <Course>[];
        for (final child in event.snapshot.children) {
          // Usa o .fromSnapshot do seu modelo (só lê 'id' e 'name')
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

  /// Remove um curso (Hard delete)
  Future<void> _removerCurso(Course curso) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Remoção'),
        content: Text(
          // MUDANÇA: Mensagem de hard delete
          'Tem certeza que deseja APAGAR o curso "${curso.name}"?\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: _whiteColor,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmacao == true && curso.id != null) {
      // Chama 'deleteCourse' do service (que faz hard-delete)
      final sucesso = await _courseService.deleteCourse(curso.id!);
      if (mounted) {
        if (sucesso) {
          MessageUtils.mostrarSucesso(context, 'Curso removido com sucesso!');
          _carregarCursos(); // Recarrega
        } else {
          MessageUtils.mostrarErro(context, 'Erro ao remover curso');
        }
      }
    }
  }

  /// Navega para tela de adicionar curso
  Future<void> _navegarParaAdicionarCurso() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdicionarCursoScreen()),
    );

    if (resultado == true) {
      _carregarCursos();
    }
  }

  /// Navega para tela de editar curso
  Future<void> _navegarParaEditarCurso(Course curso) async {
    // MUDANÇA: Código descomentado
    final resultado = await Navigator.push(
      context,
      // Passa o objeto Course para a tela de edição
      MaterialPageRoute(builder: (context) => EditarCursoScreen(curso: curso)),
    );

    if (resultado == true) {
      _carregarCursos();
    }
  }

  Widget _buildCursoCard(Course curso) {
    // O card está simplificado, mostrando apenas o 'name'
    // pois é o único dado que o seu model.dart possui.

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3), // Borda padrão
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    curso.name, // Usa curso.name
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _navegarParaEditarCurso(curso),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(foregroundColor: _primaryColor),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _removerCurso(curso),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Remover'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: _whiteColor,
        title: const Text(
          'Gerenciar Cursos',
          style: TextStyle(
            fontFamily: 'Inter-Bold',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _carregarCursos,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Botão adicionar curso
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navegarParaAdicionarCurso,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Curso'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: _whiteColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Lista de cursos
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  )
                : _cursos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: _textColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum curso encontrado',
                          style: TextStyle(
                            fontSize: 18,
                            color: _textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adicione um curso para começar',
                          style: TextStyle(
                            fontSize: 14,
                            color: _textColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _carregarCursos,
                    color: _primaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _cursos.length,
                      itemBuilder: (context, index) {
                        final curso = _cursos[index];
                        return _buildCursoCard(curso);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
