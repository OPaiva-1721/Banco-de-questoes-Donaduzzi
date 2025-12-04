# Guia Completo: Configuração de Deploy de Aplicativos Flutter na Google Play Store

Este material descreve, passo a passo, como preparar e publicar o aplicativo **Sistema de Provas** na Google Play Store, tanto em Linux quanto em Windows. O foco é prático: mostrar pastas, arquivos, comandos e pontos críticos de configuração (keystore, assinatura, versão, build e envio no Google Play Console).

---

## 1. Pré-requisitos Gerais

- ✅ Conta Google Play Console ativa (taxa única de cadastro atualmente US$25, paga uma vez por conta de desenvolvedor)
- ✅ Flutter instalado e configurado (canal stable)
- ✅ Android SDK e ferramentas de build instaladas (via Android Studio ou sdkmanager)
- ✅ Java Development Kit (JDK 17 ou versão recomendada pelo Flutter/Android Gradle Plugin)
- ✅ Projeto Flutter funcional (testado em modo debug antes de pensar em deploy)
- ✅ Acesso ao código-fonte do projeto (VS Code, Android Studio ou outro editor)

**Verifique seu ambiente com o comando:**
```bash
flutter doctor
```

Resolva todos os problemas reportados antes de continuar.

### ⚠️ Problema com Licenças do Android SDK

Se o `flutter doctor` mostrar o seguinte aviso:

```
[!] Android toolchain - develop for Android devices
    X Android license status unknown.
      Run `flutter doctor --android-licenses` to accept the SDK licenses.
```

**Isso PODE afetar o deploy porque:**
- O Gradle pode falhar ao baixar dependências durante o build
- Algumas ferramentas do Android SDK podem não funcionar corretamente
- O build pode falhar silenciosamente ou com erros inesperados

**Como resolver:**

### Método 1: Via Flutter (Recomendado)

1. Execute o comando para aceitar as licenças:
   ```bash
   flutter doctor --android-licenses
   ```

2. Para cada licença exibida, digite `y` e pressione Enter para aceitar

### Método 2: Via sdkmanager Diretamente (Se o Método 1 não funcionar)

Se você receber o erro "Android sdkmanager not found", siga estes passos:

#### Passo 1: Encontrar o caminho do Android SDK

No PowerShell, execute:
```powershell
$env:LOCALAPPDATA\Android\Sdk
```

Ou verifique no Android Studio:
- Abra o Android Studio
- Vá em **File → Settings → Appearance & Behavior → System Settings → Android SDK**
- O caminho do SDK está em **Android SDK Location**

#### Passo 2: Verificar se cmdline-tools está instalado

Verifique se existe a pasta:
```
C:\Users\SEU_USUARIO\AppData\Local\Android\Sdk\cmdline-tools
```

**Se não existir**, instale via Android Studio:
1. Abra o Android Studio
2. Vá em **Tools → SDK Manager**
3. Na aba **SDK Tools**, marque **Android SDK Command-line Tools (latest)**
4. Clique em **Apply** e aguarde a instalação

#### Passo 3: Executar o comando de licenças

**No PowerShell:**
```powershell
# Substitua SEU_USUARIO pelo seu nome de usuário
& "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
```

**No CMD (Prompt de Comando):**
```cmd
%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat --licenses
```

**Se o caminho `latest` não existir**, tente com a versão específica:
```powershell
# Liste as versões disponíveis
Get-ChildItem "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools"

# Use a versão encontrada (exemplo: 12.0)
& "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\12.0\bin\sdkmanager.bat" --licenses
```

### Método 3: Via Android Studio (Mais Fácil)

1. Abra o Android Studio
2. Vá em **Tools → SDK Manager**
3. Na aba **SDK Tools**, marque **Android SDK Command-line Tools (latest)**
4. Clique em **Apply** e aguarde a instalação
5. Depois, tente novamente o Método 1 ou 2

### Verificar se funcionou

Após aceitar as licenças, verifique:
```bash
flutter doctor
```

O aviso sobre licenças deve desaparecer.

