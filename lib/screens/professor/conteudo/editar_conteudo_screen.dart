import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../models/content_model.dart';
import '../../../services/content_service.dart';
import '../../../utils/message_utils.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_save_button.dart';
import '../../../widgets/form_field_section.dart';

class EditarConteudoScreen extends StatefulWidget {
  final Content conteudo;

  const EditarConteudoScreen({super.key, required this.conteudo});

  @override
  State<EditarConteudoScreen> createState() => _EditarConteudoScreenState();
}

class _EditarConteudoScreenState extends State<EditarConteudoScreen> {
  final ContentService _contentService = ContentService();
  late final TextEditingController _descricaoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descricaoController = TextEditingController(
      text: widget.conteudo.description,
    );
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  bool _validarFormulario() {
    if (_descricaoController.text.trim().isEmpty) {
      MessageUtils.mostrarErro(context, 'Digite a descrição do conteúdo');
      return false;
    }
    return true;
  }

  Future<void> _salvarAlteracoes() async {
    if (!_validarFormulario()) return;
    if (widget.conteudo.id == null) {
      MessageUtils.mostrarErro(context, 'Erro: ID do conteúdo não encontrado.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _contentService.updateContent(
        widget.conteudo.id!,
        {'description': _descricaoController.text.trim()},
      );
      if (mounted) {
        MessageUtils.mostrarSucesso(context, 'Conteúdo atualizado com sucesso!');
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
        title: const Text('Editar Conteúdo'),
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
                label: 'Descrição do Conteúdo',
                field: TextField(
                  controller: _descricaoController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Introdução à álgebra linear, Vetores e matrizes...',
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
