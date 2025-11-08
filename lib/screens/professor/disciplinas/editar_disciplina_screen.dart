import 'package:flutter/material.dart';
import '../../../models/discipline_model.dart';
import '../../../services/subject_service.dart';
import '../../../utils/message_utils.dart';

class EditarDisciplinaScreen extends StatefulWidget {
  final Discipline disciplina;

  const EditarDisciplinaScreen({super.key, required this.disciplina});

  @override
  State<EditarDisciplinaScreen> createState() => _EditarDisciplinaScreenState();
}

class _EditarDisciplinaScreenState extends State<EditarDisciplinaScreen> {
  static const Color _primaryColor = Color(0xFF541822);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _whiteColor = Colors.white;

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
      MessageUtils.mostrarErro(
        context,
        'Erro: ID da disciplina não encontrado.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updateData = {
        'name': _nomeController.text.trim(),
        'semester': _semestreSelecionado,
      };

      final sucesso = await _subjectService.updateSubject(
        widget.disciplina.id!,
        updateData,
      );

      if (mounted) {
        if (sucesso) {
          MessageUtils.mostrarSucesso(
            context,
            'Disciplina atualizada com sucesso!',
          );
          Navigator.pop(context, true);
        } else {
          MessageUtils.mostrarErro(context, 'Erro ao atualizar disciplina');
        }
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErro(context, 'Erro ao atualizar disciplina: $e');
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
        title: const Text('Editar Disciplina'),
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
                    'Nome da Disciplina',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Matemática, Português, etc.',
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
            const SizedBox(height: 20),
            _buildContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semestre',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _semestreSelecionado,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items: List.generate(
                      10,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}º Semestre'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _semestreSelecionado = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _salvarAlteracoes,
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
    );
  }
}