**Importante:** Resolva isso ANTES de tentar gerar o build de release. Um build pode parecer funcionar, mas pode falhar em etapas críticas ou gerar um AAB inválido.

---

## 2. Estrutura de Pastas Relevante no Projeto Flutter

No projeto Flutter, as pastas principais para o deploy Android são:

```
prova-versao-anterior/
├── android/
│   ├── app/
│   │   ├── src/main/AndroidManifest.xml
│   │   ├── build.gradle.kts          # Configurações do módulo app
│   │   └── my-key.jks                # Keystore (será criado)
│   ├── build.gradle.kts              # Configurações globais Gradle
│   └── key.properties                # Configuração da keystore (será criado)
├── pubspec.yaml                      # Controle de versão do app
└── .gitignore                        # Garantir que keystore não seja commitado
```

---

## 3. Ajustando o Nome do Aplicativo (Label)

1. Abra o arquivo `android/app/src/main/AndroidManifest.xml`
2. Localize o atributo `android:label="prova"`
3. Altere para o nome que será exibido ao usuário na tela inicial e na Play Store

**Exemplo:**
```xml
<application
    android:label="Sistema de Provas"
    android:name="${applicationName}"
    android:icon="@mipmap/launcher_icon">
```

> **Nota:** Este nome pode ser diferente do package name (`com.exemplo.prova`).

---

## 4. Gerando a Keystore (Assinatura do App)

A keystore é o arquivo que contém a chave usada para assinar o seu aplicativo. Ela é **obrigatória** para publicar na Play Store e deve ser guardada com **extremo cuidado**.

### ⚠️ Sobre a Senha da Keystore

**IMPORTANTE:** A senha da keystore **NÃO existe previamente** - **VOCÊ CRIA A SENHA** durante o processo de geração da keystore!

- Quando você executar o comando `keytool`, ele vai pedir para você **digitar uma senha**
- **Você escolhe a senha** que quiser (use uma senha forte!)
- **Anote essa senha em local seguro** - você precisará dela sempre que gerar um build de release
- **Se perder a senha, não conseguirá mais atualizar o app na Play Store**

Não existe senha padrão ou senha pré-definida. A senha é criada por você no momento da geração da keystore.

### 4.1. No Linux / macOS

Execute no terminal (ajuste caminhos, alias e senhas conforme necessário):

```bash
keytool -genkey -v -keystore ~/my-key.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
```

Durante o processo, será solicitado:
- **Senha da keystore** - **VOCÊ ESCOLHE ESTA SENHA** (digite uma senha forte e anote com segurança!)
- **Confirmar senha da keystore** - Digite a mesma senha novamente
- **Senha da chave** - Geralmente é a mesma da keystore (pode pressionar Enter para usar a mesma)
- Nome completo
- Nome da unidade organizacional
- Nome da organização
- Nome da cidade
- Nome do estado
- Código do país (ex: BR para Brasil)

**⚠️ IMPORTANTE - Anote com segurança (em local seguro!):**
- Caminho do arquivo da keystore
- **Senha da keystore** (você escolheu esta senha - não existe senha padrão!)
- Alias utilizado (ex: `my-key-alias`)

> **⚠️ ATENÇÃO:** Se você perder a senha ou o arquivo da keystore, **NÃO conseguirá atualizar o app na Play Store**. Faça backup seguro!

### 4.2. No Windows

**Pré-requisitos específicos no Windows:**
- Instalar o JDK (versão compatível) — o comando `keytool` vem junto com o JDK
- Garantir que o diretório `bin` do JDK esteja no PATH do sistema para que o comando `keytool` funcione
- Ter o Flutter e o Android SDK configurados no PATH

**Com o ambiente pronto, execute no PowerShell:**

**⚠️ IMPORTANTE:** No PowerShell do Windows, **NÃO use `~`** - ele não funciona. Use o caminho completo ou variável de ambiente.

**Opção 1: Gerar diretamente na pasta do projeto (Recomendado):**

