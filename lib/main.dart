import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kJcPadrao = 'Johrei Center Betim';
const kAccent = Color(0xFF1B5E20);
const kSoftGreen = Color(0xFFE8F5E9);
const kTextDark = Color(0xFF1F1F1F);

final brDate = DateFormat('dd/MM/yyyy');
final brMoney = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final brMoneyInput = NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2);

const kFiltroTodos = 'Todos';
const kFiltroTodasOrigens = 'Todas';
const kTiposPessoaDonativo = ['Membro', 'Frequentador', 'Outro'];
const kTiposPessoaFrequencia = ['Membro', 'Frequentador', '1ª vez'];
const kTiposDonativo = ['Mensal', 'Diário', 'Construção', 'Prece', 'Reconsagração', 'Revista', 'Sorei Saishi', 'Outro'];
const kOrigensDonativo = ['Urna', 'Transferência', 'Online'];
const kTiposOrigemNomeDonativo = ['Pessoa', 'Referencia'];
const kTiposEventoPadrao = ['Dia a dia', 'Culto Mensal', 'Oração pela Construção do Paraíso no Lar'];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProjetoShinkenApp());
}

class ProjetoShinkenApp extends StatefulWidget {
  const ProjetoShinkenApp({super.key});

  @override
  State<ProjetoShinkenApp> createState() => _ProjetoShinkenAppState();
}

class _ProjetoShinkenAppState extends State<ProjetoShinkenApp> {
  final AppStore store = AppStore();

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Projeto Shinken',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: kAccent),
            scaffoldBackgroundColor: const Color(0xFFF7F8F5),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              backgroundColor: Color(0xFFF7F8F5),
              foregroundColor: kTextDark,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: Colors.white,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDADFD8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDADFD8)),
              ),
            ),
          ),
          home: store.isLoading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : MainShell(store: store),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.store});
  final AppStore store;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(store: widget.store),
      DonativosPage(store: widget.store),
      FrequenciaPage(store: widget.store),
      PessoasPage(store: widget.store),
      MaisPage(store: widget.store),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Projeto Shinken', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text(kJcPadrao, style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Painel'),
          NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined), selectedIcon: Icon(Icons.volunteer_activism), label: 'Donativos'),
          NavigationDestination(icon: Icon(Icons.event_available_outlined), selectedIcon: Icon(Icons.event_available), label: 'Frequência'),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt), label: 'Pessoas'),
          NavigationDestination(icon: Icon(Icons.apps_outlined), selectedIcon: Icon(Icons.apps), label: 'Mais'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalMes = store.totalDonativosMes(now);
    final presencasMes = store.presencasMes(now);
    final resumo = store.decendios(now);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Visão geral'),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            KpiCard(title: 'Pessoas', value: '${store.pessoas.length}', icon: Icons.people_alt),
            KpiCard(title: 'Presenças/mês', value: '$presencasMes', icon: Icons.event_available),
            KpiCard(title: 'Donativos/mês', value: brMoney.format(totalMes), icon: Icons.volunteer_activism),
            KpiCard(title: 'Experiências', value: '${store.experiencias.length}', icon: Icons.auto_stories),
          ],
        ),
        const SizedBox(height: 24),
        const SectionTitle('Donativos por decêndio'),
        for (final item in resumo)
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: kSoftGreen, child: Text('${item.numero}º')),
              title: Text(item.rotulo, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${item.quantidade} lançamento(s)'),
              trailing: Text(brMoney.format(item.total), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}

class DonativosPage extends StatefulWidget {
  const DonativosPage({super.key, required this.store});
  final AppStore store;

  @override
  State<DonativosPage> createState() => _DonativosPageState();
}

class _DonativosPageState extends State<DonativosPage> {
  final buscaController = TextEditingController();
  String busca = '';
  String origemSelecionada = kFiltroTodasOrigens;
  DateTime? dataInicial;
  DateTime? dataFinal;

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  List<Donativo> get dadosFiltrados {
    final termo = normalizeText(busca);
    final inicio = dataInicial == null ? null : dateOnly(dataInicial!);
    final fim = dataFinal == null ? null : dateOnly(dataFinal!);

    final dados = widget.store.donativos.where((item) {
      final dataItem = dateOnly(item.data);
      final textoBusca = normalizeText('${item.nome} ${item.tipoDonativo} ${item.tipoDonativoManual} ${item.origem} ${item.subtipo}');
      final matchBusca = termo.isEmpty || textoBusca.contains(termo);
      final matchOrigem = origemSelecionada == kFiltroTodasOrigens || item.origem == origemSelecionada;
      final matchInicio = inicio == null || !dataItem.isBefore(inicio);
      final matchFim = fim == null || !dataItem.isAfter(fim);
      return matchBusca && matchOrigem && matchInicio && matchFim;
    }).toList();

    dados.sort((a, b) {
      final byDate = b.data.compareTo(a.data);
      if (byDate != 0) return byDate;
      return b.id.compareTo(a.id);
    });
    return dados;
  }

  bool get temFiltrosAtivos => busca.trim().isNotEmpty || origemSelecionada != kFiltroTodasOrigens || dataInicial != null || dataFinal != null;

  void limparFiltros() {
    setState(() {
      buscaController.clear();
      busca = '';
      origemSelecionada = kFiltroTodasOrigens;
      dataInicial = null;
      dataFinal = null;
    });
  }

  Future<void> selecionarData({required bool inicio}) async {
    final atual = inicio ? dataInicial : dataFinal;
    final selecionada = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: atual ?? DateTime.now(),
    );
    if (selecionada == null) return;

    setState(() {
      if (inicio) {
        dataInicial = selecionada;
        if (dataFinal != null && dateOnly(dataFinal!).isBefore(dateOnly(selecionada))) dataFinal = selecionada;
      } else {
        dataFinal = selecionada;
        if (dataInicial != null && dateOnly(dataInicial!).isAfter(dateOnly(selecionada))) dataInicial = selecionada;
      }
    });
  }

  Future<void> abrirNovo() async {
    await openSheet(context, DonativoForm(store: widget.store));
  }

  Future<void> abrirEdicao(Donativo item) async {
    await openSheet(context, DonativoForm(store: widget.store, initialValue: item));
  }

  Future<void> confirmarExclusao(Donativo item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: Text('Deseja excluir o donativo de ${item.nome.isEmpty ? 'Sem nome' : item.nome} em ${brDate.format(item.data)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmar != true) return;
    await widget.store.deleteDonativo(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Donativo excluído.')));
  }

  @override
  Widget build(BuildContext context) {
    final dados = dadosFiltrados;
    final totalFiltrado = widget.store.totalizarDonativos(dados);
    final resumoDecendios = widget.store.resumirDecendios(dados);
    final largura = MediaQuery.sizeOf(context).width;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeaderWithAction(
          title: 'Donativos',
          subtitle: 'Lançamentos, filtros, edição, exclusão e totais.',
          buttonLabel: 'Novo',
          onPressed: abrirNovo,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Filtros', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                    if (temFiltrosAtivos)
                      TextButton.icon(onPressed: limparFiltros, icon: const Icon(Icons.filter_alt_off_outlined), label: const Text('Limpar')),
                  ],
                ),
                SearchBox(
                  controller: buscaController,
                  hintText: 'Buscar por nome, tipo, origem ou subtipo',
                  onChanged: (v) => setState(() => busca = v),
                ),
                const SizedBox(height: 12),
                Text('Origem', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final origem in [kFiltroTodasOrigens, ...kOrigensDonativo])
                      ChoiceChip(
                        label: Text(origem),
                        selected: origemSelecionada == origem,
                        onSelected: (_) => setState(() => origemSelecionada = origem),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CompactDateFilterField(
                        label: 'Data inicial',
                        value: dataInicial,
                        onTap: () => selecionarData(inicio: true),
                        onClear: dataInicial == null ? null : () => setState(() => dataInicial = null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CompactDateFilterField(
                        label: 'Data final',
                        value: dataFinal,
                        onTap: () => selecionarData(inicio: false),
                        onClear: dataFinal == null ? null : () => setState(() => dataFinal = null),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SummaryStatTile(icon: Icons.payments_outlined, title: 'Total filtrado', value: brMoney.format(totalFiltrado), subtitle: 'Soma dos registros'),
            SummaryStatTile(icon: Icons.receipt_long_outlined, title: 'Lançamentos', value: '${dados.length}', subtitle: 'Registros encontrados'),
            SummaryStatTile(icon: Icons.date_range_outlined, title: 'Período', value: formatPeriodo(dataInicial, dataFinal), subtitle: 'Filtro aplicado'),
          ],
        ),
        const SizedBox(height: 20),
        const SectionTitle('Totais por decêndio'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in resumoDecendios)
              DecendioStatCard(resumo: item, width: largura > 760 ? (largura - 72) / 3 : double.infinity),
          ],
        ),
        const SizedBox(height: 20),
        const SectionTitle('Lançamentos'),
        for (final item in dados)
          Card(
            child: ListTile(
              onTap: () => abrirEdicao(item),
              leading: const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.volunteer_activism, color: kAccent)),
              title: Text(item.nome.isEmpty ? 'Sem nome' : item.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${brDate.format(item.data)} • ${item.tipoDonativoExibicao} • ${item.origem} • ${item.subtipo}'),
              trailing: SizedBox(
                width: 138,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        brMoney.format(item.valor),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'editar') await abrirEdicao(item);
                        if (value == 'excluir') await confirmarExclusao(item);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                        PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        EmptyState(show: dados.isEmpty, message: 'Nenhum donativo encontrado.'),
      ],
    );
  }
}


