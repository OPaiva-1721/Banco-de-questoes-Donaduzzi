class AppConstants {
  // Configurações do app
  static const String appName = 'Sistema de Provas';
  static const String appVersion = '1.0.0';

  // Configurações de UI
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultElevation = 4.0;

  // Configurações de animação
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Configurações de mensagens
  static const Duration messageDuration = Duration(seconds: 3);
  static const Duration toastDuration = Duration(seconds: 2);

  // Configurações de validação
  static const int minPasswordLength = 6;
  static const int maxQuestionTextLength = 500;
  static const int maxOptionTextLength = 200;

  // Configurações de responsividade
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;
}