```powershell
# Gera diretamente na pasta android/app/ (onde será usado)
keytool -genkey -v -keystore android\app\my-key.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
```

**Opção 2: Gerar na pasta do usuário e depois mover:**

```powershell
# No PowerShell, use $env:USERPROFILE
keytool -genkey -v -keystore "$env:USERPROFILE\my-key.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
```

**No CMD (Prompt de Comando):**

```cmd
keytool -genkey -v -keystore %USERPROFILE%\my-key.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
```

**Depois, converta para PKCS12 (recomendado para compatibilidade):**

**Se gerou na pasta do projeto:**
```powershell
keytool -importkeystore -srckeystore android\app\my-key.jks -destkeystore android\app\my-key.jks -deststoretype pkcs12
```

**Se gerou na pasta do usuário:**
```powershell
keytool -importkeystore -srckeystore "$env:USERPROFILE\my-key.jks" -destkeystore "$env:USERPROFILE\my-key.jks" -deststoretype pkcs12
```

**Durante o processo, será solicitado:**
- **Senha da keystore** - **VOCÊ ESCOLHE ESTA SENHA** (digite uma senha forte e anote com segurança!)
- **Confirmar senha da keystore** - Digite a mesma senha novamente
- **Senha da chave** - Geralmente é a mesma da keystore (pode pressionar Enter para usar a mesma)
- Nome completo
- Nome da unidade organizacional
- Nome da organização
- Nome da cidade
- Nome do estado
- Código do país (ex: BR para Brasil)

**⚠️ IMPORTANTE - Anote com segurança (em local seguro!):**
- Caminho completo da keystore (ex: `C:\Users\SEU_USUARIO\my-key.jks`)
- **Senha da keystore** (você escolheu esta senha - não existe senha padrão!)
- Alias utilizado (ex: `my-key-alias`)

> **⚠️ ATENÇÃO:** Se você perder a senha ou o arquivo da keystore, **NÃO conseguirá atualizar o app na Play Store**. Faça backup seguro!

**Necessário JDK:** https://jdk.java.net/25/

---

## 5. Movendo a Keystore para o Projeto

Para organização, mova a keystore para dentro do projeto Flutter:

```
android/app/my-key.jks
```

Você pode usar outro caminho/pasta, mas precisará referenciar corretamente no arquivo de configuração.

**Exemplo no Windows:**
```bash
move C:\Users\SEU_USUARIO\my-key.jks android\app\my-key.jks
```

**Exemplo no Linux/macOS:**
```bash
mv ~/my-key.jks android/app/my-key.jks
```

---

## 6. Criando o Arquivo key.properties

No diretório `android/`, crie um arquivo chamado `key.properties`

**Exemplo de conteúdo (ajuste com seus dados reais):**

```properties
storeFile=app/my-key.jks
storePassword=SUA_SENHA_AQUI
keyAlias=my-key-alias
keyPassword=SUA_SENHA_AQUI
```

**Observações importantes:**
- O caminho em `storeFile` é relativo à pasta `android/`
- Se você deixar a keystore em outro lugar, ajuste o caminho corretamente
- **NUNCA** commite `key.properties` e o arquivo `.jks` em repositórios públicos

---

## 7. Configurando o build.gradle.kts (Módulo App)

O projeto usa **Kotlin DSL** (`build.gradle.kts`), então a configuração é ligeiramente diferente do Groovy.

Abra o arquivo `android/app/build.gradle.kts`

### 7.1. Adicione no topo do arquivo (antes do bloco `android`):

```kotlin
// Carrega propriedades da keystore
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
```

### 7.2. Dentro do bloco `android { ... }`, adicione a configuração de assinatura:

```kotlin
android {
    namespace = "com.exemplo.prova"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.exemplo.prova"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Configuração de assinatura
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false // ou true se você configurar ProGuard/R8
        }
    }
}
```

**Importante:** Adicione o import no topo do arquivo:

```kotlin
import java.util.Properties
```

---

## 8. Ajustando Package Name e Versão

### 8.1. Defina o applicationId (package name) em `android/app/build.gradle.kts`

