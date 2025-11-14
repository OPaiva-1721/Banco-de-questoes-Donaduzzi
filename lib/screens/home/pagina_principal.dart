import 'package:flutter/material.dart';
import 'package:prova/screens/professor/banco_questoes/banco_questoes_menu_screen.dart';
import 'package:prova/screens/professor/conteudo/gerenciar_conteudos_screen.dart';
import '../../utils/message_utils.dart';
import '../../services/firebase_service.dart';
import '../auth/tela_login.dart';
import '../professor/criar_prova/criar_prova_screen.dart';
import '../professor/provas_geradas_screen.dart';
import '../professor/disciplinas/gerenciar_disciplinas_screen.dart';
import '../professor/cursos/gerenciar_cursos_screen.dart';

class TelaInicio extends StatelessWidget {
  const TelaInicio({super.key});

  static final FirebaseService _firebaseService = FirebaseService();

  // Sistema de temas
  static const Color _primaryColor = Color(0xFF541822);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _textSecondaryColor = Colors.black54;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;
    final isTablet = screenSize.width >= 768 && screenSize.width < 1024;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          // Header fixo
          _buildHeader(context, isMobile, isTablet),

          // Conteúdo principal
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 24.0,
                vertical: 24.0,
              ),
              child: Column(
                children: [
                  // Título
                  _buildTitle(isMobile, isTablet),

                  const SizedBox(height: 32),

                  // Cards de funcionalidades
                  _buildCardsGrid(context, isMobile, isTablet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header responsivo
  Widget _buildHeader(BuildContext context, bool isMobile, bool isTablet) {
    final headerHeight = isMobile ? 100.0 : (isTablet ? 110.0 : 120.0);
    final logoSize = isMobile ? 140.0 : (isTablet ? 150.0 : 160.0);
    final logoHeight = isMobile ? 50.0 : (isTablet ? 55.0 : 60.0);

    return Container(
      width: double.infinity,
      height: headerHeight,
      decoration: BoxDecoration(
        color: _primaryColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 4,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Logo centralizado
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: logoSize,
              height: logoHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: logoSize,
                  height: logoHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'LOGO',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Botão de logout no canto direito
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () => _fazerLogout(context),
                icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                tooltip: 'Sair',
                style: IconButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Título da página
  Widget _buildTitle(bool isMobile, bool isTablet) {
    return Text(
      "Painel do Professor",
      style: TextStyle(
        fontFamily: "Inter",
        fontSize: isMobile ? 24 : 30,
        fontWeight: FontWeight.bold,
        color: _textColor,
      ),
    );
  }

  // Grid de cards responsivo
  Widget _buildCardsGrid(BuildContext context, bool isMobile, bool isTablet) {
    final cards = [
      _CardData(
        title: "Criar nova prova",
        subtitle: "Crie uma nova prova selecionando questões do banco.",
        icon: Icons.add,
        onTap: () => _navegarParaCriarProva(context),
      ),
      _CardData(
        title: "Banco de questões",
        subtitle: "Adicione, edite ou visualize as questões existentes.",
        icon: Icons.list_alt,
        onTap: () => _navegarParaBancoQuestoes(context),
      ),
      _CardData(
        title: "Provas geradas",
        subtitle: "Histórico de provas geradas.",
        icon: Icons.history,
        onTap: () => _navegarParaProvasGeradas(context),
      ),
      _CardData(
        title: "Gerenciar Disciplinas",
        subtitle: "Adicione, edite ou gerencie as disciplinas do sistema.",
        icon: Icons.school,
        onTap: () => _navegarParaDisciplinas(context),
      ),
      _CardData(
        title: "Criar novo conteudo",
        subtitle: "Crie um novo conteúdo selecionando questões do banco.",
        icon: Icons.add,
        onTap: () => _navegarParaCriarConteudo(context),
      ),
      _CardData(
        title: "Gerenciar Cursos",
        subtitle: "Adicione, edite ou gerencie os cursos do sistema.",
        icon: Icons.school_outlined,
        onTap: () => _navegarParaCursos(context),
      ),
    ];

    return Column(
      children: cards
          .map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCard(context, card, isMobile, isTablet),
            ),
          )
          .toList(),
    );
  }

  // Card individual otimizado
  Widget _buildCard(
    BuildContext context,
    _CardData cardData,
    bool isMobile,
    bool isTablet,
  ) {
    final cardHeight = isMobile ? 120.0 : (isTablet ? 130.0 : 134.0);
    final iconSize = isMobile ? 25.0 : (isTablet ? 28.0 : 30.0);
    final iconRadius = isMobile ? 25.0 : (isTablet ? 28.0 : 33.0);
    final titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);
    final subtitleFontSize = isMobile ? 13.0 : (isTablet ? 14.0 : 15.0);

    return Semantics(
      label: cardData.title,
      hint: cardData.subtitle,
      button: true,
      child: GestureDetector(
        onTap: cardData.onTap,
        child: Container(
          width: double.infinity,
          height: cardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 16 : 20,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: iconRadius,
                  backgroundColor: _primaryColor,
                  child: Icon(
                    cardData.icon,
                    color: Colors.white,
                    size: iconSize,
                    semanticLabel: cardData.title,
                  ),
                ),
                SizedBox(width: isMobile ? 16 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cardData.title,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cardData.subtitle,
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: _textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: _textSecondaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navegarParaCriarProva(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CriarProvaScreen()),
    );
  }

  void _navegarParaBancoQuestoes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GerenciarQuestoesScreen()),
    );
  }

  void _navegarParaProvasGeradas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProvasGeradasScreen()),
    );
  }
  

  void _navegarParaDisciplinas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GerenciarDisciplinasScreen(),
      ),
    );
  }

  void _navegarParaCriarConteudo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GerenciarConteudosScreen()),
    );
  }

  void _navegarParaCursos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GerenciarCursosScreen()),
    );
  }

  // Método para fazer logout
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

// Classe para dados dos cards
class _CardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _CardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
