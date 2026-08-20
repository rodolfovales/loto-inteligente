import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LotoInteligenteApp());
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

// ============================================================
// MODELO DO JOGO
// ============================================================

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

  Map<String, dynamic> toMap() {
    return {
      'dezenas': dezenas,
      'score': score,
      'pares': pares,
      'soma': soma,
    };
  }

  factory Jogo.fromMap(Map<String, dynamic> map) {
    return Jogo(
      dezenas: List<int>.from(map['dezenas'] as List),
      score: (map['score'] as num).toDouble(),
      pares: (map['pares'] as num).toInt(),
      soma: (map['soma'] as num).toInt(),
    );
  }
}

// ============================================================
// GERADOR INTELIGENTE
// ============================================================

class Gerador {
  static Jogo gerar({
    List<int> fixas = const [],
    List<int> excluidas = const [],
  }) {
    final random = Random();

    final proibidas = excluidas.toSet();
    final numeros = <int>{};

    // Adiciona as dezenas fixas.
    for (final numero in fixas) {
      if (!proibidas.contains(numero) &&
          numero >= 1 &&
          numero <= 25) {
        numeros.add(numero);
      }
    }

    // Completa o jogo até chegar a 15 dezenas.
    while (numeros.length < 15) {
      final numero = random.nextInt(25) + 1;

      if (!proibidas.contains(numero)) {
        numeros.add(numero);
      }
    }

    final dezenas = numeros.toList()..sort();

    // Quantidade de pares.
    final pares =
        dezenas.where((numero) => numero.isEven).length;

    // Soma das dezenas.
    final soma =
        dezenas.fold<int>(0, (total, numero) => total + numero);

    // Equilíbrio entre pares e ímpares.
    final equilibrio =
        (100 - ((pares - 7.5).abs() * 18))
            .clamp(0, 100)
            .toDouble();

    // Distribuição pelas 5 faixas:
    // 01-05
    // 06-10
    // 11-15
    // 16-20
    // 21-25
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

    // Score final.
    double score =
        equilibrio * 0.55 +
        distribuicao * 0.30 +
        15;

    // Bônus para soma dentro da faixa definida.
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

// ============================================================
// APP SHELL
// ============================================================

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const String _chaveJogos = 'jogos_salvos';

  int pagina = 0;

  List<Jogo> jogosSalvos = [];

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarJogos();
  }

  // ==========================================================
  // CARREGAR JOGOS
  // ==========================================================

  Future<void> _carregarJogos() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getStringList(_chaveJogos);

    if (dados != null) {
      try {
        jogosSalvos = dados.map((item) {
          final mapa =
              jsonDecode(item) as Map<String, dynamic>;

          return Jogo.fromMap(mapa);
        }).toList();
      } catch (_) {
        jogosSalvos = [];
      }
    }

    if (mounted) {
      setState(() {
        carregando = false;
      });
    }
  }

  // ==========================================================
  // SALVAR JOGOS
  // ==========================================================

  Future<void> _salvarJogosNoDispositivo() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = jogosSalvos.map((jogo) {
      return jsonEncode(jogo.toMap());
    }).toList();

    await prefs.setStringList(
      _chaveJogos,
      dados,
    );
  }

  // ==========================================================
  // SALVAR UM JOGO
  // ==========================================================

  Future<void> _salvarJogo(Jogo jogo) async {
    setState(() {
      jogosSalvos.add(jogo);
    });

    await _salvarJogosNoDispositivo();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Jogo salvo com sucesso!',
        ),
      ),
    );
  }

  // ==========================================================
  // APAGAR UM JOGO
  // ==========================================================

  Future<void> _apagarJogo(int indice) async {
    if (indice < 0 || indice >= jogosSalvos.length) {
      return;
    }

    setState(() {
      jogosSalvos.removeAt(indice);
    });

    await _salvarJogosNoDispositivo();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Jogo apagado.',
        ),
      ),
    );
  }

  // ==========================================================
  // APAGAR TODOS
  // ==========================================================

  Future<void> _apagarTodosOsJogos() async {
    if (jogosSalvos.isEmpty) {
      return;
    }

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Apagar todos os jogos?',
          ),
          content: const Text(
            'Todos os jogos salvos serão removidos '
            'do aplicativo.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Apagar todos'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) {
      return;
    }

    setState(() {
      jogosSalvos.clear();
    });

    await _salvarJogosNoDispositivo();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Todos os jogos foram apagados.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
        salvarJogo: _salvarJogo,
      ),

      const LaboratorioPage(),

      MeusJogosPage(
        jogos: jogosSalvos,
        apagarJogo: _apagarJogo,
        apagarTodos: _apagarTodosOsJogos,
      ),

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
            icon: Icon(
              Icons.confirmation_number_outlined,
            ),
            selectedIcon: Icon(
              Icons.confirmation_number,
            ),
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