O package name atual é `com.exemplo.prova`. Se quiser alterar:

```kotlin
defaultConfig {
    applicationId = "com.suaempresa.sistemaprovas"  // Altere aqui
    // ...
}
```

> **⚠️ ATENÇÃO:** Se mudar o package name, passa a ser outro app para a Play Store. O package name deve ser único e não pode ser alterado depois da primeira publicação.

### 8.2. No arquivo `pubspec.yaml`

Ajuste a linha de versão no formato:

```yaml
version: 1.0.0+1
```

**Formato:** `version: VERSION_NAME+VERSION_CODE`

- **VERSION_NAME** (1.0.0): Versão visível ao usuário
- **VERSION_CODE** (+1): Número interno que deve sempre aumentar

**Antes de cada novo envio à Play Store, incremente:**
- O número à direita (+1, +2, +3...) quando for uma nova build (versionCode)
- A parte visível (1.0.0 → 1.0.1 → 1.1.0) quando for relevante ao usuário

**Exemplos:**
- Primeira versão: `version: 1.0.0+1`
- Correção de bug: `version: 1.0.1+2`
- Nova feature: `version: 1.1.0+3`
- Atualização maior: `version: 2.0.0+4`

---

## 9. Garantindo que Keystore Não Seja Commitada

Adicione ao `.gitignore` (se ainda não estiver):

```gitignore
# Keystore files
*.jks
*.keystore
android/key.properties
android/app/my-key.jks
```

**Verifique também o `android/.gitignore`:**

```gitignore
*.jks
*.keystore
key.properties
```

---

## 10. Gerando o App Bundle (AAB)

O App Bundle (`.aab`) é o formato recomendado pela Google Play Store. Ele permite que a Play Store gere APKs otimizados para cada dispositivo.

No terminal, dentro da pasta do projeto Flutter, execute:

```bash
flutter clean
flutter pub get
flutter build appbundle
```

Ao final, o arquivo será gerado em:

```
build/app/outputs/bundle/release/app-release.aab
```

Este é o arquivo que você fará upload no Google Play Console.

---

## 11. Gerando a APK (Opcional)

Se precisar de uma APK para testes ou distribuição fora da Play Store:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

A APK será gerada em:

```
build/app/outputs/flutter-apk/app-release.apk
```

### APKs Separados por Arquitetura

Se quiser APKs otimizados por ABI (útil para distribuição fora da Play Store ou via links diretos):

```bash
flutter build apk --release --split-per-abi
```

Ele vai gerar arquivos como:

