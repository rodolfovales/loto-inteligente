import 'package:flutter_test/flutter_test.dart';
import 'package:loto_inteligente/main.dart';

void main() {
  testWidgets(
    'Loto Inteligente inicia corretamente',
    (tester) async {
      await tester.pumpWidget(
        const LotoInteligenteApp(),
      );

      expect(
        find.text('Loto Inteligente'),
        findsOneWidget,
      );
    },
  );
}

class LotoInteligenteApp extends StatelessWidget {
  const LotoInteligenteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loto Inteligente',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const AppShell(),
    );
  }
}

class Jogo {
  final List<int> dezenas;
  final double score;
  final int pares;
  final int soma;

  const Jogo({
    required this.dezenas,
    required this.score,
    required this.pares,
    required this.soma,
  });
}

class Gerador {
  static Jogo gerar({
    List<int> fixas = const [],
    List<int> excluidas = const [],
  }) {
    final random = Random();
    final proibidas = excluidas.toSet();
    final numeros = <int>{};

    for (final numero in fixas) {
      if (!proibidas.contains(numero) &&
          numero >= 1 &&
          numero <= 25) {
        numeros.add(numero);
      }
    }

    while (numeros.length < 15) {
      final numero = random.nextInt(25) + 1;

      if (!proibidas.contains(numero)) {
        numeros.add(numero);
      }
    }

    final dezenas = numeros.toList()..sort();

    final pares =
        dezenas.where((numero) => numero.isEven).length;

    final soma =
        dezenas.fold<int>(0, (total, numero) => total + numero);

    final equilibrioParidade =
        (100 - ((pares - 7.5).abs() * 18))
            .clamp(0, 100)
            .toDouble();

    final faixas = List<int>.filled(5, 0);

    for (final numero in dezenas) {
      final faixa = min(4, (numero - 1) ~/ 5);
      faixas[faixa]++;
    }

    double erroDistribuicao = 0;

    for (final quantidade in faixas) {
      erroDistribuicao += (quantidade - 3).abs();
    }

    final distribuicao =
        (100 - erroDistribuicao * 10)
            .clamp(0, 100)
            .toDouble();

    double score =
        equilibrioParidade * 0.55 +
        distribuicao * 0.30 +
        15;

    if (soma >= 150 && soma <= 220) {
      score += 5;
    }

    score = score.clamp(0, 100);

    return Jogo(
      dezenas: dezenas,
      score: double.parse(score.toStringAsFixed(1)),
      pares: pares,
      soma: soma,
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int pagina = 0;

  final List<Jogo> jogosSalvos = [];

  @override
  Widget build(BuildContext context) {
    final paginas = [
      DashboardPage(
        jogosSalvos: jogosSalvos.length,
        abrirGerador: () {
          setState(() {
            pagina = 1;
          });
        },
      ),
      GeradorPage(
        salvarJogo: (jogo) {
          setState(() {
            jogosSalvos.add(jogo);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jogo salvo com sucesso!'),
            ),
          );
        },
      ),
      const LaboratorioPage(),
      MeusJogosPage(jogos: jogosSalvos),
      const PerfilPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: paginas[pagina],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: pagina,
        onDestinationSelected: (index) {
          setState(() {
            pagina = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Gerador',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science),
            label: 'Laboratório',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Meus Jogos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final int jogosSalvos;
  final VoidCallback abrirGerador;

  const DashboardPage({
    super.key,
    required this.jogosSalvos,
    required this.abrirGerador,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Olá! 👋',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 4),

        const Text(
          'Bem-vindo ao Loto Inteligente.',
        ),

        const SizedBox(height: 24),

        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRÓXIMO CONCURSO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Lotofácil',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Dados oficiais serão sincronizados '
                  'na próxima etapa.',
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: abrirGerador,
                    icon: const Icon(
                      Icons.auto_awesome,
                    ),
                    label: const Text(
                      'GERAR JOGOS',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: StatCard(
                titulo: 'Jogos salvos',
                valor: '$jogosSalvos',
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: StatCard(
                titulo: 'Melhor resultado',
                valor: '—',
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        const Row(
          children: [
            Expanded(
              child: StatCard(
                titulo: 'Concursos',
                valor: '—',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatCard(
                titulo: 'Acertos 11+',
                valor: '—',
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'O score é um índice estatístico '
                    'interno. Ele não representa garantia '
                    'ou previsão de prêmio.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MeusJogosPage extends StatelessWidget {
  final List<Jogo> jogos;

  const MeusJogosPage({
    super.key,
    required this.jogos,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Meus Jogos',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 18),

        if (jogos.isEmpty)
          const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Nenhum jogo salvo ainda.',
                ),
              ),
            ),
          ),

        ...jogos.asMap().entries.map(
          (entrada) {
            final jogo = entrada.value;

            return Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: Card(
                elevation: 0,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      '${entrada.key + 1}',
                    ),
                  ),
                  title: Text(
                    'Jogo ${entrada.key + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Dezenas: ${jogo.dezenas.join(' - ')}\n'
                    'Score: ${jogo.score} • '
                    'Pares: ${jogo.pares} • '
                    'Soma: ${jogo.soma}',
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class GeradorPage extends StatefulWidget {
  final ValueChanged<Jogo> salvarJogo;

  const GeradorPage({
    super.key,
    required this.salvarJogo,
  });

  @override
  State<GeradorPage> createState() =>
      _GeradorPageState();
}

class _GeradorPageState
    extends State<GeradorPage> {

  final fixasController =
      TextEditingController();

  final excluidasController =
      TextEditingController();

  int quantidade = 5;

  List<Jogo> jogos = [];

  List<int> converterNumeros(String texto) {
    return texto
        .split(RegExp(r'[,;\s]+'))
        .where((item) => item.isNotEmpty)
        .map(int.tryParse)
        .whereType<int>()
        .where((numero) =>
            numero >= 1 && numero <= 25)
        .toSet()
        .toList();
  }

  void gerarJogos() {
    final fixas =
        converterNumeros(fixasController.text);

    final excluidas =
        converterNumeros(
          excluidasController.text,
        );

    if (fixas.any(excluidas.contains)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Uma dezena não pode ser fixa e excluída.',
          ),
        ),
      );
      return;
    }

    if (fixas.length > 15) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Você pode fixar no máximo 15 dezenas.',
          ),
        ),
      );
      return;
    }

    if (excluidas.length > 10) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Para gerar 15 dezenas, deixe pelo menos '
            '15 números disponíveis.',
          ),
        ),
      );
      return;
    }

    setState(() {
      jogos = List.generate(
        quantidade,
        (_) => Gerador.gerar(
          fixas: fixas,
          excluidas: excluidas,
        ),
      );
    });
  }

  @override
  void dispose() {
    fixasController.dispose();
    excluidasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Gerador Inteligente',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Crie combinações para análise '
          'estatística.',
        ),

        const SizedBox(height: 20),

        DropdownButtonFormField<int>(
          value: quantidade,
          decoration: const InputDecoration(
            labelText: 'Quantidade de jogos',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: 1,
              child: Text('1 jogo'),
            ),
            DropdownMenuItem(
              value: 3,
              child: Text('3 jogos'),
            ),
            DropdownMenuItem(
              value: 5,
              child: Text('5 jogos'),
            ),
            DropdownMenuItem(
              value: 10,
              child: Text('10 jogos'),
            ),
            DropdownMenuItem(
              value: 20,
              child: Text('20 jogos'),
            ),
          ],
          onChanged: (valor) {
            setState(() {
              quantidade = valor ?? 5;
            });
          },
        ),

        const SizedBox(height: 12),

        TextField(
          controller: fixasController,
          keyboardType:
              TextInputType.number,
          decoration:
              const InputDecoration(
            labelText: 'Dezenas fixas',
            hintText: 'Ex.: 3, 8, 13',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: excluidasController,
          keyboardType:
              TextInputType.number,
          decoration:
              const InputDecoration(
            labelText: 'Dezenas excluídas',
            hintText: 'Ex.: 4, 10, 20',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: gerarJogos,
            icon: const Icon(
              Icons.auto_awesome,
            ),
            label: const Text(
              'GERAR JOGOS',
            ),
          ),
        ),

        const SizedBox(height: 20),

        ...jogos.asMap().entries.map(
          (entrada) {
            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child: JogoCard(
                jogo: entrada.value,
                indice:
                    entrada.key + 1,
                salvar: () =>
                    widget.salvarJogo(
                  entrada.value,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class JogoCard extends StatelessWidget {
  final Jogo jogo;
  final int indice;
  final VoidCallback salvar;

  const JogoCard({
    super.key,
    required this.jogo,
    required this.indice,
    required this.salvar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'JOGO $indice',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  'Score ${jogo.score}',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  jogo.dezenas.map(
                (numero) {
                  return CircleAvatar(
                    radius: 19,
                    child: Text(
                      numero
                          .toString()
                          .padLeft(2, '0'),
                    ),
                  );
                },
              ).toList(),
            ),

            const Divider(
              height: 26,
            ),

            Text(
              'Pares: ${jogo.pares}   •   '
              'Ímpares: ${15 - jogo.pares}',
            ),

            const SizedBox(height: 5),

            Text(
              'Soma: ${jogo.soma}',
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: salvar,
              icon: const Icon(
                Icons.save_outlined,
              ),
              label: const Text(
                'Salvar jogo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LaboratorioPage
    extends StatelessWidget {

  const LaboratorioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Laboratório',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
                fontWeight:
                    FontWeight.bold,
              ),
        ),

        const SizedBox(height: 18),

        const LaboratorioCard(
          icone: Icons.history,
          titulo: 'Backtest',
          descricao:
              'Teste estratégias usando '
              'concursos históricos.',
        ),

        const LaboratorioCard(
          icone: Icons.compare_arrows,
          titulo:
              'Comparar estratégias',
          descricao:
              'Compare diferentes métodos '
              'sob a mesma metodologia.',
        ),

        const LaboratorioCard(
          icone: Icons.science,
          titulo: 'Monte Carlo',
          descricao:
              'Realize simulações estatísticas.',
        ),

        const LaboratorioCard(
          icone: Icons.analytics_outlined,
          titulo: 'Estatísticas',
          descricao:
              'Frequência, atrasos, '
              'repetições e distribuição.',
        ),
      ],
    );
  }
}

class LaboratorioCard
    extends StatelessWidget {

  final IconData icone;
  final String titulo;
  final String descricao;

  const LaboratorioCard({
    super.key,
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding:
            const EdgeInsets.all(14),
        leading: CircleAvatar(
          child: Icon(icone),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(descricao),
        trailing: const Icon(
          Icons.chevron_right,
        ),
      ),
    );
  }
}

class MeusJogosPage
    extends StatelessWidget {

  final List<Jogo> jogos;

  const MeusJogosPage({
    super.key,
    required this.jogos,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Meus Jogos',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
                fontWeight:
                    FontWeight.bold,
              ),
        ),

        const SizedBox(height: 18),

                if (jogos.isEmpty)
          const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Nenhum jogo salvo ainda.'),
              ),
            ),
          ),

        ...jogos.asMap().entries.map(
          (entrada) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${entrada.key + 1}'),
                  ),
                  title: Text(
                    'Jogo ${entrada.key + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    entrada.value.numeros.join(' - '),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
