import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_constants.dart';
import '../../../models/course_model.dart'; // MUDANÇA: Importa o modelo
import '../../../services/course_service.dart';
import '../../../utils/message_utils.dart';

class EditarCursoScreen extends StatefulWidget {
  // MUDANÇA: Recebe o objeto Course, não um Map
  final Course curso;

  const EditarCursoScreen({super.key, required this.curso});

  @override
  State<EditarCursoScreen> createState() => _EditarCursoScreenState();
}

class _EditarCursoScreenState extends State<EditarCursoScreen> {
  // Constantes de cores
  static const Color _primaryColor = AppColors.primary;
  static const Color _backgroundColor = AppColors.background;
  static const Color _textColor = AppColors.text;
  static const Color _whiteColor = AppColors.white;

  // Serviços
  final CourseService _courseService = CourseService();

  // Controladores
  late final TextEditingController _nomeController;
  // REMOVIDO: _descricaoController
  // REMOVIDO: _duracaoController

  // Estados
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // MUDANÇA: Inicializar controlador com dados do objeto Course
    _nomeController = TextEditingController(text: widget.curso.name);
    // REMOVIDO: Inicialização dos outros controllers
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  /// Valida se todos os campos obrigatórios foram preenchidos
  bool _validarFormulario() {
    if (_nomeController.text.trim().isEmpty) {
      MessageUtils.mostrarErro(context, 'Digite o nome do curso');
      return false;
    }
    return true;
  }

  /// Salva as alterações após validar o formulário
  Future<void> _salvarAlteracoes() async {
    if (!_validarFormulario()) return;
    if (widget.curso.id == null) {
      MessageUtils.mostrarErro(context, 'Erro: ID do curso não encontrado.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final nome = _nomeController.text.trim();

      // MUDANÇA: Chama 'updateCourse' do service
      // passando um Map apenas com 'name', como o service espera.
      final sucesso = await _courseService.updateCourse(widget.curso.id!, nome);

      if (mounted) {
        if (sucesso) {
          MessageUtils.mostrarSucesso(context, 'Curso atualizado com sucesso!');
          Navigator.pop(context, true);
        } else {
          MessageUtils.mostrarErro(context, 'Erro ao atualizar curso');
        }
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErro(context, 'Erro ao atualizar curso: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Limpa todos os campos do formulário
  void _limparFormulario() {
    // Reseta para o nome original
    _nomeController.text = widget.curso.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: _whiteColor,
        title: const Text(
          'Editar Curso',
          style: TextStyle(
            fontFamily: 'Inter-Bold',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Center(
              child: Text(
                'Editar Curso',
                style: TextStyle(
                  color: _textColor,
                  fontFamily: 'Inter-Bold',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Campo Nome
            const Text(
              'Nome do Curso',
              style: TextStyle(
                color: _textColor,
                fontFamily: 'Inter-Bold',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _whiteColor,
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultBorderRadius,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Engenharia de Software',
                  hintStyle: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // REMOVIDO: Campo Descrição
            // REMOVIDO: Campo Duração
            const SizedBox(height: 32),

            // Botões de Ação
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _limparFormulario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: _textColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Resetar', // Texto alterado
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _salvarAlteracoes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _whiteColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _whiteColor,
                              ),
                            ),
                          )
                        : const Text(
                            'Salvar Alterações', // Texto alterado
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
