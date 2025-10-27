// import 'package:flutter/material.dart';
// import '../../services/exam_service.dart';
// import '../../services/discipline_service.dart';
// import '../../utils/message_utils.dart';

// class ProvasGeradasScreen extends StatefulWidget {
//   const ProvasGeradasScreen({super.key});

//   @override
//   State<ProvasGeradasScreen> createState() => _ProvasGeradasScreenState();
// }

// class _ProvasGeradasScreenState extends State<ProvasGeradasScreen> {
//   // Constantes de cores
//   static const Color _primaryColor = Color(0xFF541822);
//   static const Color _backgroundColor = Color(0xFFF5F5F5);
//   static const Color _textColor = Color(0xFF333333);
//   static const Color _whiteColor = Colors.white;

//   // Serviços
//   final ExamService _examService = ExamService();
//   final DisciplineService _disciplineService = DisciplineService();

//   // Estados
//   List<Map<String, dynamic>> _provas = [];
//   List<Map<String, dynamic>> _disciplinas = [];
//   bool _isLoading = true;
//   String _filtroStatus = 'todas';

//   @override
//   void initState() {
//     super.initState();
//     _carregarDados();
//   }

//   /// Carrega provas e disciplinas do Firebase
//   Future<void> _carregarDados() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Carregar disciplinas
//       await _carregarDisciplinas();

//       // Carregar provas
//       await _carregarProvas();
//     } catch (e) {
//       MessageUtils.mostrarErro(context, 'Erro ao carregar dados: $e');
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
//       await for (final event in stream) {
//         if (event.snapshot.exists) {
//           final disciplinas = <Map<String, dynamic>>[];
//           for (final child in event.snapshot.children) {
//             final disciplina = {
//               'id': child.key,
//               ...Map<String, dynamic>.from(child.value as Map),
//             };
//             disciplinas.add(disciplina);
//           }
//           if (mounted) {
//             setState(() {
//               _disciplinas = disciplinas;
//             });
//           }
//         }
//       }
//     } catch (e) {
//       print('Erro ao carregar disciplinas: $e');
//     }
//   }

//   /// Carrega provas do Firebase
//   Future<void> _carregarProvas() async {
//     try {
//       final stream = _examService.listarExames();
//       await for (final event in stream) {
//         if (event.snapshot.exists) {
//           final provas = <Map<String, dynamic>>[];
//           for (final child in event.snapshot.children) {
//             final prova = {
//               'id': child.key,
//               ...Map<String, dynamic>.from(child.value as Map),
//             };
//             provas.add(prova);
//           }
//           if (mounted) {
//             setState(() {
//               _provas = provas;
//             });
//           }
//         }
//       }
//     } catch (e) {
//       print('Erro ao carregar provas: $e');
//     }
//   }

//   /// Filtra provas baseado no status
//   List<Map<String, dynamic>> _getProvasFiltradas() {
//     if (_filtroStatus == 'todas') {
//       return _provas;
//     }
//     return _provas.where((prova) => prova['status'] == _filtroStatus).toList();
//   }

//   /// Obtém o nome da disciplina pelo ID
//   String _getNomeDisciplina(String? disciplinaId) {
//     if (disciplinaId == null) return 'Disciplina não encontrada';

//     final disciplina = _disciplinas.firstWhere(
//       (d) => d['id'] == disciplinaId,
//       orElse: () => {'nome': 'Disciplina não encontrada'},
//     );

//     return disciplina['nome'] ?? 'Disciplina não encontrada';
//   }

//   /// Formata a data de criação
//   String _formatarData(dynamic timestamp) {
//     if (timestamp == null) return 'Data não disponível';

//     try {
//       final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
//       return '${date.day}/${date.month}/${date.year}';
//     } catch (e) {
//       return 'Data inválida';
//     }
//   }

//   /// Deleta uma prova
//   Future<void> _deletarProva(Map<String, dynamic> prova) async {
//     final confirmacao = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirmar exclusão'),
//         content: Text(
//           'Tem certeza que deseja deletar a prova:\n"${prova['titulo']}"?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancelar'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Deletar'),
//           ),
//         ],
//       ),
//     );

