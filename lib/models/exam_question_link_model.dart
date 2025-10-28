/// Modelo para os metadados da relação Prova-Questão
/// Não é uma coleção, mas um sub-objeto dentro de Exam.
class ExamQuestionLink {
  final String questionId; // FK para Question
  final int questionNumber;
  final int? linesForAnswer;

  ExamQuestionLink({
    required this.questionId,
    required this.questionNumber,
    this.linesForAnswer,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'questionNumber': questionNumber,
    'linesForAnswer': linesForAnswer,
  };

  factory ExamQuestionLink.fromJson(Map<String, dynamic> json) =>
      ExamQuestionLink(
        questionId: json['questionId'] ?? '',
        questionNumber: (json['questionNumber'] as num?)?.toInt() ?? 0,
        linesForAnswer: (json['linesForAnswer'] as num?)?.toInt(),
      );
}
