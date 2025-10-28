// import '../services/course_service.dart';
// import '../services/discipline_service.dart';

// /// Utilitário para popular o Firebase com dados de exemplo
// ///
// /// Este arquivo contém métodos para adicionar dados iniciais
// /// ao Firebase para testes e demonstração.
// class FirebaseDataPopulator {
//   static final CourseService _courseService = CourseService();
//   static final DisciplineService _disciplineService = DisciplineService();

//   /// Popula o Firebase com cursos de exemplo
//   static Future<void> popularCursos() async {
//     print('🚀 Iniciando população de cursos...');

//     final cursos = [
//       {
//         'nome': 'Engenharia de Software',
//         'descricao':
//             'Curso focado no desenvolvimento de software e sistemas computacionais',
//         'duracao': 8,
//         'idEsperado': 'engenharia_de_software', // ID que será gerado
//       },
//       {
//         'nome': 'Medicina',
//         'descricao':
//             'Curso de formação médica com foco em diagnóstico e tratamento',
//         'duracao': 12,
//         'idEsperado': 'medicina',
//       },
//       {
//         'nome': 'Direito',
//         'descricao': 'Curso de formação jurídica e advocacia',
//         'duracao': 10,
//         'idEsperado': 'direito',
//       },
//       {
//         'nome': 'Administração',
//         'descricao': 'Curso de gestão empresarial e administração de negócios',
//         'duracao': 8,
//         'idEsperado': 'administração',
//       },
//       {
//         'nome': 'Psicologia',
//         'descricao': 'Curso de formação em psicologia clínica e comportamental',
//         'duracao': 10,
//         'idEsperado': 'psicologia',
//       },
//     ];

//     for (final curso in cursos) {
//       try {
//         final cursoId = await _courseService.criarCurso(
//           curso['nome'] as String,
//           curso['descricao'] as String,
//         );

//         if (cursoId != null) {
//           await _courseService.atualizarCurso(cursoId, {
//             'duracao': curso['duracao'] as int,
//           });
//           print('✅ Curso criado: ${curso['nome']} (ID: $cursoId)');
//         } else {
//           print('❌ Erro ao criar curso: ${curso['nome']}');
//         }
//       } catch (e) {
//         print('❌ Erro ao criar curso ${curso['nome']}: $e');
//       }
//     }

//     print('🎉 População de cursos concluída!');
//   }

//   /// Popula o Firebase com disciplinas de exemplo
//   static Future<void> popularDisciplinas() async {
//     print('🚀 Iniciando população de disciplinas...');

//     final disciplinas = [
//       // Engenharia de Software
//       {
//         'nome': 'Programação I',
//         'semestre': 1,
//         'cargaHoraria': 60,
//         'cursoId': 'engenharia_de_software',
//       },
//       {
//         'nome': 'Algoritmos e Estruturas de Dados',
//         'semestre': 2,
//         'cargaHoraria': 80,
//         'cursoId': 'engenharia_de_software',
//       },
//       {
//         'nome': 'Banco de Dados',
//         'semestre': 3,
//         'cargaHoraria': 60,
//         'cursoId': 'engenharia_de_software',
//       },
//       {
//         'nome': 'Engenharia de Software',
//         'semestre': 4,
//         'cargaHoraria': 80,
//         'cursoId': 'engenharia_de_software',
//       },
//       {
//         'nome': 'Desenvolvimento Web',
//         'semestre': 5,
//         'cargaHoraria': 60,
//         'cursoId': 'engenharia_de_software',
//       },
//       {
//         'nome': 'Desenvolvimento Mobile',
//         'semestre': 6,
//         'cargaHoraria': 60,
//         'cursoId': 'engenharia_de_software',
//       },
//       {
//         'nome': 'Inteligência Artificial',
//         'semestre': 7,
//         'cargaHoraria': 60,
//         'cursoId': 'engenharia_de_software',
//       },
//       {
//         'nome': 'Projeto de Software',
//         'semestre': 8,
//         'cargaHoraria': 80,
//         'cursoId': 'engenharia_de_software',
//       },

//       // Medicina
//       {
//         'nome': 'Anatomia Humana',
//         'semestre': 1,
//         'cargaHoraria': 120,
//         'cursoId': 'medicina',
//       },
//       {
//         'nome': 'Fisiologia',
//         'semestre': 2,
//         'cargaHoraria': 100,
//         'cursoId': 'medicina',
//       },
//       {
//         'nome': 'Bioquímica',
//         'semestre': 3,
//         'cargaHoraria': 80,
//         'cursoId': 'medicina',
//       },
//       {
//         'nome': 'Patologia',
//         'semestre': 4,
//         'cargaHoraria': 100,
//         'cursoId': 'medicina',
//       },
//       {
//         'nome': 'Farmacologia',
//         'semestre': 5,
//         'cargaHoraria': 80,
//         'cursoId': 'medicina',
//       },
//       {
//         'nome': 'Clínica Médica',
//         'semestre': 6,
//         'cargaHoraria': 120,
//         'cursoId': 'medicina',
//       },

