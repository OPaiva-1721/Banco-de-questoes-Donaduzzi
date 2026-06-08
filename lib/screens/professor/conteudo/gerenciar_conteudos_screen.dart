import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../models/content_model.dart';
import '../../../models/discipline_model.dart';
import '../../../services/content_service.dart';
import '../../../services/subject_service.dart';
import '../../../utils/message_utils.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/confirm_delete_dialog.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/form_field_section.dart';
import 'adicionar_conteudo_screen.dart';
import 'editar_conteudo_screen.dart';

class GerenciarConteudosScreen extends StatefulWidget {
  const GerenciarConteudosScreen({super.key});

  @override
  State<GerenciarConteudosScreen> createState() =>
      _GerenciarConteudosScreenState();
}

class _GerenciarConteudosScreenState extends State<GerenciarConteudosScreen> {
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
    setState(() => _isLoading = true);
    try {
      await _carregarDisciplinas();
      if (_disciplinaFiltro != null) await _carregarConteudos();
    } catch (e) {
      if (mounted) MessageUtils.mostrarErroFormatado(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      if (mounted) MessageUtils.mostrarErroFormatado(context, e);
    }
  }

  Future<void> _carregarConteudos() async {
    if (_disciplinaFiltro == null) return;
    try {
      final conteudos = await _contentService
          .getContentBySubjectStream(_disciplinaFiltro!)
          .first;
      if (mounted) setState(() => _conteudos = conteudos);
    } catch (e) {
      if (mounted) MessageUtils.mostrarErroFormatado(context, e);
    }
  }

  Future<void> _deletarConteudo(Content conteudo) async {
    final confirmado = await showConfirmDeleteDialog(context, itemName: conteudo.description);
    if (confirmado && conteudo.id != null) {
      try {
        await _contentService.deleteContent(conteudo.id!);
        if (mounted) {
          MessageUtils.mostrarSucesso(context, 'Conteúdo apagado com sucesso!');
          await _carregarConteudos();
        }
      } catch (e) {
        if (mounted) MessageUtils.mostrarErroFormatado(context, e);
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
    if (resultado == true) await _carregarConteudos();
  }

  Future<void> _navegarParaEditar(Content conteudo) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarConteudoScreen(conteudo: conteudo),
      ),
    );
    if (resultado == true) await _carregarConteudos();
  }

  String _getNomeDisciplina(String? disciplinaId) {
    if (disciplinaId == null) return 'Desconhecida';
    final disciplina = _disciplinas.firstWhere(
      (d) => d.id == disciplinaId,
      orElse: () => Discipline(name: 'Desconhecida', semester: 0),
    );
    return disciplina.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gerenciar Conteúdos'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AppCard(
                    child: FormFieldSection(
                      label: 'Filtrar por Disciplina',
                      field: DropdownButtonFormField<String>(
                        initialValue: _disciplinaFiltro,
                        decoration: const InputDecoration(),
                        items: _disciplinas.map((disciplina) {
                          return DropdownMenuItem(
                            value: disciplina.id,
                            child: Text(disciplina.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _disciplinaFiltro = value);
                          _carregarConteudos();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_conteudos.length} conteúdo(s)',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _navegarParaAdicionar,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Novo Conteúdo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        ? EmptyStateWidget(
                            icon: Icons.library_books_outlined,
                            message: 'Nenhum conteúdo cadastrado',
                            actionLabel: 'Adicionar primeiro conteúdo',
                            onAction: _navegarParaAdicionar,
                          )
                        : ListView.builder(
                            itemCount: _conteudos.length,
                            itemBuilder: (context, index) {
                              final conteudo = _conteudos[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AppCard(
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.article_outlined,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                    title: Text(
                                      conteudo.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _getNomeDisciplina(conteudo.subjectId),
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: AppColors.primary,
                                          onPressed: () => _navegarParaEditar(conteudo),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () => _deletarConteudo(conteudo),
                                        ),
                                      ],
                                    ),
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
