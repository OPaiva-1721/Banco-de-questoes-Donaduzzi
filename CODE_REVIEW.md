# Code Review — Banco de Questões Donaduzzi

**Data:** 2026-06-08
**Revisor:** Claude Sonnet 4.6

---

## Legenda de Severidade

| Ícone | Severidade |
|---|---|
| 🔴 | Crítico — corrigir antes de qualquer release |
| 🟡 | Médio — corrigir no próximo sprint |
| 🟢 | Sugestão — melhoria recomendada |

---

## 1. Segurança

### 🔴 CRÍTICO — `.env` bundlado no APK/IPA

**Arquivo:** `pubspec.yaml:103`

```yaml
assets:
  - assets/images/
  - .env          # qualquer um com apktool extrai a chave Gemini
```

O `.env` está declarado como Flutter asset — compila dentro do APK/IPA. Extraível com `apktool` (Android) ou `jtool` (iOS).

**Correção:** Mover chamadas Gemini para backend (Firebase Cloud Functions). No app, requisição autenticada ao backend, nunca à API diretamente.

---

### 🔴 CRÍTICO — `.env` não ignorado pelo git

**Arquivo:** `.gitignore:89-92`

```
.env.local
.env.development.local   # apenas variantes são ignoradas
.env.test.local
.env.production.local
# O .env raiz NÃO está na lista
```

**Correção imediata:**
```
# .gitignore — adicionar:
.env
```

Verificar histórico: `git log --all -- .env`. Se commitado, limpar com `git filter-repo` ou `BFG Repo Cleaner` e rotacionar a chave Gemini.

---

### 🔴 CRÍTICO — Três projetos Firebase diferentes no mesmo app

| Arquivo | Project ID | API Key |
|---|---|---|
| `lib/firebase_options.dart` | `banco-de-questoes-cdc6b` | `AIzaSyA60rpc…` |
| `android/app/google-services.json` | `provasdonaduzzi` | `AIzaSyCPno-…` |
| `firebase.json` | `prova-5b69a` | — |

O Flutter usa `firebase_options.dart` em runtime. O `google-services.json` errado causa falhas silenciosas no Android ou grava dados no projeto errado.

**Correção:** Executar `flutterfire configure` apontando para o projeto correto e substituir todos os arquivos de configuração.

---

### 🔴 CRÍTICO — Regras do Realtime Database não verificadas no repositório

Arquivo `database.rules.json` não encontrado. Projetos criados em modo "test" têm acesso público total por 30 dias.

**Verificar agora:** Firebase Console → Realtime Database → Regras.

**Regras mínimas corretas:**
```json
{
  "rules": {
    ".read": false,
    ".write": false,
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "questions": {
      ".read": "auth !== null",
      ".write": "auth !== null"
    }
  }
}
```

---

### 🟡 MÉDIO — `google-services.json` commitado com API key

**Arquivo:** `android/app/google-services.json`

Contém `AIzaSyCPno-yqbirOM0F7UxHoVFUQkNfK8fL8XU`. O `.gitignore` ignora `GoogleService-Info.plist` (iOS) mas não o equivalente Android.

**Correção:**
```
# .gitignore — adicionar:
android/app/google-services.json
```

Adicionar ao CI/CD via secret injection.

---

### 🟡 MÉDIO — `sanitizeInput` é apenas `trim()` — não sanitiza conteúdo

**Arquivo:** `lib/services/security_service.dart:27-29`

```dart
String sanitizeInput(String text) {
  return text.trim(); // apenas remove espaços
}
```

Sem remoção de caracteres de controle ou escaping. Input vai para LLM (Gemini) sem proteção contra prompt injection.

**Correção:**
```dart
String sanitizeInput(String text, {bool forDisplay = false}) {
  var sanitized = text.trim();
  sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  if (forDisplay) {
    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
  return sanitized;
}
```

---

### 🟡 MÉDIO — `print()` em handler de erro de segurança

**Arquivo:** `lib/services/security_service.dart:67`

```dart
print('Error writing to security log: $e');
```

Em produção vai para `adb logcat`, visível a qualquer dev com USB debug.

**Correção:**
```dart
if (kDebugMode) debugPrint('Error writing to security log: $e');
```

---

## 2. Qualidade de Código

### 🔴 CRÍTICO — Validação de senha inconsistente

