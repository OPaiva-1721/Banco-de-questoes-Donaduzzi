import 'package:flutter/material.dart';

class AdicionarQuestaoScreen extends StatefulWidget {
  const AdicionarQuestaoScreen({super.key});

  @override
  State<AdicionarQuestaoScreen> createState() => _AdicionarQuestaoScreenState();
}

class _AdicionarQuestaoScreenState extends State<AdicionarQuestaoScreen> {
  // Constantes de cores
  static const Color _primaryColor = Color(0xFF541822);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _whiteColor = Colors.white;

  // Controladores para os campos
  final TextEditingController _enunciadoController = TextEditingController();

  // Estados dos dropdowns
  String? _cursoSelecionado;
  String? _materiaSelecionada;
  String _dificuldadeSelecionada = 'Fácil';

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
    _enunciadoController.dispose();
    super.dispose();
  }

  /// Salva a questão após validar o formulário
  void _salvarQuestao() {
    if (_validarFormulario()) {
      // TODO: Implementar a lógica para salvar no Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Questão salva com sucesso!'),
          backgroundColor: _primaryColor,
        ),
      );
      _limparFormulario();
    }
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
    if (_enunciadoController.text.trim().isEmpty) {
      _mostrarErro('Digite o enunciado da questão');
      return false;
    }
    return true;
  }

  /// Exibe uma mensagem de erro para o usuário
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  /// Limpa todos os campos do formulário
  void _limparFormulario() {
    setState(() {
      _cursoSelecionado = null;
      _materiaSelecionada = null;
      _dificuldadeSelecionada = 'Fácil';
      _enunciadoController.clear();
    });
  }

  /// Cria um container reutilizável com estilo padrão
  Widget _buildContainer({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height ?? 50,
      decoration: BoxDecoration(
        color: _whiteColor,
        borderRadius: BorderRadius.circular(10),
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

  /// Cria um botão de seleção de dificuldade
  Widget _buildDificuldadeButton(String dificuldade, int index) {
    final isSelected = _dificuldadeSelecionada == dificuldade;

    return GestureDetector(
      onTap: () {
        setState(() {
          _dificuldadeSelecionada = dificuldade;
        });
      },
      child: Container(
        width: 80,
        height: 49,
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : _whiteColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            dificuldade,
            style: TextStyle(
              color: isSelected ? _whiteColor : _textColor,
              fontFamily: 'Inter-Bold',
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
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
            height: 100, // Altura original
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
                  const Center(
                    child: Text(
                      'Adicionar Questões',
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

                  // Campo Dificuldade
                  const Text(
                    'Nível de dificuldade',
                    style: TextStyle(
                      color: _textColor,
                      fontFamily: 'Inter-Bold',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDificuldadeButton('Fácil', 0),
                        const SizedBox(width: 20),
                        _buildDificuldadeButton('Médio', 1),
                        const SizedBox(width: 20),
                        _buildDificuldadeButton('Difícil', 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo Enunciado
                  const Text(
                    'Enunciado',
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
                      controller: _enunciadoController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Insira o enunciado da questão',
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
                          onPressed: _salvarQuestao,
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
                            'Salvar Questão',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _limparFormulario,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
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
                            'Limpar',
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