class FrequenciaPage extends StatefulWidget {
  const FrequenciaPage({super.key, required this.store});
  final AppStore store;

  @override
  State<FrequenciaPage> createState() => _FrequenciaPageState();
}

class _FrequenciaPageState extends State<FrequenciaPage> {
  final buscaController = TextEditingController();
  String busca = '';
  String tipoEventoSelecionado = kFiltroTodos;
  String categoriaSelecionada = kFiltroTodos;
  DateTime? dataInicial;
  DateTime? dataFinal;

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  List<String> get tiposEvento {
    final set = <String>{...kTiposEventoPadrao, ...widget.store.frequencias.map((e) => e.tipoEvento).where((e) => e.trim().isNotEmpty)};
    final lista = set.toList()..sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
    return [kFiltroTodos, ...lista];
  }

  List<Frequencia> get dadosFiltrados {
    final termo = normalizeText(busca);
    final inicio = dataInicial == null ? null : dateOnly(dataInicial!);
    final fim = dataFinal == null ? null : dateOnly(dataFinal!);

    final dados = widget.store.frequencias.where((item) {
      final dataItem = dateOnly(item.data);
      final textoBusca = normalizeText('${item.nome} ${item.tipoEvento} ${item.tipoPessoaAtual} ${item.observacao}');
      final matchBusca = termo.isEmpty || textoBusca.contains(termo);
      final matchEvento = tipoEventoSelecionado == kFiltroTodos || item.tipoEvento == tipoEventoSelecionado;
      final matchCategoria = categoriaSelecionada == kFiltroTodos || item.tipoPessoaAtual == categoriaSelecionada;
      final matchInicio = inicio == null || !dataItem.isBefore(inicio);
      final matchFim = fim == null || !dataItem.isAfter(fim);
      return matchBusca && matchEvento && matchCategoria && matchInicio && matchFim;
    }).toList();

    dados.sort((a, b) {
      final byDate = b.data.compareTo(a.data);
      if (byDate != 0) return byDate;
      return normalizeText(a.nome).compareTo(normalizeText(b.nome));
    });
    return dados;
  }

  bool get temFiltrosAtivos => busca.trim().isNotEmpty || tipoEventoSelecionado != kFiltroTodos || categoriaSelecionada != kFiltroTodos || dataInicial != null || dataFinal != null;

  void limparFiltros() {
    setState(() {
      buscaController.clear();
      busca = '';
      tipoEventoSelecionado = kFiltroTodos;
      categoriaSelecionada = kFiltroTodos;
      dataInicial = null;
      dataFinal = null;
    });
  }

  Future<void> selecionarData({required bool inicio}) async {
    final atual = inicio ? dataInicial : dataFinal;
    final selecionada = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: atual ?? DateTime.now(),
    );
    if (selecionada == null) return;

    setState(() {
      if (inicio) {
        dataInicial = selecionada;
        if (dataFinal != null && dateOnly(dataFinal!).isBefore(dateOnly(selecionada))) dataFinal = selecionada;
      } else {
        dataFinal = selecionada;
        if (dataInicial != null && dateOnly(dataInicial!).isAfter(dateOnly(selecionada))) dataInicial = selecionada;
      }
    });
  }

  Future<void> abrirNovo() async {
    await openSheet(context, FrequenciaForm(store: widget.store));
  }

  Future<void> abrirEdicao(Frequencia item) async {
    await openSheet(context, FrequenciaForm(store: widget.store, initialValue: item));
  }

  Future<void> confirmarExclusao(Frequencia item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir presença?'),
        content: Text('Deseja excluir a presença de ${item.nome} em ${brDate.format(item.data)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmar != true) return;
    await widget.store.deleteFrequencia(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presença excluída.')));
  }

  Map<String, int> contarPorCategoria(List<Frequencia> dados) {
    final map = <String, int>{};
    for (final item in dados) {
      final chave = item.tipoPessoaAtual.trim().isEmpty ? 'Sem categoria' : item.tipoPessoaAtual;
      map[chave] = (map[chave] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> contarPorEvento(List<Frequencia> dados) {
    final map = <String, int>{};
    for (final item in dados) {
      final chave = item.tipoEvento.trim().isEmpty ? 'Sem evento' : item.tipoEvento;
      map[chave] = (map[chave] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final dados = dadosFiltrados;
    final porCategoria = contarPorCategoria(dados);
    final porEvento = contarPorEvento(dados);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeaderWithAction(
          title: 'Frequência',
          subtitle: 'Lançamentos, filtros, edição, exclusão e bloqueio de duplicidade.',
          buttonLabel: 'Lançar',
          onPressed: abrirNovo,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Filtros', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                    if (temFiltrosAtivos)
                      TextButton.icon(onPressed: limparFiltros, icon: const Icon(Icons.filter_alt_off_outlined), label: const Text('Limpar')),
                  ],
                ),
                SearchBox(
                  controller: buscaController,
                  hintText: 'Buscar por nome, evento, categoria ou observação',
                  onChanged: (v) => setState(() => busca = v),
                ),
                const SizedBox(height: 12),
                AppDropdown(
                  value: tipoEventoSelecionado,
                  labelText: 'Tipo de evento',
                  items: tiposEvento,
                  onChanged: (v) => setState(() => tipoEventoSelecionado = v),
                ),
                const SizedBox(height: 12),
                AppDropdown(
                  value: categoriaSelecionada,
                  labelText: 'Categoria',
                  items: [kFiltroTodos, ...kTiposPessoaFrequencia],
                  onChanged: (v) => setState(() => categoriaSelecionada = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CompactDateFilterField(
                        label: 'Data inicial',
                        value: dataInicial,
                        onTap: () => selecionarData(inicio: true),
                        onClear: dataInicial == null ? null : () => setState(() => dataInicial = null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CompactDateFilterField(
                        label: 'Data final',
                        value: dataFinal,
                        onTap: () => selecionarData(inicio: false),
                        onClear: dataFinal == null ? null : () => setState(() => dataFinal = null),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SummaryStatTile(icon: Icons.event_available_outlined, title: 'Presenças', value: '${dados.length}', subtitle: 'Registros filtrados'),
            SummaryStatTile(icon: Icons.date_range_outlined, title: 'Período', value: formatPeriodo(dataInicial, dataFinal), subtitle: 'Filtro aplicado'),
            SummaryStatTile(icon: Icons.people_alt_outlined, title: 'Pessoas únicas', value: '${dados.map((e) => normalizeText(e.nome)).toSet().length}', subtitle: 'Nomes distintos'),
          ],
        ),
        const SizedBox(height: 20),
        const SectionTitle('Resumo por categoria'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in porCategoria.entries) InfoChip(icon: Icons.person_outline, label: '${entry.key}: ${entry.value}'),
          ],
        ),
        const SizedBox(height: 20),
        const SectionTitle('Resumo por evento'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in porEvento.entries) InfoChip(icon: Icons.event_note_outlined, label: '${entry.key}: ${entry.value}'),
          ],
        ),
        const SizedBox(height: 20),
        const SectionTitle('Presenças'),
        for (final item in dados)
          Card(
            child: ListTile(
              onTap: () => abrirEdicao(item),
              leading: const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.event_available, color: kAccent)),
              title: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${brDate.format(item.data)} • ${item.tipoEvento} • ${item.tipoPessoaAtual}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'editar') await abrirEdicao(item);
                  if (value == 'excluir') await confirmarExclusao(item);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                ],
              ),
            ),
          ),
        EmptyState(show: dados.isEmpty, message: 'Nenhuma presença encontrada.'),
      ],
    );
  }
}


