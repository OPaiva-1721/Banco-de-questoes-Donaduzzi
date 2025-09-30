import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ========== AUTENTICAÇÃO ==========

  // Registrar novo usuário
  Future<bool> registrarUsuario(String email, String senha, String nome) async {
    try {
      print('Iniciando registro para: $email');

      // Verificar se o email já existe
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('Email já está em uso');
      }

      // Criar usuário diretamente no Firestore
      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      await _firestore.collection('usuarios').doc(userId).set({
        'nome': nome,
        'email': email,
        'senha': senha, // Em produção, isso deveria ser criptografado
        'dataCriacao': FieldValue.serverTimestamp(),
        'tipo': 'professor',
        'status': 'ativo',
      });

      print('Usuário criado no Firestore: $userId');
      return true;
    } catch (e) {
      print('Erro ao registrar usuário: $e');
      print('Tipo do erro: ${e.runtimeType}');
      rethrow;
    }
  }

  // Fazer login
  Future<bool> fazerLogin(String email, String senha) async {
    try {
      print('Tentando fazer login para: $email');

      // Buscar usuário no Firestore
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .where('senha', isEqualTo: senha)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        print('Login realizado com sucesso: ${userDoc.id}');
        return true;
      } else {
        print('Email ou senha incorretos');
        return false;
      }
    } catch (e) {
      print('Erro ao fazer login: $e');
      rethrow; // Re-throw para ser tratado na UI
    }
  }

  // Fazer login com Google
  Future<UserCredential?> fazerLoginComGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

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
        await _firestore.collection('usuarios').doc(result.user!.uid).set({
          'nome': result.user!.displayName ?? '',
          'email': result.user!.email ?? '',
          'dataCriacao': FieldValue.serverTimestamp(),
          'tipo': 'professor', // Assumindo que todos são professores
        });
      }

      return result;
    } catch (e) {
      print('Erro ao fazer login com Google: $e');
      return null;
    }
  }

  // Fazer logout
  Future<void> fazerLogout() async {
    await _auth.signOut();
  }

  // Usuário atual
  User? get usuarioAtual => _auth.currentUser;

  // Stream do usuário atual
  Stream<User?> get streamUsuario => _auth.authStateChanges();

  // ========== DADOS DOS USUÁRIOS ==========

  // Buscar dados do usuário atual
  Future<DocumentSnapshot?> buscarDadosUsuario() async {
    if (usuarioAtual == null) return null;

    try {
      return await _firestore
          .collection('usuarios')
          .doc(usuarioAtual!.uid)
          .get();
    } catch (e) {
      print('Erro ao buscar dados do usuário: $e');
      return null;
    }
  }

  // Atualizar dados do usuário
  Future<bool> atualizarDadosUsuario(Map<String, dynamic> dados) async {
    if (usuarioAtual == null) return false;

    try {
      await _firestore
          .collection('usuarios')
          .doc(usuarioAtual!.uid)
          .update(dados);
      return true;
    } catch (e) {
      print('Erro ao atualizar dados do usuário: $e');
      return false;
    }
  }

  // ========== EXEMPLO: TAREFAS ==========

  // Adicionar tarefa
  Future<bool> adicionarTarefa(String titulo, String descricao) async {
    if (usuarioAtual == null) return false;

    try {
      await _firestore.collection('tarefas').add({
        'titulo': titulo,
        'descricao': descricao,
        'concluida': false,
        'usuarioId': usuarioAtual!.uid,
        'dataCriacao': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erro ao adicionar tarefa: $e');
      return false;
    }
  }

  // Buscar tarefas do usuário
  Stream<QuerySnapshot> buscarTarefas() {
    if (usuarioAtual == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('tarefas')
        .where('usuarioId', isEqualTo: usuarioAtual!.uid)
        .orderBy('dataCriacao', descending: true)
        .snapshots();
  }

  // Atualizar tarefa
  Future<bool> atualizarTarefa(
    String tarefaId,
    Map<String, dynamic> dados,
  ) async {
    try {
      await _firestore.collection('tarefas').doc(tarefaId).update(dados);
      return true;
    } catch (e) {
      print('Erro ao atualizar tarefa: $e');
      return false;
    }
  }

  // Deletar tarefa
  Future<bool> deletarTarefa(String tarefaId) async {
    try {
      await _firestore.collection('tarefas').doc(tarefaId).delete();
      return true;
    } catch (e) {
      print('Erro ao deletar tarefa: $e');
      return false;
    }
  }
}
