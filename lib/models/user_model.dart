import 'package:firebase_database/firebase_database.dart';

/// Model for `AppUser`
/// Stores user data in the Realtime Database, complementing Firebase Auth.
class AppUser {
  final String uid; // Firebase Auth UID (is the node 'key')
  final String? name;
  final String? email;
  final String? userType; // e.g., 'professor', 'coordinator'

  AppUser({required this.uid, this.name, this.email, this.userType});

  /// Converts the object to a Map (JSON) for Firebase.
  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email, 'userType': userType};
  }

  /// Creates an object from a Firebase DataSnapshot.
  factory AppUser.fromSnapshot(DataSnapshot snapshot) {
    // Helper to read the data as a Map
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    return AppUser(
      uid: snapshot.key!, // The node ID is the Auth UID
      name: data['name'],
      email: data['email'],
      userType: data['userType'],
    );
  }
}
