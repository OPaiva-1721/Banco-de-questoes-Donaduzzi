import 'package:firebase_database/firebase_database.dart';

class Course {
  final String? id;
  final String name;

  Course({this.id, required this.name});

  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  static Map<String, dynamic> _dataToMap(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is Map) {
      return Map<String, dynamic>.from(value.cast<dynamic, dynamic>());
    }
    return {};
  }

  factory Course.fromSnapshot(DataSnapshot snapshot) {
    final data = _dataToMap(snapshot);
    return Course(
      id: snapshot.key,
      name: data['name']?.toString() ?? ''
    );
  }
}