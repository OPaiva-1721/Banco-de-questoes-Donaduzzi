import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/exceptions/app_exceptions.dart';
import 'error_messages.dart';
import 'auth_error_utils.dart';

class MessageUtils {
  static void mostrarMensagem(
    BuildContext context,
    String mensagem, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration,
        elevation: 6,
      ),
    );
  }

  static void mostrarSucesso(
    BuildContext context,
    String mensagem, {
    Duration duration = const Duration(seconds: 3),
  }) {
    mostrarMensagem(
      context,
      mensagem,
      isError: false,
      duration: duration,
      icon: Icons.check_circle_outline,
    );
  }

  static void mostrarErro(
    BuildContext context,
    String mensagem, {
    Duration duration = const Duration(seconds: 4),
  }) {
    mostrarMensagem(
      context,
      mensagem,
      isError: true,
      duration: duration,
      icon: Icons.error_outline,
    );
  }

  /// Mostra erro formatado a partir de uma exceção
  /// 
  /// Converte automaticamente exceções em mensagens amigáveis usando
  /// ErrorMessages.fromException() e exibe com ícone apropriado.
  static void mostrarErroFormatado(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
    String? mensagemPersonalizada,
  }) {
    String mensagem;

    if (mensagemPersonalizada != null) {
      mensagem = mensagemPersonalizada;
    } else if (error is AppException) {
      mensagem = error.message;
    } else if (error is FirebaseAuthException) {
      mensagem = AuthErrorUtils.getErrorMessage(error);
    } else {
      mensagem = ErrorMessages.fromException(error);
    }

    IconData? icon = Icons.error_outline;
    if (error is NetworkException) {
      icon = Icons.wifi_off;
    } else if (error is ValidationException) {
      icon = Icons.warning_amber_rounded;
    } else if (error is NotFoundException) {
      icon = Icons.search_off;
    } else if (error is ResourceInUseException) {
      icon = Icons.block;
    } else if (error is AuthorizationException) {
      icon = Icons.lock_outline;
    } else if (error is AuthenticationException) {
      icon = Icons.person_off_outlined;
    } else if (error is FirebaseAuthException) {
      if (AuthErrorUtils.isNetworkError(error)) {
        icon = Icons.wifi_off;
      } else if (AuthErrorUtils.isCredentialError(error)) {
        icon = Icons.person_off_outlined;
      } else {
        icon = Icons.error_outline;
      }
    }

    mostrarMensagem(
      context,
      mensagem,
      isError: true,
      duration: duration,
      icon: icon,
    );
  }

  /// Mostra erro de validação (mais curto e específico)
  static void mostrarErroValidacao(
    BuildContext context,
    String mensagem,
  ) {
    mostrarMensagem(
      context,
      mensagem,
      isError: true,
      duration: const Duration(seconds: 3),
      icon: Icons.warning_amber_rounded,
    );
  }

  /// Mostra erro de rede (com sugestão de ação)
  static void mostrarErroRede(
    BuildContext context, {
    String? mensagemPersonalizada,
  }) {
    final mensagem = mensagemPersonalizada ?? ErrorMessages.networkError;
    mostrarMensagem(
      context,
      mensagem,
      isError: true,
      duration: const Duration(seconds: 5),
      icon: Icons.wifi_off,
    );
  }

  static void mostrarToast(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: const Color(0xFF541822),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
