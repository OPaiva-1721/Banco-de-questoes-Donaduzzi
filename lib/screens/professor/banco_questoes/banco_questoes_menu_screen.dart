import 'package:flutter/material.dart';
import 'adicionar_questao_screen.dart';
import 'editar_questao_screen.dart';

class BancoQuestoesMenuScreen extends StatefulWidget {
  const BancoQuestoesMenuScreen({super.key});

  @override
  State<BancoQuestoesMenuScreen> createState() =>
      _BancoQuestoesMenuScreenState();
}

class _BancoQuestoesMenuScreenState extends State<BancoQuestoesMenuScreen> {
  // Constantes de cores
  static const Color _primaryColor = Color(0xFF541822);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _whiteColor = Colors.white;

  // Lista de questões de exemplo (em produção, isso viria do Firebase)
  final List<Map<String, dynamic>> _questoes = [
    {
      'id': '1',
      'enunciado':
          'Qual é a complexidade temporal do algoritmo de ordenação QuickSort no pior caso?',
      'curso': 'Ciência da Computação',
      'materia': 'Algoritmos',
      'dificuldade': 'Médio',
      'dataCriacao': '2024-01-15',
    },
    {
      'id': '2',
      'enunciado':
          'Explique o conceito de herança em programação orientada a objetos.',
      'curso': 'Engenharia de Software',
      'materia': 'Programação',
      'dificuldade': 'Fácil',
      'dataCriacao': '2024-01-14',
    },
    {
      'id': '3',
      'enunciado':
          'Como funciona o protocolo TCP/IP e qual sua diferença do UDP?',
      'curso': 'Sistemas de Informação',
      'materia': 'Redes',
      'dificuldade': 'Difícil',
      'dataCriacao': '2024-01-13',
    },
  ];

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
            child: Column(
              children: [
                // Título e botão adicionar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Banco de Questões',
                        style: TextStyle(
                          color: _textColor,
                          fontFamily: 'Inter-Bold',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdicionarQuestaoScreen(),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: _whiteColor,
                          padding: const EdgeInsets.all(12),
                          shape: const CircleBorder(),
                          elevation: 4,
                        ),
                        child: const Icon(Icons.add, size: 24),
                      ),
                    ],
                  ),
                ),
                // Lista de questões
                Expanded(
                  child: _questoes.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _questoes.length,
                          itemBuilder: (context, index) {
                            final questao = _questoes[index];
                            return _buildQuestaoCard(questao);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Cria o estado vazio quando não há questões
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Nenhuma questão cadastrada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Clique em "Nova Questão" para começar',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Cria um card para cada questão
  Widget _buildQuestaoCard(Map<String, dynamic> questao) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com dificuldade e botão editar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDificuldadeChip(questao['dificuldade']),
                IconButton(
                  onPressed: () => _editarQuestao(questao),
                  icon: const Icon(Icons.edit),
                  color: _primaryColor,
                  tooltip: 'Editar questão',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Enunciado
            Text(
              questao['enunciado'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Informações da questão
            Row(
              children: [
                _buildInfoChip(Icons.school, questao['curso'], Colors.blue),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.book, questao['materia'], Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Cria um chip de dificuldade
  Widget _buildDificuldadeChip(String dificuldade) {
    Color color;
    switch (dificuldade.toLowerCase()) {
      case 'fácil':
        color = Colors.green;
        break;
      case 'médio':
        color = Colors.orange;
        break;
      case 'difícil':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        dificuldade,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Cria um chip de informação
  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Navega para a tela de editar questão
  void _editarQuestao(Map<String, dynamic> questao) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarQuestaoScreen(questao: questao),
      ),
    );
  }
}