class PessoasPage extends StatefulWidget {
  const PessoasPage({super.key, required this.store});
  final AppStore store;

  @override
  State<PessoasPage> createState() => _PessoasPageState();
}

class _PessoasPageState extends State<PessoasPage> {
  String busca = '';

  @override
  Widget build(BuildContext context) {
    final dados = widget.store.pessoas.where((p) => p.nome.toLowerCase().contains(busca.toLowerCase())).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeaderWithAction(
          title: 'Pessoas',
          subtitle: 'Cadastro base para módulos e relatórios.',
          buttonLabel: 'Adicionar',
          onPressed: () => openSheet(context, PessoaForm(store: widget.store)),
        ),
        SearchBox(onChanged: (v) => setState(() => busca = v)),
        const SizedBox(height: 12),
        for (final item in dados)
          Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.person, color: kAccent)),
              title: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${item.tipoPessoaAtual} • ${item.qtdPresencas} presença(s)'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        EmptyState(show: dados.isEmpty, message: 'Nenhuma pessoa encontrada.'),
      ],
    );
  }
}

class MaisPage extends StatelessWidget {
  const MaisPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Outros módulos'),
        MenuTile(
          icon: Icons.auto_stories,
          title: 'Experiência de Fé',
          subtitle: '${store.experiencias.length} registro(s)',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExperienciasPage(store: store))),
        ),
        MenuTile(
          icon: Icons.link,
          title: 'Referências',
          subtitle: '${store.referencias.length} referência(s)',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReferenciasPage(store: store))),
        ),
        MenuTile(
          icon: Icons.alternate_email,
          title: 'Identificação Online',
          subtitle: '${store.onlineIdentificacoes.length} identificação(ões)',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OnlinePage(store: store))),
        ),
        MenuTile(
          icon: Icons.settings,
          title: 'Configurações',
          subtitle: 'JC fixo, exportação e limpeza local.',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConfigPage(store: store))),
        ),
      ],
    );
  }
}

class ExperienciasPage extends StatelessWidget {
  const ExperienciasPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Experiência de Fé')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeaderWithAction(
            title: 'Experiências de Fé',
            subtitle: 'Cadastro, resumo, status, envio e apresentação.',
            buttonLabel: 'Nova',
            onPressed: () => openSheet(context, ExperienciaForm(store: store)),
          ),
          for (final e in store.experiencias)
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.auto_stories, color: kAccent)),
                title: Text(e.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${e.nome} • ${e.status}'),
              ),
            ),
          EmptyState(show: store.experiencias.isEmpty, message: 'Nenhuma experiência cadastrada.'),
        ],
      ),
    );
  }
}

class ReferenciasPage extends StatelessWidget {
  const ReferenciasPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Referências')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeaderWithAction(
            title: 'Referências',
            subtitle: 'Nomes não vinculados diretamente à BD_Pessoas.',
            buttonLabel: 'Nova',
            onPressed: () => openSheet(context, ReferenciaForm(store: store)),
          ),
          for (final r in store.referencias)
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.link, color: kAccent)),
                title: Text(r.nomeReferencia, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${r.tipoReferencia} • ${r.ativo ? 'Ativo' : 'Inativo'}'),
              ),
            ),
          EmptyState(show: store.referencias.isEmpty, message: 'Nenhuma referência cadastrada.'),
        ],
      ),
    );
  }
}

class OnlinePage extends StatelessWidget {
  const OnlinePage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identificação Online')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeaderWithAction(
            title: 'Identificação Online',
            subtitle: 'Controle separado do app/online, sem misturar com urna.',
            buttonLabel: 'Nova',
            onPressed: () => openSheet(context, OnlineForm(store: store)),
          ),
          for (final o in store.onlineIdentificacoes)
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.alternate_email, color: kAccent)),
                title: Text(o.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${brDate.format(o.dataReferencia)} • ${o.formaIdentificacao}'),
              ),
            ),
          EmptyState(show: store.onlineIdentificacoes.isEmpty, message: 'Nenhuma identificação online cadastrada.'),
        ],
      ),
    );
  }
}

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.home_work_outlined),
              title: Text('Johrei Center fixo'),
              subtitle: Text(kJcPadrao),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('Estrutura importada do Excel'),
              subtitle: const Text('Este protótipo já segue as abas BD_Pessoas, BD_Frequencia, BD_Donativos, BD_ExperienciaFe, BD_OnlineIdentificacao e BD_Referencias.'),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await store.importarDadosDoExcel();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dados do Excel recarregados no app.')),
                );
              }
            },
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Recarregar dados reais do Excel'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await store.resetLocal();
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Limpar dados locais'),
          ),
        ],
      ),
    );
  }
}

class PessoaForm extends StatefulWidget {
  const PessoaForm({super.key, required this.store});
  final AppStore store;

  @override
  State<PessoaForm> createState() => _PessoaFormState();
}

class _PessoaFormState extends State<PessoaForm> {
  final nome = TextEditingController();
  String tipo = 'Membro';

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Nova pessoa',
      children: [
        TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 12),
        AppDropdown(value: tipo, items: const ['Membro', 'Frequentador', '1ª vez'], onChanged: (v) => setState(() => tipo = v)),
      ],
      onSave: () {
        widget.store.addPessoa(Pessoa(
          idPessoa: widget.store.nextPessoaId(),
          nome: nome.text.trim(),
          tipoPessoaAtual: tipo,
          primeiraPresenca: DateTime.now(),
          ultimaPresenca: DateTime.now(),
          qtdPresencas: 0,
          jc: kJcPadrao,
        ));
        Navigator.pop(context);
      },
    );
  }
}

class DonativoForm extends StatefulWidget {
  const DonativoForm({super.key, required this.store, this.initialValue});
  final AppStore store;
  final Donativo? initialValue;

  bool get isEditing => initialValue != null;

  @override
  State<DonativoForm> createState() => _DonativoFormState();
}

class _DonativoFormState extends State<DonativoForm> {
  final formKey = GlobalKey<FormState>();
  final nome = TextEditingController();
  final valor = TextEditingController();
  final tipoManual = TextEditingController();
  final dataController = TextEditingController();

  String tipoPessoa = 'Membro';
  String tipoDonativo = 'Mensal';
  String origem = 'Urna';
  String subtipo = 'Presencial';
  String tipoOrigemNome = 'Pessoa';

  List<String> get subtiposDisponiveis => subtiposPorOrigem(origem);
  List<String> get nomesBase => tipoOrigemNome == 'Pessoa' ? widget.store.nomesPessoas() : widget.store.nomesReferencias();

  @override
  void initState() {
    super.initState();
    final item = widget.initialValue;
    final dataInicial = item?.data ?? DateTime.now();
    nome.text = item?.nome ?? '';
    valor.text = item == null ? '' : formatValorInput(item.valor);
    tipoManual.text = item?.tipoDonativoManual ?? '';
    dataController.text = brDate.format(dataInicial);
    tipoPessoa = valorSeguro(item?.tipoPessoa, kTiposPessoaDonativo, fallback: 'Membro');
    tipoDonativo = valorSeguro(item?.tipoDonativo, kTiposDonativo, fallback: 'Mensal');
    origem = valorSeguro(item?.origem, kOrigensDonativo, fallback: 'Urna');
    tipoOrigemNome = valorSeguro(item?.tipoOrigemNome, kTiposOrigemNomeDonativo, fallback: 'Pessoa');
    subtipo = valorSeguro(item?.subtipo, subtiposDisponiveis, fallback: subtiposDisponiveis.first);
    if (tipoOrigemNome == 'Referencia') tipoPessoa = 'Outro';
  }

  @override
  void dispose() {
    nome.dispose();
    valor.dispose();
    tipoManual.dispose();
    dataController.dispose();
    super.dispose();
  }

