import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importa o FirebaseAuth
import 'firebase_options.dart';
import 'screens/auth/tela_login.dart'; // Sua tela de login
import 'screens/home/pagina_principal.dart'; // Sua tela principal (TelaInicio)
// Removido: import 'services/firebase_service.dart'; // Não precisa mais importar aqui

/// Ponto de entrada principal da aplicação
void main() async {
  // Garante que o Flutter está pronto antes de inicializar o Firebase
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializa o Firebase (essencial para Auth e Database)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase inicializado com sucesso');
  } catch (e) {
    print('Erro ao inicializar Firebase: $e');
    // Considerar mostrar uma tela de erro se o Firebase falhar
  }

  runApp(const MyApp());
}

/// Widget principal da aplicação (Stateless)
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
      // AuthWrapper decide qual tela mostrar: Login ou Principal
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Widget que "ouve" o estado de autenticação do Firebase
/// e mostra a tela correta (Login ou Principal).
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder escuta as mudanças no estado de autenticação
    return StreamBuilder<User?>(
      // A "fonte" dos dados é o stream do FirebaseAuth
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Estado de Carregamento: Enquanto o Firebase verifica
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verificando autenticação...'), // Traduzido
                ],
              ),
            ),
          );
        }

        // 2. Estado de Erro: Se algo deu errado no Stream
        if (snapshot.hasError) {
          print(
            'AuthWrapper - Erro no stream de autenticação: ${snapshot.error}',
          );
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Erro na autenticação'), // Traduzido
                ],
              ),
            ),
          );
        }

        // 3. Estado Logado: Se o snapshot tem dados (User não é null)
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          print('AuthWrapper - Usuário logado: ${user.email} (${user.uid})');
          // Mostra a tela principal do aplicativo
          return const TelaInicio(); // Ou PaginaPrincipal, como preferir
        }
        // 4. Estado Deslogado: Se o snapshot não tem dados (User é null)
        else {
          print('AuthWrapper - Usuário não logado, mostrando TelaLogin');
          // Mostra a tela de login
          return const TelaLogin();
        }
      },
    );
  }
}
