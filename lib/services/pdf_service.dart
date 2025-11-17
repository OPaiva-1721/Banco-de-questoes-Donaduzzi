// lib/services/pdf_service.dart
import '/models/exam_model.dart';
import '/models/question_model.dart';
import '/services/question_service.dart';
import '/models/exam_question_link_model.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static final QuestionService _questionService = QuestionService();

  static Future<void> gerarProvaPdf({
    required Exam prova,
    required String nomeCurso,
    required String nomeMateria,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final ByteData cabecalhoBytes = await rootBundle.load(
      'assets/images/cabecalho-prova.png',
    );
    final Uint8List cabecalhoImage = cabecalhoBytes.buffer.asUint8List();
    final pw.ImageProvider cabecalhoProvider = pw.MemoryImage(cabecalhoImage);

    String nomeProfessor = prova.createdBy.trim();
    if (nomeProfessor.isEmpty) {
      nomeProfessor = 'Professor não informado';
    }
    final List<Question> questoesCompletas = await _fetchQuestionDetails(
      prova.questions,
    );

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(
            cabecalhoProvider,
            prova,
            nomeCurso,
            nomeMateria,
            nomeProfessor,
          ),
          _buildInstructions(prova),
          _buildQuestions(prova, questoesCompletas),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _buildHeader(
    pw.ImageProvider cabecalhoProvider,
    Exam prova,
    String nomeCurso,
    String nomeMateria,
    String nomeProfessor,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return pw.Stack(
      alignment: pw.Alignment.topLeft,
      children: [
        pw.Image(cabecalhoProvider, fit: pw.BoxFit.contain),
        pw.Positioned(
          left: 30,
          top: 64,
          child: pw.Text(nomeProfessor, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Positioned(
          left: 500,
          top: 60,
          child: pw.Text(
            '$nomeCurso - $nomeMateria',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        pw.Positioned(
          left: 580,
          top: 60,
          child: pw.Text(
            dateFormat.format(prova.createdAt),
            style: const pw.TextStyle(fontSize: 9),
          ),
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
        pw.Text(prova.instructions, style: const pw.TextStyle(fontSize: 12)),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 16),
          child: pw.Divider(),
        ),
      ],
    );
  }

  static pw.Widget _buildQuestions(
    Exam prova,
    List<Question> questoesCompletas,
  ) {
    final widgets = <pw.Widget>[];

    final Map<String, int> numerosMap = {
      for (var link in prova.questions) link.questionId: link.order,
    };

    questoesCompletas.sort((a, b) {
      final orderA = numerosMap[a.id] ?? 999;
      final orderB = numerosMap[b.id] ?? 999;
      return orderA.compareTo(orderB);
    });

    for (int i = 0; i < questoesCompletas.length; i++) {
      final questao = questoesCompletas[i];
      final numeroQuestao = numerosMap[questao.id] ?? (i + 1);

      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '$numeroQuestao) ${questao.questionText}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            ...questao.options.map(
              (option) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 20, bottom: 4),
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

    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  static Future<List<Question>> _fetchQuestionDetails(
    List<ExamQuestionLink> questionLinks,
  ) async {
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
