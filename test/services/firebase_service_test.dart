// import 'package:flutter_test/flutter_test.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:prova/services/firebase_service.dart';
// import 'package:prova/utils/password_validator.dart';
// import 'package:prova/utils/auth_error_utils.dart';

// void main() {
//   group('FirebaseService', () {
//     late FirebaseService firebaseService;

//     setUp(() {
//       firebaseService = FirebaseService();
//     });

//     group('Validação de Entrada', () {
//       test('deve validar entrada válida', () {
//         expect(firebaseService.validarEntrada('teste@email.com'), true);
//         expect(firebaseService.validarEntrada('João Silva'), true);
//       });

//       test('deve rejeitar entrada vazia', () {
//         expect(firebaseService.validarEntrada(''), false);
//         expect(firebaseService.validarEntrada('   '), false);
//       });

//       test('deve rejeitar entrada com caracteres perigosos', () {
//         expect(firebaseService.validarEntrada('<script>'), false);
//         expect(firebaseService.validarEntrada('teste"'), false);
//         expect(firebaseService.validarEntrada("teste'"), false);
//       });

//       test('deve respeitar limite de caracteres', () {
//         final entradaLonga = 'a' * 101;
//         expect(
//           firebaseService.validarEntrada(entradaLonga, maxLength: 100),
//           false,
//         );
//         expect(firebaseService.validarEntrada('teste', maxLength: 100), true);
//       });
//     });

//     group('Sanitização de Entrada', () {
//       test('deve sanitizar caracteres perigosos', () {
//         expect(firebaseService.sanitizarEntrada('<script>'), '&lt;script&gt;');
//         expect(firebaseService.sanitizarEntrada('teste"'), 'teste&quot;');
//         expect(firebaseService.sanitizarEntrada("teste'"), 'teste&#x27;');
//         expect(firebaseService.sanitizarEntrada('teste&'), 'teste&amp;');
//       });

//       test('deve remover espaços em branco', () {
//         expect(firebaseService.sanitizarEntrada('  teste  '), 'teste');
//       });
//     });

//     group('Verificação de Permissões', () {
//       test('deve retornar false para usuário não logado', () async {
//         // Mock para usuário não logado
//         final result = await firebaseService.verificarPermissao('criarProvas');
//         expect(result, false);
//       });
//     });
//   });
// }

// // Testes para PasswordValidator
// void mainPasswordValidator() {
//   group('PasswordValidator', () {
//     test('deve validar senha forte', () {
//       final result = PasswordValidator.validatePassword('MinhaSenh@123');
//       expect(result.isValid, true);
//       expect(result.strength, PasswordStrength.strong);
//     });

//     test('deve rejeitar senha fraca', () {
//       final result = PasswordValidator.validatePassword('123');
//       expect(result.isValid, false);
//       expect(result.strength, PasswordStrength.weak);
//       expect(result.errors.length, greaterThan(0));
//     });

//     test('deve rejeitar senha comum', () {
//       final result = PasswordValidator.validatePassword('password');
//       expect(result.isValid, false);
//       expect(result.errors.any((error) => error.contains('comum')), true);
//     });

//     test('deve calcular força corretamente', () {
//       expect(
//         PasswordValidator.validatePassword('123').strength,
//         PasswordStrength.weak,
//       );
//       expect(
//         PasswordValidator.validatePassword('Minha123').strength,
//         PasswordStrength.medium,
//       );
//       expect(
//         PasswordValidator.validatePassword('MinhaSenh@123').strength,
//         PasswordStrength.strong,
//       );
//       expect(
//         PasswordValidator.validatePassword('MinhaSenh@MuitoForte123!').strength,
//         PasswordStrength.veryStrong,
//       );
//     });
//   });
// }

// // Testes para AuthErrorUtils
// void mainAuthErrorUtils() {
//   group('AuthErrorUtils', () {
//     test('deve converter erro user-not-found', () {
//       final exception = FirebaseAuthException(code: 'user-not-found');
//       final message = AuthErrorUtils.getErrorMessage(exception);
//       expect(message, 'Nenhum usuário encontrado com este email.');
//     });

//     test('deve converter erro wrong-password', () {
//       final exception = FirebaseAuthException(code: 'wrong-password');
//       final message = AuthErrorUtils.getErrorMessage(exception);
//       expect(message, 'Senha incorreta. Tente novamente.');
//     });

//     test('deve identificar erro de rede', () {
//       final exception = FirebaseAuthException(code: 'network-request-failed');
//       expect(AuthErrorUtils.isNetworkError(exception), true);
//       expect(AuthErrorUtils.isCredentialError(exception), false);
//     });

//     test('deve identificar erro de credenciais', () {
//       final exception = FirebaseAuthException(code: 'user-not-found');
//       expect(AuthErrorUtils.isNetworkError(exception), false);
//       expect(AuthErrorUtils.isCredentialError(exception), true);
//     });

//     test('deve identificar erro de rate limit', () {
//       final exception = FirebaseAuthException(code: 'too-many-requests');
//       expect(AuthErrorUtils.isRateLimitError(exception), true);
//     });
//   });
// }