// ============================================================
// DASHBOARD
// ============================================================

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

// ============================================================
// STAT CARD
// ============================================================

class StatCard extends StatelessWidget {
  final String titulo;
  final String valor;

  const StatCard({
    super.key,
    required this.titulo,
    required this.valor,
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
            Text(titulo),

            const SizedBox(height: 8),

            Text(
              valor,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// GERADOR PAGE
// ============================================================

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

class _GeradorPageState extends State<GeradorPage> {
  final fixasController =
      TextEditingController();

  final excluidasController =
      TextEditingController();

  int quantidade = 5;

  List<Jogo> jogos = [];

  // ==========================================================
  // CONVERTER TEXTO EM NÚMEROS
  // ==========================================================

  List<int> converterNumeros(String texto) {
    return texto
        .split(RegExp(r'[,;\s]+'))
        .where((item) => item.isNotEmpty)
        .map(int.tryParse)
        .whereType<int>()
        .where(
          (numero) => numero >= 1 && numero <= 25,
        )
        .toSet()
        .toList();
  }

  // ==========================================================
  // GERAR JOGOS
  // ==========================================================

  void gerarJogos() {
    final fixas =
        converterNumeros(fixasController.text);

    final excluidas =
        converterNumeros(
      excluidasController.text,
    );

    if (fixas.any(excluidas.contains)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Uma dezena não pode ser fixa e excluída.',
          ),
        ),
      );
      return;
    }

    if (fixas.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Você pode fixar no máximo 15 dezenas.',
          ),
        ),
      );
      return;
    }

    if (25 - excluidas.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'É necessário deixar pelo menos 15 '
            'dezenas disponíveis.',
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
          'Crie combinações para análise estatística.',
        ),

        const SizedBox(height: 20),

        DropdownButtonFormField<int>(
          initialValue: quantidade,
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
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Dezenas fixas',
            hintText: 'Ex.: 3, 8, 13',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: excluidasController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
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
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: JogoCard(
                jogo: entrada.value,
                indice: entrada.key + 1,
                salvar: () {
                  widget.salvarJogo(
                    entrada.value,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// JOGO CARD
// ============================================================

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
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  'Score ${jogo.score}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: jogo.dezenas.map(
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

            const Divider(height: 26),

            Text(
              'Pares: ${jogo.pares} • '
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

// ============================================================
// LABORATÓRIO
// ============================================================

class LaboratorioPage extends StatelessWidget {
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
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Ferramentas de análise estatística.',
        ),

        const SizedBox(height: 18),

        LaboratorioCard(
          icone: Icons.history,
          titulo: 'Backtest',
          descricao:
              'Teste estratégias usando concursos históricos.',
          aoTocar: () {
            _mostrarEmDesenvolvimento(
              context,
              'Backtest',
            );
          },
        ),

        LaboratorioCard(
          icone: Icons.compare_arrows,
          titulo: 'Comparar estratégias',
          descricao:
              'Compare diferentes métodos sob a mesma metodologia.',
          aoTocar: () {
            _mostrarEmDesenvolvimento(
              context,
              'Comparar estratégias',
            );
          },
        ),

        LaboratorioCard(
          icone: Icons.science,
          titulo: 'Monte Carlo',
          descricao:
              'Realize simulações estatísticas.',
          aoTocar: () {
            _mostrarEmDesenvolvimento(
              context,
              'Monte Carlo',
            );
          },
        ),

        LaboratorioCard(
          icone: Icons.analytics_outlined,
          titulo: 'Estatísticas',
          descricao:
              'Frequência, atrasos, repetições e distribuição.',
          aoTocar: () {
            _mostrarEmDesenvolvimento(
              context,
              'Estatísticas',
            );
          },
        ),
      ],
    );
  }

  static void _mostrarEmDesenvolvimento(
    BuildContext context,
    String recurso,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$recurso será implementado na próxima etapa.',
        ),
      ),
    );
  }
}

