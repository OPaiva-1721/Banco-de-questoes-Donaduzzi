import 'package:firebase_database/firebase_database.dart';

/// Modelo para `Course` (Curso)
class Course {
  final String? id; // Nulável, pois não existe antes de criar
  final String name;

  Course({this.id, required this.name});

  /// Converte um objeto Dart em um Map para o Realtime Database.
  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  /// Helper para converter um Map genérico (vindo do snapshot) em um Map<String, dynamic>
  static Map<String, dynamic> _dataToMap(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is Map) {
      return Map<String, dynamic>.from(value.cast<dynamic, dynamic>());
    }
    return {};
  }

  /// Cria um objeto Dart a partir de um DataSnapshot do Realtime Database.
  factory Course.fromSnapshot(DataSnapshot snapshot) {
    final data = _dataToMap(snapshot);
    return Course(id: snapshot.key, name: data['name'] ?? '');
  }
}