  Future<void> selecionarData() async {
    final atual = tryParseBrDate(dataController.text) ?? widget.initialValue?.data ?? DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: atual,
    );
    if (selecionada == null) return;
    setState(() => dataController.text = brDate.format(selecionada));
  }

  Future<void> selecionarNomeDaBase() async {
    final selecionado = await pickStringFromList(
      context,
      title: tipoOrigemNome == 'Pessoa' ? 'Selecionar pessoa' : 'Selecionar referência',
      options: nomesBase,
    );
    if (selecionado == null) return;
    setState(() {
      nome.text = selecionado;
      preencherTipoPessoaPelaBase(selecionado);
    });
  }

  void preencherTipoPessoaPelaBase(String raw) {
    if (tipoOrigemNome == 'Referencia') {
      tipoPessoa = 'Outro';
      return;
    }
    final pessoa = widget.store.findPessoaByName(raw);
    if (pessoa != null) tipoPessoa = valorSeguro(pessoa.tipoPessoaAtual, kTiposPessoaDonativo, fallback: 'Membro');
  }

  Future<void> salvar() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;

    final dataLancamento = tryParseBrDate(dataController.text)!;
    final referencia = tipoOrigemNome == 'Referencia' ? widget.store.findReferenciaByName(nome.text) : null;
    final pessoa = tipoOrigemNome == 'Pessoa' ? widget.store.findPessoaByName(nome.text) : null;

    final novo = Donativo(
      id: widget.initialValue?.id ?? widget.store.nextDonativoId(),
      data: dataLancamento,
      nome: nome.text.trim(),
      jc: widget.initialValue?.jc ?? kJcPadrao,
      tipoPessoa: tipoOrigemNome == 'Referencia' ? 'Outro' : (pessoa?.tipoPessoaAtual ?? tipoPessoa),
      tipoDonativo: tipoDonativo,
      tipoDonativoManual: tipoDonativo == 'Outro' ? tipoManual.text.trim() : '',
      origem: origem,
      subtipo: subtipo,
      valor: parseValor(valor.text),
      comprovante: widget.initialValue?.comprovante ?? '',
      tipoOrigemNome: tipoOrigemNome,
      idReferencia: referencia?.idReferencia ?? widget.initialValue?.idReferencia ?? '',
    );

    await widget.store.upsertDonativo(novo);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: widget.isEditing ? 'Editar donativo' : 'Novo donativo',
      formKey: formKey,
      onSave: salvar,
      children: [
        FormSectionLabel('Identificação'),
        AppDropdown(
          value: tipoOrigemNome,
          labelText: 'Base do nome',
          items: kTiposOrigemNomeDonativo,
          onChanged: (v) {
            setState(() {
              tipoOrigemNome = v;
              if (tipoOrigemNome == 'Referencia') {
                tipoPessoa = 'Outro';
              } else {
                preencherTipoPessoaPelaBase(nome.text);
              }
            });
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: nome,
          decoration: InputDecoration(
            labelText: tipoOrigemNome == 'Pessoa' ? 'Nome da pessoa' : 'Nome da referência',
            suffixIcon: IconButton(
              onPressed: nomesBase.isEmpty ? null : selecionarNomeDaBase,
              icon: const Icon(Icons.search),
              tooltip: 'Selecionar da base',
            ),
          ),
          onChanged: (value) => setState(() => preencherTipoPessoaPelaBase(value)),
          validator: (value) {
            final nomeLimpo = value?.trim() ?? '';
            if (nomeLimpo.isEmpty) return 'Informe um nome.';
            if (tipoOrigemNome == 'Referencia' && widget.store.findReferenciaByName(nomeLimpo) == null) {
              return 'Selecione uma referência cadastrada.';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: nomesBase.isEmpty ? null : selecionarNomeDaBase,
            icon: const Icon(Icons.list_alt_outlined),
            label: Text(tipoOrigemNome == 'Pessoa' ? 'Selecionar da base de pessoas (${widget.store.pessoas.length})' : 'Selecionar da base de referências (${widget.store.referencias.length})'),
          ),
        ),
        const SizedBox(height: 12),
        AppDropdown(
          value: tipoPessoa,
          labelText: 'Categoria da pessoa',
          items: kTiposPessoaDonativo,
          enabled: tipoOrigemNome != 'Referencia',
          onChanged: (v) => setState(() => tipoPessoa = v),
        ),
        const SizedBox(height: 20),
        FormSectionLabel('Lançamento'),
        BrDateFormField(controller: dataController, labelText: 'Data', onPickDate: selecionarData),
        const SizedBox(height: 12),
        TextFormField(
          controller: valor,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [BrMoneyTextInputFormatter()],
          decoration: const InputDecoration(labelText: 'Valor', hintText: '0,00', prefixText: 'R\$ '),
          validator: (value) {
            final atual = parseValor(value ?? '');
            if (atual <= 0) return 'Informe um valor maior que zero.';
            return null;
          },
        ),
        const SizedBox(height: 12),
        AppDropdown(value: tipoDonativo, labelText: 'Tipo de donativo', items: kTiposDonativo, onChanged: (v) => setState(() => tipoDonativo = v)),
        if (tipoDonativo == 'Outro') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: tipoManual,
            decoration: const InputDecoration(labelText: 'Tipo manual'),
            validator: (value) {
              if (tipoDonativo == 'Outro' && (value?.trim().isEmpty ?? true)) return 'Informe o tipo manual.';
              return null;
            },
          ),
        ],
        const SizedBox(height: 12),
        AppDropdown(
          value: origem,
          labelText: 'Origem',
          items: kOrigensDonativo,
          onChanged: (v) {
            setState(() {
              origem = v;
              subtipo = subtiposPorOrigem(origem).first;
            });
          },
        ),
        const SizedBox(height: 12),
        AppDropdown(value: subtipo, labelText: 'Subtipo', items: subtiposDisponiveis, onChanged: (v) => setState(() => subtipo = v)),
      ],
    );
  }
}

class FrequenciaForm extends StatefulWidget {
  const FrequenciaForm({super.key, required this.store, this.initialValue});
  final AppStore store;
  final Frequencia? initialValue;

  bool get isEditing => initialValue != null;

  @override
  State<FrequenciaForm> createState() => _FrequenciaFormState();
}

class _FrequenciaFormState extends State<FrequenciaForm> {
  final formKey = GlobalKey<FormState>();
  final nome = TextEditingController();
  final obs = TextEditingController();
  final dataController = TextEditingController();
  String tipoEvento = 'Dia a dia';
  String tipoPessoa = 'Membro';

  List<String> get tiposEvento {
    final set = <String>{...kTiposEventoPadrao, ...widget.store.frequencias.map((e) => e.tipoEvento).where((e) => e.trim().isNotEmpty)};
    final lista = set.toList()..sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
    return lista;
  }

  @override
  void initState() {
    super.initState();
    final item = widget.initialValue;
    dataController.text = brDate.format(item?.data ?? DateTime.now());
    nome.text = item?.nome ?? '';
    obs.text = item?.observacao ?? '';
    tipoEvento = valorSeguro(item?.tipoEvento, tiposEvento, fallback: 'Dia a dia');
    tipoPessoa = valorSeguro(item?.tipoPessoaAtual, kTiposPessoaFrequencia, fallback: 'Membro');
  }

  @override
  void dispose() {
    nome.dispose();
    obs.dispose();
    dataController.dispose();
    super.dispose();
  }