//     if (confirmacao == true) {
//       try {
//         final sucesso = await _examService.deletarExame(prova['id']);
//         if (sucesso) {
//           MessageUtils.mostrarSucesso(context, 'Prova deletada com sucesso!');
//           _carregarDados(); // Recarregar dados
//         } else {
//           MessageUtils.mostrarErro(context, 'Erro ao deletar prova');
//         }
//       } catch (e) {
//         MessageUtils.mostrarErro(context, 'Erro ao deletar prova: $e');
//       }
//     }
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
//                 // Título
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Provas Geradas',
//                         style: TextStyle(
//                           color: _textColor,
//                           fontFamily: 'Inter-Bold',
//                           fontSize: 30,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Filtro de status
//                 _buildFiltroStatus(),
//                 // Lista de provas
//                 Expanded(
//                   child: _isLoading
//                       ? const Center(child: CircularProgressIndicator())
//                       : _getProvasFiltradas().isEmpty
//                       ? _buildEmptyState()
//                       : ListView.builder(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           itemCount: _getProvasFiltradas().length,
//                           itemBuilder: (context, index) {
//                             final prova = _getProvasFiltradas()[index];
//                             return _buildProvaCard(prova);
//                           },
//                         ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Cria o estado vazio quando não há provas
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
//           const SizedBox(height: 24),
//           Text(
//             'Nenhuma prova gerada',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Crie uma nova prova para começar',
//             style: TextStyle(fontSize: 16, color: Colors.grey[500]),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Cria o filtro de status
//   Widget _buildFiltroStatus() {
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
//           const Text(
//             'Filtrar por status:',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: _textColor,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: DropdownButtonFormField<String>(
//               value: _filtroStatus,
//               decoration: const InputDecoration(
//                 border: OutlineInputBorder(),
//                 contentPadding: EdgeInsets.symmetric(
//                   horizontal: 8,
//                   vertical: 8,
//                 ),
//               ),
//               items: const [
//                 DropdownMenuItem<String>(value: 'todas', child: Text('Todas')),
//                 DropdownMenuItem<String>(
//                   value: 'rascunho',
//                   child: Text('Rascunho'),
//                 ),
//                 DropdownMenuItem<String>(
//                   value: 'finalizada',
//                   child: Text('Finalizada'),
//                 ),
//                 DropdownMenuItem<String>(
//                   value: 'aplicada',
//                   child: Text('Aplicada'),
//                 ),
//               ],
//               onChanged: (value) {
//                 setState(() {
//                   _filtroStatus = value ?? 'todas';
//                 });
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Cria um card para cada prova
//   Widget _buildProvaCard(Map<String, dynamic> prova) {
//     final status = prova['status'] ?? 'rascunho';

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
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
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header com status e botões
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildStatusChip(status),
//                 Row(
//                   children: [
//                     IconButton(
//                       onPressed: () => _deletarProva(prova),
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       tooltip: 'Deletar prova',
//                     ),
//                     IconButton(
//                       onPressed: () {
//                         // TODO: Implementar visualização/edição da prova
//                         MessageUtils.mostrarSucesso(
//                           context,
//                           'Funcionalidade em desenvolvimento',
//                         );
//                       },
//                       icon: const Icon(Icons.visibility),
//                       color: _primaryColor,
//                       tooltip: 'Visualizar prova',
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             // Título da prova
//             Text(
//               prova['titulo'] ?? 'Prova sem título',
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: _textColor,
//               ),
//             ),
//             const SizedBox(height: 8),
//             // Informações da prova
//             Row(
//               children: [
//                 _buildInfoChip(
//                   Icons.school,
//                   _getNomeDisciplina(prova['disciplinaId']),
//                   Colors.blue,
//                 ),
//                 const SizedBox(width: 8),
//                 _buildInfoChip(
//                   Icons.quiz,
//                   '${prova['estatisticas']?['totalQuestoes'] ?? 0} questões',
//                   Colors.green,
//                 ),
//                 const SizedBox(width: 8),
//                 _buildInfoChip(
//                   Icons.calendar_today,
//                   _formatarData(prova['dataCriacao']),
//                   Colors.orange,
//                 ),
//               ],
//             ),
//             if (prova['instrucoes'] != null &&
//                 prova['instrucoes'].isNotEmpty) ...[
//               const SizedBox(height: 8),
//               Text(
//                 prova['instrucoes'],
//                 style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   /// Cria um chip de status
//   Widget _buildStatusChip(String status) {
//     Color color;
//     String texto;
//     switch (status.toLowerCase()) {
//       case 'rascunho':
//         color = Colors.orange;
//         texto = 'Rascunho';
//         break;
//       case 'finalizada':
//         color = Colors.green;
//         texto = 'Finalizada';
//         break;
//       case 'aplicada':
//         color = Colors.blue;
//         texto = 'Aplicada';
//         break;
//       default:
//         color = Colors.grey;
//         texto = 'Rascunho';
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Text(
//         texto,
//         style: TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.bold,
//           color: color,
//         ),
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
//           ),
//         ],
//       ),
//     );
//   }
// }
