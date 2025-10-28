// import 'package:flutter/material.dart';
// import '../../../services/question_service.dart';
// import '../../../services/discipline_service.dart';
// import '../../../utils/message_utils.dart';

// class SelecionarQuestoesScreen extends StatefulWidget {
//   final String disciplinaId;
//   final String tituloProva;
//   final String instrucoesProva;

//   const SelecionarQuestoesScreen({
//     super.key,
//     required this.disciplinaId,
//     required this.tituloProva,
//     required this.instrucoesProva,
//   });

//   @override
//   State<SelecionarQuestoesScreen> createState() =>
//       _SelecionarQuestoesScreenState();
// }

// class _SelecionarQuestoesScreenState extends State<SelecionarQuestoesScreen> {
//   // Constantes de cores
//   static const Color _primaryColor = Color(0xFF541822);
//   static const Color _backgroundColor = Color(0xFFF5F5F5);
//   static const Color _textColor = Color(0xFF333333);
//   static const Color _whiteColor = Colors.white;

//   // Serviços
//   final QuestionService _questionService = QuestionService();
//   final DisciplineService _disciplineService = DisciplineService();

//   // Estados
//   List<Map<String, dynamic>> _questoes = [];
//   List<Map<String, dynamic>> _disciplinas = [];
//   Set<String> _questoesSelecionadas = {};
//   bool _isLoading = true;
//   String? _disciplinaFiltro;
//   String _dificuldadeFiltro = 'todas';

//   @override
//   void initState() {
//     super.initState();
//     _disciplinaFiltro = widget.disciplinaId;
//     _carregarDados();
//   }

//   /// Carrega questões e disciplinas do Firebase
//   Future<void> _carregarDados() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       await Future.wait([_carregarDisciplinas(), _carregarQuestoes()]);
//     } catch (e) {
//       print('Erro ao carregar dados: $e');
//       if (mounted) {
//         MessageUtils.mostrarErro(context, 'Erro ao carregar dados: $e');
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
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
//           });
//         }
//       }
//     } catch (e) {
//       print('Erro ao carregar disciplinas: $e');
//     }
//   }

//   /// Carrega questões do Firebase
//   Future<void> _carregarQuestoes() async {
//     try {
//       final stream = _questionService.listarQuestoes();
//       final event = await stream.first;

//       if (event.snapshot.exists) {
//         final questoes = <Map<String, dynamic>>[];
//         for (final child in event.snapshot.children) {
//           final questao = {
//             'id': child.key,
//             ...Map<String, dynamic>.from(child.value as Map<dynamic, dynamic>),
//           };
//           questoes.add(questao);
//         }
//         if (mounted) {
//           setState(() {
//             _questoes = questoes;
//           });
//         }
//       }
//     } catch (e) {
//       print('Erro ao carregar questões: $e');
//     }
//   }

//   /// Filtra questões baseado nos filtros selecionados
//   List<Map<String, dynamic>> _getQuestoesFiltradas() {
//     return _questoes.where((questao) {
//       // Filtro por disciplina
//       if (_disciplinaFiltro != null &&
//           questao['disciplinaId'] != _disciplinaFiltro) {
//         return false;
//       }

//       // Filtro por dificuldade
//       if (_dificuldadeFiltro != 'todas' &&
//           questao['dificuldade'] != _dificuldadeFiltro) {
//         return false;
//       }

//       return true;
//     }).toList();
//   }

//   /// Alterna seleção de uma questão
//   void _alternarSelecaoQuestao(String questaoId) {
//     setState(() {
//       if (_questoesSelecionadas.contains(questaoId)) {
//         _questoesSelecionadas.remove(questaoId);
//       } else {
//         _questoesSelecionadas.add(questaoId);
//       }
//     });
//   }

//   /// Obtém o nome da disciplina pelo ID
//   String _getNomeDisciplina(String disciplinaId) {
//     final disciplina = _disciplinas.firstWhere(
//       (d) => d['id'] == disciplinaId,
//       orElse: () => {'nome': 'Disciplina não encontrada'},
//     );
//     return disciplina['nome'] ?? 'Disciplina sem nome';
//   }

