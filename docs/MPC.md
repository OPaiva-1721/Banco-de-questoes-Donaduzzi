# Matriz de Permissões e Compliance

## Sistema de Provas - Projeto Integrador

| Feature principal | Dado mínimo | Permissão | Tipo (inst./exec./esp.) | Pedido em contexto (mensagem) | Alternativa digna | Proteção/ret. | Política Play / Declaração |
|-------------------|-------------|-----------|-------------------------|-------------------------------|-------------------|---------------|----------------------------|
| Comunicação com Firebase (Auth, Database) | Conexão de rede ativa | `INTERNET` | Instalação (normal) | Não requer pedido (permissão de instalação) | Modo offline limitado: cache local de dados essenciais | Dados transmitidos via HTTPS/TLS; credenciais nunca armazenadas em texto plano | Declaração: "Comunicação com serviços Firebase para autenticação e sincronização de dados" |
| Verificação de conectividade | Status da conexão de rede | `ACCESS_NETWORK_STATE` | Instalação (normal) | Não requer pedido (permissão de instalação) | Assumir conectividade e mostrar erro se falhar | Apenas leitura do status; nenhum dado sensível coletado | Declaração: "Verificação de conectividade para otimizar experiência do usuário" |
| Geração e compartilhamento de PDFs | Acesso ao armazenamento para salvar/compartilhar PDF | `WRITE_EXTERNAL_STORAGE` (Android < 10) ou Scoped Storage (Android 10+) | Execução (dangerous - Android < 10) / Instalação (normal - Android 10+) | "Precisamos salvar o PDF da prova no seu dispositivo. Permitir acesso ao armazenamento?" (apenas Android < 10) | Compartilhamento direto via Intent sem salvar no dispositivo; visualização apenas | PDFs gerados temporariamente; usuário escolhe destino; dados acadêmicos não sensíveis | Declaração: "Salvar e compartilhar provas em formato PDF para impressão e distribuição" |
| Notificações push (Firebase Messaging) | Capacidade de exibir notificações no dispositivo | `POST_NOTIFICATIONS` (Android 13+) | Execução (dangerous - Android 13+) | "Permitir que o app exiba notificações sobre novas provas e atualizações?" | Notificações in-app apenas; usuário pode verificar manualmente | Notificações apenas sobre eventos acadêmicos; usuário pode desativar a qualquer momento | Declaração: "Notificações sobre novas provas, lembretes e atualizações do sistema" |
| Upload de imagens para questões | Acesso a imagens da galeria do dispositivo | `READ_MEDIA_IMAGES` (Android 13+) ou `READ_EXTERNAL_STORAGE` (Android < 13) | Execução (dangerous) | "Precisamos acessar suas imagens para adicionar fotos às questões. Permitir?" | Inserir URL de imagem manualmente; usar apenas texto nas questões | Imagens enviadas para Firebase Storage; usuário controla quais imagens compartilhar | Declaração: "Acesso a imagens para adicionar fotos e diagramas às questões educacionais" |
| Captura de fotos para questões | Acesso à câmera do dispositivo | `CAMERA` | Execução (dangerous) | "Precisamos usar a câmera para tirar fotos para as questões. Permitir?" | Selecionar imagem da galeria; usar apenas texto nas questões | Fotos capturadas apenas quando usuário solicita; não armazenadas localmente após upload | Declaração: "Captura de fotos para adicionar imagens às questões educacionais" |
| Manter dispositivo acordado durante provas | Prevenir que a tela desligue durante aplicação de provas | `WAKE_LOCK` | Instalação (normal) | Não requer pedido (permissão de instalação) | Usuário deve manter tela ativa manualmente; notificações de inatividade | Usado apenas durante aplicação de provas; desativado automaticamente ao finalizar | Declaração: "Manter tela ativa durante aplicação de provas para garantir experiência contínua" |

## Resumo: Permissões que Precisam de Aceitação do Usuário

### ❌ **NÃO precisam de aceitação** (Concedidas automaticamente na instalação):
- `INTERNET` - Comunicação com Firebase
- `ACCESS_NETWORK_STATE` - Verificação de conectividade  
- `WAKE_LOCK` - Manter tela ativa

### ✅ **SIM, precisam de aceitação** (Solicitadas em tempo de execução):
- `POST_NOTIFICATIONS` (Android 13+) - Notificações push
- `READ_MEDIA_IMAGES` (Android 13+) - Acesso a imagens
- `READ_EXTERNAL_STORAGE` (Android < 13) - Acesso a imagens
- `CAMERA` - Acesso à câmera
- `WRITE_EXTERNAL_STORAGE` (Android < 10) - Salvar PDFs

**Nota:** Todas as permissões dangerous são solicitadas apenas quando o usuário precisa da funcionalidade específica, não no início do app. Ver `/docs/PERMISSOES_ACEITACAO.md` para detalhes completos.

## Notas Importantes

### Escopo Mínimo
- Apenas permissões essenciais para funcionalidades principais foram incluídas
- Permissões de instalação (INTERNET, ACCESS_NETWORK_STATE, WAKE_LOCK) são necessárias para o funcionamento básico do app
- Permissão de armazenamento é condicional (apenas Android < 10) e pode ser evitada usando Scoped Storage
- Permissões de mídia (READ_MEDIA_IMAGES, CAMERA) são opcionais e usadas apenas quando usuário solicita upload de imagens
- Permissão de notificações (POST_NOTIFICATIONS) é opcional e pode ser negada sem afetar funcionalidade principal

### Conformidade Google Play
- Todas as permissões têm justificativa clara ligada à função principal
- Pedidos de permissão são feitos em contexto apropriado
- Alternativas dignas estão disponíveis para todas as funcionalidades
- Dados sensíveis são protegidos (HTTPS, sem armazenamento de credenciais)

### Proteção de Dados
- Dados transmitidos via HTTPS/TLS
- Credenciais nunca armazenadas em texto plano
- PDFs gerados temporariamente; usuário controla destino
- Logs de segurança não incluem dados sensíveis

