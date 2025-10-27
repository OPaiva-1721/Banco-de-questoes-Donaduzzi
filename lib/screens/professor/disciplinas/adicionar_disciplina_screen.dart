// import 'package:flutter/material.dart';
// import '../../../services/discipline_service.dart';
// import '../../../services/course_service.dart';
// import '../../../utils/message_utils.dart';

// class AdicionarDisciplinaScreen extends StatefulWidget {
//   const AdicionarDisciplinaScreen({super.key});

//   @override
//   State<AdicionarDisciplinaScreen> createState() =>
//       _AdicionarDisciplinaScreenState();
// }

// class _AdicionarDisciplinaScreenState extends State<AdicionarDisciplinaScreen> {
//   // Constantes de cores
//   static const Color _primaryColor = Color(0xFF541822);
//   static const Color _backgroundColor = Color(0xFFF5F5F5);
//   static const Color _textColor = Color(0xFF333333);
//   static const Color _whiteColor = Colors.white;

//   // Serviços
//   final DisciplineService _disciplineService = DisciplineService();
//   final CourseService _courseService = CourseService();

//   // Controladores
//   final TextEditingController _nomeController = TextEditingController();
//   final TextEditingController _descricaoController = TextEditingController();
//   final TextEditingController _cargaHorariaController = TextEditingController();

//   // Estados
//   String? _cursoSelecionado;
//   int _semestreSelecionado = 1;
//   bool _isLoading = false;
//   List<Map<String, dynamic>> _cursos = [];

//   @override
//   void initState() {
//     super.initState();
//     _carregarCursos();
//   }

//   @override
//   void dispose() {
//     _nomeController.dispose();
//     _descricaoController.dispose();
//     _cargaHorariaController.dispose();
//     super.dispose();
//   }

//   /// Carrega cursos do Firebase
//   Future<void> _carregarCursos() async {
//     try {
//       final stream = _courseService.listarCursos();
//       await for (final event in stream) {
//         if (event.snapshot.exists) {
//           final cursos = <Map<String, dynamic>>[];
//           for (final child in event.snapshot.children) {
//             final curso = {
//               'id': child.key,
//               ...Map<String, dynamic>.from(child.value as Map),
//             };
//             if (curso['status'] == 'ativo') {
//               cursos.add(curso);
//             }
//           }
//           if (mounted) {
//             setState(() {
//               _cursos = cursos;
//             });
//           }
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         MessageUtils.mostrarErro(context, 'Erro ao carregar cursos: $e');
//       }
//     }
//   }

//   /// Valida se todos os campos obrigatórios foram preenchidos
//   bool _validarFormulario() {
//     if (_cursoSelecionado == null) {
//       MessageUtils.mostrarErro(context, 'Selecione um curso');
//       return false;
//     }
//     if (_nomeController.text.trim().isEmpty) {
//       MessageUtils.mostrarErro(context, 'Digite o nome da disciplina');
//       return false;
//     }
//     if (_cargaHorariaController.text.trim().isEmpty) {
//       MessageUtils.mostrarErro(context, 'Digite a carga horária');
//       return false;
//     }

//     final cargaHoraria = int.tryParse(_cargaHorariaController.text.trim());
//     if (cargaHoraria == null || cargaHoraria <= 0) {
//       MessageUtils.mostrarErro(
//         context,
//         'Carga horária deve ser um número positivo',
//       );
//       return false;
//     }

//     return true;
//   }

//   /// Salva a disciplina após validar o formulário
//   Future<void> _salvarDisciplina() async {
//     if (!_validarFormulario()) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final disciplinaId = await _disciplineService.criarDisciplina(
//         _nomeController.text.trim(),
//         _semestreSelecionado,
//         cursoId: _cursoSelecionado,
//       );

//       if (disciplinaId != null) {
//         // Atualizar com informações adicionais
//         await _disciplineService.atualizarDisciplina(disciplinaId, {
//           'descricao': _descricaoController.text.trim(),
//           'cargaHoraria': int.parse(_cargaHorariaController.text.trim()),
//         });

