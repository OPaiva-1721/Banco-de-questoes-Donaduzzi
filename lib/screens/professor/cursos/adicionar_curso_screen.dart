import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_constants.dart';
import '../../../services/course_service.dart';
import '../../../utils/message_utils.dart';

class AdicionarCursoScreen extends StatefulWidget {
  const AdicionarCursoScreen({super.key});

  @override
  State<AdicionarCursoScreen> createState() => _AdicionarCursoScreenState();
}

class _AdicionarCursoScreenState extends State<AdicionarCursoScreen> {
  // Constantes de cores
  static const Color _primaryColor = AppColors.primary;
  static const Color _backgroundColor = AppColors.background;
  static const Color _textColor = AppColors.text;
  static const Color _whiteColor = AppColors.white;

  // Serviços
  final CourseService _courseService = CourseService();

  // Controladores
  final TextEditingController _nomeController = TextEditingController();
  // REMOVIDO: _descricaoController
  // REMOVIDO: _duracaoController

  // Estados
  bool _isLoading = false;

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

  /// Salva o curso após validar o formulário
  Future<void> _salvarCurso() async {
    if (!_validarFormulario()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nome = _nomeController.text.trim();

      // MUDANÇA: Chama o createCourse só com o nome
      final cursoId = await _courseService.createCourse(nome);

      if (mounted) {
        if (cursoId != null) {
          MessageUtils.mostrarSucesso(context, 'Curso criado com sucesso!');
          Navigator.pop(context, true);
        } else {
          MessageUtils.mostrarErro(context, 'Erro ao criar curso');
        }
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErro(context, 'Erro ao criar curso: $e');
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
    _nomeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: _whiteColor,
        title: const Text(
          'Adicionar Curso',
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
                'Novo Curso',
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
                      'Limpar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _salvarCurso,
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
                            'Salvar Curso',
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
