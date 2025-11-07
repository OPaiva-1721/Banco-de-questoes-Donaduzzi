import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:prova/models/discipline_model.dart';
import '../../../core/app_colors.dart'; // Assumindo que você tem isso
import '../../../services/subject_service.dart'; // MUDANÇA: Service correto
import '../../../utils/message_utils.dart';
import 'adicionar_disciplina_screen.dart';
import 'editar_disciplina_screen.dart';

class GerenciarDisciplinasScreen extends StatefulWidget {
  const GerenciarDisciplinasScreen({super.key});

  @override
  State<GerenciarDisciplinasScreen> createState() =>
      _GerenciarDisciplinasScreenState();
}

class _GerenciarDisciplinasScreenState
    extends State<GerenciarDisciplinasScreen> {
  // Constantes de cores
  static const Color _primaryColor = Color(0xFF541822);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _whiteColor = Colors.white;

  // Serviços
  final SubjectService _subjectService =
      SubjectService(); // MUDANÇA: Service correto

  // Estados
  List<Discipline> _disciplinas = []; // MUDANÇA: Usa o modelo Subject
  bool _isLoading = true;
  // REMOVIDO: _filtroStatus

  @override
  void initState() {
    super.initState();
    _carregarDisciplinas();
  }

  /// Carrega disciplinas do Firebase
  Future<void> _carregarDisciplinas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // MUDANÇA: Usa a stream do service
      final event = await _subjectService.listarDisciplinas().first;

      if (event.snapshot.exists && event.snapshot.value != null) {
        final disciplinas = <Discipline>[];
        for (final child in event.snapshot.children) {
          // MUDANÇA: Usa o factory .fromSnapshot
          disciplinas.add(Discipline.fromSnapshot(child));
        }
        if (mounted) {
          setState(() {
            _disciplinas = disciplinas;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _disciplinas = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        MessageUtils.mostrarErro(context, 'Erro ao carregar disciplinas: $e');
      }
    }
  }

  // REMOVIDO: _getDisciplinasFiltradas()
  // REMOVIDO: _formatarData()

  /// Deleta uma disciplina (Hard Delete)
  Future<void> _deletarDisciplina(Discipline disciplina) async {
    // MUDANÇA: Recebe Subject
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          // MUDANÇA: usa disciplina.name
          'Tem certeza que deseja APAGAR a disciplina:\n"${disciplina.name}"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmacao == true && disciplina.id != null) {
      try {
        // MUDANÇA: Chama deleteSubject do service
        final sucesso = await _subjectService.deleteSubject(disciplina.id!);
        if (mounted) {
          MessageUtils.mostrarSucesso(
            context,
            'Disciplina deletada com sucesso!',
          );
          _carregarDisciplinas(); // Recarregar dados
        }
      } catch (e) {
        // O service lança uma exceção se a disciplina estiver em uso
        if (mounted) {
          MessageUtils.mostrarErro(context, 'Erro: ${e.toString()}');
        }
      }
    }
  }

  // REMOVIDO: _alterarStatusDisciplina()

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
                        'Gerenciar Disciplinas',
                        style: TextStyle(
                          color: _textColor,
                          fontFamily: 'Inter-Bold',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final resultado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdicionarDisciplinaScreen(),
                            ),
                          );
                          if (resultado == true) {
                            _carregarDisciplinas(); // Recarregar se adicionou
                          }
                        },
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
                // REMOVIDO: Filtro de status
                // Lista de disciplinas
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _disciplinas.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _disciplinas.length,
                          itemBuilder: (context, index) {
                            final disciplina = _disciplinas[index];
                            return _buildDisciplinaCard(disciplina);
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

  /// Cria o estado vazio quando não há disciplinas
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Nenhuma disciplina cadastrada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Clique em "+" para adicionar uma disciplina',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Cria um card para cada disciplina
  Widget _buildDisciplinaCard(Discipline disciplina) {
    // MUDANÇA: Recebe Subject

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
            // Header com botões
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // REMOVIDO: Botão de status
                IconButton(
                  onPressed: () => _deletarDisciplina(disciplina),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Deletar disciplina',
                ),
                IconButton(
                  onPressed: () async {
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditarDisciplinaScreen(disciplina: disciplina),
                      ),
                    );
                    if (resultado == true) {
                      _carregarDisciplinas(); // Recarregar se editou
                    }
                  },
                  icon: const Icon(Icons.edit),
                  color: _primaryColor,
                  tooltip: 'Editar disciplina',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Nome da disciplina
            Text(
              disciplina.name, // MUDANÇA: usa disciplina.name
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            // Informações da disciplina
            Row(
              children: [
                _buildInfoChip(
                  Icons.school,
                  'Semestre ${disciplina.semester}', // MUDANÇA: usa disciplina.semester
                  Colors.blue,
                ),
                // REMOVIDO: Carga Horária e Data de Criação
              ],
            ),
            // REMOVIDO: Descrição
          ],
        ),
      ),
    );
  }

  /// Cria um chip de informação (reutilizado)
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
}