// ============================================================
// LABORATÓRIO CARD
// ============================================================

class LaboratorioCard extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback aoTocar;

  const LaboratorioCard({
    super.key,
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),

        leading: CircleAvatar(
          child: Icon(icone),
        ),

        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(descricao),

        trailing: const Icon(
          Icons.chevron_right,
        ),

        onTap: aoTocar,
      ),
    );
  }
}

// ============================================================
// MEUS JOGOS
// ============================================================

class MeusJogosPage extends StatelessWidget {
  final List<Jogo> jogos;

  final Future<void> Function(int indice) apagarJogo;

  final Future<void> Function() apagarTodos;

  const MeusJogosPage({
    super.key,
    required this.jogos,
    required this.apagarJogo,
    required this.apagarTodos,
  });

  // ==========================================================
  // CONFIRMAR APAGAMENTO
  // ==========================================================

  Future<void> _confirmarApagar(
    BuildContext context,
    int indice,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Apagar jogo?',
          ),
          content: const Text(
            'Deseja realmente apagar este jogo?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Apagar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmou == true) {
      await apagarJogo(indice);
    }
  }

  // ==========================================================
  // CONFIRMAR APAGAR TODOS
  // ==========================================================

  Future<void> _confirmarApagarTodos(
    BuildContext context,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Apagar todos os jogos?',
          ),
          content: const Text(
            'Essa ação removerá todos os jogos '
            'salvos do aplicativo.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Apagar todos',
              ),
            ),
          ],
        );
      },
    );

    if (confirmou == true) {
      await apagarTodos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Meus Jogos',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            if (jogos.isNotEmpty)
              IconButton(
                tooltip: 'Apagar todos',
                onPressed: () {
                  _confirmarApagarTodos(
                    context,
                  );
                },
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                ),
              ),
          ],
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
            final indice = entrada.key;
            final jogo = entrada.value;

            return Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: Card(
                elevation: 0,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  leading: CircleAvatar(
                    child: Text(
                      '${indice + 1}',
                    ),
                  ),

                  title: Text(
                    'Jogo ${indice + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 6,
                    ),
                    child: Text(
                      'Dezenas: '
                      '${jogo.dezenas.join(' - ')}\n'
                      'Score: ${jogo.score} • '
                      'Pares: ${jogo.pares} • '
                      'Soma: ${jogo.soma}',
                    ),
                  ),

                  isThreeLine: true,

                  trailing: IconButton(
                    tooltip: 'Apagar jogo',
                    onPressed: () {
                      _confirmarApagar(
                        context,
                        indice,
                      );
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
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

// ============================================================
// PERFIL
// ============================================================

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() =>
      _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  bool notificacoes = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Perfil',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 18),

        const Card(
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                Icons.person,
              ),
            ),
            title: Text(
              'Usuário',
            ),
            subtitle: Text(
              'Loto Inteligente',
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          elevation: 0,
          child: SwitchListTile(
            value: notificacoes,
            onChanged: (valor) {
              setState(() {
                notificacoes = valor;
              });
            },
            title: const Text(
              'Notificações',
            ),
            subtitle: const Text(
              'Ativar alertas do aplicativo.',
            ),
          ),
        ),

        const SizedBox(height: 12),

        const Card(
          elevation: 0,
          child: ListTile(
            leading: Icon(
              Icons.login,
            ),
            title: Text(
              'Conta Google',
            ),
            subtitle: Text(
              'Login com Google será conectado ao Firebase.',
            ),
            trailing: Icon(
              Icons.chevron_right,
            ),
          ),
        ),

        const SizedBox(height: 12),

        const Card(
          elevation: 0,
          child: ListTile(
            leading: Icon(
              Icons.security_outlined,
            ),
            title: Text(
              'Segurança',
            ),
            subtitle: Text(
              'Configurações de segurança da conta.',
            ),
          ),
        ),

        const SizedBox(height: 12),

        const Card(
          elevation: 0,
          child: ListTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
            ),
            title: Text(
              'Privacidade',
            ),
            subtitle: Text(
              'Configurações de privacidade do aplicativo.',
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Center(
          child: Text(
            'Loto Inteligente • Versão 1.0.0',
            style: TextStyle(
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
