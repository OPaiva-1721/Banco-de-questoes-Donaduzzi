import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

/// Serviço para comunicação com Google Gemini para detecção de gabarito
class GeminiService {
  // IMPORTANTE: Configure sua API Key do Gemini via arquivo .env ou variável de ambiente
  // Para obter uma API Key: https://aistudio.google.com/app/apikey
  // 
  // Ordem de prioridade:
  // 1. Arquivo .env (GEMINI_API_KEY=...)
  // 2. Variável de ambiente (GEMINI_API_KEY=...)
  // 3. Valor padrão (vazio)
  static String get _apiKey {
    // Tenta pegar do .env primeiro
    final envKey = dotenv.env['GEMINI_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    // Se não encontrou no .env, tenta variável de ambiente
    const envVarKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (envVarKey.isNotEmpty) {
      return envVarKey;
    }
    
    // Se não encontrou em nenhum lugar, retorna vazio
    return '';
  }

  late final GenerativeModel _model;

  GeminiService() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY não configurada. '
        'Configure a variável de ambiente GEMINI_API_KEY ou defina no código.',
      );
    }
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  /// Detecta respostas marcadas em uma imagem de gabarito
  /// 
  /// Retorna um Map<int, String> onde:
  /// - Key: número da questão (1, 2, 3, ...)
  /// - Value: letra da alternativa marcada (A, B, C, D, E)
  Future<Map<int, String>> detectarRespostas({
    required Uint8List imageBytes,
    required int totalQuestoes,
    required List<String> alternativas,
  }) async {
    try {
      // Criar prompt detalhado para o Gemini
      final prompt = _criarPrompt(totalQuestoes, alternativas);

      // Criar conteúdo com imagem e prompt
      final content = [
        Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart(prompt),
        ])
      ];

      // Chamar o modelo
      final response = await _model.generateContent(content);

      // Extrair texto da resposta
      final textoResposta = response.text;
      if (textoResposta == null || textoResposta.isEmpty) {
        throw Exception('Gemini não retornou resposta');
      }

      if (kDebugMode) debugPrint('=== RESPOSTA DO GEMINI ===');
      if (kDebugMode) debugPrint(textoResposta);
      if (kDebugMode) debugPrint('==========================');

      // Parsear JSON da resposta
      final respostas = _parsearResposta(textoResposta);

      if (kDebugMode) debugPrint('✓ Gemini detectou ${respostas.length} respostas');
      return respostas;
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao detectar respostas com Gemini: $e');
      rethrow;
    }
  }

  /// Cria o prompt para o Gemini analisar o gabarito
  String _criarPrompt(int totalQuestoes, List<String> alternativas) {
    final alternativasStr = alternativas.join(', ');
    
    return '''
Você é um especialista em análise de gabaritos de prova. Analise a imagem fornecida e identifique qual alternativa foi marcada em cada questão.

INSTRUÇÕES CRÍTICAS:
1. A imagem contém um gabarito com $totalQuestoes questões
2. Cada questão tem as seguintes alternativas disponíveis: $alternativasStr
3. CADA QUESTÃO DEVE TER APENAS UMA ALTERNATIVA MARCADA
4. Se uma questão tiver MAIS DE UMA alternativa marcada, ela é INVÁLIDA
5. Identifique qual alternativa está marcada (círculo preenchido) para cada questão válida

FORMATO DA RESPOSTA (JSON):
{
  "respostas": {
    "1": "A",
    "2": "B",
    "3": "C"
  },
  "invalidas": {
    "4": ["B", "C"]
  }
}

REGRAS:
- Use apenas números como chaves (strings): "1", "2", "3", etc.
- Use apenas letras maiúsculas como valores: "A", "B", "C", "D", "E"
- Se uma questão não tiver nenhuma alternativa marcada, NÃO inclua ela no JSON
- Se uma questão tiver EXATAMENTE UMA alternativa marcada, inclua em "respostas"
- Se uma questão tiver MAIS DE UMA alternativa marcada, inclua em "invalidas" com array das alternativas marcadas
- Se uma questão tiver múltiplas alternativas, NÃO escolha uma - marque como inválida
- Retorne APENAS o JSON, sem markdown, sem explicações, sem texto adicional

IMPORTANTE: 
- Retorne APENAS o JSON, nada mais!
- Valide que cada questão tem apenas UMA resposta marcada
- Questões com múltiplas respostas devem ir em "invalidas"
''';
  }

  /// Parseia a resposta do Gemini extraindo o JSON
  /// Retorna um Map com respostas válidas e informações sobre questões inválidas
  Map<int, String> _parsearResposta(String textoResposta) {
    try {
      // Tentar extrair JSON do texto (pode estar dentro de markdown code blocks)
      String jsonStr = textoResposta.trim();

      // Remover markdown code blocks se existirem
      if (jsonStr.startsWith('```')) {
        final lines = jsonStr.split('\n');
        jsonStr = lines
            .skipWhile((line) => line.trim().startsWith('```'))
            .takeWhile((line) => !line.trim().startsWith('```'))
            .join('\n');
      }

      // Remover espaços em branco extras
      jsonStr = jsonStr.trim();

      // Parsear JSON
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Extrair respostas válidas
      final respostasMap = json['respostas'] as Map<String, dynamic>?;
      
      // Extrair questões inválidas (com múltiplas respostas)
      final invalidasMap = json['invalidas'] as Map<String, dynamic>?;
      
      // Logar questões com múltiplas respostas (mas não parar o processamento)
      if (invalidasMap != null && invalidasMap.isNotEmpty) {
        final List<String> questoesInvalidas = [];
        invalidasMap.forEach((key, value) {
          if (value is List) {
            final alternativas = (value).map((e) => e.toString()).join(', ');
            questoesInvalidas.add('Questão $key: ${alternativas}');
          } else {
            questoesInvalidas.add('Questão $key: múltiplas respostas');
          }
        });
        
        if (kDebugMode) debugPrint('! ATENÇÃO: Questões com múltiplas respostas detectadas (serão consideradas erradas):');
        for (var questao in questoesInvalidas) {
          if (kDebugMode) debugPrint('  - $questao');
        }
        if (kDebugMode) debugPrint('Essas questões não terão resposta marcada e serão consideradas erradas na correção.\n');
      }

      // Converter para Map<int, String> (apenas questões válidas)
      final Map<int, String> respostas = {};
      if (respostasMap != null) {
        respostasMap.forEach((key, value) {
          final questaoNum = int.tryParse(key);
          if (questaoNum != null && value is String) {
            respostas[questaoNum] = value.toUpperCase();
          }
        });
      }

      // Se não encontrou nenhuma resposta válida, lançar exceção
      if (respostas.isEmpty) {
        throw Exception('Nenhuma resposta válida encontrada na imagem');
      }

      return respostas;
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao parsear resposta do Gemini: $e');
      if (kDebugMode) debugPrint('Texto recebido: $textoResposta');
      rethrow;
    }
  }

  /// Verifica se o serviço está disponível (sempre true se a API key está configurada)
  bool verificarDisponibilidade() {
    return _apiKey.isNotEmpty;
  }
}

