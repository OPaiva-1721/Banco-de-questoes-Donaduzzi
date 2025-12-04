import 'package:flutter/material.dart';
import '../../utils/message_utils.dart';
import '../../services/firebase_service.dart';
import '../../core/app_colors.dart';
import '../auth/tela_login.dart';
// Mantenha seus imports de telas...
import '../professor/criar_prova/criar_prova_screen.dart';
import '../professor/banco_questoes/banco_questoes_menu_screen.dart';
import '../professor/provas_geradas_screen.dart';
import '../professor/corrigir_prova/corrigir_prova_screen.dart';
import '../professor/disciplinas/gerenciar_disciplinas_screen.dart';
import '../professor/conteudo/gerenciar_conteudos_screen.dart';
import '../professor/cursos/gerenciar_cursos_screen.dart';

class TelaInicio extends StatelessWidget {
  const TelaInicio({super.key});

  static final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;
    // Pega as iniciais do usuário ou usa padrão
    final userInitials = user?.displayName?.isNotEmpty == true 
        ? user!.displayName!.substring(0, 2).toUpperCase() 
        : "PF";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              child: Text(userInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Olá, Professor", style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(user?.displayName ?? "Bem-vindo", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _fazerLogout(context),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
        ),
        child: Column(
          children: [
            // Container decorativo no topo
            Container(
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2, // 2 Colunas
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1, // Controla altura dos cards
                  children: [
                    _DashboardCard(
                      title: "Criar Prova",
                      icon: Icons.note_add_outlined,
                      color: Colors.blue.shade700,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CriarProvaScreen())),
                    ),
                    _DashboardCard(
                      title: "Banco de Questões",
                      icon: Icons.storage_rounded,
                      color: Colors.orange.shade700,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GerenciarQuestoesScreen())),
                    ),
                    _DashboardCard(
                      title: "Provas Geradas",
                      icon: Icons.history_edu_rounded,
                      color: Colors.purple.shade700,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProvasGeradasScreen())),
                    ),
                    _DashboardCard(
                      title: "Corrigir Prova",
                      icon: Icons.document_scanner_rounded,
                      color: Colors.teal.shade700,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CorrigirProvaScreen())),
                    ),
                     _DashboardCard(
                      title: "Disciplinas",
                      icon: Icons.book_outlined,
                      color: Colors.indigo.shade700,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GerenciarDisciplinasScreen())),
                    ),
                    _DashboardCard(
                      title: "Conteúdos",
                      icon: Icons.library_books_outlined,
                      color: Colors.pink.shade700,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GerenciarConteudosScreen())),
                    ),
                    _DashboardCard(
                      title: "Cursos",
                      icon: Icons.school_outlined,
                      color: Colors.brown.shade700,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GerenciarCursosScreen())),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fazerLogout(BuildContext context) async {
    try {
      await _firebaseService.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const TelaLogin()),
        (route) => false,
      );
    } catch (e) {
      MessageUtils.mostrarErroFormatado(context, e);
    }
  }
}

// Widget auxiliar para os Cards do Dashboard
class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}