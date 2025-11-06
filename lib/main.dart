import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth/tela_login.dart';
import 'screens/home/pagina_principal.dart';

/// Ponto de entrada principal da aplicação
void main() async {
  // Garante que o Flutter está pronto
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // --- ESTA É A PARTE IMPORTANTE ---
    // Verifica se já existe uma instância default do Firebase
    if (Firebase.apps.isEmpty) {
      // Se não houver, inicializa uma nova
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase inicializado com sucesso');
    } else {
      // Se já existir, apenas informa
      print('Firebase já inicializado');
    }
    // --- FIM DA PARTE IMPORTANTE ---
  } catch (e) {
    print('Erro ao inicializar Firebase: $e');
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
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Widget que "ouve" o estado de autenticação do Firebase
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Estado de Carregamento
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

        // 2. Estado de Erro
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
                  Text('Erro na autenticação'),
                ],
              ),
            ),
          );
        }

        // 3. Estado Logado
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          print('AuthWrapper - Usuário logado: ${user.email} (${user.uid})');
          return const TelaInicio();
        }
        // 4. Estado Deslogado
        else {
          print('AuthWrapper - Usuário não logado, mostrando TelaLogin');
          return const TelaLogin();
        }
      },
    );
  }
}