```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

Cada um é menor e específico para uma arquitetura.

---

## 12. Testando o Build de Release

Antes de enviar para a Play Store, teste o app em modo release:

```bash
flutter run --release
```

Ou instale a APK gerada em um dispositivo físico:

```bash
flutter install --release
```

Isso ajuda a identificar problemas que só aparecem em builds de produção.

---

## 13. Subindo o App no Google Play Console

### 13.1. Acesse o Google Play Console

Acesse https://play.google.com/console com a conta de desenvolvedor.

### 13.2. Criar um Novo App

1. Clique em **"Criar app"**
2. Preencha:
   - **Nome do app:** Sistema de Provas (ou o nome escolhido)
   - **Idioma padrão:** Português (Brasil)
   - **Tipo:** App
   - **Distribuição:** Gratuito ou Pago
3. Confirme as declarações e políticas

### 13.3. Preencher a Ficha de Loja

Na seção **"Presença na loja"**, preencha:

- **Descrição curta:** Resumo de até 80 caracteres
- **Descrição completa:** Descrição detalhada do app
- **Ícone:** 512x512 pixels (PNG, sem transparência)
- **Screenshots:** 
  - Pelo menos 2 screenshots obrigatórios
  - Recomendado: 4-8 screenshots
  - Tamanho mínimo: 320px, máximo: 3840px
- **Categoria:** Educação
- **Classificação indicativa:** Preencha o questionário
- **Política de privacidade:** URL obrigatória (crie uma página com a política)

### 13.4. Configurar Permissões e Declarações

Na seção **"Política e programas"**, responda:

- **Declaração de permissões:** Justifique cada permissão dangerous
- **Política de privacidade:** URL obrigatória
- **Coleta de dados:** Declare quais dados são coletados
- **Segurança:** Responda sobre criptografia e segurança de dados

> **Referência:** Use a documentação em `/docs/MPC.md` e `/docs/permissions.yaml` para justificar as permissões.

### 13.5. Criar uma Release

1. No menu lateral, vá em **"Produção"** (ou **"Teste interno"** / **"Teste fechado"**)
2. Clique em **"Criar nova versão"**
3. Faça upload do arquivo `.aab` gerado:
   - Arraste o arquivo `app-release.aab` ou clique em **"Fazer upload"**
4. Adicione **Notas da versão:**
   ```
   Versão 1.0.0
   - Primeira versão do Sistema de Provas
   - Gerenciamento de questões e provas
   - Geração de PDFs
   ```
5. Clique em **"Salvar"**

### 13.6. Testes Internos (Recomendado Primeiro)

Antes de publicar em produção:

1. Vá em **"Teste interno"**
2. Crie uma release e faça upload do `.aab`
3. Adicione testadores (e-mails do Google)
4. Os testadores receberão um link para instalar

### 13.7. Enviar para Revisão

Após preencher todas as informações obrigatórias:

1. Verifique se todos os campos obrigatórios estão preenchidos
2. Clique em **"Enviar para revisão"**
3. O Google revisará o app (pode levar de algumas horas a alguns dias)
4. Você receberá notificações sobre o status da revisão

---

## 14. Boas Práticas e Pontos Críticos

### ⚠️ **CRÍTICO: Nunca perca a keystore nem a senha**

- Sem elas, você **não conseguirá atualizar** o mesmo app na Play Store
- Faça backup em local seguro (pen drive, nuvem criptografada, etc.)
- Considere usar um gerenciador de senhas para guardar as credenciais

### 🔒 **Segurança**

- **NÃO** envie a keystore nem o `key.properties` para repositórios públicos
- Adicione ambos ao `.gitignore`
- Se acidentalmente commitou, **revogue a keystore** e gere uma nova antes de publicar

### 📦 **Package Name**

- Garanta que o package name (`applicationId`) seja único
- Se mudar o package name, passa a ser outro app para a Play Store
- O package name não pode ser alterado depois da primeira publicação

### 🧪 **Testes**

- Antes de gerar o appbundle, teste o app em modo release (`flutter run --release`)
- Teste em dispositivos físicos diferentes
- Teste todas as funcionalidades principais

### 📋 **Declarações**

- Responda corretamente as declarações de permissões (especialmente localização, câmera, microfone, coleta de dados)
- Use a documentação em `/docs/MPC.md` como referência
- Seja honesto e específico nas justificativas

### 🔢 **Versionamento**

- Mantenha o `versionCode` (+X) sempre crescente
- Cada envio precisa de um número maior que o anterior
- A Play Store rejeita builds com versionCode menor ou igual ao anterior

### 📱 **Screenshots e Assets**

- Use screenshots reais do app
- Crie ícone de alta qualidade (512x512)
- Adicione gráfico de destaque (1024x500) se disponível

---

## 15. Checklist Rápido

Use este checklist antes de cada publicação:

### Configuração Inicial (Uma vez)
- [ ] `flutter doctor` sem erros críticos
- [ ] **Aceitar licenças do Android SDK** (`flutter doctor --android-licenses`)
- [ ] Gerar keystore (Linux/Windows) e anotar senhas + alias
- [ ] Mover keystore para `android/app/` (ou caminho definido)
- [ ] Criar `android/key.properties` corretamente
- [ ] Configurar `signingConfigs.release` no `build.gradle.kts`
- [ ] Adicionar keystore e `key.properties` ao `.gitignore`
- [ ] Ajustar `applicationId` (package name) e `android:label`
- [ ] Definir `version: X.Y.Z+N` no `pubspec.yaml`

### Antes de Cada Publicação
- [ ] Testar app em modo release (`flutter run --release`)
- [ ] Incrementar `versionCode` no `pubspec.yaml`
- [ ] Atualizar `versionName` se necessário
- [ ] Executar `flutter clean`
- [ ] Executar `flutter pub get`
- [ ] Executar `flutter build appbundle`
- [ ] Verificar que o arquivo `.aab` foi gerado corretamente
- [ ] Criar/atualizar app no Google Play Console
- [ ] Fazer upload do `.aab`
- [ ] Adicionar notas da versão
- [ ] Verificar todas as declarações e políticas
- [ ] Enviar para revisão

---

## 16. Comandos Úteis

### Verificar informações do build

```bash
# Ver informações do app
flutter build appbundle --verbose

