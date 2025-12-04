import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:prova/models/user_model.dart';
import 'security_service.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SecurityService _securityService = SecurityService();

  // Dependência: O AuthService precisa do UserService
  final UserService _userService;

  // Construtor: Recebe o UserService
  AuthService(this._userService);

  /// Stream para ouvir mudanças no estado de login (usuário logado/deslogado)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Pega o usuário atualmente logado no Firebase Auth
  User? get currentUser => _auth.currentUser;

  /// Registra um novo usuário (e-mail/senha)
  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String name,
    String userType = 'professor', // Tipo padrão
  }) async {
    // Validação básica
    if (!_securityService.validateText(email, maxLength: 100) ||
        !email.contains('@')) {
      throw Exception('Invalid email address.');
    }
    if (!_securityService.validateText(password, maxLength: 100) ||
        password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    if (!_securityService.validateText(name, maxLength: 50)) {
      throw Exception('Invalid name.');
    }

    UserCredential userCredential;
    try {
      // 1. Cria o usuário no Firebase Authentication
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // (Opcional) Atualiza o nome no perfil do Auth
        await user.updateDisplayName(name);
        await user.reload();

        // 2. Prepara os dados para salvar no Realtime Database
        final newUserRecord = AppUser(
          uid: user.uid, // Usa o UID do Auth como chave
          name: name,
          email: email,
          userType: userType,
        );

        // 3. Chama o UserService para salvar os dados no banco
        await _userService.createUserRecord(newUserRecord);

        await _securityService.logSecurityActivity(
          'register_user',
          'User ${user.uid} registered successfully.',
          success: true,
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      await _securityService.logSecurityActivity(
        'error_register_user',
        'Error: ${e.message}',
        success: false,
      );
      throw Exception(e.message); // Lança o erro para a UI
    }
  }

  /// Faz login com e-mail e senha
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _securityService.logSecurityActivity(
        'sign_in_email',
        'User ${userCredential.user?.uid} signed in.',
        success: true,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      await _securityService.logSecurityActivity(
        'error_sign_in_email',
        'Error: ${e.message}',
        success: false,
      );
      throw Exception(e.message);
    }
  }

  /// Faz login ou registro com Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In aborted by user.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Entra no Firebase Auth
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Verifica se já existe um registro no banco de dados para esse usuário
        final existingUser = await _userService.getUserData(user.uid);

        // Prepara os dados (mantém o tipo se já existe, senão 'professor')
        final userRecord = AppUser(
          uid: user.uid,
          name: user.displayName,
          email: user.email,
          userType: existingUser?.userType ?? 'professor',
        );

        // Cria ou atualiza o registro no banco de dados
        await _userService.createUserRecord(userRecord);

        await _securityService.logSecurityActivity(
          'sign_in_google',
          'User ${user.uid} signed in with Google.',
          success: true,
        );
      }
      return userCredential;
    } catch (e) {
      await _securityService.logSecurityActivity(
        'error_sign_in_google',
        'Error: ${e.toString()}',
        success: false,
      );
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }

  /// Faz logout
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Importante se usou login com Google
      await _auth.signOut();
      await _securityService.logSecurityActivity(
        'sign_out',
        'User signed out.',
        success: true,
      );
    } catch (e) {
      print('Error signing out: $e');
      // Não lançar erro aqui, apenas registrar se necessário
    }
  }

  /// Envia e-mail de redefinição de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      await _securityService.logSecurityActivity(
        'password_reset',
        'Password reset email sent to $email.',
        success: true,
      );
    } on FirebaseAuthException catch (e) {
      await _securityService.logSecurityActivity(
        'error_password_reset',
        'Error: ${e.message}',
        success: false,
      );
      throw Exception(e.message);
    }
  }
}
