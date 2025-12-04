import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Serviço para comunicação com a API Python de detecção de gabarito
class DetectionService {
  // URL da API - ajuste conforme necessário
  // Para desenvolvimento local: 'http://localhost:8000'
  // Para produção: configure a URL do seu servidor
  // NOTA: A API simplificada está no mesmo endpoint
  static const String _apiBaseUrl = String.fromEnvironment(
    'DETECTION_API_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Detecta círculos preenchidos em uma imagem de gabarito
  /// 
  /// [imageBytes]: Bytes da imagem
  /// [totalQuestoes]: Número total de questões
  /// [alternativas]: Lista de alternativas (ex: ['A', 'B', 'C', 'D', 'E'])
  /// 
  /// Retorna um Map com as respostas detectadas: {numeroQuestao: alternativa}
  Future<Map<int, String>> detectarRespostas({
    required Uint8List imageBytes,
    required int totalQuestoes,
    required List<String> alternativas,
  }) async {
    try {
      final url = Uri.parse('$_apiBaseUrl/detect');
      
      // Criar requisição multipart
      final request = http.MultipartRequest('POST', url);
      
      // Adicionar parâmetros
      request.fields['total_questoes'] = totalQuestoes.toString();
      request.fields['alternativas'] = alternativas.join(',');
      
      // Adicionar arquivo
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'gabarito.jpg',
        ),
      );
      
      // Enviar requisição
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao comunicar com a API');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          // Converter respostas de String para int nas chaves
          final respostasMap = jsonResponse['respostas'] as Map<String, dynamic>;
          final Map<int, String> respostas = {};
          
          respostasMap.forEach((key, value) {
            final questaoNum = int.tryParse(key);
            if (questaoNum != null && value is String) {
              respostas[questaoNum] = value;
            }
          });
          
          print('✓ API detectou ${respostas.length} respostas');
          if (jsonResponse['debug_info'] != null) {
            print('Debug: ${jsonResponse['debug_info']}');
          }
          
          return respostas;
        } else {
          throw Exception(
            jsonResponse['message'] ?? 'Erro desconhecido na API',
          );
        }
      } else {
        throw Exception(
          'Erro HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('Erro ao chamar API de detecção: $e');
      rethrow;
    }
  }

  /// Verifica se a API está disponível
  Future<bool> verificarDisponibilidade() async {
    try {
      final url = Uri.parse('$_apiBaseUrl/health');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('API não disponível: $e');
      return false;
    }
  }
}

