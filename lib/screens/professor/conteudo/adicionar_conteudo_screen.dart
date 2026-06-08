import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../services/content_service.dart';
import '../../../utils/message_utils.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_save_button.dart';
import '../../../widgets/form_field_section.dart';

class AdicionarConteudoScreen extends StatefulWidget {
  final String disciplinaId;

  const AdicionarConteudoScreen({super.key, required this.disciplinaId});

  @override
  State<AdicionarConteudoScreen> createState() =>
      _AdicionarConteudoScreenState();
}

class _AdicionarConteudoScreenState extends State<AdicionarConteudoScreen> {
  final ContentService _contentService = ContentService();
  late final TextEditingController _descricaoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descricaoController = TextEditingController();
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

  Future<void> _salvarConteudo() async {
    if (!_validarFormulario()) return;
    setState(() => _isLoading = true);
    try {
      await _contentService.createContent(
        description: _descricaoController.text.trim(),
        subjectId: widget.disciplinaId,
      );
      if (mounted) {
        MessageUtils.mostrarSucesso(context, 'Conteúdo criado com sucesso!');
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
        title: const Text('Novo Conteúdo'),
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
              label: 'Salvar Conteúdo',
              isLoading: _isLoading,
              onPressed: _salvarConteudo,
            ),
          ],
        ),
      ),
    );
  }
}
