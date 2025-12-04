import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';
import 'dart:async';

class CourseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseReference _coursesRef;
  final SecurityService _securityService = SecurityService();

  CourseService() {
    _coursesRef = _database.ref('courses');
  }

  Future<String?> createCourse(String name) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    if (!_securityService.validateText(name, maxLength: 100)) {
      throw Exception('Invalid course name.');
    }

    final sanitizedName = _securityService.sanitizeInput(name);

    try {
      final courseData = {
        'name': sanitizedName,
        'createdAt': ServerValue.timestamp,
        'createdBy': userId,
        'status': 'active', // Using string 'status' here
      };

      final newCourseRef = _coursesRef.push();
      await newCourseRef.set(courseData);

      await _securityService.logSecurityActivity(
        'create_course',
        'Course created: $sanitizedName',
        success: true,
      );
      return newCourseRef.key;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_create_course',
        'Error: ${e.toString()}',
        success: false,
      );
      return null;
    }
  }

  Stream<DatabaseEvent> getCoursesStream() {
    return _coursesRef.onValue;
  }

  Future<DataSnapshot?> getCourse(String courseId) async {
    try {
      return await _coursesRef.child(courseId).get();
    } catch (e) {
      print('Error fetching course: $e');
      return null;
    }
  }

  Future<bool> updateCourse(
    String courseId,
    Map<String, dynamic> updateData,
  ) async {
    if (updateData.containsKey('name')) {
      if (!_securityService.validateText(updateData['name'])) {
        throw Exception('Invalid course name.');
      }
      updateData['name'] = _securityService.sanitizeInput(updateData['name']);
    }
    // ... (add validation for other fields if needed) ...

    try {
      updateData['lastUpdatedAt'] = ServerValue.timestamp;
      await _coursesRef.child(courseId).update(updateData);

      await _securityService.logSecurityActivity(
        'update_course',
        'Course $courseId updated',
        success: true,
      );
      return true;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_update_course',
        'Error: ${e.toString()}',
        success: false,
      );
      return false;
    }
  }

  /// Soft deletes the course by setting its status to 'inactive'.
  Future<bool> deleteCourse(String courseId) async {
    try {
      await _coursesRef.child(courseId).update({
        'status': 'inactive',
        'deletedAt': ServerValue.timestamp,
      });

      await _securityService.logSecurityActivity(
        'delete_course',
        'Course $courseId deactivated',
        success: true,
      );
      return true;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_delete_course',
        'Error: ${e.toString()}',
        success: false,
      );
      return false;
    }
  }
}