  Future<void> selecionarData() async {
    final atual = tryParseBrDate(dataController.text) ?? widget.initialValue?.data ?? DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: atual,
    );
    if (selecionada == null) return;
    setState(() => dataController.text = brDate.format(selecionada));
  }

  Future<void> selecionarPessoa() async {
    final selecionado = await pickStringFromList(context, title: 'Selecionar pessoa', options: widget.store.nomesPessoas());
    if (selecionado == null) return;
    setState(() {
      nome.text = selecionado;
      preencherCategoriaPelaBase(selecionado);
    });
  }

  void preencherCategoriaPelaBase(String raw) {
    final pessoa = widget.store.findPessoaByName(raw);
    if (pessoa != null) tipoPessoa = valorSeguro(pessoa.tipoPessoaAtual, kTiposPessoaFrequencia, fallback: 'Membro');
  }

  Future<void> salvar() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;

    final dataLancamento = tryParseBrDate(dataController.text)!;
    final pessoa = widget.store.findPessoaByName(nome.text);
    final categoriaHistorica = pessoa?.tipoPessoaAtual ?? tipoPessoa;

    final duplicado = widget.store.existeFrequenciaDuplicada(
      nome: nome.text,
      data: dataLancamento,
      tipoEvento: tipoEvento,
      ignorarId: widget.initialValue?.id,
    );

    if (duplicado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Essa pessoa já foi lançada nesse mesmo dia e tipo de evento.')),
      );
      return;
    }

    final novo = Frequencia(
      id: widget.initialValue?.id ?? widget.store.nextFrequenciaId(),
      data: dataLancamento,
      tipoEvento: tipoEvento,
      nome: nome.text.trim(),
      tipoPessoaInformado: categoriaHistorica,
      tipoPessoaAtual: categoriaHistorica,
      jc: widget.initialValue?.jc ?? kJcPadrao,
      observacao: obs.text.trim(),
      dataLancamento: widget.initialValue?.dataLancamento ?? DateTime.now(),
      horaLancamento: widget.initialValue?.horaLancamento ?? TimeOfDay.now().format(context),
    );

    await widget.store.upsertFrequencia(novo);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: widget.isEditing ? 'Editar frequência' : 'Lançar frequência',
      formKey: formKey,
      onSave: salvar,
      children: [
        FormSectionLabel('Lançamento'),
        BrDateFormField(controller: dataController, labelText: 'Data', onPickDate: selecionarData),
        const SizedBox(height: 12),
        TextFormField(
          controller: nome,
          decoration: InputDecoration(
            labelText: 'Nome da pessoa',
            suffixIcon: IconButton(
              onPressed: widget.store.pessoas.isEmpty ? null : selecionarPessoa,
              icon: const Icon(Icons.search),
              tooltip: 'Selecionar da base de pessoas',
            ),
          ),
          onChanged: (value) => setState(() => preencherCategoriaPelaBase(value)),
          validator: (value) => (value?.trim().isEmpty ?? true) ? 'Informe o nome.' : null,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.store.pessoas.isEmpty ? null : selecionarPessoa,
            icon: const Icon(Icons.list_alt_outlined),
            label: Text('Selecionar da base de pessoas (${widget.store.pessoas.length})'),
          ),
        ),
        const SizedBox(height: 12),
        AppDropdown(value: tipoEvento, labelText: 'Tipo de evento', items: tiposEvento, onChanged: (v) => setState(() => tipoEvento = v)),
        const SizedBox(height: 12),
        AppDropdown(value: tipoPessoa, labelText: 'Categoria histórica', items: kTiposPessoaFrequencia, onChanged: (v) => setState(() => tipoPessoa = v)),
        const SizedBox(height: 12),
        TextFormField(controller: obs, decoration: const InputDecoration(labelText: 'Observação')),
      ],
    );
  }
}


class ExperienciaForm extends StatefulWidget {
  const ExperienciaForm({super.key, required this.store});
  final AppStore store;

  @override
  State<ExperienciaForm> createState() => _ExperienciaFormState();
}

class _ExperienciaFormState extends State<ExperienciaForm> {
  final nome = TextEditingController();
  final titulo = TextEditingController();
  final resumo = TextEditingController();
  String status = 'Rascunho';

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Nova experiência',
      children: [
        TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 12),
        TextField(controller: titulo, decoration: const InputDecoration(labelText: 'Título')),
        const SizedBox(height: 12),
        TextField(controller: resumo, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'Resumo')),
        const SizedBox(height: 12),
        AppDropdown(value: status, items: const ['Rascunho', 'Em revisão', 'Aprovada', 'Apresentada'], onChanged: (v) => setState(() => status = v)),
      ],
      onSave: () {
        widget.store.addExperiencia(ExperienciaFe(
          id: widget.store.nextExperienciaId(),
          dataRegistro: DateTime.now(),
          dataExperiencia: DateTime.now(),
          idPessoa: 0,
          nome: nome.text.trim(),
          tipoPessoa: '',
          jc: kJcPadrao,
          titulo: titulo.text.trim(),
          resumo: resumo.text.trim(),
          categoria: '',
          tema: '',
          status: status,
          responsavelRegistro: '',
          observacao: '',
          arquivo: '',
          foiEnviada: false,
          aprovada: status == 'Aprovada' || status == 'Apresentada',
          foiApresentada: status == 'Apresentada',
        ));
        Navigator.pop(context);
      },
    );
  }
}

class ReferenciaForm extends StatefulWidget {
  const ReferenciaForm({super.key, required this.store});
  final AppStore store;

  @override
  State<ReferenciaForm> createState() => _ReferenciaFormState();
}

class _ReferenciaFormState extends State<ReferenciaForm> {
  final nome = TextEditingController();
  String tipo = 'Outro';

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Nova referência',
      children: [
        TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome da referência')),
        const SizedBox(height: 12),
        AppDropdown(value: tipo, items: const ['Outro', 'Empresa', 'Família', 'Anônimo'], onChanged: (v) => setState(() => tipo = v)),
      ],
      onSave: () {
        widget.store.addReferencia(ReferenciaNome(
          idReferencia: widget.store.nextReferenciaId(),
          nomeReferencia: nome.text.trim(),
          tipoReferencia: tipo,
          idPessoaVinculada: 0,
          nomePessoaVinculada: '',
          jc: kJcPadrao,
          observacao: '',
          ativo: true,
          dataCadastro: DateTime.now(),
          horaCadastro: TimeOfDay.now().format(context),
        ));
        Navigator.pop(context);
      },
    );
  }
}

class OnlineForm extends StatefulWidget {
  const OnlineForm({super.key, required this.store});
  final AppStore store;

  @override
  State<OnlineForm> createState() => _OnlineFormState();
}

class _OnlineFormState extends State<OnlineForm> {
  final nome = TextEditingController();
  final obs = TextEditingController();
  DateTime data = DateTime.now();
  String forma = 'Aplicativo';
  String tipoPessoa = 'Membro';

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Nova identificação online',
      children: [
        DateSelector(label: 'Data referência', value: data, onChanged: (v) => setState(() => data = v)),
        TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 12),
        AppDropdown(value: tipoPessoa, items: const ['Membro', 'Frequentador', 'Outro'], onChanged: (v) => setState(() => tipoPessoa = v)),
        const SizedBox(height: 12),
        AppDropdown(value: forma, items: const ['Aplicativo', 'PIX Online', 'Site', 'Outro'], onChanged: (v) => setState(() => forma = v)),
        const SizedBox(height: 12),
        TextField(controller: obs, decoration: const InputDecoration(labelText: 'Observação')),
      ],
      onSave: () {
        widget.store.addOnline(OnlineIdentificacao(
          id: widget.store.nextOnlineId(),
          dataReferencia: data,
          nome: nome.text.trim(),
          idPessoa: 0,
          tipoPessoa: tipoPessoa,
          formaIdentificacao: forma,
          observacao: obs.text.trim(),
          jc: kJcPadrao,
          dataLancamento: DateTime.now(),
          horaLancamento: TimeOfDay.now().format(context),
        ));
        Navigator.pop(context);
      },
    );
  }
}

class AppStore extends ChangeNotifier {
  bool isLoading = true;
  late SharedPreferences prefs;

  List<Pessoa> pessoas = [];
  List<Donativo> donativos = [];
  List<Frequencia> frequencias = [];
  List<ExperienciaFe> experiencias = [];
  List<ReferenciaNome> referencias = [];
  List<OnlineIdentificacao> onlineIdentificacoes = [];

  static const _seedImportedKey = 'seed_excel_importado_v1';

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    pessoas = _loadList('pessoas', Pessoa.fromJson);
    donativos = _loadList('donativos', Donativo.fromJson);
    frequencias = _loadList('frequencias', Frequencia.fromJson);
    experiencias = _loadList('experiencias', ExperienciaFe.fromJson);
    referencias = _loadList('referencias', ReferenciaNome.fromJson);
    onlineIdentificacoes = _loadList('online_identificacoes', OnlineIdentificacao.fromJson);

    final jaImportouSeed = prefs.getBool(_seedImportedKey) ?? false;
    final bancoLocalVazio = pessoas.isEmpty && donativos.isEmpty && frequencias.isEmpty && experiencias.isEmpty && referencias.isEmpty && onlineIdentificacoes.isEmpty;

