import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/pagina_principal.dart'; // Sua TelaInicio
import '../../services/firebase_service.dart'; // Usaremos a fachada
import '../../utils/message_utils.dart';
import '../../utils/auth_error_utils.dart';
import '../../utils/password_validator.dart';
// Removido: import google_sign_in (não é mais necessário)

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _nomeController = TextEditingController();
  late final FirebaseService _firebaseServico;
  bool _senhaVisivel = false;
  bool _isLoading = false;
  bool _isRegistro = false; // Controla se estamos em modo Login ou Registro
  // Removido: bool _lembrarMe = false;
  PasswordValidationResult? _passwordValidation;

  @override
  void initState() {
    super.initState();
    // Instancia a fachada de serviços
    _firebaseServico = FirebaseService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  // --- FUNÇÃO DE LOGIN ---
  Future<void> _fazerLogin() async {
    // Valida o formulário antes de prosseguir
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true); // Mostra indicador de carregamento

      try {
        final email = _emailController.text.trim();
        final senha = _senhaController.text.trim();

        // Chama o método de login do FirebaseService (que usa FirebaseAuth)
        await _firebaseServico.signIn(email, senha);

        // Se chegou aqui, o login foi bem-sucedido.
        // O AuthWrapper no main.dart vai detectar a mudança e navegar automaticamente.
        // Não precisamos navegar manualmente aqui.
        if (mounted) {
          MessageUtils.mostrarSucesso(context, 'Login realizado com sucesso!');
          // A navegação será feita pelo AuthWrapper
        }
      } on FirebaseAuthException catch (e) {
        // Trata erros específicos do Firebase Auth
        final errorMessage = AuthErrorUtils.getErrorMessage(e);
        if (mounted) MessageUtils.mostrarErro(context, errorMessage);
      } catch (e) {
        // Trata outros erros inesperados
        if (mounted)
          MessageUtils.mostrarErro(context, 'Erro inesperado: ${e.toString()}');
      } finally {
        // Garante que o indicador de carregamento seja removido, mesmo com erro
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // --- FUNÇÃO DE REGISTRO ---
  Future<void> _fazerRegistro() async {
    // Valida o formulário antes de prosseguir
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true); // Mostra indicador de carregamento

      try {
        final email = _emailController.text.trim();
        final senha = _senhaController.text.trim();
        // Usa o nome digitado ou parte do email como padrão
        final nome = _nomeController.text.trim().isEmpty
            ? email.split('@')[0]
            : _nomeController.text.trim();

        // Chama o método de registro do FirebaseService (que usa FirebaseAuth)
        await _firebaseServico.registerUser(
          email: email,
          password: senha,
          name: nome,
        );

        // Se chegou aqui, o registro foi bem-sucedido.
        if (mounted) {
          MessageUtils.mostrarSucesso(
            context,
            'Conta criada com sucesso! Você já está logado.', // Mensagem simplificada
          );
          // O AuthWrapper no main.dart vai detectar a mudança e navegar automaticamente.
        }
      } on FirebaseAuthException catch (e) {
        final errorMessage = AuthErrorUtils.getErrorMessage(e);
        if (mounted) MessageUtils.mostrarErro(context, errorMessage);
      } catch (e) {
        if (mounted)
          MessageUtils.mostrarErro(
            context,
            'Erro ao criar conta: ${e.toString()}',
          );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Removido: _fazerLoginComGoogle()

  // Removido: _mostrarDialogoVerificacaoEmail()

  // --- FUNÇÃO PARA RECUPERAR SENHA --- (Mantida)
  void _mostrarDialogoRecuperarSenha() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recuperar Senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Digite seu email para receber instruções de recuperação de senha.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  if (mounted)
                    MessageUtils.mostrarErro(
                      context,
                      'Digite um email válido.',
                    );
                  return;
                }
                try {
                  // Chama o método de recuperação do FirebaseService
                  await _firebaseServico.sendPasswordResetEmail(email);
                  if (mounted) {
                    MessageUtils.mostrarSucesso(
                      context,
                      'Email de recuperação enviado! Verifique sua caixa de entrada.',
                    );
                    Navigator.of(context).pop(); // Fecha o diálogo
                  }
                } on FirebaseAuthException catch (e) {
                  final errorMessage = AuthErrorUtils.getErrorMessage(e);
                  if (mounted) MessageUtils.mostrarErro(context, errorMessage);
                } catch (e) {
                  if (mounted)
                    MessageUtils.mostrarErro(
                      context,
                      'Erro ao enviar email: ${e.toString()}',
                    );
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  // Funções de validação de senha (mantidas)
  void _validarSenha(String senha) {
    if (_isRegistro && senha.isNotEmpty) {
      setState(() {
        _passwordValidation = PasswordValidator.validatePassword(senha);
      });
    } else if (!_isRegistro) {
      // Limpa a validação se estiver na tela de login
      setState(() {
        _passwordValidation = null;
      });
    }
  }

  Color _getPasswordStrengthColor() {
    if (_passwordValidation == null || !_isRegistro) return Colors.grey;
    // ... (código igual)
    switch (_passwordValidation!.strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.blue;
      case PasswordStrength.veryStrong:
        return Colors.green;
    }
  }

  IconData _getPasswordStrengthIcon() {
    if (_passwordValidation == null || !_isRegistro) return Icons.help_outline;
    // ... (código igual)
    switch (_passwordValidation!.strength) {
      case PasswordStrength.weak:
        return Icons.warning;
      case PasswordStrength.medium:
        return Icons.info;
      case PasswordStrength.strong:
        return Icons.check_circle_outline;
      case PasswordStrength.veryStrong:
        return Icons.verified;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 768;

    // Cálculos responsivos (mantidos)
    final headerHeight = isMobile ? screenHeight * 0.2 : 150.0;
    final logoWidth = isMobile ? screenWidth * 0.5 : 196.0;
    final logoHeight = isMobile ? logoWidth * 0.34 : 67.0;
    final fieldWidth = isMobile ? screenWidth * 0.8 : 300.0;
    final fieldHeight = isMobile ? 50.0 : 48.0;
    final buttonWidth = isMobile ? screenWidth * 0.7 : 280.0;
    final buttonHeight = isMobile ? 50.0 : 45.0;

    return Scaffold(
      body: Container(
        color: const Color(0xFFF5F5F5),
        width: double.infinity,
        height: screenHeight,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: Column(
              children: [
                // Faixa superior (igual)
                Container(
                  width: double.infinity,
                  height: headerHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF541822),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: const Offset(0, 8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      "assets/images/logo.png", // Confirme se o caminho está correto
                      width: logoWidth,
                      height: logoHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          // Placeholder em caso de erro ao carregar a imagem
                          width: logoWidth,
                          height: logoHeight,
                          color: Colors.white,
                          child: Icon(
                            Icons
                                .image_not_supported, // Ícone de imagem não suportada
                            size: logoWidth * 0.2,
                            color: const Color(0xFF541822),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Conteúdo principal
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20.0 : 40.0,
                    vertical: isMobile ? 30.0 : 50.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Título Login/Registro (Dinâmico)
                        Text(
                          _isRegistro
                              ? "Criar Conta"
                              : "Login", // Muda o título
                          style: TextStyle(
                            fontSize: isMobile ? 28.0 : 32.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),

                        SizedBox(height: isMobile ? 40.0 : 50.0),

                        // Campo Nome (apenas no registro)
                        if (_isRegistro) ...[
                          Container(
                            width: fieldWidth,
                            // height: fieldHeight, // Removido para permitir expansão com erro
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: const Color(0xFF020101),
                                width: 1,
                              ),
                            ),
                            child: TextFormField(
                              controller: _nomeController,
                              style: TextStyle(
                                fontSize: isMobile ? 16.0 : 18.0,
                                color: const Color(0xFF333333),
                              ),
                              decoration: InputDecoration(
                                hintText: "Nome completo",
                                hintStyle: TextStyle(
                                  fontSize: isMobile ? 16.0 : 18.0,
                                  color: const Color.fromRGBO(0, 0, 0, 0.49),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12, // Ajuste conforme necessário
                                ),
                              ),
                              validator: (value) {
                                // Validação só é necessária no registro
                                if (_isRegistro &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'Por favor, digite seu nome';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: isMobile ? 20.0 : 25.0),
                        ],

                        // Campo Email (igual)
                        Container(
                          width: fieldWidth,
                          // height: fieldHeight, // Removido
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: const Color(0xFF020101),
                              width: 1,
                            ),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontSize: isMobile ? 16.0 : 18.0,
                              color: const Color(0xFF333333),
                            ),
                            decoration: InputDecoration(
                              hintText: "Email", // "Gmail" -> "Email"
                              hintStyle: TextStyle(
                                fontSize: isMobile ? 16.0 : 18.0,
                                color: const Color.fromRGBO(0, 0, 0, 0.49),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor, digite seu email';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                // Validação simples
                                return 'Por favor, digite um email válido';
                              }
                              return null;
                            },
                          ),
                        ),

                        SizedBox(height: isMobile ? 20.0 : 25.0),

                        // Campo Senha (igual)
                        Container(
                          width: fieldWidth,
                          // height: fieldHeight, // Removido
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: const Color(0xFF020101),
                              width: 1,
                            ),
                          ),
                          child: TextFormField(
                            controller: _senhaController,
                            obscureText: !_senhaVisivel,
                            onChanged:
                                _validarSenha, // Valida ao digitar (no registro)
                            style: TextStyle(
                              fontSize: isMobile ? 16.0 : 18.0,
                              color: const Color(0xFF333333),
                            ),
                            decoration: InputDecoration(
                              hintText: "Senha",
                              hintStyle: TextStyle(
                                fontSize: isMobile ? 16.0 : 18.0,
                                color: const Color.fromRGBO(0, 0, 0, 0.48),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _senhaVisivel
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: const Color.fromRGBO(0, 0, 0, 0.48),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _senhaVisivel = !_senhaVisivel;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, digite sua senha';
                              }
                              // Validação de força só no registro
                              if (_isRegistro &&
                                  _passwordValidation != null &&
                                  !_passwordValidation!.isValid) {
                                return _passwordValidation!.errors.isNotEmpty
                                    ? _passwordValidation!.errors.first
                                    : 'Senha inválida'; // Fallback
                              }
                              // Validação mínima para login
                              if (!_isRegistro && value.length < 6) {
                                return 'A senha deve ter pelo menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),

                        // Indicador de força da senha (apenas no registro)
                        if (_isRegistro && _passwordValidation != null) ...[
                          SizedBox(height: isMobile ? 10.0 : 15.0),
                          Container(
                            width: fieldWidth,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getPasswordStrengthColor().withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getPasswordStrengthColor(),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getPasswordStrengthIcon(),
                                      color: _getPasswordStrengthColor(),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Força da senha: ${_passwordValidation!.strengthText}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 12.0 : 14.0,
                                        color: _getPasswordStrengthColor(),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                // Mostra os erros específicos se houver
                                if (_passwordValidation!.errors.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  ..._passwordValidation!.errors.map(
                                    (error) => Padding(
                                      padding: const EdgeInsets.only(
                                        left: 24,
                                        bottom: 2,
                                      ), // Indenta os erros
                                      child: Text(
                                        '• $error',
                                        style: TextStyle(
                                          fontSize: isMobile ? 11.0 : 12.0,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // Removido: Checkbox "Lembrar-me"
                        SizedBox(
                          height: isMobile ? 25.0 : 30.0,
                        ), // Aumenta espaço
                        // Botão Entrar / Criar Conta
                        GestureDetector(
                          onTap: _isLoading
                              ? null // Desabilita se estiver carregando
                              : (_isRegistro ? _fazerRegistro : _fazerLogin),
                          child: Container(
                            width: buttonWidth,
                            height: buttonHeight,
                            decoration: BoxDecoration(
                              color: _isLoading
                                  ? const Color(0xFF541822).withOpacity(0.7)
                                  : const Color(0xFF541822),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? SizedBox(
                                      // Indicador de carregamento
                                      width: isMobile ? 24.0 : 28.0,
                                      height: isMobile ? 24.0 : 28.0,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFFF5F5F5),
                                            ),
                                      ),
                                    )
                                  : Text(
                                      // Texto do botão (dinâmico)
                                      _isRegistro ? "Criar Conta" : "Entrar",
                                      style: TextStyle(
                                        fontSize: isMobile ? 18.0 : 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFF5F5F5),
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        SizedBox(height: isMobile ? 20.0 : 25.0),

                        // Link para recuperar senha (apenas no login)
                        if (!_isRegistro) ...[
                          GestureDetector(
                            onTap: _isLoading
                                ? null
                                : _mostrarDialogoRecuperarSenha,
                            child: Text(
                              "Esqueceu sua senha?",
                              style: TextStyle(
                                fontSize: isMobile ? 14.0 : 16.0,
                                color: _isLoading
                                    ? Colors.grey
                                    : const Color(
                                        0xFF541822,
                                      ), // Desabilita cor se carregando
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: isMobile ? 30.0 : 40.0,
                          ), // Aumenta espaço
                        ],
                        // Se for registro, adiciona espaço extra no final
                        if (_isRegistro)
                          SizedBox(height: isMobile ? 30.0 : 40.0),

                        // Divisor (removido porque o botão Google foi removido)
                        // Row(...),

                        // SizedBox(height: isMobile ? 20.0 : 25.0),

                        // Botão para alternar entre login e registro
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                  // Desabilita se carregando
                                  setState(() {
                                    _isRegistro = !_isRegistro;
                                    // Limpa os campos e a validação ao trocar de modo
                                    _formKey.currentState?.reset();
                                    _emailController.clear();
                                    _senhaController.clear();
                                    _nomeController.clear();
                                    _passwordValidation = null;
                                  });
                                },
                          child: Text(
                            _isRegistro
                                ? "Já tem uma conta? Faça login"
                                : "Não tem uma conta? Criar conta",
                            style: TextStyle(
                              fontSize: isMobile ? 14.0 : 16.0,
                              color: _isLoading
                                  ? Colors.grey
                                  : const Color(0xFF541822), // Desabilita cor
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        // Removido: Botão Login com Google
                        SizedBox(
                          height: isMobile ? 30.0 : 50.0,
                        ), // Espaço final
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
