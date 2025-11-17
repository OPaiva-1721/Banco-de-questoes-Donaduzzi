# Permissões: Quais Precisam de Aceitação do Usuário?

## Resumo Rápido

### ❌ **NÃO precisam de aceitação** (Permissões de Instalação - Normal)
Estas permissões são concedidas automaticamente na instalação do app:

1. **INTERNET** - Comunicação com Firebase
2. **ACCESS_NETWORK_STATE** - Verificar conectividade
3. **WAKE_LOCK** - Manter tela ativa

### ✅ **SIM, precisam de aceitação** (Permissões de Execução - Dangerous)
Estas permissões precisam ser solicitadas e aceitas pelo usuário em tempo de execução:

1. **POST_NOTIFICATIONS** (Android 13+) - Notificações push
2. **READ_MEDIA_IMAGES** (Android 13+) - Acesso a imagens da galeria
3. **READ_EXTERNAL_STORAGE** (Android < 13) - Acesso a imagens
4. **CAMERA** - Acesso à câmera
5. **WRITE_EXTERNAL_STORAGE** (Android < 10) - Salvar PDFs

---

## Detalhamento por Permissão

### 🔵 Permissões de Instalação (Normal) - **NÃO precisam de aceitação**

#### 1. INTERNET
- **Quando é concedida:** Automaticamente na instalação
- **Usuário vê diálogo?** ❌ Não
- **Por quê?** É essencial para o funcionamento básico do app

#### 2. ACCESS_NETWORK_STATE
- **Quando é concedida:** Automaticamente na instalação
- **Usuário vê diálogo?** ❌ Não
- **Por quê?** Apenas lê status da conexão, não acessa dados sensíveis

#### 3. WAKE_LOCK
- **Quando é concedida:** Automaticamente na instalação
- **Usuário vê diálogo?** ❌ Não
- **Por quê?** Não acessa dados pessoais, apenas controla tela

---

### 🔴 Permissões de Execução (Dangerous) - **SIM, precisam de aceitação**

#### 1. POST_NOTIFICATIONS (Android 13+)
- **Quando é solicitada:** Na primeira vez que o app tenta exibir notificação
- **Usuário vê diálogo?** ✅ Sim
- **Mensagem exibida:** "Permitir que o app exiba notificações sobre novas provas e atualizações?"
- **O que acontece se negar:** App funciona normalmente, mas não exibe notificações push
- **Alternativa:** Notificações in-app apenas

#### 2. READ_MEDIA_IMAGES (Android 13+)
- **Quando é solicitada:** Quando usuário tenta adicionar imagem a uma questão
- **Usuário vê diálogo?** ✅ Sim
- **Mensagem exibida:** "Precisamos acessar suas imagens para adicionar fotos às questões. Permitir?"
- **O que acontece se negar:** Usuário pode inserir URL de imagem manualmente ou criar questão sem imagem
- **Alternativa:** Inserir URL manualmente ou usar apenas texto

#### 3. READ_EXTERNAL_STORAGE (Android < 13)
- **Quando é solicitada:** Quando usuário tenta adicionar imagem a uma questão (Android < 13)
- **Usuário vê diálogo?** ✅ Sim
- **Mensagem exibida:** "Precisamos acessar suas imagens para adicionar fotos às questões. Permitir?"
- **O que acontece se negar:** Usuário pode inserir URL de imagem manualmente ou criar questão sem imagem
- **Alternativa:** Inserir URL manualmente ou usar apenas texto

#### 4. CAMERA
- **Quando é solicitada:** Quando usuário clica em "Tirar foto" ao adicionar imagem
- **Usuário vê diálogo?** ✅ Sim
- **Mensagem exibida:** "Precisamos usar a câmera para tirar fotos para as questões. Permitir?"
- **O que acontece se negar:** Usuário pode selecionar imagem da galeria ou usar apenas texto
- **Alternativa:** Selecionar da galeria ou inserir URL

#### 5. WRITE_EXTERNAL_STORAGE (Android < 10)
- **Quando é solicitada:** Quando usuário tenta gerar PDF (Android < 10)
- **Usuário vê diálogo?** ✅ Sim
- **Mensagem exibida:** "Precisamos salvar o PDF da prova no seu dispositivo. Permitir acesso ao armazenamento?"
- **O que acontece se negar:** PDF pode ser compartilhado diretamente via Intent sem salvar
- **Alternativa:** Compartilhar via email/drive sem salvar no dispositivo

---

## Como Funciona o Processo de Solicitação

### Fluxo Típico para Permissões Dangerous:

1. **Usuário executa ação** que requer permissão (ex: clica em "Adicionar imagem")
2. **App verifica** se já tem a permissão
3. **Se não tiver:**
   - App exibe diálogo explicando por que precisa da permissão
   - Sistema Android exibe diálogo nativo pedindo permissão
   - Usuário escolhe: **Permitir** ou **Negar**
4. **Se permitir:** Funcionalidade funciona normalmente
5. **Se negar:** App oferece alternativa (ex: inserir URL manualmente)

### Comportamento "Não perguntar novamente":

- Se usuário negar 2 vezes, Android oferece opção "Não perguntar novamente"
- Se marcado, app não pode mais solicitar essa permissão
- Usuário precisa ir em Configurações do Android para reativar

---

## Boas Práticas Implementadas

✅ **Pedido em contexto:** Permissões são solicitadas apenas quando usuário precisa da funcionalidade

✅ **Alternativas sempre disponíveis:** Se usuário negar, app oferece forma alternativa de fazer a ação

✅ **Mensagens claras:** Explicamos exatamente por que precisamos da permissão

✅ **Não bloqueia funcionalidade principal:** App funciona mesmo se todas as permissões opcionais forem negadas

---

## Resumo Visual

| Permissão | Tipo | Precisa Aceitação? | Quando é Solicitada |
|-----------|------|-------------------|---------------------|
| INTERNET | Normal | ❌ Não | Instalação automática |
| ACCESS_NETWORK_STATE | Normal | ❌ Não | Instalação automática |
| WAKE_LOCK | Normal | ❌ Não | Instalação automática |
| POST_NOTIFICATIONS | Dangerous | ✅ Sim | Primeira notificação (Android 13+) |
| READ_MEDIA_IMAGES | Dangerous | ✅ Sim | Ao adicionar imagem (Android 13+) |
| READ_EXTERNAL_STORAGE | Dangerous | ✅ Sim | Ao adicionar imagem (Android < 13) |
| CAMERA | Dangerous | ✅ Sim | Ao clicar "Tirar foto" |
| WRITE_EXTERNAL_STORAGE | Dangerous | ✅ Sim | Ao gerar PDF (Android < 10) |

---

## Implementação Técnica

Para solicitar permissões dangerous em Flutter, você precisa usar o pacote `permission_handler`:

```dart
import 'package:permission_handler/permission_handler.dart';

// Exemplo: Solicitar permissão de câmera
Future<bool> solicitarPermissaoCamera() async {
  final status = await Permission.camera.request();
  return status.isGranted;
}
```

**Importante:** O pedido deve ser feito no momento certo (quando usuário precisa da funcionalidade), não no início do app.

