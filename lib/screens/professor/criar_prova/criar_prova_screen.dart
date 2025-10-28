// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import '../../../core/app_colors.dart';
// import '../../../core/app_constants.dart';
// import '../../../services/exam_service.dart';
// import '../../../services/discipline_service.dart';
// import '../../../services/course_service.dart';
// import '../../../utils/message_utils.dart';
// import 'selecionar_questoes_screen.dart';

// class CriarProvaScreen extends StatefulWidget {
//   const CriarProvaScreen({super.key});

//   @override
//   State<CriarProvaScreen> createState() => _CriarProvaScreenState();
// }

// class _CriarProvaScreenState extends State<CriarProvaScreen> {
//   // Constantes de cores
//   static const Color _primaryColor = AppColors.primary;
//   static const Color _backgroundColor = AppColors.background;
//   static const Color _textColor = AppColors.text;
//   static const Color _whiteColor = AppColors.white;

//   // Serviços
//   final ExamService _examService = ExamService();
//   final DisciplineService _disciplineService = DisciplineService();
//   final CourseService _courseService = CourseService();

//   // Estados dos dropdowns
//   String? _cursoSelecionado;
//   String? _disciplinaSelecionada;
//   final TextEditingController _tituloController = TextEditingController();
//   final TextEditingController _instrucoesController = TextEditingController();

//   // Estados
//   bool _isLoading = false;
//   List<Map<String, dynamic>> _cursos = [];
//   List<Map<String, dynamic>> _disciplinas = [];

//   @override
//   void initState() {
//     super.initState();
//     _testarConexaoFirebase();
//     _carregarCursos();
//     _carregarDisciplinas();
//   }

//   /// Testa a conexão com o Firebase
//   Future<void> _testarConexaoFirebase() async {
//     try {
//       print('🔥 Testando conexão com Firebase...');
//       final database = FirebaseDatabase.instance;
//       final ref = database.ref();
//       final snapshot = await ref.get();
//       print(
//         '✅ Conexão com Firebase OK - Dados disponíveis: ${snapshot.exists}',
//       );

//       if (snapshot.exists) {
//         print('📊 Estrutura do banco: ${snapshot.value}');
//       } else {
//         print('⚠️ Banco de dados vazio - pode ser necessário popular dados');
//         _verificarSePrecisaPopularDados();
//       }
//     } catch (e) {
//       print('❌ Erro na conexão com Firebase: $e');
//     }
//   }

//   /// Verifica se precisa popular dados de teste
//   Future<void> _verificarSePrecisaPopularDados() async {
//     try {
//       print('🔍 Verificando se há dados de cursos e disciplinas...');

//       // Verificar cursos
//       final cursosSnapshot = await FirebaseDatabase.instance
//           .ref('cursos')
//           .get();
//       print('📊 Cursos encontrados: ${cursosSnapshot.children.length}');

//       // Verificar disciplinas
//       final disciplinasSnapshot = await FirebaseDatabase.instance
//           .ref('disciplinas')
//           .get();
//       print(
//         '📚 Disciplinas encontradas: ${disciplinasSnapshot.children.length}',
//       );

//       if (cursosSnapshot.children.isEmpty ||
//           disciplinasSnapshot.children.isEmpty) {
//         print(
//           '⚠️ Dados insuficientes encontrados. Recomenda-se usar a função "Popular Dados" na tela principal.',
//         );
//         if (mounted) {
//           MessageUtils.mostrarErro(
//             context,
//             'Nenhum curso ou disciplina encontrado. Use "Popular Dados" na tela principal para adicionar dados de exemplo.',
//           );
//         }
//       }
//     } catch (e) {
//       print('❌ Erro ao verificar dados: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _tituloController.dispose();
//     _instrucoesController.dispose();
//     super.dispose();
//   }

//   /// Carrega cursos do Firebase
//   Future<void> _carregarCursos() async {
//     try {
//       print('🔍 Iniciando carregamento de cursos...');
//       final stream = _courseService.listarCursos();
//       await for (final event in stream) {
//         print(
//           '📡 Evento de cursos recebido do Firebase: ${event.snapshot.exists}',
//         );
//         if (event.snapshot.exists) {
//           final cursos = <Map<String, dynamic>>[];
//           print(
//             '📊 Número de cursos encontrados: ${event.snapshot.children.length}',
//           );

