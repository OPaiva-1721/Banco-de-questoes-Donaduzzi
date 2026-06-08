import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../models/discipline_model.dart';
import '../../../services/subject_service.dart';
import '../../../utils/message_utils.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_save_button.dart';
import '../../../widgets/form_field_section.dart';

class EditarDisciplinaScreen extends StatefulWidget {
  final Discipline disciplina;

  const EditarDisciplinaScreen({super.key, required this.disciplina});

  @override
  State<EditarDisciplinaScreen> createState() => _EditarDisciplinaScreenState();
}

class _EditarDisciplinaScreenState extends State<EditarDisciplinaScreen> {
  final SubjectService _subjectService = SubjectService();
  late final TextEditingController _nomeController;
  late int _semestreSelecionado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.disciplina.name);
    _semestreSelecionado = widget.disciplina.semester;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  bool _validarFormulario() {
    if (_nomeController.text.trim().isEmpty) {
      MessageUtils.mostrarErro(context, 'Digite o nome da disciplina');
      return false;
    }
    return true;
  }

  Future<void> _salvarAlteracoes() async {
    if (!_validarFormulario()) return;
    if (widget.disciplina.id == null) {
      MessageUtils.mostrarErro(context, 'Erro: ID da disciplina não encontrado.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _subjectService.updateSubject(
        widget.disciplina.id!,
        {
          'name': _nomeController.text.trim(),
          'semester': _semestreSelecionado,
        },
      );
      if (mounted) {
        MessageUtils.mostrarSucesso(context, 'Disciplina atualizada com sucesso!');
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
        title: const Text('Editar Disciplina'),
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
                label: 'Nome da Disciplina',
                field: TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Matemática, Português, etc.',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: FormFieldSection(
                label: 'Semestre',
                field: DropdownButtonFormField<int>(
                  initialValue: _semestreSelecionado,
                  decoration: const InputDecoration(),
                  items: List.generate(
                    10,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1}º Semestre'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) setState(() => _semestreSelecionado = value);
                  },
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
