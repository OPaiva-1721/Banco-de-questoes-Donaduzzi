import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:async';
import 'dart:typed_data';

// Import condicional para Platform e File (não disponível na web)
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:prova/models/exam_model.dart';
import 'package:prova/models/question_model.dart';
import 'package:prova/services/exam_service.dart';
import 'package:prova/services/question_service.dart';
import 'package:prova/services/gemini_service.dart';
import 'package:prova/utils/message_utils.dart';
import 'package:prova/core/app_colors.dart';

class CorrigirProvaScreen extends StatefulWidget {
  const CorrigirProvaScreen({super.key});

  @override
  State<CorrigirProvaScreen> createState() => _CorrigirProvaScreenState();
}

class _CorrigirProvaScreenState extends State<CorrigirProvaScreen> {
  static const Color _primaryColor = AppColors.primary;
  static const Color _backgroundColor = AppColors.background;

  final ExamService _examService = ExamService();
  final QuestionService _questionService = QuestionService();
  final ImagePicker _imagePicker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  bool _isLoading = false;
  List<Exam> _provas = [];
  Exam? _provaSelecionada;
  Map<int, String> _respostasAluno = {}; // número da questão -> letra marcada
  Map<int, String> _gabaritoCorreto = {}; // número da questão -> letra correta
  int _totalQuestoes = 0;
  int _acertos = 0;
  double _nota = 0.0;
  bool _mostrarResultado = false;
  late final bool _isWindowsDesktop;

  StreamSubscription? _provasSubscription;

  bool _checkIsWindowsDesktop() {
    if (kIsWeb) return false;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _isWindowsDesktop = _checkIsWindowsDesktop();
    _carregarProvas();
  }

  @override
  void dispose() {
    _provasSubscription?.cancel();
    super.dispose();
  }

  void _carregarProvas() {
    setState(() => _isLoading = true);
    _provasSubscription = _examService.getAllExamsStream().listen(
      (event) {
        if (event.snapshot.exists) {
          final data = event.snapshot.value;
          final List<Exam> provas = [];
          
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                final examSnapshot = event.snapshot.child(key);
                try {
                  provas.add(Exam.fromSnapshot(examSnapshot));
                } catch (e) {
                  // Ignora provas com formato inválido
                }
              }
            });
          }
          
