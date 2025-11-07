import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prova/models/discipline_model.dart';
import '../../../core/app_colors.dart'; // Assumindo que você tem isso
import '../../../core/app_constants.dart'; // Assumindo que você tem isso
import '../../../services/subject_service.dart'; // MUDANÇA: Service correto
import '../../../utils/message_utils.dart';

class EditarDisciplinaScreen extends StatefulWidget {
  // MUDANÇA: Recebe o objeto Subject
  final Discipline disciplina;

  const EditarDisciplinaScreen({super.key, required this.disciplina});

  @override
  State<EditarDisciplinaScreen> createState() => _EditarDisciplinaScreenState();
}

class _EditarDisciplinaScreenState extends State<EditarDisciplinaScreen> {
  // Constantes de cores
  static const Color _primaryColor = Color(0xFF541822);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _whiteColor = Colors.white;

  // Serviços
  final SubjectService _subjectService =
      SubjectService(); // MUDANÇA: Service correto

  // Controladores
  late final TextEditingController _nomeController;
  // REMOVIDO: _descricaoController
  // REMOVIDO: _cargaHorariaController

  // Estados
  late int _semestreSelecionado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // MUDANÇA: Inicializar com dados do objeto Subject
    _nomeController = TextEditingController(text: widget.disciplina.name);
    _semestreSelecionado = widget.disciplina.semester;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  /// Valida se todos os campos obrigatórios foram preenchidos
  bool _validarFormulario() {
    if (_nomeController.text.trim().isEmpty) {
      MessageUtils.mostrarErro(context, 'Digite o nome da disciplina');
      return false;
    }
    return true;
  }

  /// Salva as alterações da disciplina
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
      // MUDANÇA: Prepara o Map apenas com os dados que o service aceita
      final updateData = {
        'name': _nomeController.text.trim(),
        'semester': _semestreSelecionado,
      };

      // MUDANÇA: Chama o updateSubject do service
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
          Navigator.pop(context, true); // Retorna true para indicar sucesso
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          // Header com logo e botão voltar
          Container(
            width: double.infinity,
            height: 100,
            decoration: const BoxDecoration(
              color: _primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 8),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Logo centralizado
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 196,
                    height: 67,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 196,
                        height: 67,
                        decoration: BoxDecoration(
                          color: _whiteColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'LOGO',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Botão voltar
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: _whiteColor,
                        size: 28,
                      ),
                      tooltip: 'Voltar',
                      style: IconButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Conteúdo principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  const Text(
                    'Editar Disciplina',
                    style: TextStyle(
                      color: _textColor,
                      fontFamily: 'Inter-Bold',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo Nome
                  const Text(
                    'Nome da Disciplina',
                    style: TextStyle(
                      color: _textColor,
                      fontFamily: 'Inter-Bold',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildContainer(
                    child: TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Programação I',
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

                  // Campo Semestre
                  const Text(
                    'Semestre',
                    style: TextStyle(
                      color: _textColor,
                      fontFamily: 'Inter-Bold',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildContainer(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _semestreSelecionado,
                        items: List.generate(20, (index) => index + 1).map((
                          semestre,
                        ) {
                          return DropdownMenuItem<int>(
                            value: semestre,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text('$semestreº Semestre'),
                            ),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _semestreSelecionado = newValue ?? 1;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // REMOVIDO: Carga Horária
                  // REMOVIDO: Descrição
                  const SizedBox(height: 32),

                  // Botão Salvar
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _salvarAlteracoes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: _whiteColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
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
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cria um container reutilizável com estilo padrão
  Widget _buildContainer({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height ?? 50,
      decoration: BoxDecoration(
        color: _whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}
