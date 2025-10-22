import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_constants.dart';
import '../../../services/course_service.dart';
import '../../../utils/message_utils.dart';

class EditarCursoScreen extends StatefulWidget {
  final Map<String, dynamic> curso;

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
  late final TextEditingController _descricaoController;
  late final TextEditingController _duracaoController;

  // Estados
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores com dados do curso
    _nomeController = TextEditingController(text: widget.curso['nome'] ?? '');
    _descricaoController = TextEditingController(
      text: widget.curso['descricao'] ?? '',
    );
    _duracaoController = TextEditingController(
      text: widget.curso['duracao']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _duracaoController.dispose();
    super.dispose();
  }

  /// Valida se todos os campos obrigatórios foram preenchidos
  bool _validarFormulario() {
    if (_nomeController.text.trim().isEmpty) {
      MessageUtils.mostrarErro(context, 'Digite o nome do curso');
      return false;
    }
    if (_duracaoController.text.trim().isEmpty) {
      MessageUtils.mostrarErro(context, 'Digite a duração do curso');
      return false;
    }

    final duracao = int.tryParse(_duracaoController.text.trim());
    if (duracao == null || duracao <= 0) {
      MessageUtils.mostrarErro(context, 'Duração deve ser um número positivo');
      return false;
    }

    return true;
  }

  /// Salva as alterações após validar o formulário
  Future<void> _salvarAlteracoes() async {
    if (!_validarFormulario()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nome = _nomeController.text.trim();
      final descricao = _descricaoController.text.trim();
      final duracao = int.parse(_duracaoController.text.trim());

      final sucesso = await _courseService.atualizarCurso(widget.curso['id'], {
        'nome': nome,
        'descricao': descricao,
        'duracao': duracao,
      });

      if (sucesso) {
        MessageUtils.mostrarSucesso(context, 'Curso atualizado com sucesso!');
        Navigator.pop(context, true);
      } else {
        MessageUtils.mostrarErro(context, 'Erro ao atualizar curso');
      }
    } catch (e) {
      MessageUtils.mostrarErro(context, 'Erro ao atualizar curso: $e');
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
    _descricaoController.clear();
    _duracaoController.clear();
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

            // Campo Descrição
            const Text(
              'Descrição (Opcional)',
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
                controller: _descricaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Descreva o curso...',
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

            // Campo Duração
            const Text(
              'Duração (Semestres)',
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
                controller: _duracaoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ex: 8',
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
          ],
        ),
      ),
    );
  }
}
