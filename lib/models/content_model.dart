import 'package:firebase_database/firebase_database.dart';

/// Modelo para `Content` (Conteúdo de uma Disciplina)
class Content {
  final String? id;
  final String description;
  final String disciplineId; // Foreign Key para Discipline/Subject

  Content({this.id, required this.description, required this.disciplineId});

  Map<String, dynamic> toJson() {
    return {'description': description, 'disciplineId': disciplineId};
  }

  static Map<String, dynamic> _dataToMap(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is Map) {
      return Map<String, dynamic>.from(value.cast<dynamic, dynamic>());
    }
    return {};
  }

  factory Content.fromSnapshot(DataSnapshot snapshot) {
    final data = _dataToMap(snapshot);
    return Content(
      id: snapshot.key,
      description: data['description'] ?? '',
      disciplineId: data['disciplineId'] ?? '',
    );
  }
}
