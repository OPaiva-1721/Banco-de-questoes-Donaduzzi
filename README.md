# 📱 Sistema de Provas - Flutter

Um sistema de gerenciamento de provas desenvolvido em Flutter com Firebase, focado na autenticação de usuários e estrutura base para expansão.

## 🚀 **Status do Projeto**

✅ **FUNCIONANDO:** App compilando e executando perfeitamente  
✅ **AUTENTICAÇÃO:** Login, registro e Google Sign-In implementados  
✅ **ESTRUTURA:** Código organizado e limpo  
✅ **FIREBASE:** Configurado e funcionando  

## 📋 **Funcionalidades Atuais**

### 🔐 **Autenticação**
- ✅ Login com email/senha
- ✅ Registro de novos usuários
- ✅ Login com Google
- ✅ Validação de formulários
- ✅ Mensagens de feedback

### 🎨 **Interface**
- ✅ Design responsivo e moderno
- ✅ Tema personalizado (cores da marca)
- ✅ Navegação entre telas
- ✅ Sistema de mensagens/toast

## 🏗️ **Estrutura do Projeto**

```
lib/
├── main.dart                    # Ponto de entrada
├── firebase_options.dart        # Configurações do Firebase
├── core/                        # Configurações centrais
│   ├── app_colors.dart         # Cores do app
│   └── app_constants.dart      # Constantes
├── services/                    # Serviços
│   └── firebase_service.dart   # Serviço de autenticação
├── utils/                       # Utilitários
│   └── message_utils.dart      # Sistema de mensagens
├── screens/                     # Telas organizadas
│   ├── auth/                   # Autenticação
│   │   └── tela_login.dart
│   ├── home/                   # Página principal
│   │   └── pagina_principal.dart
│   ├── coordinator/            # Funcionalidades de coordenador
│   └── professor/              # Funcionalidades de professor
└── widgets/                     # Componentes reutilizáveis
```

## 🛠️ **Tecnologias Utilizadas**

- **Flutter:** Framework principal
- **Firebase:** Autenticação e banco de dados
  - Firebase Auth
  - Realtime Database
  - Google Sign-In
- **Dart:** Linguagem de programação

## 📦 **Dependências Principais**

```yaml
dependencies:
  flutter: sdk
  firebase_core: ^3.15.2
  firebase_database: ^11.0.2
  firebase_auth: ^5.3.1
  google_sign_in: ^6.2.1
```

## 🚀 **Como Executar**

### **Pré-requisitos**
- Flutter SDK (versão 3.9.2+)
- Android Studio / VS Code
- Conta Firebase configurada

### **Passos**
1. **Clone o repositório:**
   ```bash
   git clone [URL_DO_REPOSITORIO]
   cd prova
   ```

2. **Instale as dependências:**
   ```bash
   flutter pub get
   ```

3. **Configure o Firebase:**
   - Adicione o arquivo `google-services.json` em `android/app/`
   - Configure as opções do Firebase em `lib/firebase_options.dart`

4. **Execute o projeto:**
   ```bash
   flutter run
   ```

## 📱 **Plataformas Suportadas**

- ✅ **Android** (testado e funcionando)
- ✅ **iOS** (configurado)
- ✅ **Web** (configurado)
- ✅ **Windows** (configurado)
- ✅ **macOS** (configurado)
- ✅ **Linux** (configurado)

## 🔧 **Configuração do Firebase**

O projeto está configurado para usar Firebase. Certifique-se de:

1. **Criar projeto no Firebase Console**
2. **Adicionar apps Android/iOS**
3. **Baixar arquivos de configuração:**
   - `google-services.json` para Android
   - `GoogleService-Info.plist` para iOS
4. **Habilitar Authentication e Realtime Database**

## 📋 **Próximos Passos para o Grupo**

### **Funcionalidades a Implementar:**
1. **CRUD de Disciplinas**
   - Criar, editar, deletar disciplinas
   - Listar disciplinas

2. **CRUD de Questões**
   - Criar questões com múltiplas opções
   - Gerenciar banco de questões
   - Categorizar por disciplina

3. **Sistema de Provas**
   - Criar provas selecionando questões
   - Gerar provas em PDF
   - Histórico de provas

4. **Melhorias de UX**
   - Loading states
   - Validações mais robustas
   - Animações

### **Estrutura Pronta para Expansão:**
- ✅ Telas base criadas em `screens/coordinator/` e `screens/professor/`
- ✅ Sistema de mensagens centralizado
- ✅ Cores e constantes organizadas
- ✅ Estrutura de serviços preparada
- ✅ Sistema de permissões simplificado (professor e coordenador)

## 🐛 **Resolução de Problemas**

### **Erro de compilação:**
```bash
flutter clean
flutter pub get
flutter run
```

### **Problemas de Firebase:**
- Verifique se os arquivos de configuração estão no lugar correto
- Confirme se o projeto Firebase está ativo
- Verifique as regras do Firestore

## 👥 **Contribuição**

1. Faça fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 📄 **Licença**

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 📞 **Contato**

Para dúvidas ou sugestões, entre em contato com a equipe de desenvolvimento.

---

**🎯 Projeto pronto para desenvolvimento em equipe!**