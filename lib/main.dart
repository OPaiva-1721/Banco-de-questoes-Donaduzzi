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
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase inicializado com sucesso');
    } else {
      print('Firebase já inicializado');
    }
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

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          print('AuthWrapper - Usuário logado: ${user.email} (${user.uid})');
          return const TelaInicio();
        } else {
          print('AuthWrapper - Usuário não logado, mostrando TelaLogin');
          return const TelaLogin();
        }
      },
    );
  }
}
