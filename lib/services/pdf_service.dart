// lib/services/pdf_service.dart
import '/models/exam_model.dart';
import '/models/question_model.dart';
import '/services/question_service.dart';
import '/models/exam_question_link_model.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  // Serviço para buscar os detalhes das questões
  static final QuestionService _questionService = QuestionService();

  static Future<void> gerarProvaPdf({
    required Exam prova,
    required String nomeCurso,
    required String nomeMateria,
  }) async {
    final pdf = pw.Document();

    // Carrega a fonte (necessário para acentos)
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // *** CORREÇÃO: Carrega os dados ANTES de criar o PDF ***
    final List<Question> questoesCompletas =
        await _fetchQuestionDetails(prova.questions);

    // Cabeçalho da Prova
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(prova, nomeCurso, nomeMateria),
          _buildInstructions(prova),
          // Passa as questões já carregadas
          _buildQuestions(prova, questoesCompletas),
        ],
      ),
    );

    // Salva ou pré-visualiza o PDF
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static pw.Widget _buildHeader(
      Exam prova, String nomeCurso, String nomeMateria) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          prova.title,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Curso: $nomeCurso', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Matéria: $nomeMateria',
                style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Professor(a): _________________________',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Data: ___/___/______',
                style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
        pw.Text('Aluno(a): ___________________________________________',
            style: const pw.TextStyle(fontSize: 12)),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 16),
          child: pw.Divider(thickness: 2),
        ),
      ],
    );
  }

  static pw.Widget _buildInstructions(Exam prova) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Instruções:',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          prova.instructions,
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 16),
          child: pw.Divider(),
        ),
      ],
    );
  }

  /// Recebe as questões já carregadas
  static pw.Widget _buildQuestions(
      Exam prova, List<Question> questoesCompletas) {
    final widgets = <pw.Widget>[];

    // Mapeia os números das questões pelo ID
    // Usa 'questionNumber' do seu model 
    final Map<String, int> numerosMap = {
      for (var link in prova.questions)
        link.questionId: link.order
    };

    // Ordena as questões com base na ordem da prova
    questoesCompletas.sort((a, b) {
      final orderA = numerosMap[a.id] ?? 999;
      final orderB = numerosMap[b.id] ?? 999;
      return orderA.compareTo(orderB);
    });

    for (int i = 0; i < questoesCompletas.length; i++) {
      final questao = questoesCompletas[i];
      // Usa o número do 'ExamQuestionLink'
      final numeroQuestao = numerosMap[questao.id] ?? (i + 1);

      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '$numeroQuestao) ${questao.questionText}', 
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            ...questao.options.map(
              (option) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                child: pw.Text(
                  '${option.letter}) ${option.text}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
            ),
            pw.SizedBox(height: 16),
          ],
        ),
      );
    }
    return pw.Column(children: widgets);
  }

  /// Busca os detalhes de cada questão no Firebase
  static Future<List<Question>> _fetchQuestionDetails(
      List<ExamQuestionLink> questionLinks) async {
    final List<Question> questoes = [];
    for (final link in questionLinks) {
      final questao = await _questionService.getQuestion(link.questionId);
      if (questao != null) {
        questoes.add(questao);
      }
    }
    return questoes;
  }
}