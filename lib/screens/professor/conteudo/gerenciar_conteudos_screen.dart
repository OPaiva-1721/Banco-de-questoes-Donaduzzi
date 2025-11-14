import 'package:flutter/material.dart';
import '../../../models/content_model.dart';
import '../../../models/discipline_model.dart';
import '../../../services/content_service.dart';
import '../../../services/subject_service.dart';
import '../../../utils/message_utils.dart';
import 'adicionar_conteudo_screen.dart';
import 'editar_conteudo_screen.dart';

class GerenciarConteudosScreen extends StatefulWidget {
  const GerenciarConteudosScreen({super.key});

  @override
  State<GerenciarConteudosScreen> createState() =>
      _GerenciarConteudosScreenState();
}

class _GerenciarConteudosScreenState extends State<GerenciarConteudosScreen> {
  static const Color _primaryColor = Color(0xFF541822);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _whiteColor = Colors.white;

  final ContentService _contentService = ContentService();
  final SubjectService _subjectService = SubjectService();

  List<Content> _conteudos = [];
  List<Discipline> _disciplinas = [];
  String? _disciplinaFiltro;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _carregarDisciplinas();
      if (_disciplinaFiltro != null) {
        await _carregarConteudos();
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErroFormatado(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _carregarDisciplinas() async {
    try {
      final event = await _subjectService.listarDisciplinas().first;

      if (event.snapshot.exists && event.snapshot.value != null) {
        final disciplinas = <Discipline>[];
        for (final child in event.snapshot.children) {
          disciplinas.add(Discipline.fromSnapshot(child));
        }
        if (mounted) {
          setState(() {
            _disciplinas = disciplinas;
            if (_disciplinaFiltro == null && disciplinas.isNotEmpty) {
              _disciplinaFiltro = disciplinas.first.id;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  Future<void> _carregarConteudos() async {
    if (_disciplinaFiltro == null) return;

    try {
      final conteudos = await _contentService
          .getContentBySubjectStream(_disciplinaFiltro!)
          .first;

      if (mounted) {
        setState(() {
          _conteudos = conteudos;
        });
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  Future<void> _deletarConteudo(Content conteudo) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Tem certeza que deseja APAGAR o conteúdo:\n"${conteudo.description}"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmacao == true && conteudo.id != null) {
      try {
        await _contentService.deleteContent(conteudo.id!);
        if (mounted) {
          MessageUtils.mostrarSucesso(
            context,
            'Conteúdo apagado com sucesso!',
          );
          await _carregarConteudos();
        }
      } catch (e) {
        if (mounted) {
          MessageUtils.mostrarErroFormatado(context, e);
        }
      }
    }
  }

  Future<void> _navegarParaAdicionar() async {
    if (_disciplinaFiltro == null) {
      MessageUtils.mostrarErro(context, 'Selecione uma disciplina primeiro');
      return;
    }

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AdicionarConteudoScreen(disciplinaId: _disciplinaFiltro!),
      ),
    );

    if (resultado == true) {
      await _carregarConteudos();
    }
  }

  Future<void> _navegarParaEditar(Content conteudo) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarConteudoScreen(conteudo: conteudo),
      ),
    );

    if (resultado == true) {
      await _carregarConteudos();
    }
  }

  String _getNomeDisciplina(String? disciplinaId) {
    if (disciplinaId == null) return 'Desconhecida';
    final disciplina = _disciplinas.firstWhere(
      (d) => d.id == disciplinaId,
      orElse: () => Discipline(name: 'Desconhecida', semester: 0),
    );
    return disciplina.name;
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
        title: const Text('Gerenciar Conteúdos'),
        backgroundColor: _primaryColor,
        elevation: 0,
        foregroundColor: _whiteColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtrar por Disciplina',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _disciplinaFiltro,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: _disciplinas.map((disciplina) {
                            return DropdownMenuItem(
                              value: disciplina.id,
                              child: Text(disciplina.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _disciplinaFiltro = value;
                            });
                            _carregarConteudos();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildContainer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: ${_conteudos.length} conteúdo(s)',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _navegarParaAdicionar,
                          icon: const Icon(Icons.add),
                          label: const Text('Novo Conteúdo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: _whiteColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _conteudos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.library_books_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhum conteúdo cadastrado',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _navegarParaAdicionar,
                                  icon: const Icon(Icons.add),
                                  label: const Text(
                                    'Adicionar primeiro conteúdo',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _conteudos.length,
                            itemBuilder: (context, index) {
                              final conteudo = _conteudos[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: _buildContainer(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              conteudo.description,
                                              style: TextStyle(
                                                color: _textColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Disciplina: ${_getNomeDisciplina(conteudo.subjectId)}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            color: _primaryColor,
                                            onPressed: () =>
                                                _navegarParaEditar(conteudo),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            color: Colors.red,
                                            onPressed: () =>
                                                _deletarConteudo(conteudo),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
