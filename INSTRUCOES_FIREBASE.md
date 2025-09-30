# 🎓 Sistema de Gerenciamento de Provas com Firebase

## ⚠️ IMPORTANTE: Você precisa fazer estas etapas manualmente

### 1. 📱 Configurar Projeto Firebase

1. Acesse [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Clique em **"Criar um projeto"**
3. Nome do projeto: `sistema-provas` (ou qualquer nome)
4. Desabilite Google Analytics (opcional)
5. Clique em **"Criar projeto"**

### 2. 🗄️ Ativar Firestore Database

1. No painel lateral, clique em **"Firestore Database"**
2. Clique em **"Criar banco de dados"**
3. Escolha **"Modo de teste"** (para desenvolvimento)
4. Escolha a localização mais próxima
5. Clique em **"Ativar"**

### 3. 🔐 Configurar Autenticação

1. No painel lateral, clique em **"Authentication"**
2. Clique em **"Começar"**
3. Vá para a aba **"Sign-in method"**
4. Habilite **"Email/Password"**
5. Habilite **"Google"** e configure com seu projeto

### 4. 🤖 Configurar Android

1. No console Firebase, clique no ícone **Android** (🟢)
2. **Nome do pacote Android**: `com.example.prova`  
3. **Apelido do app**: `prova-android`
4. Clique em **"Registrar app"**
5. **BAIXE** o arquivo `google-services.json`
6. **COLOQUE** o arquivo em: `android/app/google-services.json`    

### 5. 🍎 Configurar iOS (Opcional)

1. No console Firebase, clique no ícone **iOS** (🍎)
2. **ID do pacote iOS**: `com.example.prova`
3. **Apelido do app**: `prova-ios`
4. Clique em **"Registrar app"**
5. **BAIXE** o arquivo `GoogleService-Info.plist`
6. **COLOQUE** o arquivo em: `ios/Runner/GoogleService-Info.plist`

### 5. 🚀 Testar o App

Após configurar os arquivos:

```bash
flutter clean
flutter pub get
flutter run
```

## 📋 O que foi implementado:

✅ **Dependências Firebase** adicionadas ao `pubspec.yaml`
✅ **Configuração Gradle** para Android
✅ **Autenticação** com Email/Senha e Google
✅ **Modelos de dados** baseados no DER
✅ **Serviço Firebase** completo para sistema de provas
✅ **Telas do sistema** (Disciplinas, Questões, Exames)
✅ **Interface responsiva** com navegação por abas

## 🎯 Funcionalidades Disponíveis:

- ✅ **Autenticação** (email/senha e Google)
- ✅ **CRUD de Disciplinas** (criar, ler, atualizar, deletar)
- ✅ **CRUD de Questões** (com múltiplas opções de resposta)
- ✅ **CRUD de Exames** (selecionar questões e criar provas)
- ✅ **Streams em tempo real** (dados atualizam automaticamente)
- ✅ **Interface moderna** com navegação por abas
- ✅ **Validação completa** de formulários

## 🔧 Estrutura de Dados (Baseada no DER):

### Coleção: `usuarios`
```json
{
  "nome": "João Silva",
  "email": "joao@email.com",
  "tipo": "professor",
  "dataCriacao": "timestamp"
}
```

### Coleção: `disciplinas`
```json
{
  "nome": "Matemática",
  "semester": 1
}
```

### Coleção: `questoes`
```json
{
  "questionText": "Qual é a capital do Brasil?",
  "knowledgeAreaId": "disciplina_id",
  "imageUrl": "url_opcional",
  "opcoes": [
    {
      "letter": "A",
      "description": "São Paulo",
      "isCorrect": false,
      "order": 1
    },
    {
      "letter": "B", 
      "description": "Brasília",
      "isCorrect": true,
      "order": 2
    }
  ]
}
```

### Coleção: `exames`
```json
{
  "title": "Prova de Matemática",
  "instructions": "Responda todas as questões",
  "teacherId": "professor_id",
  "questoes": [
    {
      "questionId": "questao_id",
      "questionNumber": 1,
      "weight": 1.0,
      "linesForAnswer": null
    }
  ]
}
```

## 🎨 Como Usar:

1. **Faça login** com email/senha ou Google
2. **Crie disciplinas** (ex: Matemática, Português)
3. **Adicione questões** com múltiplas opções de resposta
4. **Crie exames** selecionando questões existentes
5. **Dados ficam salvos** na nuvem do Firebase
6. **Navegue** entre as abas para gerenciar cada seção

## 🆘 Problemas Comuns:

- **Erro de configuração**: Verifique se os arquivos `google-services.json` e `GoogleService-Info.plist` estão nos locais corretos
- **Erro de build**: Execute `flutter clean` e `flutter pub get`
- **Erro de permissão**: Verifique as regras do Firestore no console Firebase

## 📚 Próximos Passos:

- ✅ Implementar autenticação com Firebase Auth
- ✅ Adicionar validação de dados
- 🔄 Implementar upload de imagens para questões
- 🔄 Adicionar sistema de respostas dos alunos
- 🔄 Implementar correção automática de provas
- 🔄 Adicionar relatórios e estatísticas
- 🔄 Configurar regras de segurança do Firestore
- 🔄 Implementar notificações push
