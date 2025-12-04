import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/message_utils.dart';
import '../../utils/password_validator.dart';
import '../../core/app_colors.dart';
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
  bool _isRegistro = false;
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

  // Lógicas de Login/Registro (mantidas do original)
  Future<void> _fazerLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await _firebaseServico.signIn(_emailController.text.trim(), _senhaController.text.trim());
        if (mounted) MessageUtils.mostrarSucesso(context, 'Bem-vindo de volta!');
      } catch (e) {
        if (mounted) MessageUtils.mostrarErroFormatado(context, e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fazerRegistro() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final nome = _nomeController.text.trim().isEmpty ? _emailController.text.split('@')[0] : _nomeController.text.trim();
        await _firebaseServico.registerUser(email: _emailController.text.trim(), password: _senhaController.text.trim(), name: nome);
        if (mounted) MessageUtils.mostrarSucesso(context, 'Conta criada com sucesso!');
      } catch (e) {
        if (mounted) MessageUtils.mostrarErroFormatado(context, e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _validarSenha(String senha) {
    if (_isRegistro && senha.isNotEmpty) {
      setState(() => _passwordValidation = PasswordValidator.validatePassword(senha));
    } else if (!_isRegistro) {
      setState(() => _passwordValidation = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Define se a tela é pequena (para esconder o logo se necessário em telas muito curtas)
    final isSmallHeight = size.height < 600; 

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- INÍCIO DA CORREÇÃO DO LOGO ---
                    if (!isSmallHeight) ...[
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          "assets/images/logo.png",
                          height: 80,
                          fit: BoxFit.contain,
                          // AQUI ESTÁ A MÁGICA:
                          // Como o fundo é claro, pintamos o logo branco com a cor primária (vinho)
                          color: AppColors.primary,
                          colorBlendMode: BlendMode.srcIn, 
                          
                          errorBuilder: (_,__,___) => const Icon(Icons.school, size: 80, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    // --- FIM DA CORREÇÃO DO LOGO ---

                    Text(
                      _isRegistro ? "Crie sua conta" : "Bem-vindo",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegistro ? "Preencha os dados para começar" : "Insira suas credenciais para continuar",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_isRegistro) ...[
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: "Nome completo",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "E-mail",
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) => (value == null || !value.contains('@')) ? 'E-mail inválido' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _senhaController,
                      obscureText: !_senhaVisivel,
                      onChanged: _validarSenha,
                      decoration: InputDecoration(
                        labelText: "Senha",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_senhaVisivel ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                        ),
                      ),
                      validator: (value) => (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),

                    if (_isRegistro && _passwordValidation != null) ...[
                       const SizedBox(height: 8),
                       LinearProgressIndicator(
                         value: _passwordValidation!.strength.index / 4,
                         color: _getPasswordStrengthColor(_passwordValidation!.strength),
                         backgroundColor: Colors.grey[200],
                         minHeight: 4,
                         borderRadius: BorderRadius.circular(2),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         "Força da senha: ${_passwordValidation!.strengthText}",
                         style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                       ),
                    ],

                    if (!_isRegistro) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecuperarSenhaScreen())),
                          child: const Text("Esqueceu a senha?"),
                        ),
                      ),
                    ] else 
                      const SizedBox(height: 24),

                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isLoading ? null : (_isRegistro ? _fazerRegistro : _fazerLogin),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isRegistro ? "CADASTRAR" : "ENTRAR"),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isRegistro ? "Já tem conta? " : "Não tem conta? "),
                        GestureDetector(
                          onTap: () {
                             setState(() {
                               _isRegistro = !_isRegistro;
                               _formKey.currentState?.reset();
                               _passwordValidation = null;
                             });
                          },
                          child: Text(
                            _isRegistro ? "Fazer Login" : "Cadastre-se",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getPasswordStrengthColor(PasswordStrength strength) {
      switch (strength) {
        case PasswordStrength.weak: return Colors.red;
        case PasswordStrength.medium: return Colors.orange;
        case PasswordStrength.strong: return Colors.blue;
        case PasswordStrength.veryStrong: return Colors.green;
      }
  }
}