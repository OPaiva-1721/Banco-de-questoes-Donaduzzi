import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/message_utils.dart';
import '../../utils/password_validator.dart';
import 'recuperar_senha_screen.dart';

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
  PasswordValidationResult? _passwordValidation;

  @override
  void initState() {
    super.initState();
    _firebaseServico = FirebaseService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final email = _emailController.text.trim();
        final senha = _senhaController.text.trim();

        await _firebaseServico.signIn(email, senha);

        if (mounted) {
          MessageUtils.mostrarSucesso(context, 'Login realizado com sucesso!');
        }
      } catch (e) {
        if (mounted) {
          MessageUtils.mostrarErroFormatado(context, e);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _fazerRegistro() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final email = _emailController.text.trim();
        final senha = _senhaController.text.trim();
        final nome = _nomeController.text.trim().isEmpty
            ? email.split('@')[0]
            : _nomeController.text.trim();

        await _firebaseServico.registerUser(
          email: email,
          password: senha,
          name: nome,
        );

        if (mounted) {
          MessageUtils.mostrarSucesso(
            context,
            'Conta criada com sucesso! Você já está logado.',
          );
        }
      } catch (e) {
        if (mounted) {
          MessageUtils.mostrarErroFormatado(context, e);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _mostrarDialogoRecuperarSenha() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecuperarSenhaScreen()),
    );
  }

  void _validarSenha(String senha) {
    if (_isRegistro && senha.isNotEmpty) {
      setState(() {
        _passwordValidation = PasswordValidator.validatePassword(senha);
      });
    } else if (!_isRegistro) {
      setState(() {
        _passwordValidation = null;
      });
    }
  }

  Color _getPasswordStrengthColor() {
    if (_passwordValidation == null || !_isRegistro) return Colors.grey;
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

    final headerHeight = isMobile ? screenHeight * 0.2 : 150.0;
    final logoWidth = isMobile ? screenWidth * 0.5 : 196.0;
    final logoHeight = isMobile ? logoWidth * 0.34 : 67.0;
    final fieldWidth = isMobile ? screenWidth * 0.8 : 300.0;
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
                      "assets/images/logo.png",
                      width: logoWidth,
                      height: logoHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: logoWidth,
                          height: logoHeight,
                          color: Colors.white,
                          child: Icon(
                            Icons.image_not_supported,
                            size: logoWidth * 0.2,
                            color: const Color(0xFF541822),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20.0 : 40.0,
                    vertical: isMobile ? 30.0 : 50.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          _isRegistro ? "Criar Conta" : "Login",
                          style: TextStyle(
                            fontSize: isMobile ? 28.0 : 32.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),

                        SizedBox(height: isMobile ? 40.0 : 50.0),

                        if (_isRegistro) ...[
                          Container(
                            width: fieldWidth,
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
                                  vertical: 12,
                                ),
                              ),
                              validator: (value) {
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

                        Container(
                          width: fieldWidth,
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
                              hintText: "Email",
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
                                return 'Por favor, digite um email válido';
                              }
                              return null;
                            },
                          ),
                        ),

                        SizedBox(height: isMobile ? 20.0 : 25.0),

                        Container(
                          width: fieldWidth,
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
                            onChanged: _validarSenha,
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
                              if (_isRegistro &&
                                  _passwordValidation != null &&
                                  !_passwordValidation!.isValid) {
                                return _passwordValidation!.errors.isNotEmpty
                                    ? _passwordValidation!.errors.first
                                    : 'Senha inválida';
                              }
                              if (!_isRegistro && value.length < 6) {
                                return 'A senha deve ter pelo menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),

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
                                if (_passwordValidation!.errors.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  ..._passwordValidation!.errors.map(
                                    (error) => Padding(
                                      padding: const EdgeInsets.only(
                                        left: 24,
                                        bottom: 2,
                                      ),
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

                        SizedBox(
                          height: isMobile ? 25.0 : 30.0,
                        ),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
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
                                    : const Color(0xFF541822),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: isMobile ? 30.0 : 40.0,
                          ),
                        ],
                        if (_isRegistro)
                          SizedBox(height: isMobile ? 30.0 : 40.0),

                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isRegistro = !_isRegistro;
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
                                  : const Color(0xFF541822),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        SizedBox(
                          height: isMobile ? 30.0 : 50.0,
                        ),
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