    if (!jaImportouSeed && bancoLocalVazio) {
      await importarDadosDoExcel(notificar: false);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> importarDadosDoExcel({bool notificar = true}) async {
    final raw = await rootBundle.loadString('assets/seed_data.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;

    pessoas = _seedList(data, 'pessoas', Pessoa.fromJson);
    donativos = _seedList(data, 'donativos', Donativo.fromJson);
    frequencias = _seedList(data, 'frequencias', Frequencia.fromJson);
    experiencias = _seedList(data, 'experiencias', ExperienciaFe.fromJson);
    referencias = _seedList(data, 'referencias', ReferenciaNome.fromJson);
    onlineIdentificacoes = _seedList(data, 'online_identificacoes', OnlineIdentificacao.fromJson);

    await _saveRawList('pessoas', pessoas, (e) => e.toJson());
    await _saveRawList('donativos', donativos, (e) => e.toJson());
    await _saveRawList('frequencias', frequencias, (e) => e.toJson());
    await _saveRawList('experiencias', experiencias, (e) => e.toJson());
    await _saveRawList('referencias', referencias, (e) => e.toJson());
    await _saveRawList('online_identificacoes', onlineIdentificacoes, (e) => e.toJson());
    await prefs.setBool(_seedImportedKey, true);

    if (notificar) notifyListeners();
  }

  List<T> _seedList<T>(Map<String, dynamic> data, String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = data[key];
    if (raw is! List) return [];
    return raw.map((e) => fromJson(Map<String, dynamic>.from(e))).toList();
  }

  List<T> _loadList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final data = jsonDecode(raw) as List<dynamic>;
    return data.map((e) => fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _saveRawList<T>(String key, List<T> values, Map<String, dynamic> Function(T) toJson) async {
    await prefs.setString(key, jsonEncode(values.map(toJson).toList()));
  }

  Future<void> _saveList<T>(String key, List<T> values, Map<String, dynamic> Function(T) toJson) async {
    await _saveRawList(key, values, toJson);
    notifyListeners();
  }

  Future<void> addPessoa(Pessoa value) async {
    pessoas.add(value);
    await _saveList('pessoas', pessoas, (e) => e.toJson());
  }

  Future<void> addDonativo(Donativo value) => upsertDonativo(value);

  Future<void> upsertDonativo(Donativo value) async {
    final index = donativos.indexWhere((item) => item.id == value.id);
    if (index >= 0) {
      donativos[index] = value;
    } else {
      donativos.add(value);
    }
    await _saveList('donativos', donativos, (e) => e.toJson());
  }

  Future<void> deleteDonativo(int id) async {
    donativos.removeWhere((item) => item.id == id);
    await _saveList('donativos', donativos, (e) => e.toJson());
  }

  Future<void> addFrequencia(Frequencia value) => upsertFrequencia(value);

  Future<void> upsertFrequencia(Frequencia value) async {
    final index = frequencias.indexWhere((item) => item.id == value.id);
    if (index >= 0) {
      frequencias[index] = value;
    } else {
      frequencias.add(value);
    }
    await _saveList('frequencias', frequencias, (e) => e.toJson());
  }

  Future<void> deleteFrequencia(int id) async {
    frequencias.removeWhere((item) => item.id == id);
    await _saveList('frequencias', frequencias, (e) => e.toJson());
  }

  bool existeFrequenciaDuplicada({required String nome, required DateTime data, required String tipoEvento, int? ignorarId}) {
    final alvoNome = normalizeText(nome);
    final alvoData = dateOnly(data);
    final alvoEvento = normalizeText(tipoEvento);
    return frequencias.any((item) {
      if (ignorarId != null && item.id == ignorarId) return false;
      return normalizeText(item.nome) == alvoNome && dateOnly(item.data) == alvoData && normalizeText(item.tipoEvento) == alvoEvento;
    });
  }

  Future<void> addExperiencia(ExperienciaFe value) async {
    experiencias.add(value);
    await _saveList('experiencias', experiencias, (e) => e.toJson());
  }

  Future<void> addReferencia(ReferenciaNome value) async {
    referencias.add(value);
    await _saveList('referencias', referencias, (e) => e.toJson());
  }

  Future<void> addOnline(OnlineIdentificacao value) async {
    onlineIdentificacoes.add(value);
    await _saveList('online_identificacoes', onlineIdentificacoes, (e) => e.toJson());
  }

  Pessoa? findPessoaByName(String nome) {
    final alvo = normalizeText(nome);
    for (final pessoa in pessoas) {
      if (normalizeText(pessoa.nome) == alvo) return pessoa;
    }
    return null;
  }

  ReferenciaNome? findReferenciaByName(String nome) {
    final alvo = normalizeText(nome);
    for (final referencia in referencias) {
      if (normalizeText(referencia.nomeReferencia) == alvo) return referencia;
    }
    return null;
  }

  List<String> nomesPessoas() {
    final nomes = pessoas.map((item) => item.nome.trim()).where((item) => item.isNotEmpty).toSet().toList();
    nomes.sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
    return nomes;
  }

  List<String> nomesReferencias() {
    final nomes = referencias.map((item) => item.nomeReferencia.trim()).where((item) => item.isNotEmpty).toSet().toList();
    nomes.sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
    return nomes;
  }

  int nextPessoaId() => pessoas.isEmpty ? 1 : pessoas.map((e) => e.idPessoa).reduce((a, b) => a > b ? a : b) + 1;
  int nextDonativoId() => donativos.isEmpty ? 1 : donativos.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextFrequenciaId() => frequencias.isEmpty ? 1 : frequencias.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextExperienciaId() => experiencias.isEmpty ? 1 : experiencias.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextOnlineId() => onlineIdentificacoes.isEmpty ? 1 : onlineIdentificacoes.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  String nextReferenciaId() => 'REF${(referencias.length + 1).toString().padLeft(6, '0')}';

  double totalDonativosMes(DateTime date) {
    return totalizarDonativos(donativos.where((d) => d.data.year == date.year && d.data.month == date.month));
  }

  int presencasMes(DateTime date) {
    return frequencias.where((f) => f.data.year == date.year && f.data.month == date.month).length;
  }

  double totalizarDonativos(Iterable<Donativo> values) {
    return values.fold(0.0, (sum, item) => sum + item.valor);
  }

  List<DecendioResumo> resumirDecendios(Iterable<Donativo> values) {
    final ranges = [
      (1, '1 a 10', 1, 10),
      (2, '11 a 20', 11, 20),
      (3, '21 ao fim do mês', 21, 31),
    ];
    final itens = values.toList();
    return ranges.map((r) {
      final dados = itens.where((item) => item.data.day >= r.$3 && item.data.day <= r.$4).toList();
      return DecendioResumo(numero: r.$1, rotulo: r.$2, quantidade: dados.length, total: totalizarDonativos(dados));
    }).toList();
  }

  List<DecendioResumo> decendios(DateTime date) {
    final dadosMes = donativos.where((d) => d.data.year == date.year && d.data.month == date.month);
    return resumirDecendios(dadosMes);
  }

  Future<void> resetLocal() async {
    await prefs.clear();
    await prefs.setBool(_seedImportedKey, true);
    pessoas.clear();
    donativos.clear();
    frequencias.clear();
    experiencias.clear();
    referencias.clear();
    onlineIdentificacoes.clear();
    notifyListeners();
  }
}


class Pessoa {
  Pessoa({required this.idPessoa, required this.nome, required this.tipoPessoaAtual, required this.primeiraPresenca, required this.ultimaPresenca, required this.qtdPresencas, required this.jc});
  final int idPessoa;
  final String nome;
  final String tipoPessoaAtual;
  final DateTime primeiraPresenca;
  final DateTime ultimaPresenca;
  final int qtdPresencas;
  final String jc;

  Map<String, dynamic> toJson() => {
        'idPessoa': idPessoa,
        'nome': nome,
        'tipoPessoaAtual': tipoPessoaAtual,
        'primeiraPresenca': primeiraPresenca.toIso8601String(),
        'ultimaPresenca': ultimaPresenca.toIso8601String(),
        'qtdPresencas': qtdPresencas,
        'jc': jc,
      };

  factory Pessoa.fromJson(Map<String, dynamic> json) => Pessoa(
        idPessoa: json['idPessoa'] ?? 0,
        nome: json['nome'] ?? '',
        tipoPessoaAtual: json['tipoPessoaAtual'] ?? '',
        primeiraPresenca: parseDate(json['primeiraPresenca']),
        ultimaPresenca: parseDate(json['ultimaPresenca']),
        qtdPresencas: json['qtdPresencas'] ?? 0,
        jc: json['jc'] ?? kJcPadrao,
      );
}

class Donativo {
  Donativo({required this.id, required this.data, required this.nome, required this.jc, required this.tipoPessoa, required this.tipoDonativo, required this.tipoDonativoManual, required this.origem, required this.subtipo, required this.valor, required this.comprovante, required this.tipoOrigemNome, required this.idReferencia});
  final int id;
  final DateTime data;
  final String nome;
  final String jc;
  final String tipoPessoa;
  final String tipoDonativo;
  final String tipoDonativoManual;
  final String origem;
  final String subtipo;
  final double valor;
  final String comprovante;
  final String tipoOrigemNome;
  final String idReferencia;

  String get tipoDonativoExibicao => tipoDonativo == 'Outro' && tipoDonativoManual.trim().isNotEmpty ? tipoDonativoManual.trim() : tipoDonativo;
  String get tipoOrigemNomeExibicao => tipoOrigemNome == 'Referencia' ? 'Referência' : 'Pessoa';

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.toIso8601String(),
        'nome': nome,
        'jc': jc,
        'tipoPessoa': tipoPessoa,
        'tipoDonativo': tipoDonativo,
        'tipoDonativoManual': tipoDonativoManual,
        'origem': origem,
        'subtipo': subtipo,
        'valor': valor,
        'comprovante': comprovante,
        'tipoOrigemNome': tipoOrigemNome,
        'idReferencia': idReferencia,
      };

  factory Donativo.fromJson(Map<String, dynamic> json) => Donativo(
        id: json['id'] ?? 0,
        data: parseDate(json['data']),
        nome: json['nome'] ?? '',
        jc: json['jc'] ?? kJcPadrao,
        tipoPessoa: json['tipoPessoa'] ?? '',
        tipoDonativo: json['tipoDonativo'] ?? '',
        tipoDonativoManual: json['tipoDonativoManual'] ?? '',
        origem: json['origem'] ?? '',
        subtipo: json['subtipo'] ?? '',
        valor: json['valor'] is num ? (json['valor'] as num).toDouble() : parseValor((json['valor'] ?? 0).toString()),
        comprovante: json['comprovante'] ?? '',
        tipoOrigemNome: json['tipoOrigemNome'] ?? '',
        idReferencia: json['idReferencia'] ?? '',
      );
}


class Frequencia {
  Frequencia({required this.id, required this.data, required this.tipoEvento, required this.nome, required this.tipoPessoaInformado, required this.tipoPessoaAtual, required this.jc, required this.observacao, required this.dataLancamento, required this.horaLancamento});
  final int id;
  final DateTime data;
  final String tipoEvento;
  final String nome;
  final String tipoPessoaInformado;
  final String tipoPessoaAtual;
  final String jc;
  final String observacao;
  final DateTime dataLancamento;
  final String horaLancamento;

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.toIso8601String(),
        'tipoEvento': tipoEvento,
        'nome': nome,
        'tipoPessoaInformado': tipoPessoaInformado,
        'tipoPessoaAtual': tipoPessoaAtual,
        'jc': jc,
        'observacao': observacao,
        'dataLancamento': dataLancamento.toIso8601String(),
        'horaLancamento': horaLancamento,
      };

  factory Frequencia.fromJson(Map<String, dynamic> json) => Frequencia(
        id: json['id'] ?? 0,
        data: parseDate(json['data']),
        tipoEvento: json['tipoEvento'] ?? '',
        nome: json['nome'] ?? '',
        tipoPessoaInformado: json['tipoPessoaInformado'] ?? '',
        tipoPessoaAtual: json['tipoPessoaAtual'] ?? '',
        jc: json['jc'] ?? kJcPadrao,
        observacao: json['observacao'] ?? '',
        dataLancamento: parseDate(json['dataLancamento']),
        horaLancamento: json['horaLancamento'] ?? '',
      );
}

class ExperienciaFe {
  ExperienciaFe({required this.id, required this.dataRegistro, required this.dataExperiencia, required this.idPessoa, required this.nome, required this.tipoPessoa, required this.jc, required this.titulo, required this.resumo, required this.categoria, required this.tema, required this.status, required this.responsavelRegistro, required this.observacao, required this.arquivo, required this.foiEnviada, required this.aprovada, required this.foiApresentada});
  final int id;
  final DateTime dataRegistro;
  final DateTime dataExperiencia;
  final int idPessoa;
  final String nome;
  final String tipoPessoa;
  final String jc;
  final String titulo;
  final String resumo;
  final String categoria;
  final String tema;
  final String status;
  final String responsavelRegistro;
  final String observacao;
  final String arquivo;
  final bool foiEnviada;
  final bool aprovada;
  final bool foiApresentada;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dataRegistro': dataRegistro.toIso8601String(),
        'dataExperiencia': dataExperiencia.toIso8601String(),
        'idPessoa': idPessoa,
        'nome': nome,
        'tipoPessoa': tipoPessoa,
        'jc': jc,
        'titulo': titulo,
        'resumo': resumo,
        'categoria': categoria,
        'tema': tema,
        'status': status,
        'responsavelRegistro': responsavelRegistro,
        'observacao': observacao,
        'arquivo': arquivo,
        'foiEnviada': foiEnviada,
        'aprovada': aprovada,
        'foiApresentada': foiApresentada,
      };

