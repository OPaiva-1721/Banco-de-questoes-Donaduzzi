class PasswordValidator {
  /// Valida se a senha atende aos critérios de segurança
  static PasswordValidationResult validatePassword(String password) {
    final errors = <String>[];

    // Verificar comprimento mínimo
    if (password.length < 8) {
      errors.add('A senha deve ter pelo menos 8 caracteres');
    }

    // Verificar se contém pelo menos uma letra minúscula
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('A senha deve conter pelo menos uma letra minúscula');
    }

    // Verificar se contém pelo menos uma letra maiúscula
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('A senha deve conter pelo menos uma letra maiúscula');
    }

    // Verificar se contém pelo menos um número
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('A senha deve conter pelo menos um número');
    }

    // Verificar se contém pelo menos um caractere especial
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add(
        'A senha deve conter pelo menos um caractere especial (!@#\$%^&*(),.?":{}|<>)',
      );
    }

    // Verificar senhas comuns
    if (_isCommonPassword(password)) {
      errors.add('Esta senha é muito comum. Escolha uma senha mais única');
    }

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      strength: _calculateStrength(password),
    );
  }

  /// Verifica se a senha é uma senha comum
  static bool _isCommonPassword(String password) {
    const commonPasswords = [
      'password',
      '123456',
      '123456789',
      'qwerty',
      'abc123',
      'password123',
      'admin',
      'letmein',
      'welcome',
      'monkey',
      '1234567890',
      'password1',
      'qwerty123',
      'dragon',
      'master',
      'hello',
      'freedom',
      'whatever',
      'qazwsx',
      'trustno1',
    ];

    return commonPasswords.contains(password.toLowerCase());
  }

  /// Calcula a força da senha
  static PasswordStrength _calculateStrength(String password) {
    int score = 0;

    // Comprimento
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (password.length >= 16) score += 1;

    // Caracteres
    if (password.contains(RegExp(r'[a-z]'))) score += 1;
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    if (password.contains(RegExp(r'[0-9]'))) score += 1;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 1;

    // Diversidade de caracteres
    final uniqueChars = password.split('').toSet().length;
    if (uniqueChars >= password.length * 0.6) score += 1;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }
}

class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;
  final PasswordStrength strength;

  PasswordValidationResult({
    required this.isValid,
    required this.errors,
    required this.strength,
  });

  String get strengthText {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Fraca';
      case PasswordStrength.medium:
        return 'Média';
      case PasswordStrength.strong:
        return 'Forte';
      case PasswordStrength.veryStrong:
        return 'Muito Forte';
    }
  }
}

enum PasswordStrength { weak, medium, strong, veryStrong }
