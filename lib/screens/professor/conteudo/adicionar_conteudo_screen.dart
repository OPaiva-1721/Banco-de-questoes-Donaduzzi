import 'package:flutter/material.dart';
import '../../../services/content_service.dart';
import '../../../utils/message_utils.dart';

class AdicionarConteudoScreen extends StatefulWidget {
  final String disciplinaId;

  const AdicionarConteudoScreen({super.key, required this.disciplinaId});

  @override
  State<AdicionarConteudoScreen> createState() =>
      _AdicionarConteudoScreenState();
}

class _AdicionarConteudoScreenState extends State<AdicionarConteudoScreen> {
  static const Color _primaryColor = Color(0xFF541822);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _whiteColor = Colors.white;

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

    setState(() {
      _isLoading = true;
    });

    try {
      final conteudoId = await _contentService.createContent(
        description: _descricaoController.text.trim(),
        subjectId: widget.disciplinaId,
      );

      if (mounted) {
        if (conteudoId != null) {
          MessageUtils.mostrarSucesso(context, 'Conteúdo criado com sucesso!');
          Navigator.pop(context, true);
        } else {
          MessageUtils.mostrarErro(context, 'Erro ao criar conteúdo');
        }
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErro(context, 'Erro ao criar conteúdo: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildContainer({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _whiteColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Novo Conteúdo'),
        backgroundColor: _primaryColor,
        elevation: 0,
        foregroundColor: _whiteColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descrição do Conteúdo',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descricaoController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText:
                          'Ex: Introdução à álgebra linear, Vetores e matrizes...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _salvarConteudo,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: _whiteColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_whiteColor),
                      ),
                    )
                  : const Text(
                      'Salvar Conteúdo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
