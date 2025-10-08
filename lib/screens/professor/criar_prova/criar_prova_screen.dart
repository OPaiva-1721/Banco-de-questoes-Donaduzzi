import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_constants.dart';

class CriarProvaScreen extends StatefulWidget {
  const CriarProvaScreen({super.key});

  @override
  State<CriarProvaScreen> createState() => _CriarProvaScreenState();
}

class _CriarProvaScreenState extends State<CriarProvaScreen> {
  // Constantes de cores
  static const Color _primaryColor = AppColors.primary;
  static const Color _backgroundColor = AppColors.background;
  static const Color _textColor = AppColors.text;
  static const Color _whiteColor = AppColors.white;

  // Estados dos dropdowns
  String? _cursoSelecionado;
  String? _materiaSelecionada;
  final TextEditingController _descriptionController = TextEditingController();

  // Listas de opções
  final List<String> _cursos = [
    'Ciência da Computação',
    'Engenharia de Software',
    'Sistemas de Informação',
    'Análise e Desenvolvimento de Sistemas',
    'Tecnologia da Informação',
  ];

  final List<String> _materias = [
    'Programação',
    'Algoritmos',
    'Estruturas de Dados',
    'Banco de Dados',
    'Engenharia de Software',
    'Redes de Computadores',
    'Inteligência Artificial',
    'Desenvolvimento Mobile',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Valida se todos os campos obrigatórios foram preenchidos
  bool _validarFormulario() {
    if (_cursoSelecionado == null) {
      _mostrarErro('Selecione um curso');
      return false;
    }
    if (_materiaSelecionada == null) {
      _mostrarErro('Selecione uma matéria');
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _mostrarErro('Digite uma descrição para a prova');
      return false;
    }
    return true;
  }

  /// Exibe uma mensagem de erro para o usuário
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: AppColors.error),
    );
  }

  /// Salva os dados da prova após validar o formulário
  void _salvarProva() {
    if (_validarFormulario()) {
      // TODO: Implementar a lógica para salvar no Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados salvos! Continuando...'),
          backgroundColor: _primaryColor,
        ),
      );
      // Navegar para próxima tela ou continuar o fluxo
    }
  }

  /// Cria um container reutilizável com estilo padrão
  Widget _buildContainer({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height ?? 50,
      decoration: BoxDecoration(
        color: _whiteColor,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
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
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  const Center(
                    child: Text(
                      'Criar Nova Prova',
                      style: TextStyle(
                        color: _textColor,
                        fontFamily: 'Inter-Bold',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo Curso
                  const Text(
                    'Curso(s)',
                    style: TextStyle(
                      color: _textColor,
                      fontFamily: 'Inter-Bold',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContainer(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _cursoSelecionado,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Selecione o(s) curso(s)',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        items: _cursos.map((String curso) {
                          return DropdownMenuItem<String>(
                            value: curso,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(curso),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _cursoSelecionado = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo Matéria
                  const Text(
                    'Matéria',
                    style: TextStyle(
                      color: _textColor,
                      fontFamily: 'Inter-Bold',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContainer(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _materiaSelecionada,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Selecione a matéria',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        items: _materias.map((String materia) {
                          return DropdownMenuItem<String>(
                            value: materia,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(materia),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _materiaSelecionada = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo Descrição
                  const Text(
                    'Descrição',
                    style: TextStyle(
                      color: _textColor,
                      fontFamily: 'Inter-Bold',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContainer(
                    height: 100,
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Insira uma descrição para a prova',
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
                          onPressed: _salvarProva,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: _whiteColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Continuar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
}
