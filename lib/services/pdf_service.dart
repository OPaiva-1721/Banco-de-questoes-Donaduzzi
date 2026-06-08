// lib/services/pdf_service.dart
import '/models/exam_model.dart';
import '/models/question_model.dart';
import '/services/question_service.dart';
import '/models/exam_question_link_model.dart';
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
    final fontItalic = await PdfGoogleFonts.robotoItalic();
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
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
          italic: fontItalic,
        ),
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
          // O gabarito é um único widget (Column). O motor do pdf
          // vai tentar colocá‑lo na página atual; se não couber,
          // ele automaticamente move o bloco inteiro para a próxima,
          // sem quebrar no meio.
          _buildAnswerKey(prova, questoesCompletas),
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

  static pw.Widget _buildAnswerKey(
    Exam prova,
    List<Question> questoesCompletas,
  ) {
    final Map<String, int> numerosMap = {
      for (var link in prova.questions) link.questionId: link.order,
    };

    questoesCompletas.sort((a, b) {
      final orderA = numerosMap[a.id] ?? 999;
      final orderB = numerosMap[b.id] ?? 999;
      return orderA.compareTo(orderB);
    });

    // Obter todas as letras disponíveis (normalmente A, B, C, D, E)
    final Set<String> todasLetras = {};
    for (var questao in questoesCompletas) {
      for (var option in questao.options) {
        todasLetras.add(option.letter.toUpperCase());
      }
    }
    final List<String> letrasOrdenadas = todasLetras.toList()..sort();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 8),
        pw.Text(
          'GABARITO',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Marque suas respostas preenchendo completamente o círculo correspondente:',
          style: pw.TextStyle(fontSize: 11),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.grey300,
              width: 0.8,
            ),
          ),
          padding: const pw.EdgeInsets.all(4),
          child: pw.Table(
            border: pw.TableBorder(
              top: const pw.BorderSide(color: PdfColors.grey300, width: 0.4),
              bottom: const pw.BorderSide(color: PdfColors.grey300, width: 0.4),
              left: const pw.BorderSide(color: PdfColors.grey300, width: 0.4),
              right: const pw.BorderSide(color: PdfColors.grey300, width: 0.4),
              horizontalInside: const pw.BorderSide(color: PdfColors.grey300, width: 0.4),
              verticalInside: const pw.BorderSide(color: PdfColors.grey300, width: 0.4),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              ...{ for (var i in List.generate(letrasOrdenadas.length, (i) => i + 1)) i : const pw.FlexColumnWidth(1) },
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: const pw.BorderSide(
                          color: PdfColors.grey400,
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'Questão',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  ...letrasOrdenadas.map(
                    (letra) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: letra == letrasOrdenadas.last
                              ? const pw.BorderSide(
                                  color: PdfColors.grey400,
                                  width: 0.8,
                                )
                              : const pw.BorderSide(
                                  color: PdfColors.grey300,
                                  width: 0.6,
                                ),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          letra,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ...questoesCompletas.asMap().entries.map((entry) {
                final questao = entry.value;
                final numeroQuestao = numerosMap[questao.id] ?? (entry.key + 1);

                return pw.TableRow(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: const pw.BorderSide(
                            color: PdfColors.grey400,
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '$numeroQuestao',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    ...letrasOrdenadas.map(
                      (letra) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: letra == letrasOrdenadas.last
                                ? const pw.BorderSide(
                                    color: PdfColors.grey400,
                                    width: 0.8,
                                  )
                                : const pw.BorderSide(
                                    color: PdfColors.grey300,
                                    width: 0.6,
                                  ),
                          ),
                        ),
                        child: pw.Center(
                          child: pw.Container(
                            width: 14,
                            height: 14,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(
                                color: PdfColors.black,
                                width: 1.2,
                              ),
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  static Future<List<Question>> _fetchQuestionDetails(
    List<ExamQuestionLink> questionLinks,
  ) async {
    final List<Question> questoes = [];
    for (final link in questionLinks) {
      final questao = await _questionService.getQuestion(link.questionId);
      questoes.add(questao);
    }
    return questoes;
  }
}
