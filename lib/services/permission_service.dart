import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// Serviço para gerenciar solicitações de permissões dangerous do Android
class PermissionService {
  /// Solicita permissão de notificações (POST_NOTIFICATIONS) para Android 13+
  /// Retorna true se a permissão foi concedida ou não é necessária
  static Future<bool> requestNotificationPermission() async {
    // Apenas Android 13+ (API 33+) requer solicitação explícita
    if (!Platform.isAndroid) {
      return true; // iOS e outras plataformas não precisam
    }

    try {
      final status = await Permission.notification.status;
      
      // Se já foi concedida, retorna true
      if (status.isGranted) {
        return true;
      }
      
      // Se foi negada permanentemente, retorna false
      if (status.isPermanentlyDenied) {
        return false;
      }
      
      // Solicita a permissão
      final result = await Permission.notification.request();
      return result.isGranted;
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao solicitar permissão de notificações: $e');
      return false;
    }
  }

  /// Verifica se a permissão de notificações está concedida
  static Future<bool> isNotificationPermissionGranted() async {
    if (!Platform.isAndroid) {
      return true;
    }
    
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao verificar permissão de notificações: $e');
      return false;
    }
  }

  /// Solicita permissão de câmera
  /// Retorna true se a permissão foi concedida
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isPermanentlyDenied) {
        return false;
      }
      
      final result = await Permission.camera.request();
      return result.isGranted;
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao solicitar permissão de câmera: $e');
      return false;
    }
  }

  /// Solicita permissão de acesso a imagens (READ_MEDIA_IMAGES para Android 13+)
  /// ou READ_EXTERNAL_STORAGE para Android < 13
  static Future<bool> requestImagePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      // Android 13+ usa READ_MEDIA_IMAGES
      // Android < 13 usa READ_EXTERNAL_STORAGE
      final permission = _getImagePermission();
      final status = await permission.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isPermanentlyDenied) {
        return false;
      }
      
      final result = await permission.request();
      return result.isGranted;
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao solicitar permissão de imagens: $e');
      return false;
    }
  }

  /// Retorna a permissão de imagem apropriada baseada na versão do Android
  static Permission _getImagePermission() {
    // Para Android 13+ (API 33+), usa READ_MEDIA_IMAGES
    // Para versões anteriores, usa READ_EXTERNAL_STORAGE
    // O permission_handler gerencia isso automaticamente
    return Permission.photos;
  }

}