  factory ExperienciaFe.fromJson(Map<String, dynamic> json) => ExperienciaFe(
        id: json['id'] ?? 0,
        dataRegistro: parseDate(json['dataRegistro']),
        dataExperiencia: parseDate(json['dataExperiencia']),
        idPessoa: json['idPessoa'] ?? 0,
        nome: json['nome'] ?? '',
        tipoPessoa: json['tipoPessoa'] ?? '',
        jc: json['jc'] ?? kJcPadrao,
        titulo: json['titulo'] ?? '',
        resumo: json['resumo'] ?? '',
        categoria: json['categoria'] ?? '',
        tema: json['tema'] ?? '',
        status: json['status'] ?? '',
        responsavelRegistro: json['responsavelRegistro'] ?? '',
        observacao: json['observacao'] ?? '',
        arquivo: json['arquivo'] ?? '',
        foiEnviada: json['foiEnviada'] ?? false,
        aprovada: json['aprovada'] ?? false,
        foiApresentada: json['foiApresentada'] ?? false,
      );
}

class ReferenciaNome {
  ReferenciaNome({required this.idReferencia, required this.nomeReferencia, required this.tipoReferencia, required this.idPessoaVinculada, required this.nomePessoaVinculada, required this.jc, required this.observacao, required this.ativo, required this.dataCadastro, required this.horaCadastro});
  final String idReferencia;
  final String nomeReferencia;
  final String tipoReferencia;
  final int idPessoaVinculada;
  final String nomePessoaVinculada;
  final String jc;
  final String observacao;
  final bool ativo;
  final DateTime dataCadastro;
  final String horaCadastro;

  Map<String, dynamic> toJson() => {
        'idReferencia': idReferencia,
        'nomeReferencia': nomeReferencia,
        'tipoReferencia': tipoReferencia,
        'idPessoaVinculada': idPessoaVinculada,
        'nomePessoaVinculada': nomePessoaVinculada,
        'jc': jc,
        'observacao': observacao,
        'ativo': ativo,
        'dataCadastro': dataCadastro.toIso8601String(),
        'horaCadastro': horaCadastro,
      };

  factory ReferenciaNome.fromJson(Map<String, dynamic> json) => ReferenciaNome(
        idReferencia: json['idReferencia'] ?? '',
        nomeReferencia: json['nomeReferencia'] ?? '',
        tipoReferencia: json['tipoReferencia'] ?? '',
        idPessoaVinculada: json['idPessoaVinculada'] ?? 0,
        nomePessoaVinculada: json['nomePessoaVinculada'] ?? '',
        jc: json['jc'] ?? kJcPadrao,
        observacao: json['observacao'] ?? '',
        ativo: json['ativo'] ?? true,
        dataCadastro: parseDate(json['dataCadastro']),
        horaCadastro: json['horaCadastro'] ?? '',
      );
}

