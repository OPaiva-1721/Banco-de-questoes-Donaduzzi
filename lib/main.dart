import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth/tela_login.dart';
import 'screens/home/pagina_principal.dart';
import 'services/firebase_service.dart';

/// Ponto de entrada principal da aplicação
///
/// Inicializa o Firebase e executa o aplicativo Flutter.
/// Este é o primeiro método executado quando o app é iniciado.
///
/// Funcionalidades:
/// - Inicializa o Firebase com as opções específicas da plataforma
/// - Configura o binding do Flutter para widgets
/// - Trata erros de inicialização do Firebase
/// - Executa o widget principal da aplicação
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase inicializado com sucesso');
  } catch (e) {
    print('Erro ao inicializar Firebase: $e');
  }

  runApp(const MyApp());
}

/// Widget principal da aplicação
///
/// Configura o MaterialApp com tema e roteamento inicial.
/// Define o AuthWrapper como tela inicial para gerenciar autenticação.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Provas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Widget responsável por gerenciar o estado de autenticação
///
/// Verifica se o usuário está logado e redireciona para a tela apropriada.
/// Implementa verificação de sessão válida e logout automático se necessário.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Verificar estado inicial do usuário
    _verificarUsuarioAtual();
  }

  /// Verifica o usuário atual e valida a sessão
  ///
  /// Executa as seguintes verificações:
  /// - Verifica se há um usuário logado
  /// - Valida se a sessão ainda é válida
  /// - Faz logout automático se a sessão expirou
  Future<void> _verificarUsuarioAtual() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Verificar se a sessão ainda é válida
      try {
        final firebaseService = FirebaseService();
        final sessaoValida = await firebaseService.verificarSessaoValida();

        if (!sessaoValida) {
          await firebaseService.fazerLogout();
        }
      } catch (e) {
        // Continuar mesmo com erro na verificação de sessão
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mostrar loading enquanto verifica o estado de autenticação
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verificando autenticação...'),
                ],
              ),
            ),
          );
        }

        // Verificar se há erro
        if (snapshot.hasError) {
          print('AuthWrapper - Erro na autenticação: ${snapshot.error}');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Erro na autenticação'),
                ],
              ),
            ),
          );
        }

        // Se o usuário está logado, mostrar a tela principal
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          print('AuthWrapper - Usuário logado: ${user.email} (${user.uid})');
          return const TelaInicio();
        }

        // Se não está logado, mostrar a tela de login
        print('AuthWrapper - Usuário não logado, indo para TelaLogin');
        return const TelaLogin();
      },
    );
  }
}
