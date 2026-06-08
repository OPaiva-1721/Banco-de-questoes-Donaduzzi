import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../models/course_model.dart';
import '../../../services/course_service.dart';
import '../../../utils/message_utils.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_save_button.dart';
import '../../../widgets/form_field_section.dart';

class EditarCursoScreen extends StatefulWidget {
  final Course curso;

  const EditarCursoScreen({super.key, required this.curso});

  @override
  State<EditarCursoScreen> createState() => _EditarCursoScreenState();
}

class _EditarCursoScreenState extends State<EditarCursoScreen> {
  final CourseService _courseService = CourseService();
  late final TextEditingController _nomeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.curso.name);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  bool _validarFormulario() {
    if (_nomeController.text.trim().isEmpty) {
      MessageUtils.mostrarErro(context, 'Digite o nome do curso');
      return false;
    }
    return true;
  }

  Future<void> _salvarAlteracoes() async {
    if (!_validarFormulario()) return;
    if (widget.curso.id == null) {
      MessageUtils.mostrarErro(context, 'Erro: ID do curso não encontrado.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _courseService.updateCourse(
        widget.curso.id!,
        {'name': _nomeController.text.trim()},
      );
      if (mounted) {
        MessageUtils.mostrarSucesso(context, 'Curso atualizado com sucesso!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) MessageUtils.mostrarErroFormatado(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Curso'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: FormFieldSection(
                label: 'Nome do Curso',
                field: TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Engenharia de Software, Medicina, etc.',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            AppSaveButton(
              label: 'Salvar Alterações',
              isLoading: _isLoading,
              onPressed: _salvarAlteracoes,
            ),
          ],
        ),
      ),
    );
  }
}