| Local | Mínimo | Arquivo |
|---|---|---|
| `AppConfig.minPasswordLength` | **8** | `app_config.dart:7` |
| `PasswordValidator` | **8** | `password_validator.dart` |
| Firebase Auth (padrão) | **6** | — |

`PasswordValidator` é feedback visual mas não bloqueia o cadastro — `AuthService` passa a senha diretamente ao Firebase que aceita 6+.

**Correção em `auth_service.dart`:**
```dart
Future<UserCredential> registerUser({...}) async {
  if (password.length < AppConfig.minPasswordLength) {
    throw Exception('Senha deve ter pelo menos ${AppConfig.minPasswordLength} caracteres.');
  }
  // ...
}
```

---

### 🟡 MÉDIO — `isProduction = false` hardcoded como `const`

**Arquivo:** `lib/core/app_config.dart:84-89`

```dart
static const bool enableDebugLogs = true;  // nunca muda
static const bool isProduction = false;    // nunca muda
```

Build de produção sempre terá debug ativo.

**Correção:**
```dart
import 'package:flutter/foundation.dart';
static bool get isProduction => !kDebugMode;
static bool get enableDebugLogs => kDebugMode;
```

---

### 🟡 MÉDIO — `AppConfig` define nomes de coleção que os Services ignoram

**Arquivo:** `lib/core/app_config.dart:26-29`

```dart
// AppConfig define (português, não usado):
static const String usersCollection = 'usuarios';
static const String securityLogsCollection = 'logs_seguranca';

// Services usam diretamente (inglês, diferente):
_database.ref('users')          // user_service.dart
_database.ref('security_logs')  // security_service.dart
```

`AppConfig` não é fonte de verdade. Dados ficam em nós diferentes no banco.

**Correção:** Atualizar `AppConfig` com nomes reais e usar as constantes:
```dart
// app_config.dart
static const String usersCollection = 'users';
static const String securityLogsCollection = 'security_logs';

// security_service.dart
_logRef = _database.ref(AppConfig.securityLogsCollection);
```

---

### 🟡 MÉDIO — 60+ `print()` em código de produção

Locais críticos:

- `corrigir_prova_screen.dart` — 40+ prints com dados internos de detecção de imagem
- `exam_model.dart` — `print("===== ERRO EM EXAM_MODEL...")` no model layer
- `content_service.dart:87` — `print('Error fetching content: $e')`
- `security_service.dart:67` — print de erro de segurança

**Correção padronizada:**
```dart
// Substituir todos os print() por:
if (kDebugMode) debugPrint('mensagem');
```

---

### 🟡 MÉDIO — `deleteContent()` sem verificação de uso — orphan data

**Arquivo:** `lib/services/content_service.dart:132`

```dart
Future<bool> deleteContent(String contentId) async {
  // TODO: Add check to see if content is used by questions
  await _contentRef.child(contentId).remove(); // deleta sem checar
```

`QuestionService` tem essa verificação. Questões vinculadas ficam com `contentId` apontando para registro inexistente.

**Correção:**
```dart
Future<bool> deleteContent(String contentId) async {
  final questionsSnap = await _database
      .ref('questions')
      .orderByChild('contentId')
      .equalTo(contentId)
      .get();
  if (questionsSnap.exists) {
    throw Exception('Conteúdo está sendo usado por questões e não pode ser deletado.');
  }
  await _contentRef.child(contentId).remove();
  // ...
}
```

---

### 🟡 MÉDIO — `corrigir_prova_screen.dart` — 1467 linhas, God Object

**Arquivo:** `lib/screens/professor/corrigir_prova/corrigir_prova_screen.dart`

Contém embutido:
- 5 algoritmos de detecção de círculos em imagem
- Parser de texto OCR com regex
- Lógica de processamento com package `image`
- Instanciação direta de 4 serviços

Viola SRP. Impossível testar sem câmera real.

**Correção:** Extrair para `ImageProcessingService`:
```dart
class ImageProcessingService {
  Future<Map<int, String>> detectMarkedAnswers(Uint8List imageBytes) async {...}
  Map<int, String> parseOcrText(String ocrText) {...}
}
// Tela chama apenas:
final respostas = await _imageProcessingService.detectMarkedAnswers(bytes);
```

---

### 🟢 SUGESTÃO — `FirebaseService` facade com delegação incompleta

**Arquivo:** `lib/services/firebase_service.dart:123, 138, 199`

```dart
// ...   ← outros métodos do CourseService não expostos
// ...   ← outros métodos do SubjectService não expostos
```

