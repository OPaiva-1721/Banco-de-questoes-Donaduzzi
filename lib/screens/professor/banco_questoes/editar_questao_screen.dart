// import 'package:flutter/material.dart';
// import '../../../services/question_service.dart';
// import '../../../services/discipline_service.dart';
// import '../../../utils/message_utils.dart';

// class EditarQuestaoScreen extends StatefulWidget {
//   final Map<String, dynamic> questao;

//   const EditarQuestaoScreen({super.key, required this.questao});

//   @override
//   State<EditarQuestaoScreen> createState() => _EditarQuestaoScreenState();
// }

// class _EditarQuestaoScreenState extends State<EditarQuestaoScreen> {
//   // Constantes de cores
//   static const Color _primaryColor = Color(0xFF541822);
//   static const Color _backgroundColor = Color(0xFFF5F5F5);
//   static const Color _textColor = Color(0xFF333333);
//   static const Color _whiteColor = Colors.white;

//   // Serviços
//   final QuestionService _questionService = QuestionService();
//   final DisciplineService _disciplineService = DisciplineService();

//   // Controladores para os campos
//   late TextEditingController _enunciadoController;
//   late TextEditingController _explicacaoController;

//   // Controladores para as opções
//   late List<TextEditingController> _opcoesControllers;

//   // Estados dos dropdowns
//   String? _disciplinaSelecionada;
//   String _dificuldadeSelecionada = 'facil';

//   // Listas de dados
//   List<Map<String, dynamic>> _disciplinas = [];
//   bool _isLoading = true;
//   bool _isSaving = false;

//   // Opções corretas
//   List<bool> _opcoesCorretas = [];

//   @override
//   void initState() {
//     super.initState();
//     _inicializarControladores();
//     _carregarDisciplinas();
//   }

//   void _inicializarControladores() {
//     // Inicializar controladores com dados da questão
//     _enunciadoController = TextEditingController(
//       text: widget.questao['enunciado'] ?? '',
//     );

//     _explicacaoController = TextEditingController(
//       text: widget.questao['explicacao'] ?? '',
//     );

//     // Inicializar disciplina e dificuldade
//     _disciplinaSelecionada = widget.questao['disciplinaId'];
//     _dificuldadeSelecionada = widget.questao['dificuldade'] ?? 'facil';

//     // Inicializar controladores das opções
//     _opcoesControllers = [];
//     _opcoesCorretas = [];

//     final opcoes = Map<String, dynamic>.from(widget.questao['opcoes'] ?? {});

//     // Processar opções existentes
//     final opcoesOrdenadas = <MapEntry<String, dynamic>>[];
//     opcoes.forEach((key, value) {
//       opcoesOrdenadas.add(MapEntry(key, value));
//     });

//     // Ordenar por chave para manter ordem
//     opcoesOrdenadas.sort((a, b) => a.key.compareTo(b.key));

//     for (final entry in opcoesOrdenadas) {
//       final opcao = Map<String, dynamic>.from(entry.value);
//       _opcoesControllers.add(TextEditingController(text: opcao['texto'] ?? ''));
//       _opcoesCorretas.add(opcao['correta'] == true);
//     }

//     // Se não há opções, adicionar duas opções vazias
//     if (_opcoesControllers.isEmpty) {
//       _adicionarOpcao();
//       _adicionarOpcao();
//     }
//   }

//   @override
//   void dispose() {
//     _enunciadoController.dispose();
//     _explicacaoController.dispose();
//     for (var controller in _opcoesControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   /// Adiciona uma nova opção à questão
//   void _adicionarOpcao() {
//     setState(() {
//       _opcoesControllers.add(TextEditingController());
//       _opcoesCorretas.add(false);
//     });
//   }

//   /// Remove uma opção da questão
//   void _removerOpcao(int index) {
//     if (_opcoesControllers.length > 2) {
//       setState(() {
//         _opcoesControllers[index].dispose();
//         _opcoesControllers.removeAt(index);
//         _opcoesCorretas.removeAt(index);
//       });
//     }
//   }

//   /// Alterna se uma opção está correta
//   void _alternarOpcaoCorreta(int index) {
//     setState(() {
//       _opcoesCorretas[index] = !_opcoesCorretas[index];
//     });
//   }

