import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_constants.dart';
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
  // Constantes de cores
  static const Color _primaryColor = AppColors.primary;
  static const Color _backgroundColor = AppColors.background;
  static const Color _textColor = AppColors.text;
  static const Color _whiteColor = AppColors.white;

  // Serviços
  final CourseService _courseService = CourseService();

  // Estados
  List<Map<String, dynamic>> _cursos = [];
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
      final stream = _courseService.listarCursos();
      await for (final event in stream) {
        if (event.snapshot.exists) {
          final cursos = <Map<String, dynamic>>[];
          for (final child in event.snapshot.children) {
            final curso = {
              'id': child.key,
              ...Map<String, dynamic>.from(child.value as Map),
            };
            cursos.add(curso);
          }
          if (mounted) {
            setState(() {
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

  /// Remove um curso
  Future<void> _removerCurso(Map<String, dynamic> curso) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Remoção'),
        content: Text(
          'Tem certeza que deseja remover o curso "${curso['nome']}"?\n\n'
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

    if (confirmacao == true) {
      final sucesso = await _courseService.removerCurso(curso['id']);
      if (sucesso) {
        MessageUtils.mostrarSucesso(context, 'Curso removido com sucesso!');
        _carregarCursos();
      } else {
        MessageUtils.mostrarErro(context, 'Erro ao remover curso');
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
  Future<void> _navegarParaEditarCurso(Map<String, dynamic> curso) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarCursoScreen(curso: curso)),
    );

    if (resultado == true) {
      _carregarCursos();
    }
  }

  Widget _buildCursoCard(Map<String, dynamic> curso) {
    final status = curso['status'] ?? 'ativo';
    final isAtivo = status == 'ativo';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAtivo
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
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
                    curso['nome'] ?? 'Curso sem nome',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAtivo ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAtivo ? 'Ativo' : 'Inativo',
                    style: const TextStyle(
                      color: _whiteColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (curso['descricao'] != null &&
                curso['descricao'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                curso['descricao'],
                style: TextStyle(
                  fontSize: 14,
                  color: _textColor.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (curso['duracao'] != null) ...[
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: _textColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${curso['duracao']} semestres',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (curso['codigo'] != null) ...[
                  Icon(
                    Icons.code,
                    size: 16,
                    color: _textColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    curso['codigo'],
                    style: TextStyle(
                      fontSize: 12,
                      color: _textColor.withOpacity(0.6),
                    ),
                  ),
                ],
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
                ? const Center(child: CircularProgressIndicator())
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
