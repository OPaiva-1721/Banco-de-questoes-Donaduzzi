/// Modelo para os metadados da relação Prova-Questão
/// Usado para construir a lista de questões dentro do Exam Model
class ExamQuestionLink {
  final String examId; 
  final String questionId; 
  final int order; 
  final double weight; 
  final int? suggestedLines;

  ExamQuestionLink({
    required this.examId,
    required this.questionId,
    required this.order,
    required this.weight,
    this.suggestedLines,
  });

  /// Factory para criar o link a partir do Map lido do Firebase
  /// (O Firebase armazena 'number' e 'peso')
  factory ExamQuestionLink.fromJson(
      String examId, String questionId, Map<String, dynamic> json) {
    return ExamQuestionLink(
      examId: examId,
      questionId: questionId,
      order: (json['number'] as num?)?.toInt() ?? 0, 
      weight: (json['peso'] as num?)?.toDouble() ?? 0.0, 
      suggestedLines: (json['suggestedLines'] as num?)?.toInt(),
    );
  }
}