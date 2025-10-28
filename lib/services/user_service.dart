import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Precisa do Auth para pegar o UID
import 'package:prova/models/user_model.dart';
import 'security_service.dart';
import 'dart:async';

class UserService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  // Instância do Auth SÓ para pegar o UID do usuário logado
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseReference _usersRef;
  final SecurityService _securityService = SecurityService();

  UserService() {
    _usersRef = _database.ref('users');
  }

  /// Cria ou atualiza o registro de dados de um usuário no Realtime Database.
  /// Chamado pelo AuthService após registro/login bem-sucedido.
  Future<void> createUserRecord(AppUser user) async {
    try {
      // Usa o UID do Auth como chave no banco de dados
      await _usersRef.child(user.uid).set(user.toJson());
    } on FirebaseException catch (e) {
      await _securityService.logSecurityActivity(
        'error_create_user_record',
        'Error creating/updating user record for ${user.uid}: ${e.message}',
        success: false,
      );
      // Não relançar o erro aqui necessariamente, depende da lógica do AuthService
      print('Failed to save user data: ${e.message}');
    }
  }

  /// Retorna um Stream com os dados do usuário ATUALMENTE logado no Firebase Auth.
  Stream<DatabaseEvent> getCurrentUserStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty(); // Retorna vazio se ninguém estiver logado
    }
    // Ouve o nó do usuário correspondente ao UID do Auth
    return _usersRef.child(userId).onValue;
  }

  /// Busca os dados de um usuário específico pelo UID (uma única vez).
  Future<AppUser?> getUserData(String uid) async {
    try {
      final snapshot = await _usersRef.child(uid).get();
      if (snapshot.exists) {
        return AppUser.fromSnapshot(snapshot);
      }
      return null; // Usuário não encontrado no banco de dados
    } catch (e) {
      print('Error fetching user data for $uid: $e');
      return null;
    }
  }

  /// Atualiza os dados do usuário ATUALMENTE logado.
  Future<bool> updateCurrentUser(Map<String, dynamic> updateData) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('Error: No user logged in to update data.');
      return false; // Não há usuário logado para atualizar
    }

    // Validação (exemplo para 'name')
    if (updateData.containsKey('name')) {
      if (!_securityService.validateText(updateData['name'])) {
        throw Exception('Invalid name.');
      }
      updateData['name'] = _securityService.sanitizeInput(updateData['name']);
    }

    try {
      await _usersRef.child(userId).update(updateData);
      await _securityService.logSecurityActivity(
        'update_user_data',
        'User data updated for $userId.',
        success: true,
      );
      return true;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_update_user_data',
        'Error updating data for $userId: ${e.toString()}',
        success: false,
      );
      print('Error updating user data: $e');
      return false;
    }
  }

  /// Obtém o tipo do usuário ATUALMENTE logado.
  Future<String> getCurrentUserType() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 'professor'; // Padrão se não logado

    try {
      final snapshot = await _usersRef.child(userId).child('userType').get();
      if (snapshot.exists && snapshot.value != null) {
        return snapshot.value as String;
      }
      // Se não houver registro no banco ou faltar o campo, retorna o padrão
      return 'professor';
    } catch (e) {
      print('Error getting user type for $userId: $e');
      return 'professor'; // Padrão em caso de erro
    }
  }

  /// Retorna um Stream com TODOS os usuários (função de Admin).
  Stream<DatabaseEvent> getAllUsersStream() {
    return _usersRef.onValue;
  }

  /// Altera o tipo de um usuário específico (função de Admin).
  Future<bool> setUserType(String userId, String newUserType) async {
    // Validação simples do tipo
    if (newUserType != 'professor' && newUserType != 'coordinator') {
      throw Exception('Invalid user type specified.');
    }

    try {
      // Verifica se o usuário existe antes de tentar atualizar
      final snapshot = await _usersRef.child(userId).get();
      if (!snapshot.exists) {
        throw Exception('User with ID $userId not found.');
      }

      await _usersRef.child(userId).update({'userType': newUserType});

      await _securityService.logSecurityActivity(
        'set_user_type',
        'User $userId type changed to $newUserType by admin.',
        success: true,
      );
      return true;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_set_user_type',
        'Error setting type for $userId: ${e.toString()}',
        success: false,
      );
      print('Error setting user type: $e');
      return false;
    }
  }
}
