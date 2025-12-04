import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SecurityService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late final DatabaseReference _logRef; // _referenciaLogs -> _logRef

  SecurityService() {
    // O nome do nó no Firebase também deve ser em inglês
    _logRef = _database.ref('security_logs'); // logs_seguranca -> security_logs
  }

  /// Validates text, checking for null, empty, or max length.
  bool validateText(String? text, {int maxLength = 100}) {
    // validarTexto -> validateText
    if (text == null || text.trim().isEmpty) {
      return false;
    }
    if (text.length > maxLength) {
      return false;
    }
    return true;
  }

  /// Cleans input text by trimming whitespace.
  String sanitizeInput(String text) {
    // sanitizarEntrada -> sanitizeInput
    return text.trim();
  }

  /// Logs a security activity to the Firebase database.
  /// Only logs if user is authenticated to avoid permission errors.
  Future<void> logSecurityActivity(
    // registrarAtividadeSeguranca -> logSecurityActivity
    String action, // acao -> action
    String details, { // detalhes -> details
    bool success = true, // sucesso -> success
  }) async {
    // Only log if user is authenticated
    // This prevents permission errors when user is not logged in
    if (_auth.currentUser == null) {
      // Silently skip logging when user is not authenticated
      // This is expected behavior during login/initialization
      return;
    }

    final userId = _auth.currentUser!.uid;

    try {
      final newLogRef = _logRef.push();
      // As chaves salvas no banco de dados também devem ser em inglês
      await newLogRef.set({
        'action': action,
        'details': details,
        'success': success,
        'userId': userId,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      // If writing the log fails, just print to console in debug mode.
      // Don't stop the main application flow.
      // Only print if it's not a permission error (which is expected when not authenticated)
      final errorString = e.toString();
      if (!errorString.contains('permission-denied') && 
          !errorString.contains('PERMISSION_DENIED')) {
        print('Error writing to security log: $e');
      }
    }
  }
}