          setState(() {
            _provas = provas;
            _isLoading = false;
          });
        } else {
          setState(() {
            _provas = [];
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          MessageUtils.mostrarErroFormatado(context, error);
          setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _carregarGabaritoCorreto(Exam prova) async {
    setState(() {
      _isLoading = true;
      _gabaritoCorreto = {};
      _totalQuestoes = 0;
      _respostasAluno = {};
      _mostrarResultado = false;
    });

    try {
      final Map<int, String> gabarito = {};
      int totalQuestoes = 0;

      for (var link in prova.questions) {
        try {
          final questao = await _questionService.getQuestion(link.questionId);
          if (questao != null) {
            totalQuestoes++;
            final numeroQuestao = link.order;
            // Encontrar a alternativa correta
            String? respostaCorreta;
            for (var option in questao.options) {
              if (option.isCorrect) {
                respostaCorreta = option.letter.toUpperCase();
                break;
              }
            }
            
            if (respostaCorreta != null) {
              gabarito[numeroQuestao] = respostaCorreta;
            } else {
              print('Aviso: Questão $numeroQuestao não tem alternativa correta marcada.');
            }
          }
        } catch (e) {
          print('Erro ao carregar questão ${link.questionId}: $e');
        }
      }

      if (totalQuestoes == 0) {
        if (mounted) {
          MessageUtils.mostrarErro(
            context,
            'Nenhuma questão encontrada nesta prova.',
          );
        }
      } else {
        if (mounted) {
          MessageUtils.mostrarSucesso(
            context,
            'Gabarito carregado: $totalQuestoes questão(ões).',
          );
        }
      }

      setState(() {
        _gabaritoCorreto = gabarito;
        _totalQuestoes = totalQuestoes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErroFormatado(context, e);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _abrirCamera() async {
    if (_provaSelecionada == null) {
      if (mounted) {
        MessageUtils.mostrarErro(
          context,
          'Por favor, selecione uma prova primeiro.',
        );
      }
      return;
    }

    try {
      final XFile? foto = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (foto != null) {
        await _processarImagemXFile(foto);
      }
    } on Exception catch (e) {
      if (mounted) {
        String mensagem = 'Erro ao abrir a câmera.';
        if (e.toString().contains('permission')) {
          mensagem = 'Permissão de câmera negada. Ative nas configurações do dispositivo.';
        }
        MessageUtils.mostrarErro(context, mensagem);
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErro(
          context,
          'Erro ao acessar a câmera: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _abrirGaleria() async {
    if (_provaSelecionada == null) {
      if (mounted) {
        MessageUtils.mostrarErro(
          context,
          'Por favor, selecione uma prova primeiro.',
        );
      }
      return;
    }

    try {
      final XFile? foto = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (foto != null) {
        await _processarImagemXFile(foto);
      }
    } on Exception catch (e) {
      if (mounted) {
        String mensagem = 'Erro ao abrir a galeria.';
        if (e.toString().contains('permission')) {
          mensagem = 'Permissão de galeria negada. Ative nas configurações do dispositivo.';
        }
        MessageUtils.mostrarErro(context, mensagem);
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.mostrarErro(
          context,
          'Erro ao acessar a galeria: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _processarImagemXFile(XFile xFile) async {
    if (_provaSelecionada == null) {
      if (mounted) {
        MessageUtils.mostrarErro(
          context,
          'Por favor, selecione uma prova antes de processar a imagem.',
        );
      }
      return;
    }

    if (_gabaritoCorreto.isEmpty) {
      if (mounted) {
        MessageUtils.mostrarErro(
          context,
          'Aguarde o carregamento do gabarito da prova.',
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verificar se o Gemini está disponível
      if (!_geminiService.verificarDisponibilidade()) {
      if (mounted) {
        MessageUtils.mostrarErro(
          context,
            'Serviço Gemini não está disponível.\n\n'
            'Configure a variável de ambiente GEMINI_API_KEY ou defina no código.',
          duration: const Duration(seconds: 8),
        );
      }
        setState(() => _isLoading = false);
      return;
    }

      // Ler bytes da imagem
      final imageBytes = await xFile.readAsBytes();
      
      // Obter alternativas da prova (buscar das questões completas)
      final Set<String> alternativasSet = {};
      
      // Buscar alternativas de todas as questões da prova
      for (var link in _provaSelecionada!.questions) {
        try {
          final questao = await _questionService.getQuestion(link.questionId);
          if (questao != null) {
            for (var option in questao.options) {
              alternativasSet.add(option.letter.toUpperCase());
            }
          }
      } catch (e) {
          print('Erro ao buscar questão ${link.questionId} para alternativas: $e');
        }
      }
      
      // Se não encontrou alternativas, usar padrão
      final List<String> alternativas;
      if (alternativasSet.isNotEmpty) {
        alternativas = alternativasSet.toList()..sort();
      } else {
        alternativas = ['A', 'B', 'C', 'D', 'E'];
      }

      // Chamar Gemini para detectar respostas
      print('=== ENVIANDO IMAGEM PARA GEMINI ===');
      print('Alternativas detectadas: $alternativas');
      print('Total questões na prova: $_totalQuestoes');
      final respostas = await _geminiService.detectarRespostas(
        imageBytes: imageBytes,
        totalQuestoes: _totalQuestoes,
        alternativas: alternativas,
      );
      print('=== RESPOSTAS DETECTADAS: ${respostas.length} ===');

      if (respostas.isEmpty) {
        if (mounted) {
          MessageUtils.mostrarErro(
            context,
            'Não foi possível identificar respostas na imagem.\n\n'
            'Certifique-se de que o gabarito está visível e os círculos estão bem preenchidos.',
            duration: const Duration(seconds: 8),
          );
        }
      } else {
        setState(() {
          _respostasAluno = respostas;
        });

        _calcularNota();
          
        if (mounted) {
          // Verificar se há questões sem resposta (podem ser questões com múltiplas respostas)
          final questoesSemResposta = _totalQuestoes - respostas.length;
          String mensagem = 'Gabarito processado com sucesso! ${respostas.length} resposta(s) identificada(s).';
          
          if (questoesSemResposta > 0) {
            mensagem += '\n\n⚠️ ${questoesSemResposta} questão(ões) sem resposta válida (múltiplas alternativas marcadas ou sem marcação). Serão consideradas erradas.';
          }
          
          MessageUtils.mostrarSucesso(
            context,
            mensagem,
            duration: const Duration(seconds: 6),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String mensagemErro;
        final errorString = e.toString().toLowerCase();
        
        if (errorString.contains('gemini_api_key')) {
          mensagemErro = 'API Key do Gemini não configurada.\n\n'
              'Configure a variável de ambiente GEMINI_API_KEY ou defina no código.\n\n'
              'Veja README_GEMINI.md para instruções.';
        } else if (errorString.contains('quota') || errorString.contains('rate limit')) {
          mensagemErro = 'Limite de requisições do Gemini excedido.\n\n'
              'Tente novamente mais tarde.';
        } else if (errorString.contains('parsear') || errorString.contains('json')) {
          mensagemErro = 'Erro ao processar resposta do Gemini.\n\n'
              'Tente novamente ou verifique se a imagem está clara.';
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          mensagemErro = 'Erro de conexão com o Gemini.\n\n'
              'Verifique sua conexão com a internet.';
        } else if (errorString.contains('permission')) {
          mensagemErro = 'Permissão negada. Verifique as permissões da câmera/galeria.';
        } else {
          mensagemErro = 'Erro ao processar imagem com Gemini: ${errorString.length > 100 ? errorString.substring(0, 100) + "..." : errorString}';
        }
        
        MessageUtils.mostrarErro(
          context,
          mensagemErro,
          duration: const Duration(seconds: 8),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<int, String> _extrairRespostasDoTexto(String texto) {
    final Map<int, String> respostas = {};
    
    final textoNormalizado = texto.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    print('=== PROCESSANDO TEXTO NORMALIZADO ===');
    print(textoNormalizado);
    
    final regex1 = RegExp(r'(?:Questão|Q\.?)\s*(\d+)[\s:-\-]*([A-E])', caseSensitive: false);
    final matches1 = regex1.allMatches(textoNormalizado);
    
    for (var match in matches1) {
      final numeroQuestao = int.tryParse(match.group(1) ?? '');
      final letra = match.group(2)?.toUpperCase();
      
      if (numeroQuestao != null && letra != null) {
        respostas[numeroQuestao] = letra;
        print('Encontrado: Questão $numeroQuestao = $letra');
      }
    }

    if (respostas.isEmpty || respostas.length < _totalQuestoes) {
      final regex2 = RegExp(r'\b(\d+)\s*[:\-]?\s*([A-E])\b', caseSensitive: false);
      final matches2 = regex2.allMatches(textoNormalizado);
      
      for (var match in matches2) {
        final numeroQuestao = int.tryParse(match.group(1) ?? '');
        final letra = match.group(2)?.toUpperCase();
        
        if (numeroQuestao != null && letra != null) {
          if (numeroQuestao >= 1 && numeroQuestao <= _totalQuestoes) {
            respostas[numeroQuestao] = letra;
            print('Encontrado: $numeroQuestao = $letra');
          }
        }
      }
    }

    if (respostas.isEmpty) {
      final linhas = texto.split('\n');
      for (var linha in linhas) {
        final regex3 = RegExp(r'(\d+).*?([A-E])', caseSensitive: false);
        final match3 = regex3.firstMatch(linha);
        if (match3 != null) {
          final numeroQuestao = int.tryParse(match3.group(1) ?? '');
          final letra = match3.group(2)?.toUpperCase();
          if (numeroQuestao != null && letra != null && numeroQuestao >= 1 && numeroQuestao <= _totalQuestoes) {
            respostas[numeroQuestao] = letra;
            print('Encontrado (linha): $numeroQuestao = $letra');
          }
        }
      }
    }

    print('=== TOTAL DE RESPOSTAS ENCONTRADAS: ${respostas.length} ===');
    return respostas;
  }

  /// Detecta círculos preenchidos na imagem do gabarito
  /// Agora detecta automaticamente a estrutura da tabela através das linhas
  Future<Map<int, String>> _detectarCirculosPreenchidos(img.Image image) async {
    final Map<int, String> respostas = {};
    
    final grayImage = img.grayscale(image);
    
    img.Image processImage = grayImage;
    if (grayImage.width > 2000 || grayImage.height > 2000) {
      processImage = img.copyResize(
        grayImage,
        width: 2000,
        height: (grayImage.height * 2000 / grayImage.width).round(),
      );
    }
    
    final width = processImage.width;
    final height = processImage.height;
    
    print('=== DETECÇÃO DE TABELA E CÍRCULOS ===');
    print('Tamanho imagem: ${width}x${height}');
    
    final linhasHorizontais = _detectarLinhasHorizontais(processImage);
    print('Linhas horizontais encontradas: ${linhasHorizontais.length}');
    
    final linhasVerticais = _detectarLinhasVerticais(processImage);
    print('Linhas verticais encontradas: ${linhasVerticais.length}');
    
    // Se não detectou linhas suficientes OU se detectou poucas colunas, usar método melhorado
    if (linhasHorizontais.length < 2 || linhasVerticais.length < 2 || linhasVerticais.length < 5) {
      print('AVISO: Não foi possível detectar a estrutura completa da tabela. Usando método de detecção global de círculos.');
      return _detectarCirculosGlobal(processImage);
    }
    
    linhasHorizontais.sort();
    linhasVerticais.sort();
    
    // A primeira linha horizontal geralmente é o cabeçalho
    final linhasQuestoes = linhasHorizontais.length > 1 
        ? linhasHorizontais.sublist(1)
        : linhasHorizontais;
    
    // A primeira coluna vertical geralmente é a coluna de números
    final colunasAlternativas = linhasVerticais.length > 1
        ? linhasVerticais.sublist(1)
        : linhasVerticais;
    
    final numLinhas = linhasQuestoes.length < _totalQuestoes 
        ? linhasQuestoes.length 
        : _totalQuestoes;
    
    final numColunas = colunasAlternativas.length < 5 
        ? colunasAlternativas.length 
        : 5;
    
    print('Estrutura detectada: $numLinhas linhas x $numColunas colunas');
    
    // Se detectou poucas colunas, usar método global
    if (numColunas < 3) {
      print('AVISO: Poucas colunas detectadas. Usando método de detecção global de círculos.');
      return _detectarCirculosGlobal(processImage);
    }
    
      final alternativas = ['A', 'B', 'C', 'D', 'E'];
    final estimatedCircleSize = (width / 25).round().clamp(8, 35);
    
    // Para cada linha (questão), procurar círculo preenchido
    for (int i = 0; i < numLinhas && i < _totalQuestoes; i++) {
      final questaoNum = i + 1;
      final linhaTop = i > 0 ? linhasQuestoes[i - 1] : linhasHorizontais[0];
      final linhaBottom = linhasQuestoes[i];
      
      // Armazenar escuridão de cada alternativa
      final Map<String, double> darknessMap = {};
      
      // Adicionar margem de segurança para não ultrapassar para outras linhas
      final cellHeight = linhaBottom - linhaTop;
      final marginY = (cellHeight * 0.1).round().clamp(3, 10);
      final safeLinhaTop = linhaTop + marginY;
      final safeLinhaBottom = linhaBottom - marginY;
      final safeLinhaCenterY = (safeLinhaTop + safeLinhaBottom) ~/ 2;
      
      // Área de busca dentro da célula (mais restrita)
      final safeCellHeight = safeLinhaBottom - safeLinhaTop;
      final searchAreaY = (safeCellHeight * 0.3).round().clamp(10, 30);
      
      print('Questão $questaoNum: Y entre $safeLinhaTop e $safeLinhaBottom (original: $linhaTop-$linhaBottom), centro: $safeLinhaCenterY');
      
      // Procurar em cada coluna de alternativa
      for (int j = 0; j < numColunas && j < alternativas.length; j++) {
        final colLeft = j > 0 ? colunasAlternativas[j - 1] : linhasVerticais[0];
        final colRight = colunasAlternativas[j];
        
        // Adicionar margem de segurança horizontal também
        final cellWidth = colRight - colLeft;
        final marginX = (cellWidth * 0.1).round().clamp(3, 10);
        final safeColLeft = colLeft + marginX;
        final safeColRight = colRight - marginX;
        final safeColCenterX = (safeColLeft + safeColRight) ~/ 2;
        
        // Área de busca dentro da célula (mais restrita)
        final safeCellWidth = safeColRight - safeColLeft;
        final searchAreaX = (safeCellWidth * 0.3).round().clamp(10, 30);
        
        // Buscar o círculo mais escuro dentro da célula (limitado aos limites SEGUROS)
        double bestDarkness = 0;
        int bestX = safeColCenterX;
        int bestY = safeLinhaCenterY;
        
        for (int offsetY = -searchAreaY; offsetY <= searchAreaY; offsetY += 1) {
          for (int offsetX = -searchAreaX; offsetX <= searchAreaX; offsetX += 1) {
            final testX = safeColCenterX + offsetX;
            final testY = safeLinhaCenterY + offsetY;
            
            // Garantir que está dentro dos limites SEGUROS da célula E da imagem
            if (testX >= safeColLeft && testX < safeColRight &&
                testY >= safeLinhaTop && testY < safeLinhaBottom &&
                testX >= 0 && testX < width && testY >= 0 && testY < height) {
        final darkness = _verificarCirculoPreenchido(
          processImage,
                testX,
                testY,
          estimatedCircleSize,
        );
        
              if (darkness > bestDarkness) {
                bestDarkness = darkness;
                bestX = testX;
                bestY = testY;
              }
            }
          }
        }
        
        darknessMap[alternativas[j]] = bestDarkness;
        print('Questão $questaoNum, Alternativa ${alternativas[j]}: Escuridão = ${bestDarkness.toStringAsFixed(1)} (pos: $bestX,$bestY, célula segura: $safeColLeft-$safeColRight, $safeLinhaTop-$safeLinhaBottom)');
      }
      
      // Usar a mesma lógica de comparação relativa
      final sortedEntries = darknessMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      if (sortedEntries.isNotEmpty) {
        final maisEscura = sortedEntries[0];
        final segundaMaisEscura = sortedEntries.length > 1 ? sortedEntries[1].value : 0.0;
        
        final outrasAlternativas = sortedEntries.length > 1 
            ? sortedEntries.sublist(1).map((e) => e.value).toList()
            : <double>[];
        final mediaOutras = outrasAlternativas.isNotEmpty
            ? outrasAlternativas.reduce((a, b) => a + b) / outrasAlternativas.length
            : 0.0;
        
        final diferencaPercentual = mediaOutras > 0 
            ? ((maisEscura.value - mediaOutras) / mediaOutras) * 100
            : (maisEscura.value > 0 ? 100.0 : 0.0);
        
        final diferencaAbsoluta = maisEscura.value - segundaMaisEscura;
        final thresholdMinimo = 20.0;
        final diferencaMinima = 5.0;
        
        if (maisEscura.value > thresholdMinimo && 
            (diferencaPercentual > 20 && diferencaAbsoluta > diferencaMinima ||
             diferencaAbsoluta > 10 ||
             maisEscura.value > 25)) {
          respostas[questaoNum] = maisEscura.key;
          print('✓ Questão $questaoNum: ${maisEscura.key} (escuridão: ${maisEscura.value.toStringAsFixed(1)}, dif%: ${diferencaPercentual.toStringAsFixed(1)}%, difAbs: ${diferencaAbsoluta.toStringAsFixed(1)})');
        } else {
          print('✗ Questão $questaoNum: Nenhuma alternativa detectada (max: ${maisEscura.value.toStringAsFixed(1)}, dif%: ${diferencaPercentual.toStringAsFixed(1)}%, difAbs: ${diferencaAbsoluta.toStringAsFixed(1)})');
        }
      }
    }
    
    print('=== TOTAL CÍRCULOS DETECTADOS: ${respostas.length} ===');
    return respostas;
  }

  List<int> _detectarLinhasHorizontais(img.Image image) {
    final List<int> linhas = [];
    final width = image.width;
    final height = image.height;
    
    // Thresholds mais baixos para detectar linhas mais facilmente
    final lineThreshold = 0.1; // Reduzido ainda mais para detectar linhas mais finas
    final darknessThreshold = 70; // Reduzido ainda mais
    
    // Aplicar suavização para melhorar detecção
    for (int y = 1; y < height - 1; y++) {
      int darkPixels = 0;
      
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final brightness = ((r + g + b) / 3).round();
        final darkness = 255 - brightness;
        
        if (darkness > darknessThreshold) {
          darkPixels++;
        }
      }
      
      // Se uma porcentagem significativa da linha é escura, é uma linha da tabela
      if (darkPixels > width * lineThreshold) {
        // Evitar duplicatas próximas (linhas adjacentes)
        if (linhas.isEmpty || (y - linhas.last).abs() > 3) {
          linhas.add(y);
        }
      }
    }
    
    return linhas;
  }

  List<int> _detectarLinhasVerticais(img.Image image) {
    final List<int> colunas = [];
    final width = image.width;
    final height = image.height;
    
    // Thresholds mais baixos para detectar linhas mais facilmente
    final lineThreshold = 0.08; // Reduzido ainda mais
    final darknessThreshold = 70; // Reduzido ainda mais
    
    for (int x = 1; x < width - 1; x++) {
      int darkPixels = 0;
      
      for (int y = 0; y < height; y++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final brightness = ((r + g + b) / 3).round();
        final darkness = 255 - brightness;
        
        if (darkness > darknessThreshold) {
          darkPixels++;
        }
      }
      
      // Se uma porcentagem significativa da coluna é escura, é uma linha da tabela
      if (darkPixels > height * lineThreshold) {
        // Evitar duplicatas próximas (linhas adjacentes)
        if (colunas.isEmpty || (x - colunas.last).abs() > 3) {
          colunas.add(x);
        }
      }
    }
    
    return colunas;
  }

  /// Método que detecta todos os círculos preenchidos primeiro, depois os associa às questões
  Map<int, String> _detectarCirculosGlobal(img.Image image) {
    final Map<int, String> respostas = {};
    final width = image.width;
    final height = image.height;
    
    // Estimar estrutura da tabela
    final estimatedRowHeight = height / (_totalQuestoes + 1);
    final estimatedColWidth = width / 6; // 1 coluna número + 5 alternativas
    final estimatedCircleSize = (width / 18).round().clamp(12, 45);
    final thresholdMinimo = 20.0; // Threshold reduzido para detectar melhor
    
    final alternativas = ['A', 'B', 'C', 'D', 'E'];
    
    print('=== DETECÇÃO GLOBAL DE CÍRCULOS ===');
    print('Altura estimada linha: ${estimatedRowHeight.round()}');
    print('Largura estimada coluna: ${estimatedColWidth.round()}');
    print('Tamanho círculo: $estimatedCircleSize');
    print('Threshold mínimo: $thresholdMinimo');
    
    // Primeiro passo: detectar TODOS os círculos preenchidos na imagem
    final List<Map<String, dynamic>> circulosEncontrados = [];
    
    // Varrer a área onde devem estar os círculos (pular cabeçalho e coluna de números)
    final startY = estimatedRowHeight.round();
    final endY = height;
    final startX = estimatedColWidth.round();
    final endX = width;
    
    print('Área de busca: X($startX-$endX) Y($startY-$endY)');
    
    // Passo 1: Busca rápida nas áreas esperadas de cada célula (muito mais rápido)
    final minDistance = estimatedCircleSize * 0.7; // Distância mínima entre círculos
    
    // Buscar apenas nas células esperadas de cada questão
    for (int questaoNum = 1; questaoNum <= _totalQuestoes; questaoNum++) {
      final rowYStart = (estimatedRowHeight * questaoNum).round();
      final rowYEnd = (estimatedRowHeight * (questaoNum + 1)).round();
      final rowYCenter = (rowYStart + rowYEnd) ~/ 2;
      
      // Para cada alternativa, buscar na célula esperada
      for (int altIndex = 0; altIndex < alternativas.length; altIndex++) {
        final colXStart = (estimatedColWidth * (altIndex + 1)).round();
        final colXEnd = (estimatedColWidth * (altIndex + 2)).round();
        final colXCenter = (colXStart + colXEnd) ~/ 2;
        
        // Área de busca dentro da célula (50% do tamanho da célula)
        final searchRadiusX = ((colXEnd - colXStart) * 0.5).round().clamp(20, 60);
        final searchRadiusY = ((rowYEnd - rowYStart) * 0.5).round().clamp(20, 60);
        
        // Busca refinada apenas nesta célula
        double bestDarkness = 0;
        int bestX = colXCenter;
        int bestY = rowYCenter;
        
        final step = 3; // Passo de 3 para ser mais rápido
        for (int offsetY = -searchRadiusY; offsetY <= searchRadiusY; offsetY += step) {
          for (int offsetX = -searchRadiusX; offsetX <= searchRadiusX; offsetX += step) {
            final testX = colXCenter + offsetX;
            final testY = rowYCenter + offsetY;
            
            if (testX >= 0 && testX < width && testY >= 0 && testY < height) {
        final darkness = _verificarCirculoPreenchido(
                image,
                testX,
                testY,
          estimatedCircleSize,
        );
        
              if (darkness > bestDarkness) {
                bestDarkness = darkness;
                bestX = testX;
                bestY = testY;
              }
            }
          }
        }
        
        // Se encontrou um círculo preenchido nesta célula
        if (bestDarkness > thresholdMinimo) {
          // Verificar se não é duplicata de outro círculo já encontrado
          bool jaDetectado = false;
          for (var circulo in circulosEncontrados) {
            final dx = (bestX - (circulo['x'] as int)).abs();
            final dy = (bestY - (circulo['y'] as int)).abs();
            final distancia = (dx * dx + dy * dy).toDouble();
            
            if (distancia < minDistance * minDistance) {
              final darknessExistente = (circulo['darkness'] as num).toDouble();
              if (bestDarkness <= darknessExistente) {
                jaDetectado = true;
                break;
              } else {
                // Este é mais escuro, remover o anterior
                circulosEncontrados.remove(circulo);
                break;
              }
            }
          }
          
          if (!jaDetectado) {
            circulosEncontrados.add({
              'x': bestX,
              'y': bestY,
              'darkness': bestDarkness,
              'questao': questaoNum,
              'alternativa': alternativas[altIndex],
            });
            print('  Círculo encontrado na Questão $questaoNum, Alternativa ${alternativas[altIndex]}: pos($bestX,$bestY), escuridão: ${bestDarkness.toStringAsFixed(1)}');
          }
        }
      }
    }
    
    print('Total de círculos preenchidos encontrados: ${circulosEncontrados.length}');
    
    // Passo 2: Associar círculos às questões (já temos a associação inicial, mas vamos validar)
    // Agrupar por questão e escolher o mais escuro de cada questão
    final Map<int, List<Map<String, dynamic>>> circulosPorQuestao = {};
    
    for (var circulo in circulosEncontrados) {
      final questao = circulo['questao'] as int;
      if (!circulosPorQuestao.containsKey(questao)) {
        circulosPorQuestao[questao] = [];
      }
      circulosPorQuestao[questao]!.add(circulo);
    }
    
    // Para cada questão, escolher o círculo mais escuro
    for (int questaoNum = 1; questaoNum <= _totalQuestoes; questaoNum++) {
      if (circulosPorQuestao.containsKey(questaoNum)) {
        final circulosDaQuestao = circulosPorQuestao[questaoNum]!;
        
        // Ordenar por escuridão (mais escuro primeiro)
        circulosDaQuestao.sort((a, b) {
          final darknessA = (a['darkness'] as num).toDouble();
          final darknessB = (b['darkness'] as num).toDouble();
          return darknessB.compareTo(darknessA);
        });
        
        final circuloMaisEscuro = circulosDaQuestao[0];
        final alternativa = circuloMaisEscuro['alternativa'] as String;
        final circuloX = circuloMaisEscuro['x'] as int;
        final circuloY = circuloMaisEscuro['y'] as int;
        final circuloDarkness = (circuloMaisEscuro['darkness'] as num).toDouble();
        
        // Verificar se é significativamente mais escuro que os outros da mesma questão
        final segundaMaisEscura = circulosDaQuestao.length > 1 
            ? (circulosDaQuestao[1]['darkness'] as num).toDouble()
            : 0.0;
        final diferenca = circuloDarkness - segundaMaisEscura;
        
        // Se a diferença é significativa (pelo menos 5 pontos) ou se é o único
        if (diferenca > 5 || circulosDaQuestao.length == 1) {
          respostas[questaoNum] = alternativa;
          print('✓ Questão $questaoNum: $alternativa (escuridão: ${circuloDarkness.toStringAsFixed(1)}, pos: $circuloX,$circuloY, dif: ${diferenca.toStringAsFixed(1)})');
        } else {
          print('✗ Questão $questaoNum: Múltiplos círculos encontrados, diferença insuficiente (mais escuro: ${circuloDarkness.toStringAsFixed(1)}, segundo: ${segundaMaisEscura.toStringAsFixed(1)})');
        }
      } else {
        print('✗ Questão $questaoNum: Nenhum círculo encontrado');
      }
    }
    
    print('=== TOTAL CÍRCULOS DETECTADOS: ${respostas.length} ===');
    return respostas;
  }

  /// Método alternativo melhorado caso a detecção de linhas falhe
  Map<int, String> _detectarCirculosAlternativoMelhorado(img.Image image) {
    final Map<int, String> respostas = {};
    final width = image.width;
    final height = image.height;
    
    // Estimar estrutura da tabela
    final estimatedRowHeight = height / (_totalQuestoes + 1);
    final estimatedColWidth = width / 6; // 1 coluna número + 5 alternativas
    final estimatedCircleSize = (width / 20).round().clamp(10, 40);
    final searchRadius = (estimatedColWidth * 0.5).round().clamp(20, 80); // Área ainda maior
    
    final alternativas = ['A', 'B', 'C', 'D', 'E'];
    
    print('=== MÉTODO ALTERNATIVO MELHORADO ===');
    print('Altura estimada linha: ${estimatedRowHeight.round()}');
    print('Largura estimada coluna: ${estimatedColWidth.round()}');
    print('Raio de busca: $searchRadius');
    print('Threshold mínimo: 20.0');
    
    for (int questaoNum = 1; questaoNum <= _totalQuestoes; questaoNum++) {
      // Calcular posição Y da linha (pular cabeçalho)
      // Usar limites mais restritos para evitar confundir com outras questões
      final rowYStart = (estimatedRowHeight * questaoNum).round();
      final rowYEnd = (estimatedRowHeight * (questaoNum + 1)).round();
      
      // Adicionar margem de segurança para não ultrapassar para outras linhas
      final marginY = (estimatedRowHeight * 0.1).round().clamp(3, 10);
      final safeRowYStart = rowYStart + marginY;
      final safeRowYEnd = rowYEnd - marginY;
      final rowYCenter = (safeRowYStart + safeRowYEnd) ~/ 2;
      
      // Limitar a busca verticalmente à área da linha (muito restrito)
      final maxSearchY = ((safeRowYEnd - safeRowYStart) * 0.3).round().clamp(10, 30);
      
      print('Questão $questaoNum: Y entre $safeRowYStart e $safeRowYEnd (original: $rowYStart-$rowYEnd), centro: $rowYCenter');
      
      // Armazenar escuridão de cada alternativa
      final Map<String, double> darknessMap = {};
      
      for (int altIndex = 0; altIndex < alternativas.length; altIndex++) {
        // Calcular posição X da coluna (pular primeira coluna)
        final colXStart = (estimatedColWidth * (altIndex + 1)).round();
        final colXEnd = (estimatedColWidth * (altIndex + 2)).round();
        
        // Adicionar margem de segurança horizontal também
        final marginX = (estimatedColWidth * 0.1).round().clamp(3, 10);
        final safeColXStart = colXStart + marginX;
        final safeColXEnd = colXEnd - marginX;
        final colXCenter = (safeColXStart + safeColXEnd) ~/ 2;
        
        // Limitar a busca horizontalmente à área da coluna (muito restrito)
        final maxSearchX = ((safeColXEnd - safeColXStart) * 0.3).round().clamp(10, 30);
        
        // Buscar o círculo mais escuro apenas dentro da célula específica
        double bestDarkness = 0;
        int bestX = colXCenter;
        int bestY = rowYCenter;
        
        for (int offsetY = -maxSearchY; offsetY <= maxSearchY; offsetY += 1) {
          for (int offsetX = -maxSearchX; offsetX <= maxSearchX; offsetX += 1) {
            final testX = colXCenter + offsetX;
            final testY = rowYCenter + offsetY;
            
            // Garantir que está dentro dos limites SEGUROS da célula E da imagem
            // Usar limites seguros para evitar pegar círculos de outras células
            if (testX >= safeColXStart && testX < safeColXEnd &&
                testY >= safeRowYStart && testY < safeRowYEnd &&
                testX >= 0 && testX < width && testY >= 0 && testY < height) {
              final darkness = _verificarCirculoPreenchido(
                image,
                testX,
                testY,
                estimatedCircleSize,
              );
              if (darkness > bestDarkness) {
                bestDarkness = darkness;
                bestX = testX;
                bestY = testY;
              }
            }
          }
        }
        
        darknessMap[alternativas[altIndex]] = bestDarkness;
        print('Questão $questaoNum, Alternativa ${alternativas[altIndex]}: Escuridão = ${bestDarkness.toStringAsFixed(1)} (pos: $bestX,$bestY, célula segura: $safeColXStart-$safeColXEnd, $safeRowYStart-$safeRowYEnd)');
      }
      
      // Encontrar a alternativa mais escura (comparação relativa)
      // Se a mais escura for significativamente mais escura que as outras, é a resposta
      final sortedEntries = darknessMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      if (sortedEntries.isNotEmpty) {
        final maisEscura = sortedEntries[0];
        final segundaMaisEscura = sortedEntries.length > 1 ? sortedEntries[1].value : 0.0;
        
        // Calcular média das outras alternativas (excluindo a mais escura)
        final outrasAlternativas = sortedEntries.length > 1 
            ? sortedEntries.sublist(1).map((e) => e.value).toList()
            : <double>[];
        final mediaOutras = outrasAlternativas.isNotEmpty
            ? outrasAlternativas.reduce((a, b) => a + b) / outrasAlternativas.length
            : 0.0;
        
        // Diferença percentual em relação à média das outras
        final diferencaPercentual = mediaOutras > 0 
            ? ((maisEscura.value - mediaOutras) / mediaOutras) * 100
            : (maisEscura.value > 0 ? 100.0 : 0.0);
        
        // Diferença absoluta entre a mais escura e a segunda
        final diferencaAbsoluta = maisEscura.value - segundaMaisEscura;
        
        // Critérios para considerar válida:
        // 1. Se for pelo menos 20% mais escura que a média das outras E pelo menos 5 pontos mais escura
        // 2. OU se for pelo menos 10 pontos mais escura que a segunda
        // 3. OU se for maior que um threshold mínimo (reduzido para 20)
        final thresholdMinimo = 20.0;
        final diferencaMinima = 5.0;
        
        if (maisEscura.value > thresholdMinimo && 
            (diferencaPercentual > 20 && diferencaAbsoluta > diferencaMinima ||
             diferencaAbsoluta > 10 ||
             maisEscura.value > 25)) {
          respostas[questaoNum] = maisEscura.key;
          print('✓ Questão $questaoNum: ${maisEscura.key} (escuridão: ${maisEscura.value.toStringAsFixed(1)}, dif%: ${diferencaPercentual.toStringAsFixed(1)}%, difAbs: ${diferencaAbsoluta.toStringAsFixed(1)})');
        } else {
          print('✗ Questão $questaoNum: Nenhuma alternativa detectada (max: ${maisEscura.value.toStringAsFixed(1)}, dif%: ${diferencaPercentual.toStringAsFixed(1)}%, difAbs: ${diferencaAbsoluta.toStringAsFixed(1)})');
        }
      }
    }
    
    return respostas;
  }

  // Manter o método antigo como fallback
  Map<int, String> _detectarCirculosAlternativo(img.Image image) {
    return _detectarCirculosAlternativoMelhorado(image);
  }

  double _verificarCirculoPreenchido(
    img.Image image,
    int centerX,
    int centerY,
    int radius,
  ) {
    int totalDarkness = 0;
    int pixelCount = 0;
    
    for (int y = centerY - radius; y <= centerY + radius; y++) {
      for (int x = centerX - radius; x <= centerX + radius; x++) {
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = (dx * dx + dy * dy).toDouble();
        
        if (distance <= radius * radius && x >= 0 && x < image.width && y >= 0 && y < image.height) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();
          final brightness = ((r + g + b) / 3).round();
          final darkness = 255 - brightness;
          totalDarkness += darkness;
          pixelCount++;
        }
      }
    }
    
    if (pixelCount == 0) return 0;
    return totalDarkness / pixelCount;
  }

  Map<int, String> _combinarRespostasOCR_e_Circulos(
    String textoOCR,
    Map<int, String> respostasCirculos,
  ) {
    final Map<int, String> respostas = {};
    
    if (respostasCirculos.isNotEmpty) {
      respostas.addAll(respostasCirculos);
      print('Usando detecção de círculos: ${respostas.length} respostas');
    }
    
    final respostasOCR = _extrairRespostasDoTexto(textoOCR);
    
    for (var entry in respostasOCR.entries) {
      if (!respostas.containsKey(entry.key)) {
        respostas[entry.key] = entry.value;
        print('Adicionando do OCR: Questão ${entry.key} = ${entry.value}');
      }
    }
    
    return respostas;
  }

  void _calcularNota() {
    int acertos = 0;
    
    for (var entry in _gabaritoCorreto.entries) {
      final numeroQuestao = entry.key;
      final respostaCorreta = entry.value;
      final respostaAluno = _respostasAluno[numeroQuestao];
      
      if (respostaAluno != null && respostaAluno == respostaCorreta) {
        acertos++;
      }
    }

    final nota = _totalQuestoes > 0 ? (acertos / _totalQuestoes) * 10 : 0.0;

    setState(() {
      _acertos = acertos;
      _nota = nota;
      _mostrarResultado = true;
    });
  }

  void _resetar() {
    setState(() {
      _respostasAluno = {};
      _acertos = 0;
      _nota = 0.0;
      _mostrarResultado = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Corrigir Prova'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSelecaoProva(),
                  const SizedBox(height: 24),
                  if (_provaSelecionada != null) ...[
                    _buildBotoesCamera(),
                    const SizedBox(height: 24),
                    if (_mostrarResultado) _buildResultado(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSelecaoProva() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecione a prova:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Exam>(
              value: _provaSelecionada,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Prova',
              ),
              items: _provas.map((prova) {
                return DropdownMenuItem<Exam>(
                  value: prova,
                  child: Text(prova.title),
                );
              }).toList(),
              onChanged: (prova) {
                if (prova != null) {
                  setState(() {
                    _provaSelecionada = prova;
                    _mostrarResultado = false;
                    _respostasAluno = {};
                  });
                  _carregarGabaritoCorreto(prova);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoesCamera() {
    final gabaritoPronto = _gabaritoCorreto.isNotEmpty && _totalQuestoes > 0;
    final podeProcessar = gabaritoPronto && !_isWindowsDesktop;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Capturar Gabarito:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (gabaritoPronto)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Pronto',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Carregando...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (gabaritoPronto) ...[
              const SizedBox(height: 8),
              Text(
                'Gabarito carregado: $_totalQuestoes questão(ões)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                ),
              ),
            ],
            if (_isWindowsDesktop) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A correção automática via câmera não está disponível no Windows desktop. Use um dispositivo Android ou iOS.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (kIsWeb && !_isWindowsDesktop) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Na versão web, a correção automática está disponível. Para melhor experiência, use um dispositivo móvel (Android/iOS).',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: podeProcessar ? _abrirCamera : null,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Câmera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: podeProcessar ? _abrirGaleria : null,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeria'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isWindowsDesktop
                  ? 'Esta funcionalidade requer um dispositivo móvel (Android/iOS).'
                  : (gabaritoPronto
                      ? (kIsWeb 
                          ? 'Selecione uma imagem do gabarito preenchido pelo aluno.'
                          : 'Aponte a câmera para o gabarito preenchido pelo aluno.')
                      : 'Aguarde o carregamento do gabarito...'),
              style: TextStyle(
                fontSize: 12,
                color: _isWindowsDesktop
                    ? Colors.orange.shade700
                    : (gabaritoPronto ? Colors.grey : Colors.orange.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultado() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resultado da Correção:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _resetar,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Corrigir outra prova',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Total de questões:', '$_totalQuestoes'),
            _buildInfoRow('Acertos:', '$_acertos'),
            _buildInfoRow('Erros:', '${_totalQuestoes - _acertos}'),
            const Divider(height: 24),
            _buildInfoRow(
              'Nota:',
              _nota.toStringAsFixed(2),
              isBold: true,
              fontSize: 20,
            ),
            const SizedBox(height: 16),
            _buildDetalhesRespostas(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? _primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalhesRespostas() {
    return ExpansionTile(
      title: const Text('Detalhes das Respostas'),
      children: [
        ...List.generate(_totalQuestoes, (index) {
          final numeroQuestao = index + 1;
          final respostaCorreta = _gabaritoCorreto[numeroQuestao] ?? '?';
          final respostaAluno = _respostasAluno[numeroQuestao];
          final estaCorreta = respostaAluno == respostaCorreta;

          return ListTile(
            dense: true,
            leading: Icon(
              estaCorreta ? Icons.check_circle : Icons.cancel,
              color: estaCorreta ? Colors.green : Colors.red,
            ),
            title: Text('Questão $numeroQuestao'),
            subtitle: Text(
              'Correta: $respostaCorreta | Aluno: ${respostaAluno ?? "Não marcada"}',
            ),
            trailing: Text(
              estaCorreta ? '✓' : '✗',
              style: TextStyle(
                fontSize: 20,
                color: estaCorreta ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }),
      ],
    );
  }
}