class OnlineIdentificacao {
  OnlineIdentificacao({required this.id, required this.dataReferencia, required this.nome, required this.idPessoa, required this.tipoPessoa, required this.formaIdentificacao, required this.observacao, required this.jc, required this.dataLancamento, required this.horaLancamento});
  final int id;
  final DateTime dataReferencia;
  final String nome;
  final int idPessoa;
  final String tipoPessoa;
  final String formaIdentificacao;
  final String observacao;
  final String jc;
  final DateTime dataLancamento;
  final String horaLancamento;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dataReferencia': dataReferencia.toIso8601String(),
        'nome': nome,
        'idPessoa': idPessoa,
        'tipoPessoa': tipoPessoa,
        'formaIdentificacao': formaIdentificacao,
        'observacao': observacao,
        'jc': jc,
        'dataLancamento': dataLancamento.toIso8601String(),
        'horaLancamento': horaLancamento,
      };

  factory OnlineIdentificacao.fromJson(Map<String, dynamic> json) => OnlineIdentificacao(
        id: json['id'] ?? 0,
        dataReferencia: parseDate(json['dataReferencia']),
        nome: json['nome'] ?? '',
        idPessoa: json['idPessoa'] ?? 0,
        tipoPessoa: json['tipoPessoa'] ?? '',
        formaIdentificacao: json['formaIdentificacao'] ?? '',
        observacao: json['observacao'] ?? '',
        jc: json['jc'] ?? kJcPadrao,
        dataLancamento: parseDate(json['dataLancamento']),
        horaLancamento: json['horaLancamento'] ?? '',
      );
}

class DecendioResumo {
  DecendioResumo({required this.numero, required this.rotulo, required this.quantidade, required this.total});
  final int numero;
  final String rotulo;
  final int quantidade;
  final double total;
}

DateTime parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  final raw = value.toString().trim();
  return DateTime.tryParse(raw) ?? tryParseBrDate(raw) ?? DateTime.now();
}

DateTime? tryParseBrDate(String raw) {
  final valor = raw.trim();
  if (valor.isEmpty) return null;
  try {
    return brDate.parseStrict(valor);
  } catch (_) {
    return null;
  }
}

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

double parseValor(String raw) {
  final clean = raw.trim().replaceAll('R\$', '').replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(clean) ?? 0;
}

String formatValorInput(double value) => brMoneyInput.format(value).trim();

String valorSeguro(String? value, List<String> options, {required String fallback}) {
  if (value != null && options.contains(value)) return value;
  if (options.contains(fallback)) return fallback;
  return options.isEmpty ? fallback : options.first;
}

String normalizeText(String raw) {
  const map = {
    'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c',
  };

  final lower = raw.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(map[char] ?? char);
  }
  return buffer.toString();
}

String formatPeriodo(DateTime? inicio, DateTime? fim) {
  if (inicio == null && fim == null) return 'Todo o período';
  if (inicio != null && fim != null) return '${brDate.format(inicio)} até ${brDate.format(fim)}';
  if (inicio != null) return 'Desde ${brDate.format(inicio)}';
  return 'Até ${brDate.format(fim!)}';
}

List<String> subtiposPorOrigem(String origem) {
  switch (origem) {
    case 'Transferência':
      return const ['PIX', 'TED', 'Depósito', 'Boleto'];
    case 'Online':
      return const ['Aplicativo', 'Site', 'PIX Online'];
    case 'Urna':
    default:
      return const ['Presencial'];
  }
}

Future<T?> openSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(heightFactor: 0.92, child: child),
  );
}

class FormScaffold extends StatelessWidget {
  const FormScaffold({super.key, required this.title, required this.children, required this.onSave, this.formKey});
  final String title;
  final List<Widget> children;
  final FutureOr<void> Function() onSave;
  final GlobalKey<FormState>? formKey;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [TextButton(onPressed: () async => onSave(), child: const Text('Salvar'))],
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            children: children,
          ),
        ),
      ),
    );
  }
}

class DateSelector extends StatelessWidget {
  const DateSelector({super.key, required this.label, required this.value, required this.onChanged});
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(brDate.format(value)),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDate: value,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

class AppDropdown extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText = 'Selecionar',
    this.enabled = true,
  });
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final String labelText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selected = items.contains(value) ? value : (items.isEmpty ? null : items.first);
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: InputDecoration(labelText: labelText),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: !enabled
          ? null
          : (v) {
              if (v != null) onChanged(v);
            },
    );
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.onChanged, this.hintText = 'Pesquisar', this.controller});
  final ValueChanged<String> onChanged;
  final String hintText;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: hintText),
    );
  }
}

class FormSectionLabel extends StatelessWidget {
  const FormSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
    );
  }
}

class BrDateFormField extends StatelessWidget {
  const BrDateFormField({super.key, required this.controller, required this.labelText, required this.onPickDate});
  final TextEditingController controller;
  final String labelText;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      inputFormatters: [BrDateTextInputFormatter()],
      decoration: InputDecoration(
        labelText: labelText,
        hintText: 'dd/mm/aaaa',
        suffixIcon: IconButton(onPressed: onPickDate, icon: const Icon(Icons.calendar_month)),
      ),
      validator: (value) {
        if (tryParseBrDate(value ?? '') == null) return 'Informe uma data válida no formato dd/mm/aaaa.';
        return null;
      },
    );
  }
}

class CompactDateFilterField extends StatelessWidget {
  const CompactDateFilterField({super.key, required this.label, required this.value, required this.onTap, this.onClear});
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onClear != null)
                IconButton(onPressed: onClear, icon: const Icon(Icons.close), tooltip: 'Limpar data'),
              const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.calendar_month)),
            ],
          ),
        ),
        child: Text(value == null ? 'Selecionar' : brDate.format(value!), style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class SummaryStatTile extends StatelessWidget {
  const SummaryStatTile({super.key, required this.icon, required this.title, required this.value, required this.subtitle});
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(backgroundColor: kSoftGreen, child: Icon(icon, color: kAccent)),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(subtitle, style: const TextStyle(color: Colors.black54), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DecendioStatCard extends StatelessWidget {
  const DecendioStatCard({super.key, required this.resumo, required this.width});
  final DecendioResumo resumo;
  final double width;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${resumo.numero}º decêndio', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(resumo.rotulo, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            Text(brMoney.format(resumo.total), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${resumo.quantidade} lançamento(s)', style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );

    if (!width.isFinite) return card;
    return SizedBox(width: width, child: card);
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: kSoftGreen, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kAccent),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class BrDateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 8; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 3) && i != digits.length - 1) buffer.write('/');
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class BrMoneyTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final cents = int.parse(digits);
    final text = formatValorInput(cents / 100);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

Future<String?> pickStringFromList(BuildContext context, {required String title, required List<String> options}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SelectionSheet(title: title, options: options),
  );
}

class _SelectionSheet extends StatefulWidget {
  const _SelectionSheet({required this.title, required this.options});
  final String title;
  final List<String> options;

  @override
  State<_SelectionSheet> createState() => _SelectionSheetState();
}

class _SelectionSheetState extends State<_SelectionSheet> {
  String busca = '';

  @override
  Widget build(BuildContext context) {
    final filtrados = widget.options.where((item) => normalizeText(item).contains(normalizeText(busca))).toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            SearchBox(hintText: 'Buscar na lista', onChanged: (value) => setState(() => busca = value)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: filtrados.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = filtrados[index];
                  return ListTile(contentPadding: EdgeInsets.zero, title: Text(item), onTap: () => Navigator.pop(context, item));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderWithAction extends StatelessWidget {
  const HeaderWithAction({super.key, required this.title, required this.subtitle, required this.buttonLabel, required this.onPressed});
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          FilledButton.icon(onPressed: onPressed, icon: const Icon(Icons.add), label: Text(buttonLabel)),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(backgroundColor: kSoftGreen, child: Icon(icon, color: kAccent)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                Text(title, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class MenuTile extends StatelessWidget {
  const MenuTile({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: kSoftGreen, child: Icon(icon, color: kAccent)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.show, required this.message});
  final bool show;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(message, style: const TextStyle(color: Colors.black54))),
      ),
    );
  }
}
