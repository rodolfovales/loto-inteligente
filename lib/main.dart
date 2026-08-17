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
      pares: map['pares'] as int,
      soma: map['soma'] as int,
    );
  }
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

    final equilibrio =
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
        equilibrio * 0.55 +
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

  List<Jogo> jogosSalvos = [];

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarJogos();
  }

  Future<void> _carregarJogos() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getStringList('jogos_salvos') ?? [];

    final jogos = <Jogo>[];

    for (final item in dados) {
      try {
        final mapa = jsonDecode(item) as Map<String, dynamic>;
        jogos.add(Jogo.fromMap(mapa));
      } catch (_) {
        // Ignora dados antigos ou corrompidos.
      }
    }

    if (!mounted) return;

    setState(() {
      jogosSalvos = jogos;
      carregando = false;
    });
  }

  Future<void> _salvarTodosOsJogos() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = jogosSalvos
        .map((jogo) => jsonEncode(jogo.toMap()))
        .toList();

    await prefs.setStringList('jogos_salvos', dados);
  }

  Future<void> _salvarJogo(Jogo jogo) async {
    setState(() {
      jogosSalvos.add(jogo);
    });

    await _salvarTodosOsJogos();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jogo salvo com sucesso!'),
      ),
    );
  }

  Future<void> _apagarJogo(int indice) async {
    setState(() {
      jogosSalvos.removeAt(indice);
    });

    await _salvarTodosOsJogos();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jogo apagado.'),
      ),
    );
  }

  Future<void> _apagarTodosOsJogos() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Apagar todos os jogos?'),
          content: const Text(
            'Todos os jogos salvos serão removidos. '
            'Essa ação não poderá ser desfeita.',
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

    if (confirmou != true) return;

    setState(() {
      jogosSalvos.clear();
    });

    await _salvarTodosOsJogos();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todos os jogos foram apagados.'),
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
        .where(
          (numero) => numero >= 1 && numero <= 25,
        )
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
            'É necessário deixar pelo menos '
            '15 dezenas disponíveis.',
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
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 18),
        const LaboratorioCard(
          icone: Icons.history,
          titulo: 'Backtest',
          descricao:
              'Teste estratégias usando concursos históricos.',
        ),
        const LaboratorioCard(
          icone: Icons.compare_arrows,
          titulo: 'Comparar estratégias',
          descricao:
              'Compare diferentes métodos sob a mesma metodologia.',
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
              'Frequência, atrasos, repetições e distribuição.',
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
      ),
    );
  }
}

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

  Future<void> _confirmarApagar(
    BuildContext context,
    int indice,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Apagar jogo?'),
          content: const Text(
            'Deseja realmente apagar este jogo?',
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
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );

    if (confirmou == true) {
      await apagarJogo(indice);
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
                onPressed: apagarTodos,
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
                  subtitle: Text(
                    'Dezenas: '
                    '${jogo.dezenas.join(' - ')}\n'
                    'Score: ${jogo.score} • '
                    'Pares: ${jogo.pares} • '
                    'Soma: ${jogo.soma}',
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
              child: Icon(Icons.person),
            ),
            title: Text('Usuário'),
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
        const Card(
          elevation: 0,
          child: ListTile(
            leading: Icon(
              Icons.security_outlined,
            ),
            title: Text('Segurança'),
            subtitle: Text(
              'Autenticação online será integrada posteriormente.',
            ),
          ),
        ),
        const Card(
          elevation: 0,
          child: ListTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
            ),
            title: Text('Privacidade'),
            subtitle: Text(
              'Configurações de privacidade serão adicionadas à versão final.',
            ),
          ),
        ),
      ],
    );
  }
}