//   /// Cria os filtros de busca
//   Widget _buildFiltros() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: _whiteColor,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             offset: const Offset(0, 2),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Filtro por disciplina
//           Expanded(
//             child: DropdownButtonFormField<String?>(
//               value:
//                   _disciplinaFiltro != null &&
//                       _disciplinas.any((d) => d['id'] == _disciplinaFiltro)
//                   ? _disciplinaFiltro
//                   : null,
//               decoration: const InputDecoration(
//                 labelText: 'Disciplina',
//                 border: OutlineInputBorder(),
//                 contentPadding: EdgeInsets.symmetric(
//                   horizontal: 8,
//                   vertical: 10,
//                 ),
//               ),
//               items: [
//                 const DropdownMenuItem<String?>(
//                   value: null,
//                   child: Text('Todas'),
//                 ),
//                 ..._disciplinas.map(
//                   (disciplina) => DropdownMenuItem<String?>(
//                     value: disciplina['id'],
//                     child: Text(
//                       disciplina['nome'] ?? 'Disciplina sem nome',
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ),
//               ],
//               onChanged: (value) {
//                 setState(() {
//                   _disciplinaFiltro = value;
//                 });
//               },
//             ),
//           ),
//           const SizedBox(width: 8),
//           // Filtro por dificuldade
//           Expanded(
//             child: DropdownButtonFormField<String>(
//               value: _dificuldadeFiltro,
//               decoration: const InputDecoration(
//                 labelText: 'Dificuldade',
//                 border: OutlineInputBorder(),
//                 contentPadding: EdgeInsets.symmetric(
//                   horizontal: 8,
//                   vertical: 8,
//                 ),
//               ),
//               items: const [
//                 DropdownMenuItem<String>(value: 'todas', child: Text('Todas')),
//                 DropdownMenuItem<String>(value: 'facil', child: Text('Fácil')),
//                 DropdownMenuItem<String>(value: 'medio', child: Text('Médio')),
//                 DropdownMenuItem<String>(
//                   value: 'dificil',
//                   child: Text('Difícil'),
//                 ),
//               ],
//               onChanged: (value) {
//                 setState(() {
//                   _dificuldadeFiltro = value ?? 'todas';
//                 });
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Cria um card para cada questão
//   Widget _buildQuestaoCard(Map<String, dynamic> questao) {
//     final isSelecionada = _questoesSelecionadas.contains(questao['id']);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: _whiteColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isSelecionada ? _primaryColor : Colors.grey[300]!,
//           width: isSelecionada ? 2 : 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             offset: const Offset(0, 2),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: InkWell(
//         onTap: () => _alternarSelecaoQuestao(questao['id']),
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header com checkbox e dificuldade
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     children: [
//                       Checkbox(
//                         value: isSelecionada,
//                         onChanged: (value) =>
//                             _alternarSelecaoQuestao(questao['id']),
//                         activeColor: _primaryColor,
//                       ),
//                       _buildDificuldadeChip(questao['dificuldade'] ?? 'medio'),
//                     ],
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               // Enunciado da questão
//               Text(
//                 questao['enunciado'] ?? 'Enunciado não disponível',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: _textColor,
//                 ),
//                 maxLines: 3,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 12),
//               // Informações da questão
//               Row(
//                 children: [
//                   _buildInfoChip(
//                     Icons.school,
//                     _getNomeDisciplina(questao['disciplinaId']),
//                     Colors.blue,
//                   ),
//                   const SizedBox(width: 8),
//                   _buildInfoChip(
//                     Icons.quiz,
//                     '${(questao['opcoes'] as Map?)?.length ?? 0} opções',
//                     Colors.green,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Cria um chip de dificuldade
//   Widget _buildDificuldadeChip(String dificuldade) {
//     Color color;
//     String label;

//     switch (dificuldade) {
//       case 'facil':
//         color = Colors.green;
//         label = 'Fácil';
//         break;
//       case 'medio':
//         color = Colors.orange;
//         label = 'Médio';
//         break;
//       case 'dificil':
//         color = Colors.red;
//         label = 'Difícil';
//         break;
//       default:
//         color = Colors.grey;
//         label = 'N/A';
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.speed, size: 14, color: color),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Cria um chip de informação
//   Widget _buildInfoChip(IconData icon, String text, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 14, color: color),
//           const SizedBox(width: 4),
//           Text(
//             text,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//               color: color,
//             ),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }

//   /// Cria o estado vazio quando não há questões
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
//           const SizedBox(height: 24),
//           Text(
//             'Nenhuma questão encontrada',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Ajuste os filtros ou adicione questões ao banco',
//             style: TextStyle(fontSize: 16, color: Colors.grey[500]),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Finaliza a seleção e retorna as questões selecionadas
//   void _finalizarSelecao() {
//     if (_questoesSelecionadas.isEmpty) {
//       MessageUtils.mostrarErro(context, 'Selecione pelo menos uma questão');
//       return;
//     }

//     final questoesSelecionadas = _questoes
//         .where((questao) => _questoesSelecionadas.contains(questao['id']))
//         .toList();

//     Navigator.pop(context, {
//       'questoes': questoesSelecionadas,
//       'titulo': widget.tituloProva,
//       'instrucoes': widget.instrucoesProva,
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
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
//             child: Column(
//               children: [
//                 // Título e contador
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           'Selecionar Questões',
//                           style: const TextStyle(
//                             color: _textColor,
//                             fontFamily: 'Inter-Bold',
//                             fontSize: 30,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: _primaryColor,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(
//                           '${_questoesSelecionadas.length} selecionadas',
//                           style: const TextStyle(
//                             color: _whiteColor,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Filtros
//                 _buildFiltros(),
//                 // Lista de questões
//                 Expanded(
//                   child: _isLoading
//                       ? const Center(child: CircularProgressIndicator())
//                       : _getQuestoesFiltradas().isEmpty
//                       ? _buildEmptyState()
//                       : RefreshIndicator(
//                           onRefresh: _carregarDados,
//                           color: _primaryColor,
//                           child: ListView.builder(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             itemCount: _getQuestoesFiltradas().length,
//                             itemBuilder: (context, index) {
//                               final questao = _getQuestoesFiltradas()[index];
//                               return _buildQuestaoCard(questao);
//                             },
//                           ),
//                         ),
//                 ),
//               ],
//             ),
//           ),
//           // Botão finalizar
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: _whiteColor,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   offset: const Offset(0, -2),
//                   blurRadius: 8,
//                 ),
//               ],
//             ),
//             child: SafeArea(
//               child: SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _finalizarSelecao,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _primaryColor,
//                     foregroundColor: _whiteColor,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     elevation: 4,
//                   ),
//                   child: Text(
//                     'Finalizar Seleção (${_questoesSelecionadas.length})',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
