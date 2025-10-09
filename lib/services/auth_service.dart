import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'security_service.dart';

/// Serviço responsável por todas as operações de autenticação
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final SecurityService _securityService = SecurityService();

  // ========== CONSTANTES ==========
  static const String tipoProfessor = 'professor';
  static const String tipoCoordenador = 'coordenador';

  // ========== MÉTODOS DE AUTENTICAÇÃO ==========

  /// Registra um novo usuário no sistema
  ///
  /// [email] Email do usuário (deve ser válido)
  /// [senha] Senha do usuário (deve atender aos critérios de segurança)
  /// [nome] Nome completo do usuário
  ///
  /// Retorna [UserCredential] se bem-sucedido, null caso contrário
  ///
  /// Lança [FirebaseAuthException] em caso de erro de autenticação
  /// Lança [Exception] se as validações falharem
  Future<UserCredential?> registrarUsuario(
    String email,
    String senha,
    String nome,
  ) async {
    try {
      // Validar entradas
      if (!_securityService.validarEntrada(email, maxLength: 100)) {
        throw Exception('Email inválido');
      }
      if (!_securityService.validarEntrada(nome, maxLength: 100)) {
        throw Exception('Nome inválido');
      }
      if (senha.length < 8) {
        throw Exception('Senha deve ter pelo menos 6 caracteres');
      }

      // Criar usuário no Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: senha);

      // Atualizar o perfil do usuário
      await userCredential.user?.updateDisplayName(nome);

      // Sanitizar dados antes de salvar
      final nomeSanitizado = _securityService.sanitizarEntrada(nome);
      final emailSanitizado = _securityService.sanitizarEntrada(email);
      // Salvar dados adicionais no Realtime Database
      final userRef = _database.ref('usuarios/${userCredential.user!.uid}');
      await userRef.set({
        'nome': nomeSanitizado,
        'email': emailSanitizado,
        'dataCriacao': ServerValue.timestamp,
        'tipo': tipoProfessor,
        'status': 'ativo',
        'emailVerificado': false,
        'grupoId': null,
        'permissoes': {
          'gerenciarProfessores': false,
          'gerenciarCoordenadores': false,
          'visualizarTodasProvas': false,
          'criarProvas': true,
          'editarProvas': true,
          'deletarProvas': true,
        },
      });

      // Enviar email de verificação
      await userCredential.user?.sendEmailVerification();

      // Registrar atividade de segurança
      await _securityService.registrarAtividadeSeguranca(
        'registro_usuario',
        'Novo usuário registrado: $email',
        sucesso: true,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Erro de autenticação: ${e.code} - ${e.message}');
      await _securityService.registrarAtividadeSeguranca(
        'erro_registro',
        'Erro ao registrar usuário: ${e.code}',
        sucesso: false,
      );
      rethrow;
    } catch (e) {
      print('Erro ao registrar usuário: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_registro',
        'Erro geral ao registrar usuário: $e',
        sucesso: false,
      );
      rethrow;
    }
  }

  /// Fazer login usando Firebase Auth
  Future<UserCredential?> fazerLogin(String email, String senha) async {
    try {
      // Fazer login no Firebase Auth
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: senha);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Erro de autenticação: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Erro ao fazer login: $e');
      rethrow;
    }
  }

  /// Fazer login com Google
  Future<UserCredential?> fazerLoginComGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );

      // Salvar dados do usuário se for novo
      if (result.additionalUserInfo?.isNewUser == true) {
        // Todos os novos usuários são professores por padrão

        // Sanitizar dados
        final nome = _securityService.sanitizarEntrada(
          result.user!.displayName ?? '',
        );
        final email = _securityService.sanitizarEntrada(
          result.user!.email ?? '',
        );

        // Criar documento completo do usuário no Realtime Database
        final userRef = _database.ref('usuarios/${result.user!.uid}');
        await userRef.set({
          'nome': nome,
          'email': email,
          'dataCriacao': ServerValue.timestamp,
          'tipo': tipoProfessor,
          'status': 'ativo',
          'emailVerificado': true, // Google já verifica o email
          'grupoId': null,
          'permissoes': {
            'gerenciarProfessores': false,
            'gerenciarCoordenadores': false,
            'visualizarTodasProvas': false,
            'criarProvas': true,
            'editarProvas': true,
            'deletarProvas': true,
          },
        });

        // Registrar atividade de segurança
        await _securityService.registrarAtividadeSeguranca(
          'registro_usuario_google',
          'Novo usuário Google registrado: $email (professor)',
          sucesso: true,
        );
      } else {
        // Registrar atividade de login
        await _securityService.registrarAtividadeSeguranca(
          'login_google',
          'Login com Google realizado: ${result.user!.email}',
          sucesso: true,
        );
      }

      return result;
    } catch (e) {
      print('Erro ao fazer login com Google: $e');
      await _securityService.registrarAtividadeSeguranca(
        'erro_login_google',
        'Erro ao fazer login com Google: $e',
        sucesso: false,
      );
      return null;
    }
  }

  /// Fazer logout
  Future<void> fazerLogout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Erro ao fazer logout: $e');
      rethrow;
    }
  }

  /// Reenviar verificação de email
  Future<void> reenviarVerificacaoEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Recuperar senha
  Future<void> recuperarSenha(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ========== GETTERS ==========

  /// Usuário atual
  User? get usuarioAtual => _auth.currentUser;

  /// Verificar se a sessão é válida
  Future<bool> verificarSessaoValida() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Verificar se o usuário ainda existe no banco
      final snapshot = await _database.ref('usuarios/${user.uid}').get();
      if (!snapshot.exists) return false;

      final userData = snapshot.value as Map<dynamic, dynamic>;
      return userData['status'] == 'ativo';
    } catch (e) {
      print('Erro ao verificar sessão: $e');
      return false;
    }
  }
}
