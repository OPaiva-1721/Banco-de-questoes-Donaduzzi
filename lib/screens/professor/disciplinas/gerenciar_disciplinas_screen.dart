import 'package:flutter/material.dart';
import '../../../services/discipline_service.dart';
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
  final DisciplineService _disciplineService = DisciplineService();

  // Estados
  List<Map<String, dynamic>> _disciplinas = [];
  bool _isLoading = true;
  String _filtroStatus = 'todas';

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
      final stream = _disciplineService.listarDisciplinas();
      await for (final event in stream) {
        if (event.snapshot.exists) {
          final disciplinas = <Map<String, dynamic>>[];
          for (final child in event.snapshot.children) {
            final disciplina = {
              'id': child.key,
              ...Map<String, dynamic>.from(child.value as Map),
            };
            disciplinas.add(disciplina);
          }
          setState(() {
            _disciplinas = disciplinas;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      MessageUtils.mostrarErro(context, 'Erro ao carregar disciplinas: $e');
    }
  }

  /// Filtra disciplinas baseado no status
  List<Map<String, dynamic>> _getDisciplinasFiltradas() {
    if (_filtroStatus == 'todas') {
      return _disciplinas;
    }
    return _disciplinas
        .where((disciplina) => disciplina['status'] == _filtroStatus)
        .toList();
  }

  /// Formata a data de criação
  String _formatarData(dynamic timestamp) {
    if (timestamp == null) return 'Data não disponível';

    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  /// Deleta uma disciplina
  Future<void> _deletarDisciplina(Map<String, dynamic> disciplina) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Tem certeza que deseja deletar a disciplina:\n"${disciplina['nome']}"?',
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

    if (confirmacao == true) {
      try {
        final sucesso = await _disciplineService.deletarDisciplina(
          disciplina['id'],
        );
        if (sucesso) {
          MessageUtils.mostrarSucesso(
            context,
            'Disciplina deletada com sucesso!',
          );
          _carregarDisciplinas(); // Recarregar dados
        } else {
          MessageUtils.mostrarErro(context, 'Erro ao deletar disciplina');
        }
      } catch (e) {
        MessageUtils.mostrarErro(context, 'Erro ao deletar disciplina: $e');
      }
    }
  }

  /// Altera o status de uma disciplina
  Future<void> _alterarStatusDisciplina(Map<String, dynamic> disciplina) async {
    final novoStatus = disciplina['status'] == 'ativo' ? 'inativo' : 'ativo';

    try {
      final sucesso = await _disciplineService.alterarStatusDisciplina(
        disciplina['id'],
        novoStatus,
      );

      if (sucesso) {
        MessageUtils.mostrarSucesso(
          context,
          'Status alterado para ${novoStatus == 'ativo' ? 'ativo' : 'inativo'}!',
        );
        _carregarDisciplinas(); // Recarregar dados
      } else {
        MessageUtils.mostrarErro(context, 'Erro ao alterar status');
      }
    } catch (e) {
      MessageUtils.mostrarErro(context, 'Erro ao alterar status: $e');
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
                // Filtro de status
                _buildFiltroStatus(),
                // Lista de disciplinas
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _getDisciplinasFiltradas().isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _getDisciplinasFiltradas().length,
                          itemBuilder: (context, index) {
                            final disciplina =
                                _getDisciplinasFiltradas()[index];
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

  /// Cria o filtro de status
  Widget _buildFiltroStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          const Text(
            'Filtrar por status:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filtroStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem<String>(value: 'todas', child: Text('Todas')),
                DropdownMenuItem<String>(value: 'ativo', child: Text('Ativas')),
                DropdownMenuItem<String>(
                  value: 'inativo',
                  child: Text('Inativas'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _filtroStatus = value ?? 'todas';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Cria um card para cada disciplina
  Widget _buildDisciplinaCard(Map<String, dynamic> disciplina) {
    final isAtivo = disciplina['status'] == 'ativo';

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
            // Header com status e botões
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip(isAtivo),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _alterarStatusDisciplina(disciplina),
                      icon: Icon(
                        isAtivo ? Icons.pause : Icons.play_arrow,
                        color: isAtivo ? Colors.orange : Colors.green,
                      ),
                      tooltip: isAtivo ? 'Desativar' : 'Ativar',
                    ),
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
              ],
            ),
            const SizedBox(height: 12),
            // Nome da disciplina
            Text(
              disciplina['nome'] ?? 'Disciplina sem nome',
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
                  'Semestre ${disciplina['semestre'] ?? 'N/A'}',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.access_time,
                  '${disciplina['cargaHoraria'] ?? 0}h',
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.calendar_today,
                  _formatarData(disciplina['dataCriacao']),
                  Colors.orange,
                ),
              ],
            ),
            if (disciplina['descricao'] != null &&
                disciplina['descricao'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                disciplina['descricao'],
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Cria um chip de status
  Widget _buildStatusChip(bool isAtivo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isAtivo ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isAtivo ? Colors.green : Colors.red).withOpacity(0.3),
        ),
      ),
      child: Text(
        isAtivo ? 'Ativa' : 'Inativa',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isAtivo ? Colors.green : Colors.red,
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
}
