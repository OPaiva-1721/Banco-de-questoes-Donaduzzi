import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async'; // Necessário para o Future.wait

// --- CORREÇÃO: Imports de Raiz ou Pacote ---
import 'package:prova/services/exam_service.dart';
import 'package:prova/services/pdf_service.dart'; //
import 'package:prova/models/exam_model.dart';
import 'package:prova/utils/message_utils.dart'; //
import 'package:prova/core/app_colors.dart';
import 'package:prova/core/exceptions/app_exceptions.dart';

import 'package:prova/services/course_service.dart';
import 'package:prova/models/course_model.dart';
import 'package:prova/services/subject_service.dart';
import 'package:prova/models/discipline_model.dart';
// ---------------------------

class ProvasGeradasScreen extends StatefulWidget {
  const ProvasGeradasScreen({super.key});

  @override
  State<ProvasGeradasScreen> createState() => _ProvasGeradasScreenState();
}

class _ProvasGeradasScreenState extends State<ProvasGeradasScreen> {
  // Constantes de cores
  static const Color _primaryColor = AppColors.primary;
  static const Color _backgroundColor = AppColors.background;
  static const Color _textColor = AppColors.text;
  static const Color _whiteColor = AppColors.white;

  // Serviços
  final ExamService _examService = ExamService();
  
  // --- ESTADO SIMPLIFICADO ---
  final CourseService _courseService = CourseService();
  final SubjectService _subjectService = SubjectService();

  bool _isLoading = true;
  List<Exam> _provas = [];
  
  // Mapas para consulta de nomes (para o PDF)
  Map<String, Course> _cursosMap = {};
  Map<String, Discipline> _disciplinasMap = {};
  // ---------------------------

  @override
  void initState() {
    super.initState();
    _carregarDados(); 
  }

  // Helper para processar dados do Firebase
  List<T> _processarSnapshot<T>(
      DataSnapshot snapshot, T Function(DataSnapshot) fromSnapshot) {
    final list = <T>[];
    if (snapshot.exists && snapshot.value != null) {
      final data = snapshot.value;
      if (data is Map) {
        for (final childSnapshot in snapshot.children) {
          list.add(fromSnapshot(childSnapshot));
        }
      }
    }
    return list;
  }

  // --- FUNÇÃO DE CARREGAMENTO SIMPLIFICADA ---
  Future<void> _carregarDados() async {
    if (mounted) setState(() => _isLoading = true);
    
    try {
      // 1. Pega todos os streams necessários
      final examsStream = _examService.getExamsStream();
      final coursesStream = _courseService.getCoursesStream();
      final subjectsStream = _subjectService.getSubjectsStream();

      // 2. Espera por todos os dados
      final results = await Future.wait([
        examsStream.first,
        coursesStream.first,
        subjectsStream.first,
      ]);

      // 3. Processa os snapshots
      final DatabaseEvent examsEvent = results[0];
      final DatabaseEvent coursesEvent = results[1];
      final DatabaseEvent subjectsEvent = results[2];

      final List<Exam> tempProvas =
          _processarSnapshot(examsEvent.snapshot, Exam.fromSnapshot);
          
      final List<Course> tempCourses =
          _processarSnapshot(coursesEvent.snapshot, Course.fromSnapshot);
      
      final List<Discipline> tempSubjects =
          _processarSnapshot(subjectsEvent.snapshot, Discipline.fromSnapshot);

      // 4. Cria os mapas de consulta (para PDF)
      final Map<String, Course> tempCursosMap = {
        for (var curso in tempCourses) curso.id!: curso
      };
      
      final Map<String, Discipline> tempDisciplinasMap = {
        for (var disciplina in tempSubjects) disciplina.id!: disciplina
      };

      // 5. Ordena as provas
      tempProvas.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _provas = tempProvas;
          _cursosMap = tempCursosMap;
          _disciplinasMap = tempDisciplinasMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MessageUtils.mostrarErroFormatado(context, e);
        print('Erro detalhado ao carregar dados: $e');
      }
    }
  }

  /// Gera o PDF da prova
  Future<void> _gerarPdf(Exam prova) async {
    final String nomeCurso = _cursosMap[prova.courseId]?.name ?? 'Curso não informado';
    final String nomeMateria = _disciplinasMap[prova.subjectId]?.name ?? 'Disciplina não informada';

    try {
      await PdfService.gerarProvaPdf(
        prova: prova,
        nomeCurso: nomeCurso,
        nomeMateria: nomeMateria,
      );
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErroFormatado(context, e);
      }
    }
  }

  /// Deleta a prova (com confirmação)
  Future<void> _deletarProva(String provaId) async {
    final bool? confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza de que deseja deletar esta prova?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _examService.deleteExam(provaId);
        if (mounted) {
          MessageUtils.mostrarSucesso(context, 'Prova deletada com sucesso');
          _carregarDados(); // Recarrega os dados
        }
      } catch (e) {
        if (mounted) {
          MessageUtils.mostrarErroFormatado(context, e);
        }
      }
    }
  }

  // Card da prova atualizado
  Widget _buildProvaCard(Exam prova) {
    
    // O campo 'createdBy' agora contém o NOME
    final String nomeAutor = prova.createdBy.isNotEmpty ? prova.createdBy : 'Autor desconhecido';
    
    final String nomeCurso = _cursosMap[prova.courseId]?.name ?? '...';
    final String nomeMateria = _disciplinasMap[prova.subjectId]?.name ?? '...';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prova.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- NOME DO AUTOR ---
                  Text(
                    'Criado por: $nomeAutor',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // --- OUTRAS INFORMAÇÕES ---
                  Text(
                    'Curso: $nomeCurso',
                    style: const TextStyle(fontSize: 14, color: _textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Disciplina: $nomeMateria',
                    style: const TextStyle(fontSize: 14, color: _textColor),
                  ),
                  const SizedBox(height: 4),
                  // ------------------------------------
                  
                  Text(
                    'Questões: ${prova.questions.length}',
                    style: const TextStyle(fontSize: 14, color: _textColor),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                  onPressed: () => _gerarPdf(prova),
                  tooltip: 'Gerar PDF',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deletarProva(prova.id!),
                  tooltip: 'Deletar Prova',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  // --- CORREÇÃO DO ERRO DE DIGITAÇÃO 'BuildContextC' ---
  Widget build(BuildContext context) {
  // -------------------------------------------------
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          // Header
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
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Título da Página
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Provas Geradas',
              style: TextStyle(
                color: _textColor,
                fontFamily: 'Inter-Bold',
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Conteúdo principal
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryColor))
                : RefreshIndicator(
                    onRefresh: _carregarDados, 
                    color: _primaryColor,
                    child: _provas.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhuma prova gerada ainda.',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            itemCount: _provas.length,
                            itemBuilder: (context, index) {
                              final prova = _provas[index];
                              return _buildProvaCard(prova);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}