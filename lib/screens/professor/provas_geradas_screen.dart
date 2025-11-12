import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '/services/exam_service.dart';
import '/models/exam_model.dart';
import '/core/app_colors.dart';
import '/utils/message_utils.dart';
import '/services/pdf_service.dart'; 
import '/services/course_service.dart';
import '/services/subject_service.dart';
import '/models/course_model.dart';
import '/models/discipline_model.dart';

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
  static const Color _whiteColor = Colors.white;

  // Serviços
  final ExamService _examService = ExamService();
  final CourseService _courseService = CourseService();
  final SubjectService _subjectService = SubjectService();

  // Listas de metadados para consulta
  List<Course> _cursos = [];
  List<Discipline> _materias = [];
  bool _isLoadingPdf = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _carregarMetadados();
  }

  /// Processa o DatabaseEvent
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

  /// Carrega cursos e matérias para podermos exibir os nomes
  Future<void> _carregarMetadados() async {
    setState(() => _isLoadingData = true);
    try {
      final cursosEvent = await _courseService.getCoursesStream().first;
      final materiasEvent = await _subjectService.getSubjectsStream().first;

      if (mounted) {
        setState(() {
          _cursos = _processarSnapshot(cursosEvent.snapshot, Course.fromSnapshot);
          _materias =
              _processarSnapshot(materiasEvent.snapshot, Discipline.fromSnapshot);
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        MessageUtils.mostrarErro(context, 'Erro ao carregar dados: $e');
      }
    }
  }

  /// Busca o nome do Curso pelo ID
  String _getNomeCurso(String? courseId) {
    if (courseId == null) return 'Curso não informado';
    return _cursos
        .firstWhere((c) => c.id == courseId, orElse: () => Course(id: '', name: '...'))
        .name;
  }

  /// Busca o nome da Matéria pelo ID
  String _getNomeMateria(String subjectId) {
    return _materias
        .firstWhere((m) => m.id == subjectId,
            orElse: () => Discipline(id: '', name: '...', semester: 0))
        .name;
  }

  /// Chama o serviço de PDF
  Future<void> _gerarPdf(Exam prova) async {
    setState(() => _isLoadingPdf = true);

    try {
      final String nomeCurso = _getNomeCurso(prova.courseId);
      final String nomeMateria = _getNomeMateria(prova.subjectId);

      // (O PdfService fará o resto, incluindo buscar as questões)
      await PdfService.gerarProvaPdf(
        prova: prova,
        nomeCurso: nomeCurso,
        nomeMateria: nomeMateria,
      );
    } catch (e) {
      MessageUtils.mostrarErro(context, 'Erro ao gerar PDF: $e');
    } finally {
      setState(() => _isLoadingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          Column(
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
                padding: EdgeInsets.all(24.0),
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

              // Lista de Provas
              Expanded(
                child: _isLoadingData
                    ? const Center(
                        child: CircularProgressIndicator(color: _primaryColor))
                    : StreamBuilder<DatabaseEvent>(
                        stream: _examService.getExamsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: _primaryColor));
                          }
                          if (!snapshot.hasData ||
                              !snapshot.data!.snapshot.exists) {
                            return const Center(
                                child: Text('Nenhuma prova encontrada.'));
                          }

                          // Processa o snapshot para List<Exam>
                          final provas = _processarSnapshot(
                              snapshot.data!.snapshot, Exam.fromSnapshot);

                          // Ordena das mais recentes para as mais antigas
                          provas.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: provas.length,
                            itemBuilder: (context, index) {
                              final prova = provas[index];
                              return _buildExamCard(context, prova);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          // Loading overlay para PDF
          if (_isLoadingPdf)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _whiteColor),
                    SizedBox(height: 16),
                    Text(
                      'Gerando PDF...',
                      style: TextStyle(color: _whiteColor, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, Exam prova) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.school,
              _getNomeCurso(prova.courseId), // Mostra o nome do curso
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.book,
              _getNomeMateria(prova.subjectId), // Mostra o nome da matéria
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.list_alt,
              '${prova.questions.length} questões',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Gerar PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: _whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoadingPdf ? null : () => _gerarPdf(prova),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }
}