//           for (final child in event.snapshot.children) {
//             final curso = {
//               'id': child.key,
//               ...Map<String, dynamic>.from(child.value as Map),
//             };
//             print(
//               '🎓 Curso carregado: ${curso['nome']} (ID: ${curso['id']}, Status: ${curso['status']})',
//             );
//             // Só adiciona cursos ativos
//             if (curso['status'] == 'ativo') {
//               cursos.add(curso);
//               print('✅ Curso ativo adicionado: ${curso['nome']}');
//             } else {
//               print('❌ Curso inativo ignorado: ${curso['nome']}');
//             }
//           }

//           print('✅ Total de cursos ativos processados: ${cursos.length}');
//           if (mounted) {
//             setState(() {
//               _cursos = cursos;
//             });
//             print('🔄 Estado atualizado com ${_cursos.length} cursos');
//           }
//         } else {
//           print('❌ Nenhum curso encontrado no Firebase');
//         }
//       }
//     } catch (e) {
//       print('💥 Erro ao carregar cursos: $e');
//       if (mounted) {
//         MessageUtils.mostrarErro(context, 'Erro ao carregar cursos: $e');
//       }
//     }
//   }

//   /// Carrega disciplinas do Firebase
//   Future<void> _carregarDisciplinas() async {
//     try {
//       print('🔍 Iniciando carregamento de disciplinas...');
//       final stream = _disciplineService.listarDisciplinas();
//       await for (final event in stream) {
//         print('📡 Evento recebido do Firebase: ${event.snapshot.exists}');
//         if (event.snapshot.exists) {
//           final disciplinas = <Map<String, dynamic>>[];
//           print(
//             '📊 Número de disciplinas encontradas: ${event.snapshot.children.length}',
//           );

//           for (final child in event.snapshot.children) {
//             final disciplina = {
//               'id': child.key,
//               ...Map<String, dynamic>.from(child.value as Map),
//             };
//             print(
//               '📚 Disciplina carregada: ${disciplina['nome']} (ID: ${disciplina['id']}, Curso: ${disciplina['cursoId']})',
//             );
//             disciplinas.add(disciplina);
//           }

//           print('✅ Total de disciplinas processadas: ${disciplinas.length}');
//           if (mounted) {
//             setState(() {
//               _disciplinas = disciplinas;
//             });
//             print(
//               '🔄 Estado atualizado com ${_disciplinas.length} disciplinas',
//             );
//           }
//         } else {
//           print('❌ Nenhuma disciplina encontrada no Firebase');
//         }
//       }
//     } catch (e) {
//       print('💥 Erro ao carregar disciplinas: $e');
//       if (mounted) {
//         MessageUtils.mostrarErro(context, 'Erro ao carregar disciplinas: $e');
//       }
//     }
//   }

//   /// Filtra disciplinas por curso selecionado
//   List<Map<String, dynamic>> _getDisciplinasFiltradas() {
//     print('🔍 Filtrando disciplinas para curso: $_cursoSelecionado');
//     print('📊 Total de disciplinas disponíveis: ${_disciplinas.length}');

//     if (_cursoSelecionado == null) {
//       print('❌ Nenhum curso selecionado');
//       return [];
//     }

//     // Filtrar disciplinas pelo curso selecionado
//     final disciplinasFiltradas = _disciplinas.where((disciplina) {
//       final match = disciplina['cursoId'] == _cursoSelecionado;
//       print(
//         '🔍 Disciplina "${disciplina['nome']}" (cursoId: ${disciplina['cursoId']}) - Match: $match',
//       );
//       return match;
//     }).toList();

//     print(
//       '✅ Disciplinas filtradas encontradas: ${disciplinasFiltradas.length}',
//     );
//     return disciplinasFiltradas;
//   }

//   /// Valida se todos os campos obrigatórios foram preenchidos
//   bool _validarFormulario() {
//     if (_cursoSelecionado == null) {
//       MessageUtils.mostrarErro(context, 'Selecione um curso');
//       return false;
//     }
//     if (_disciplinaSelecionada == null) {
//       MessageUtils.mostrarErro(context, 'Selecione uma disciplina');
//       return false;
//     }
//     if (_tituloController.text.trim().isEmpty) {
//       MessageUtils.mostrarErro(context, 'Digite um título para a prova');
//       return false;
//     }
//     if (_instrucoesController.text.trim().isEmpty) {
//       MessageUtils.mostrarErro(context, 'Digite as instruções da prova');
//       return false;
//     }
//     return true;
//   }

//   /// Navega para a tela de seleção de questões
//   Future<void> _selecionarQuestoes() async {
//     if (!_validarFormulario()) return;