//         MessageUtils.mostrarSucesso(context, 'Disciplina criada com sucesso!');
//         Navigator.pop(context, true); // Retorna true para indicar sucesso
//       } else {
//         MessageUtils.mostrarErro(context, 'Erro ao criar disciplina');
//       }
//     } catch (e) {
//       MessageUtils.mostrarErro(context, 'Erro ao criar disciplina: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
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
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Título
//                   const Text(
//                     'Nova Disciplina',
//                     style: TextStyle(
//                       color: _textColor,
//                       fontFamily: 'Inter-Bold',
//                       fontSize: 30,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // Campo Curso
//                   const Text(
//                     'Curso',
//                     style: TextStyle(
//                       color: _textColor,
//                       fontFamily: 'Inter-Bold',
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     decoration: BoxDecoration(
//                       color: _whiteColor,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           offset: const Offset(0, 2),
//                           blurRadius: 4,
//                         ),
//                       ],
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: _cursoSelecionado,
//                         hint: const Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 16),
//                           child: Text(
//                             'Selecione o curso',
//                             style: TextStyle(
//                               color: Colors.black54,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w300,
//                             ),
//                           ),
//                         ),
//                         items: _cursos.map((curso) {
//                           return DropdownMenuItem<String>(
//                             value: curso['id'],
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                               ),
//                               child: Text(curso['nome'] ?? 'Curso sem nome'),
//                             ),
//                           );
//                         }).toList(),
//                         onChanged: (String? newValue) {
//                           setState(() {
//                             _cursoSelecionado = newValue;
//                           });
//                         },
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // Campo Nome
//                   const Text(
//                     'Nome da Disciplina',
//                     style: TextStyle(
//                       color: _textColor,
//                       fontFamily: 'Inter-Bold',
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   _buildContainer(
//                     child: TextField(
//                       controller: _nomeController,
//                       decoration: const InputDecoration(
//                         hintText: 'Ex: Programação I',
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
//                   const SizedBox(height: 24),

//                   // Campo Semestre
//                   const Text(
//                     'Semestre',
//                     style: TextStyle(
//                       color: _textColor,
//                       fontFamily: 'Inter-Bold',
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   _buildContainer(
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<int>(
//                         value: _semestreSelecionado,
//                         items: List.generate(20, (index) => index + 1).map((
//                           semestre,
//                         ) {
//                           return DropdownMenuItem<int>(
//                             value: semestre,
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                               ),
//                               child: Text('$semestreº Semestre'),
//                             ),
//                           );
//                         }).toList(),
//                         onChanged: (int? newValue) {
//                           setState(() {
//                             _semestreSelecionado = newValue ?? 1;
//                           });
//                         },
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // Campo Carga Horária
//                   const Text(
//                     'Carga Horária',
//                     style: TextStyle(
//                       color: _textColor,
//                       fontFamily: 'Inter-Bold',
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   _buildContainer(
//                     child: TextField(
//                       controller: _cargaHorariaController,
//                       keyboardType: TextInputType.number,
//                       decoration: const InputDecoration(
//                         hintText: 'Ex: 60',
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
//                   const SizedBox(height: 24),

//                   // Campo Descrição
//                   const Text(
//                     'Descrição (Opcional)',
//                     style: TextStyle(
//                       color: _textColor,
//                       fontFamily: 'Inter-Bold',
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   _buildContainer(
//                     height: 100,
//                     child: TextField(
//                       controller: _descricaoController,
//                       maxLines: 4,
//                       decoration: const InputDecoration(
//                         hintText: 'Descreva o conteúdo da disciplina...',
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

//                   // Botão Salvar
//                   Center(
//                     child: ElevatedButton(
//                       onPressed: _isLoading ? null : _salvarDisciplina,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: _primaryColor,
//                         foregroundColor: _whiteColor,
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 48,
//                           vertical: 16,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         elevation: 4,
//                       ),
//                       child: _isLoading
//                           ? const SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                   Colors.white,
//                                 ),
//                               ),
//                             )
//                           : const Text(
//                               'Criar Disciplina',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
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

//   /// Cria um container reutilizável com estilo padrão
//   Widget _buildContainer({required Widget child, double? height}) {
//     return Container(
//       width: double.infinity,
//       height: height ?? 50,
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
//       child: child,
//     );
//   }
// }
