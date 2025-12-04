import 'package:firebase_database/firebase_database.dart';

class Discipline {
  final String? id;
  final String name;
  final int semester;

  Discipline({this.id, required this.name, required this.semester});

  Map<String, dynamic> toJson() {
    return {'name': name, 'semester': semester};
  }

  static Map<String, dynamic> _dataToMap(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is Map) {
      return Map<String, dynamic>.from(value.cast<dynamic, dynamic>());
    }
    return {};
  }

  factory Discipline.fromSnapshot(DataSnapshot snapshot) {
    final data = _dataToMap(snapshot);
    return Discipline(
      id: snapshot.key,
      name: data['name']?.toString() ?? '',
      semester: (data['semester'] as num?)?.toInt() ?? 1,
    );
  }
}