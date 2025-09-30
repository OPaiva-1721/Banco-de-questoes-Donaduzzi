import 'package:flutter/material.dart';
import '../home/pagina_principal.dart';
import '../../services/firebase_service.dart';
import '../../utils/message_utils.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  late final FirebaseService _firebaseServico;
  bool _senhaVisivel = false;
  bool _isLoading = false;
  bool _isRegistro = false;

  @override
  void initState() {
    super.initState();
    _firebaseServico = FirebaseService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final senha = _senhaController.text.trim();

        final sucesso = await _firebaseServico.fazerLogin(email, senha);

        if (sucesso) {
          MessageUtils.mostrarSucesso(context, 'Login realizado com sucesso!');

          // Navegar para a próxima tela
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TelaInicio()),
            );
          }
        } else {
          MessageUtils.mostrarErro(context, 'Email ou senha incorretos!');
        }
      } catch (e) {
        MessageUtils.mostrarErro(
          context,
          'Erro ao fazer login: ${e.toString()}',
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _fazerRegistro() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final senha = _senhaController.text.trim();
        final nome = email.split('@')[0]; // Usar parte do email como nome

        print('Tentando registrar usuário: $email');
        final sucesso = await _firebaseServico.registrarUsuario(
          email,
          senha,
          nome,
        );

        if (sucesso) {
          print('Usuário registrado com sucesso');
          MessageUtils.mostrarSucesso(context, 'Conta criada com sucesso!');

          // Navegar para a próxima tela
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TelaInicio()),
            );
          }
        } else {
          MessageUtils.mostrarErro(context, 'Erro ao criar conta!');
        }
      } catch (e) {
        print('Erro no registro: $e');
        MessageUtils.mostrarErro(
          context,
          'Erro ao criar conta: ${e.toString()}',
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _fazerLoginComGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _firebaseServico.fazerLoginComGoogle();

      if (result != null) {
        MessageUtils.mostrarSucesso(
          context,
          'Login com Google realizado com sucesso!',
        );

        // Navegar para a próxima tela
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TelaInicio()),
          );
        }
      } else {
        MessageUtils.mostrarErro(context, 'Erro ao fazer login com Google!');
      }
    } catch (e) {
      MessageUtils.mostrarErro(
        context,
        'Erro ao fazer login com Google: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 768;

    // Cálculos responsivos
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
                // Faixa superior
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
                            Icons.lock_outline,
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
                        // Título Login
                        Text(
                          "Login",
                          style: TextStyle(
                            fontSize: isMobile ? 28.0 : 32.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),

                        SizedBox(height: isMobile ? 40.0 : 50.0),

                        // Campo Email
                        Container(
                          width: fieldWidth,
                          height: fieldHeight,
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
                              hintText: "Gmail",
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
                              if (value == null || value.isEmpty) {
                                return 'Por favor, digite seu email';
                              }
                              if (!value.contains('@')) {
                                return 'Por favor, digite um email válido';
                              }
                              return null;
                            },
                          ),
                        ),

                        SizedBox(height: isMobile ? 20.0 : 25.0),

                        // Campo Senha
                        Container(
                          width: fieldWidth,
                          height: fieldHeight,
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
                              if (value.length < 6) {
                                return 'A senha deve ter pelo menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),

                        SizedBox(height: isMobile ? 30.0 : 40.0),

                        // Botão Entrar
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

                        // Divisor
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[400])),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "ou",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: isMobile ? 14.0 : 16.0,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[400])),
                          ],
                        ),

                        SizedBox(height: isMobile ? 20.0 : 25.0),

                        // Botão para alternar entre login e registro
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isRegistro = !_isRegistro;
                            });
                          },
                          child: Text(
                            _isRegistro
                                ? "Já tem uma conta? Faça login"
                                : "Não tem uma conta? Criar conta",
                            style: TextStyle(
                              fontSize: isMobile ? 14.0 : 16.0,
                              color: const Color(0xFF541822),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        SizedBox(height: isMobile ? 10.0 : 15.0),

                        SizedBox(height: isMobile ? 20.0 : 25.0),

                        // Botão Login com Google
                        GestureDetector(
                          onTap: _isLoading ? null : _fazerLoginComGoogle,
                          child: Container(
                            width: buttonWidth,
                            height: buttonHeight,
                            decoration: BoxDecoration(
                              color: _isLoading
                                  ? Colors.grey.withOpacity(0.7)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
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
                                              Color(0xFF541822),
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.g_mobiledata,
                                          size: isMobile ? 24.0 : 28.0,
                                          color: const Color(0xFF541822),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Entrar com Google",
                                          style: TextStyle(
                                            fontSize: isMobile ? 16.0 : 18.0,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF541822),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
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
