import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_service.dart';
import 'dart:async';
import '../models/content_model.dart'; 

class ContentService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseReference _contentRef;
  final SecurityService _securityService = SecurityService();

  ContentService() {
    _contentRef = _database.ref('contents');
  }

  /// Creates a new content item linked to a subject.
  Future<String?> createContent({
    required String description,
    required String subjectId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    if (!_securityService.validateText(description, maxLength: 200)) {
      throw Exception('Invalid content description.');
    }
    // We should also validate that the subjectId exists...

    try {
      final newContent = Content(
        description: _securityService.sanitizeInput(description),
        subjectId: subjectId,
      );

      // O Realtime Database não tem um ServerValue.timestampAsInt nativo
      // Vamos usar um Map para usar o ServerValue.timestamp
      final contentData = newContent.toJson();
      contentData['createdAt'] = ServerValue.timestamp;

      final newContentRef = _contentRef.push();
      await newContentRef.set(contentData);

      await _securityService.logSecurityActivity(
        'create_content',
        'Content created: $description',
        success: true,
      );
      return newContentRef.key;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_create_content',
        'Error: ${e.toString()}',
        success: false,
      );
      return null;
    }
  }

  Stream<DatabaseEvent> getContentStream() {
    return _contentRef.onValue;
  }
  /// Returns a Stream of Content objects filtered by subjectId.
  Stream<List<Content>> getContentBySubjectStream(String subjectId) {
    final query = _contentRef.orderByChild('subjectId').equalTo(subjectId);

    return query.onValue.map((event) {
      final contentList = <Content>[];
      if (event.snapshot.exists && event.snapshot.value != null) {
        for (final childSnapshot in event.snapshot.children) {
          contentList.add(Content.fromSnapshot(childSnapshot));
        }
      }
      return contentList;
    });
  }

  /// Fetches a single Content object.
  Future<Content?> getContent(String contentId) async {
    try {
      final snapshot = await _contentRef.child(contentId).get();
      if (snapshot.exists) {
        return Content.fromSnapshot(snapshot);
      }
      return null;
    } catch (e) {
      print('Error fetching content: $e');
      return null;
    }
  }

  /// Updates an existing content item.
  Future<bool> updateContent(
    String contentId,
    Map<String, dynamic> updateData,
  ) async {
    if (updateData.containsKey('description')) {
      if (!_securityService.validateText(
        updateData['description'],
        maxLength: 200,
      )) {
        throw Exception('Invalid content description.');
      }
      updateData['description'] = _securityService.sanitizeInput(
        updateData['description'],
      );
    }

    try {
      updateData['lastUpdatedAt'] = ServerValue.timestamp;
      await _contentRef.child(contentId).update(updateData);

      await _securityService.logSecurityActivity(
        'update_content',
        'Content $contentId updated',
        success: true,
      );
      return true;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_update_content',
        'Error: ${e.toString()}',
        success: false,
      );
      return false;
    }
  }

  /// Deletes a content item.
  Future<bool> deleteContent(String contentId) async {
    try {
      // TODO: Add check to see if content is used by questions

      await _contentRef.child(contentId).remove();

      await _securityService.logSecurityActivity(
        'delete_content',
        'Content $contentId deleted',
        success: true,
      );
      return true;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_delete_content',
        'Error: ${e.toString()}',
        success: false,
      );
      return false;
    }
  }
}