# Ver tamanho do bundle
ls -lh build/app/outputs/bundle/release/app-release.aab
```

### Analisar o AAB

```bash
# Instalar bundletool (ferramenta do Google)
# https://github.com/google/bundletool

# Gerar APKs a partir do AAB para teste
bundletool build-apks --bundle=app-release.aab --output=app.apks
```

### Verificar assinatura

```bash
# Verificar se o AAB está assinado corretamente
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

---

## 17. Solução de Problemas Comuns

### Erro: "Keystore file not found"

- Verifique o caminho em `key.properties`
- O caminho é relativo à pasta `android/`
- Use barras normais `/` mesmo no Windows

### Erro: "Keystore was tampered with, or password was incorrect"

- Verifique se a senha está correta
- Verifique se o alias está correto
- Tente regenerar a keystore se necessário

### Erro: "versionCode must be incremented"

- Incremente o número após o `+` no `pubspec.yaml`
- Exemplo: `1.0.0+1` → `1.0.0+2`

### Erro: "Package name already exists"

- O package name deve ser único
- Escolha um package name diferente
- Formato recomendado: `com.suaempresa.nomeapp`

### Build falha com erro de assinatura

- Verifique se `key.properties` existe e está correto
- Verifique se a keystore existe no caminho especificado
- Execute `flutter clean` e tente novamente

### Erro: "Android license status unknown" ou "Android sdkmanager not found"

**Sintomas:**
- `flutter doctor --android-licenses` retorna "Android sdkmanager not found"
- Build pode falhar silenciosamente ou com erros inesperados

**Soluções:**

1. **Instalar Command-line Tools via Android Studio:**
   - Abra Android Studio
   - Vá em **Tools → SDK Manager**
   - Aba **SDK Tools**
   - Marque **Android SDK Command-line Tools (latest)**
   - Clique em **Apply**

2. **Executar via PowerShell (sintaxe correta):**
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
   ```

3. **Se o caminho `latest` não existir:**
   ```powershell
   # Liste as versões disponíveis
   Get-ChildItem "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools"
   
   # Use a versão encontrada
   & "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\VERSÃO_ENCONTRADA\bin\sdkmanager.bat" --licenses
   ```

4. **Verificar novamente:**
   ```bash
   flutter doctor
   ```

**Nota:** Este problema pode causar falhas no build mesmo que pareça funcionar. É essencial resolver antes do deploy.

---

## 18. Recursos Adicionais

- [Documentação oficial do Flutter - Deploy Android](https://docs.flutter.dev/deployment/android)
- [Google Play Console](https://play.google.com/console)
- [Guia de assinatura de apps Android](https://developer.android.com/studio/publish/app-signing)
- [Bundletool (ferramenta do Google)](https://github.com/google/bundletool)

---

## 19. Próximos Passos Após Publicação

1. **Monitorar métricas:** Acompanhe downloads, avaliações e crash reports no Play Console
2. **Responder avaliações:** Interaja com usuários que deixam avaliações
3. **Atualizações:** Prepare atualizações incrementais conforme necessário
4. **Marketing:** Divulgue o app nas redes sociais e canais apropriados

---

**Boa sorte com a publicação! 🚀**

