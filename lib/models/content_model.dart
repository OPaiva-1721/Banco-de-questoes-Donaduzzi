import 'package:firebase_database/firebase_database.dart';

class Content {
  final String? id;
  final String description;
  final String subjectId; 

  Content({this.id, required this.description, required this.subjectId});

  Map<String, dynamic> toJson() {
    return {'description': description, 'subjectId': subjectId};
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
      description: data['description']?.toString() ?? '',
      subjectId: data['subjectId']?.toString() ?? '',
    );
  }
}