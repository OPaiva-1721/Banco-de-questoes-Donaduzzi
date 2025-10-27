import 'package:firebase_database/firebase_database.dart';

/// Modelo para `AppUser` (Usuário)
/// Armazena dados do usuário no RTDB, complementando o Firebase Auth.
class AppUser {
  final String uid; // ID do Firebase Auth (é o 'key' do nó)
  final String? name;
  final String? email;
  final String? userType; // Ex: 'professor', 'aluno'

  AppUser({required this.uid, this.name, this.email, this.userType});

  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email, 'userType': userType};
  }

  static Map<String, dynamic> _dataToMap(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is Map) {
      return Map<String, dynamic>.from(value.cast<dynamic, dynamic>());
    }
    return {};
  }

  factory AppUser.fromSnapshot(DataSnapshot snapshot) {
    final data = _dataToMap(snapshot);
    return AppUser(
      uid: snapshot.key!, // O ID do nó é o UID do Auth
      name: data['name'],
      email: data['email'],
      userType: data['userType'],
    );
  }
}