Telas que precisam de mais operações instanciam os sub-serviços diretamente, tornando a facade irrelevante.

**Decisão:** Ou completar a facade (expor todos os métodos) ou removê-la e usar DI diretamente.

---

### 🟢 SUGESTÃO — `DetectionService` — código morto

**Arquivo:** `lib/services/detection_service.dart`

Aponta para `http://localhost:8000` (servidor Python local). Nenhuma tela importa esse serviço.

**Correção:** Remover o arquivo.

---

### 🟢 SUGESTÃO — Sem gerenciamento de estado / DI

**Arquivo:** Todas as screens (`corrigir_prova_screen.dart:31-34`, etc.)

```dart
final ExamService _examService = ExamService();
final QuestionService _questionService = QuestionService();
```

Cada screen cria instâncias próprias. Instâncias duplicadas sem compartilhamento de estado.

**Correção sugerida (`get_it`):**
```dart
// setup.dart
final getIt = GetIt.instance;
void setupDI() {
  getIt.registerLazySingleton(() => AuthService());
  getIt.registerLazySingleton(() => ExamService());
}

// nas telas:
final _examService = getIt<ExamService>();
```

---

### 🟢 SUGESTÃO — `FirebaseAuth.instance` direto em tela

**Arquivo:** `lib/screens/professor/banco_questoes/adicionar_questao_screen.dart`

```dart
final userId = FirebaseAuth.instance.currentUser?.uid;
```

Bypassa o `AuthService`. Se a camada de Auth mudar, essa tela fica inconsistente.

**Correção:** Passar `AuthService` para a tela e usar `_authService.currentUser?.uid`.

---

## 3. Firebase / Banco de Dados

### 🟡 MÉDIO — Queries sem índice declarado

**Arquivo:** `lib/services/content_service.dart:65`, `question_service.dart`, `exam_service.dart`

```dart
final query = _contentRef.orderByChild('subjectId').equalTo(subjectId);
```

Sem `.indexOn` nas regras, full-scan em cada query. Firebase emite warning no console e performance degrada com volume.

**Correção nas regras do Realtime Database:**
```json
{
  "rules": {
    "contents": {
      ".indexOn": ["subjectId"]
    },
    "questions": {
      ".indexOn": ["subjectId", "contentId"]
    },
    "exams": {
      ".indexOn": ["userId"]
    }
  }
}
```

---

## 4. Problemas Práticos

### 🟢 SUGESTÃO — `.vscode/` não ignorado

**Arquivo:** `.gitignore:21-22`

```
#.vscode/     ← linha comentada
```

Configurações pessoais de IDE podem ser commitadas.

**Correção:** Descomentar a linha no `.gitignore`.

---

### 🟢 SUGESTÃO — `name: prova` no pubspec.yaml genérico

**Arquivo:** `pubspec.yaml:1`

Nome `prova` aparece em todos os imports: `import 'package:prova/...'`. Renomear para algo que identifique o projeto (`banco_questoes_donaduzzi`).

---

### ✅ OK — `pubspec.lock` está commitado

Correto para aplicações Flutter. Sem ação necessária.

---

## Resumo Geral

| Categoria | 🔴 Críticos | 🟡 Médios | 🟢 Sugestões |
|---|---|---|---|
| Segurança | 4 | 2 | 0 |
| Qualidade de Código | 1 | 4 | 4 |
| Firebase | 0 | 1 | 0 |
| Práticos | 0 | 0 | 2 |
| **Total** | **5** | **7** | **6** |

**Nota geral: 5.5 / 10**

Estrutura de services bem pensada (Facade, separação de responsabilidades). Comprometida por falhas de segurança sérias que precisam ser resolvidas antes de qualquer release.

---

## Top 3 — Prioridades Imediatas

### 1. 🔴 Remover `.env` dos assets e adicionar ao `.gitignore`
A chave Gemini está compilada no APK e é extraível trivialmente. Verificar histórico git e rotacionar a chave se necessário. Ação para hoje.

### 2. 🔴 Unificar para um único projeto Firebase
Três arquivos de configuração apontando para projetos diferentes. O app pode estar gravando dados em um projeto e lendo de outro. Executar `flutterfire configure` com o projeto correto e substituir todos os configs.

### 3. 🔴 Verificar regras de segurança do Realtime Database
Se o projeto foi criado em modo "test", qualquer pessoa com a URL do banco tem acesso total de leitura e escrita. Acessar o Firebase Console agora e configurar as regras.