//   /// Carrega disciplinas do Firebase
//   Future<void> _carregarDisciplinas() async {
//     try {
//       final stream = _disciplineService.listarDisciplinas();
//       final event = await stream.first;

//       if (event.snapshot.exists) {
//         final disciplinas = <Map<String, dynamic>>[];
//         for (final child in event.snapshot.children) {
//           final disciplina = {
//             'id': child.key,
//             ...Map<String, dynamic>.from(child.value as Map<dynamic, dynamic>),
//           };
//           disciplinas.add(disciplina);
//         }
//         if (mounted) {
//           setState(() {
//             _disciplinas = disciplinas;
//             _isLoading = false;
//           });
//         }
//       } else {
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     } catch (e) {
//       print('Erro ao carregar disciplinas: $e');
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//         MessageUtils.mostrarErro(context, 'Erro ao carregar disciplinas: $e');
//       }
//     }
//   }

//   /// Salva as alterações da questão
//   Future<void> _salvarAlteracoes() async {
//     if (!_validarFormulario()) return;

//     setState(() {
//       _isSaving = true;
//     });

//     try {
//       // Preparar dados das opções
//       final opcoes = <String, Map<String, dynamic>>{};
//       for (int i = 0; i < _opcoesControllers.length; i++) {
//         final texto = _opcoesControllers[i].text.trim();
//         if (texto.isNotEmpty) {
//           opcoes['opcao_${i + 1}'] = {
//             'texto': texto,
//             'correta': _opcoesCorretas[i],
//             'ordem': i + 1,
//           };
//         }
//       }

//       // Preparar dados para atualização
//       final dados = {
//         'enunciado': _enunciadoController.text.trim(),
//         'disciplinaId': _disciplinaSelecionada!,
//         'dificuldade': _dificuldadeSelecionada,
//         'opcoes': opcoes,
//         'explicacao': _explicacaoController.text.trim().isEmpty
//             ? null
//             : _explicacaoController.text.trim(),
//         'dataAtualizacao': DateTime.now().toIso8601String(),
//       };

//       // Atualizar questão no Firebase
//       final sucesso = await _questionService.atualizarQuestao(
//         widget.questao['id'],
//         dados,
//       );

//       if (sucesso) {
//         MessageUtils.mostrarSucesso(context, 'Questão atualizada com sucesso!');
//         Navigator.pop(context, true); // Retorna true para indicar sucesso
//       } else {
//         MessageUtils.mostrarErro(context, 'Erro ao atualizar questão');
//       }
//     } catch (e) {
//       print('Erro ao salvar questão: $e');
//       MessageUtils.mostrarErro(context, 'Erro ao salvar questão: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSaving = false;
//         });
//       }
//     }
//   }

//   /// Valida se todos os campos obrigatórios foram preenchidos
//   bool _validarFormulario() {
//     if (_disciplinaSelecionada == null) {
//       MessageUtils.mostrarErro(context, 'Selecione uma disciplina');
//       return false;
//     }
//     if (_enunciadoController.text.trim().isEmpty) {
//       MessageUtils.mostrarErro(context, 'Digite o enunciado da questão');
//       return false;
//     }

//     // Validar opções
//     for (int i = 0; i < _opcoesControllers.length; i++) {
//       if (_opcoesControllers[i].text.trim().isEmpty) {
//         MessageUtils.mostrarErro(
//           context,
//           'Todas as opções devem ser preenchidas',
//         );
//         return false;
//       }
//     }

//     // Verificar se pelo menos uma opção está marcada como correta
//     bool temOpcaoCorreta = _opcoesCorretas.any((correta) => correta);
//     if (!temOpcaoCorreta) {
//       MessageUtils.mostrarErro(
//         context,
//         'Pelo menos uma opção deve estar marcada como correta',
//       );
//       return false;
//     }

//     return true;
//   }

//   /// Limpa todos os campos do formulário
//   void _limparFormulario() {
//     setState(() {
//       _disciplinaSelecionada = null;
//       _dificuldadeSelecionada = 'facil';
//       _enunciadoController.clear();
//       _explicacaoController.clear();

//       // Limpar opções
//       for (var controller in _opcoesControllers) {
//         controller.clear();
//       }
//       _opcoesCorretas.fillRange(0, _opcoesCorretas.length, false);
//     });
//   }

//   /// Cria um container reutilizável com estilo padrão
//   Widget _buildContainer({required Widget child, double? height}) {
//     return Container(
//       width: double.infinity,
//       height: height ?? 50,
//       decoration: BoxDecoration(
//         color: _whiteColor,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.25),
//             offset: const Offset(0, 4),
//             blurRadius: 4,
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }

