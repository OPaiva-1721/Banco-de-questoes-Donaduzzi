import 'package:flutter/material.dart';

class MessageUtils {
  // Mostrar mensagem de sucesso ou erro
  static void mostrarMensagem(
    BuildContext context,
    String mensagem, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration,
      ),
    );
  }

  // Mostrar mensagem de sucesso
  static void mostrarSucesso(BuildContext context, String mensagem) {
    mostrarMensagem(context, mensagem, isError: false);
  }

  // Mostrar mensagem de erro
  static void mostrarErro(BuildContext context, String mensagem) {
    mostrarMensagem(context, mensagem, isError: true);
  }

  // Mostrar toast no canto inferior direito (conforme preferência do usuário)
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
