import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../services/course_service.dart';
import '../../../utils/message_utils.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_save_button.dart';
import '../../../widgets/form_field_section.dart';

class AdicionarCursoScreen extends StatefulWidget {
  const AdicionarCursoScreen({super.key});

  @override
  State<AdicionarCursoScreen> createState() => _AdicionarCursoScreenState();
}

class _AdicionarCursoScreenState extends State<AdicionarCursoScreen> {
  final CourseService _courseService = CourseService();
  late final TextEditingController _nomeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
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

  Future<void> _salvarCurso() async {
    if (!_validarFormulario()) return;
    setState(() => _isLoading = true);
    try {
      await _courseService.createCourse(_nomeController.text.trim());
      if (mounted) {
        MessageUtils.mostrarSucesso(context, 'Curso criado com sucesso!');
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
        title: const Text('Novo Curso'),
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
              label: 'Salvar Curso',
              isLoading: _isLoading,
              onPressed: _salvarCurso,
            ),
          ],
        ),
      ),
    );
  }
}