//     final resultado = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => SelecionarQuestoesScreen(
//           disciplinaId: _disciplinaSelecionada!,
//           tituloProva: _tituloController.text.trim(),
//           instrucoesProva: _instrucoesController.text.trim(),
//         ),
//       ),
//     );

//     if (resultado != null && resultado is Map<String, dynamic>) {
//       await _criarProvaComQuestoes(resultado);
//     }
//   }

//   /// Cria a prova com as questões selecionadas
//   Future<void> _criarProvaComQuestoes(Map<String, dynamic> dados) async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final questoes = dados['questoes'] as List<Map<String, dynamic>>;

//       // Preparar questões para o exame
//       final questoesExame = <String, Map<String, dynamic>>{};
//       for (int i = 0; i < questoes.length; i++) {
//         questoesExame[questoes[i]['id']] = {'ordem': i + 1, 'peso': 1.0};
//       }

//       final exameId = await _examService.criarExame(
//         titulo: dados['titulo'],
//         instrucoes: dados['instrucoes'],
//         disciplinaId: _disciplinaSelecionada!,
//         configuracoes: {
//           'tempoLimite': 3600, // 1 hora em segundos
//           'permiteVoltar': true,
//           'mostraRespostas': false,
//           'pesoTotal': questoes.length.toDouble(),
//           'permiteConsultarMaterial': false,
//           'ordemQuestoes': 'sequencial',
//           'mostraProgresso': true,
//           'questoes': questoesExame,
//         },
//       );

//       if (exameId != null) {
//         MessageUtils.mostrarSucesso(
//           context,
//           'Prova criada com sucesso com ${questoes.length} questões!',
//         );
//         Navigator.pop(context, true); // Retorna true para indicar sucesso
//       } else {
//         MessageUtils.mostrarErro(context, 'Erro ao criar prova');
//       }
//     } catch (e) {
//       MessageUtils.mostrarErro(context, 'Erro ao criar prova: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   /// Cria um container reutilizável com estilo padrão
//   Widget _buildContainer({required Widget child, double? height}) {
//     return Container(
//       width: double.infinity,
//       height: height ?? 50,
//       decoration: BoxDecoration(
//         color: _whiteColor,
//         borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
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
//               padding: const EdgeInsets.all(AppConstants.defaultPadding),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Título
//                   const Center(
//                     child: Text(
//                       'Criar Nova Prova',
//                       style: TextStyle(
//                         color: _textColor,
//                         fontFamily: 'Inter-Bold',
//                         fontSize: 30,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // Campo Curso
//                   const Text(
//                     'Curso',
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
//                             _disciplinaSelecionada =
//                                 null; // Reset disciplina quando curso muda
//                           });
//                         },
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
//                         hint: const Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 16),
//                           child: Text(
//                             'Selecione a disciplina',
//                             style: TextStyle(
//                               color: Colors.black54,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w300,
//                             ),
//                           ),
//                         ),
//                         items: _getDisciplinasFiltradas().map((disciplina) {
//                           return DropdownMenuItem<String>(
//                             value: disciplina['id'],
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                               ),
//                               child: Text(
//                                 disciplina['nome'] ?? 'Disciplina sem nome',
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                         onChanged: _cursoSelecionado != null
//                             ? (String? newValue) {
//                                 setState(() {
//                                   _disciplinaSelecionada = newValue;
//                                 });
//                               }
//                             : null,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // Campo Título
//                   const Text(
//                     'Título da Prova',
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
//                       controller: _tituloController,
//                       decoration: const InputDecoration(
//                         hintText: 'Digite o título da prova',
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
//                   const SizedBox(height: 16),

//                   // Campo de instruções
//                   _buildContainer(
//                     height: 100,
//                     child: TextField(
//                       controller: _instrucoesController,
//                       maxLines: 4,
//                       decoration: const InputDecoration(
//                         hintText: 'Digite as instruções da prova',
//                         hintStyle: TextStyle(
//                           color: Colors.black54,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w300,
//                         ),
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 12,
//                         ),
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
//                           onPressed: _isLoading ? null : _selecionarQuestoes,
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
//                           child: _isLoading
//                               ? const SizedBox(
//                                   width: 20,
//                                   height: 20,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     valueColor: AlwaysStoppedAnimation<Color>(
//                                       Colors.white,
//                                     ),
//                                   ),
//                                 )
//                               : const Text(
//                                   'Selecionar Questões',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
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
