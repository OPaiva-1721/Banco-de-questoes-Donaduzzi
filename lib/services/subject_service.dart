import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';
import 'dart:async';

class SubjectService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseReference _subjectsRef;
  late final DatabaseReference _questionsRef; // To check dependencies
  final SecurityService _securityService = SecurityService();

  SubjectService() {
    _subjectsRef = _database.ref('subjects');
    _questionsRef = _database.ref('questions');
  }

  Future<String?> createSubject(String name, int semester) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    if (!_securityService.validateText(name, maxLength: 100)) {
      throw Exception('Invalid subject name.');
    }
    if (semester <= 0 || semester > 20) {
      throw Exception('Invalid semester.');
    }

    final sanitizedName = _securityService.sanitizeInput(name);

    try {
      final subjectData = {
        'name': sanitizedName,
        'semester': semester,
        'createdAt': ServerValue.timestamp,
        'createdBy': userId,
      };

      final newSubjectRef = _subjectsRef.push();
      await newSubjectRef.set(subjectData);

      await _securityService.logSecurityActivity(
        'create_subject',
        'Subject created: $sanitizedName',
        success: true,
      );
      return newSubjectRef.key;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_create_subject',
        'Error: ${e.toString()}',
        success: false,
      );
      return null;
    }
  }

  Stream<DatabaseEvent> listarDisciplinas() {
    return _subjectsRef.onValue;
  }

  Stream<DatabaseEvent> getSubjectsBySemesterStream(int semester) {
    final query = _subjectsRef.orderByChild('semester').equalTo(semester);
    return query.onValue;
  }

  Future<DataSnapshot?> getSubject(String subjectId) async {
    try {
      return await _subjectsRef.child(subjectId).get();
    } catch (e) {
      print('Error fetching subject: $e');
      return null;
    }
  }

  Future<bool> updateSubject(
    String subjectId,
    Map<String, dynamic> updateData,
  ) async {
    if (updateData.containsKey('name')) {
      if (!_securityService.validateText(updateData['name'])) {
        throw Exception('Invalid subject name.');
      }
      updateData['name'] = _securityService.sanitizeInput(updateData['name']);
    }

    try {
      updateData['lastUpdatedAt'] = ServerValue.timestamp;
      await _subjectsRef.child(subjectId).update(updateData);

      await _securityService.logSecurityActivity(
        'update_subject',
        'Subject $subjectId updated',
        success: true,
      );
      return true;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_update_subject',
        'Error: ${e.toString()}',
        success: false,
      );
      return false;
    }
  }

  Future<bool> deleteSubject(String subjectId) async {
    try {
      // 1. Check if subject is used by any questions
      final query = _questionsRef.orderByChild('subjectId').equalTo(subjectId);
      final snapshot = await query.get();

      if (snapshot.exists) {
        throw Exception(
          'Cannot delete: Subject is used by existing questions.',
        );
      }

      // 2. If not used, delete
      await _subjectsRef.child(subjectId).remove();

      await _securityService.logSecurityActivity(
        'delete_subject',
        'Subject $subjectId deleted',
        success: true,
      );
      return true;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_delete_subject',
        'Error: ${e.toString()}',
        success: false,
      );
      return false;
    }
  }
}