//       // Direito
//       {
//         'nome': 'Introdução ao Direito',
//         'semestre': 1,
//         'cargaHoraria': 60,
//         'cursoId': 'direito',
//       },
//       {
//         'nome': 'Direito Constitucional',
//         'semestre': 2,
//         'cargaHoraria': 80,
//         'cursoId': 'direito',
//       },
//       {
//         'nome': 'Direito Civil',
//         'semestre': 3,
//         'cargaHoraria': 80,
//         'cursoId': 'direito',
//       },
//       {
//         'nome': 'Direito Penal',
//         'semestre': 4,
//         'cargaHoraria': 80,
//         'cursoId': 'direito',
//       },
//       {
//         'nome': 'Direito Processual',
//         'semestre': 5,
//         'cargaHoraria': 80,
//         'cursoId': 'direito',
//       },
//       {
//         'nome': 'Direito Trabalhista',
//         'semestre': 6,
//         'cargaHoraria': 60,
//         'cursoId': 'direito',
//       },

//       // Administração
//       {
//         'nome': 'Introdução à Administração',
//         'semestre': 1,
//         'cargaHoraria': 60,
//         'cursoId': 'administração',
//       },
//       {
//         'nome': 'Matemática Financeira',
//         'semestre': 2,
//         'cargaHoraria': 60,
//         'cursoId': 'administração',
//       },
//       {
//         'nome': 'Contabilidade',
//         'semestre': 3,
//         'cargaHoraria': 80,
//         'cursoId': 'administração',
//       },
//       {
//         'nome': 'Marketing',
//         'semestre': 4,
//         'cargaHoraria': 60,
//         'cursoId': 'administração',
//       },
//       {
//         'nome': 'Gestão de Pessoas',
//         'semestre': 5,
//         'cargaHoraria': 60,
//         'cursoId': 'administração',
//       },
//       {
//         'nome': 'Gestão Financeira',
//         'semestre': 6,
//         'cargaHoraria': 80,
//         'cursoId': 'administração',
//       },

//       // Psicologia
//       {
//         'nome': 'Introdução à Psicologia',
//         'semestre': 1,
//         'cargaHoraria': 60,
//         'cursoId': 'psicologia',
//       },
//       {
//         'nome': 'Psicologia do Desenvolvimento',
//         'semestre': 2,
//         'cargaHoraria': 80,
//         'cursoId': 'psicologia',
//       },
//       {
//         'nome': 'Psicologia Social',
//         'semestre': 3,
//         'cargaHoraria': 60,
//         'cursoId': 'psicologia',
//       },
//       {
//         'nome': 'Psicopatologia',
//         'semestre': 4,
//         'cargaHoraria': 80,
//         'cursoId': 'psicologia',
//       },
//       {
//         'nome': 'Psicoterapia',
//         'semestre': 5,
//         'cargaHoraria': 80,
//         'cursoId': 'psicologia',
//       },
//       {
//         'nome': 'Neuropsicologia',
//         'semestre': 6,
//         'cargaHoraria': 60,
//         'cursoId': 'psicologia',
//       },
//     ];

//     for (final disciplina in disciplinas) {
//       try {
//         final disciplinaId = await _disciplineService.criarDisciplina(
//           disciplina['nome'] as String,
//           disciplina['semestre'] as int,
//           cursoId: disciplina['cursoId'] as String?,
//         );

//         if (disciplinaId != null) {
//           await _disciplineService.atualizarDisciplina(disciplinaId, {
//             'cargaHoraria': disciplina['cargaHoraria'] as int,
//             'descricao': 'Disciplina do curso',
//           });
//           print('✅ Disciplina criada: ${disciplina['nome']}');
//         } else {
//           print('❌ Erro ao criar disciplina: ${disciplina['nome']}');
//         }
//       } catch (e) {
//         print('❌ Erro ao criar disciplina ${disciplina['nome']}: $e');
//       }
//     }

//     print('🎉 População de disciplinas concluída!');
//   }

//   /// Popula todos os dados de exemplo
//   static Future<void> popularTodosDados() async {
//     print('🚀 Iniciando população completa do Firebase...');

//     await popularCursos();
//     await Future.delayed(const Duration(seconds: 2)); // Aguarda 2 segundos
//     await popularDisciplinas();

//     print('🎉 População completa concluída!');
//     print('📊 Dados adicionados:');
//     print('   - 5 cursos');
//     print('   - 30 disciplinas');
//   }
// }