//   /// Cria um botão de seleção de dificuldade
//   Widget _buildDificuldadeButton(String label, String value) {
//     final isSelected = _dificuldadeSelecionada == value;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _dificuldadeSelecionada = value;
//         });
//       },
//       child: Container(
//         width: 80,
//         height: 49,
//         decoration: BoxDecoration(
//           color: isSelected ? _primaryColor : _whiteColor,
//           borderRadius: BorderRadius.circular(10),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.25),
//               offset: const Offset(0, 4),
//               blurRadius: 4,
//             ),
//           ],
//         ),
//         child: Center(
//           child: Text(
//             label,
//             style: TextStyle(
//               color: isSelected ? _whiteColor : _textColor,
//               fontFamily: 'Inter-Bold',
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   /// Cria um card para cada opção de resposta
//   Widget _buildOpcaoCard(int index) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: _whiteColor,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             offset: const Offset(0, 2),
//             blurRadius: 4,
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           children: [
//             // Checkbox para marcar como correta
//             Checkbox(
//               value: _opcoesCorretas[index],
//               onChanged: (value) => _alternarOpcaoCorreta(index),
//               activeColor: _primaryColor,
//             ),
//             const SizedBox(width: 8),
//             // Campo de texto da opção
//             Expanded(
//               child: TextField(
//                 controller: _opcoesControllers[index],
//                 decoration: InputDecoration(
//                   hintText: 'Opção ${index + 1}',
//                   hintStyle: const TextStyle(
//                     color: Colors.black54,
//                     fontSize: 14,
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: BorderSide(
//                       color: _opcoesCorretas[index]
//                           ? _primaryColor
//                           : Colors.grey[300]!,
//                     ),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: BorderSide(
//                       color: _opcoesCorretas[index]
//                           ? _primaryColor
//                           : Colors.grey[300]!,
//                     ),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: const BorderSide(
//                       color: _primaryColor,
//                       width: 2,
//                     ),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 8,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             // Botão para remover opção (se houver mais de 2)
//             if (_opcoesControllers.length > 2)
//               IconButton(
//                 onPressed: () => _removerOpcao(index),
//                 icon: const Icon(Icons.remove_circle_outline),
//                 color: Colors.red,
//                 tooltip: 'Remover opção',
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: _backgroundColor,
//         body: const Center(
//           child: CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: _backgroundColor,
//       body: Column(
//         children: [
//           // Header com logo e botão voltar
//           Container(
//             width: double.infinity,
//             height: 100,
//             decoration: const BoxDecoration(
//               color: _primaryColor,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black26,
//                   offset: Offset(0, 8),
//                   blurRadius: 8,
//                 ),
//               ],
//             ),
//             child: Stack(
//               children: [
//                 // Logo centralizado
//                 Center(
//                   child: Image.asset(
//                     'assets/images/logo.png',
//                     width: 196,
//                     height: 67,
//                     fit: BoxFit.contain,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         width: 196,
//                         height: 67,
//                         decoration: BoxDecoration(
//                           color: _whiteColor,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: const Center(
//                           child: Text(
//                             'LOGO',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: _primaryColor,
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 // Botão voltar
//                 Positioned(
//                   left: 16,
//                   top: 0,
//                   bottom: 0,
//                   child: Center(
//                     child: IconButton(
//                       onPressed: () => Navigator.pop(context),
//                       icon: const Icon(
//                         Icons.arrow_back,
//                         color: _whiteColor,
//                         size: 28,
//                       ),
//                       tooltip: 'Voltar',
//                       style: IconButton.styleFrom(
//                         backgroundColor: _primaryColor,
//                         shape: const CircleBorder(),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Conteúdo principal
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Título
//                   const Center(
//                     child: Text(
//                       'Editar Questões',
//                       style: TextStyle(
//                         color: _textColor,
//                         fontFamily: 'Inter-Bold',
//                         fontSize: 30,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // Campo Disciplina
//                   const Text(
//                     'Disciplina',
//                     style: TextStyle(
//                       color: _textColor,
//                       fontFamily: 'Inter-Bold',
//                       fontSize: 25,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildContainer(
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: _disciplinaSelecionada,
//                         isExpanded: true,
//                         hint: const Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 16),
//                           child: Text(
//                             'Selecione a disciplina',
//                             style: TextStyle(
//                               color: Colors.black54,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w300,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         items: _disciplinas.map((disciplina) {
//                           return DropdownMenuItem<String>(
//                             value: disciplina['id'],
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                               ),
//                               child: Text(
//                                 disciplina['nome'] ?? 'Disciplina sem nome',
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                         onChanged: (String? newValue) {
//                           setState(() {
//                             _disciplinaSelecionada = newValue;
//                           });
//                         },
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // Campo Dificuldade
//                   const Text(
//                     'Nível de dificuldade',
//                     style: TextStyle(
//                       color: _textColor,
//                       fontFamily: 'Inter-Bold',
//                       fontSize: 25,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Center(
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         _buildDificuldadeButton('Fácil', 'facil'),
//                         const SizedBox(width: 12),
//                         _buildDificuldadeButton('Médio', 'medio'),
//                         const SizedBox(width: 12),
//                         _buildDificuldadeButton('Difícil', 'dificil'),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // Campo Enunciado
//                   const Text(
//                     'Enunciado',
//                     style: TextStyle(
//                       color: _textColor,
//                       fontFamily: 'Inter-Bold',
//                       fontSize: 25,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildContainer(
//                     height: 100,
//                     child: TextField(
//                       controller: _enunciadoController,
//                       maxLines: 4,
//                       decoration: const InputDecoration(
//                         hintText: 'Insira o enunciado da questão',
//                         hintStyle: TextStyle(
//                           color: Colors.black54,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w300,
//                         ),
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.all(16),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // Seção de Opções
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Opções de Resposta',
//                         style: TextStyle(
//                           color: _textColor,
//                           fontFamily: 'Inter-Bold',
//                           fontSize: 25,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: _adicionarOpcao,
//                         icon: const Icon(Icons.add, size: 18),
//                         label: const Text('Adicionar'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _primaryColor,
//                           foregroundColor: _whiteColor,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 8,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),

//                   // Lista de Opções
//                   ...List.generate(_opcoesControllers.length, (index) {
//                     return _buildOpcaoCard(index);
//                   }),

//                   const SizedBox(height: 32),

//                   // Campo Explicação (Opcional)
//                   const Text(
//                     'Explicação (Opcional)',
//                     style: TextStyle(
//                       color: _textColor,
//                       fontFamily: 'Inter-Bold',
//                       fontSize: 25,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildContainer(
//                     height: 80,
//                     child: TextField(
//                       controller: _explicacaoController,
//                       maxLines: 3,
//                       decoration: const InputDecoration(
//                         hintText:
//                             'Insira uma explicação para a resposta correta',
//                         hintStyle: TextStyle(
//                           color: Colors.black54,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w300,
//                         ),
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.all(16),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // Botões de Ação
//                   Center(
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         ElevatedButton(
//                           onPressed: _isSaving ? null : _salvarAlteracoes,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: _primaryColor,
//                             foregroundColor: _whiteColor,
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 32,
//                               vertical: 16,
//                             ),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             elevation: 4,
//                           ),
//                           child: _isSaving
//                               ? const SizedBox(
//                                   width: 20,
//                                   height: 20,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     valueColor: AlwaysStoppedAnimation<Color>(
//                                       _whiteColor,
//                                     ),
//                                   ),
//                                 )
//                               : const Text(
//                                   'Salvar Questão',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                         ),
//                         const SizedBox(width: 16),
//                         ElevatedButton(
//                           onPressed: _isSaving ? null : _limparFormulario,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.grey[600],
//                             foregroundColor: _whiteColor,
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 32,
//                               vertical: 16,
//                             ),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             elevation: 4,
//                           ),
//                           child: const Text(
//                             'Limpar',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
