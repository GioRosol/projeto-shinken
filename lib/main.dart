
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
  String busca = '';

  @override
  Widget build(BuildContext context) {
    final dados = widget.store.donativos.where((d) => d.nome.toLowerCase().contains(busca.toLowerCase())).toList()
      ..sort((a, b) => b.data.compareTo(a.data));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeaderWithAction(
          title: 'Donativos',
          subtitle: 'Urna, transferência, online e relatórios.',
          buttonLabel: 'Novo',
          onPressed: () => openSheet(context, DonativoForm(store: widget.store)),
        ),
        SearchBox(onChanged: (v) => setState(() => busca = v)),
        const SizedBox(height: 12),
        for (final item in dados)
          Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.volunteer_activism, color: kAccent)),
              title: Text(item.nome.isEmpty ? 'Sem nome' : item.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${brDate.format(item.data)} • ${item.tipoDonativo} • ${item.origem}'),
              trailing: Text(brMoney.format(item.valor), style: const TextStyle(fontWeight: FontWeight.w800)),
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
  String busca = '';

  @override
  Widget build(BuildContext context) {
    final dados = widget.store.frequencias.where((f) => f.nome.toLowerCase().contains(busca.toLowerCase())).toList()
      ..sort((a, b) => b.data.compareTo(a.data));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeaderWithAction(
          title: 'Frequência',
          subtitle: 'Dia a dia, culto mensal e eventos.',
          buttonLabel: 'Lançar',
          onPressed: () => openSheet(context, FrequenciaForm(store: widget.store)),
        ),
        SearchBox(onChanged: (v) => setState(() => busca = v)),
        const SizedBox(height: 12),
        for (final item in dados)
          Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.event_available, color: kAccent)),
              title: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${brDate.format(item.data)} • ${item.tipoEvento} • ${item.tipoPessoaAtual}'),
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
  const DonativoForm({super.key, required this.store});
  final AppStore store;

  @override
  State<DonativoForm> createState() => _DonativoFormState();
}

class _DonativoFormState extends State<DonativoForm> {
  final nome = TextEditingController();
  final valor = TextEditingController();
  final tipoManual = TextEditingController();
  DateTime data = DateTime.now();
  String tipoPessoa = 'Membro';
  String tipoDonativo = 'Mensal';
  String origem = 'Urna';
  String subtipo = 'Presencial';
  String tipoOrigemNome = 'Pessoa';

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Novo donativo',
      children: [
        DateSelector(label: 'Data', value: data, onChanged: (v) => setState(() => data = v)),
        TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 12),
        TextField(controller: valor, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor')),
        const SizedBox(height: 12),
        AppDropdown(value: tipoPessoa, items: const ['Membro', 'Frequentador', 'Outro'], onChanged: (v) => setState(() => tipoPessoa = v)),
        const SizedBox(height: 12),
        AppDropdown(value: tipoDonativo, items: const ['Mensal', 'Diário', 'Construção', 'Prece', 'Reconsagração', 'Revista', 'Sorei Saishi', 'Outro'], onChanged: (v) => setState(() => tipoDonativo = v)),
        const SizedBox(height: 12),
        TextField(controller: tipoManual, decoration: const InputDecoration(labelText: 'Tipo manual, se for Outro')),
        const SizedBox(height: 12),
        AppDropdown(value: origem, items: const ['Urna', 'Transferência', 'Online'], onChanged: (v) => setState(() => origem = v)),
        const SizedBox(height: 12),
        AppDropdown(value: subtipo, items: const ['Presencial', 'PIX', 'Boleto', 'Aplicativo'], onChanged: (v) => setState(() => subtipo = v)),
        const SizedBox(height: 12),
        AppDropdown(value: tipoOrigemNome, items: const ['Pessoa', 'Referencia'], onChanged: (v) => setState(() => tipoOrigemNome = v)),
      ],
      onSave: () {
        widget.store.addDonativo(Donativo(
          id: widget.store.nextDonativoId(),
          data: data,
          nome: nome.text.trim(),
          jc: kJcPadrao,
          tipoPessoa: tipoPessoa,
          tipoDonativo: tipoDonativo,
          tipoDonativoManual: tipoManual.text.trim(),
          origem: origem,
          subtipo: subtipo,
          valor: parseValor(valor.text),
          comprovante: '',
          tipoOrigemNome: tipoOrigemNome,
          idReferencia: '',
        ));
        Navigator.pop(context);
      },
    );
  }
}

class FrequenciaForm extends StatefulWidget {
  const FrequenciaForm({super.key, required this.store});
  final AppStore store;

  @override
  State<FrequenciaForm> createState() => _FrequenciaFormState();
}

class _FrequenciaFormState extends State<FrequenciaForm> {
  final nome = TextEditingController();
  final obs = TextEditingController();
  DateTime data = DateTime.now();
  String tipoEvento = 'Dia a dia';
  String tipoPessoa = 'Membro';

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Lançar frequência',
      children: [
        DateSelector(label: 'Data', value: data, onChanged: (v) => setState(() => data = v)),
        TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 12),
        AppDropdown(value: tipoEvento, items: const ['Dia a dia', 'Culto Mensal', 'Oração pela Construção do Paraíso no Lar'], onChanged: (v) => setState(() => tipoEvento = v)),
        const SizedBox(height: 12),
        AppDropdown(value: tipoPessoa, items: const ['Membro', 'Frequentador', '1ª vez'], onChanged: (v) => setState(() => tipoPessoa = v)),
        const SizedBox(height: 12),
        TextField(controller: obs, decoration: const InputDecoration(labelText: 'Observação')),
      ],
      onSave: () {
        widget.store.addFrequencia(Frequencia(
          id: widget.store.nextFrequenciaId(),
          data: data,
          tipoEvento: tipoEvento,
          nome: nome.text.trim(),
          tipoPessoaInformado: tipoPessoa,
          tipoPessoaAtual: tipoPessoa,
          jc: kJcPadrao,
          observacao: obs.text.trim(),
          dataLancamento: DateTime.now(),
          horaLancamento: TimeOfDay.now().format(context),
        ));
        Navigator.pop(context);
      },
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
    final bancoLocalVazio = pessoas.isEmpty &&
        donativos.isEmpty &&
        frequencias.isEmpty &&
        experiencias.isEmpty &&
        referencias.isEmpty &&
        onlineIdentificacoes.isEmpty;

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

    await prefs.setString('pessoas', jsonEncode(pessoas.map((e) => e.toJson()).toList()));
    await prefs.setString('donativos', jsonEncode(donativos.map((e) => e.toJson()).toList()));
    await prefs.setString('frequencias', jsonEncode(frequencias.map((e) => e.toJson()).toList()));
    await prefs.setString('experiencias', jsonEncode(experiencias.map((e) => e.toJson()).toList()));
    await prefs.setString('referencias', jsonEncode(referencias.map((e) => e.toJson()).toList()));
    await prefs.setString('online_identificacoes', jsonEncode(onlineIdentificacoes.map((e) => e.toJson()).toList()));
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

  Future<void> _saveList<T>(String key, List<T> values, Map<String, dynamic> Function(T) toJson) async {
    await prefs.setString(key, jsonEncode(values.map(toJson).toList()));
    notifyListeners();
  }

  Future<void> addPessoa(Pessoa value) async {
    pessoas.add(value);
    await _saveList('pessoas', pessoas, (e) => e.toJson());
  }

  Future<void> addDonativo(Donativo value) async {
    donativos.add(value);
    await _saveList('donativos', donativos, (e) => e.toJson());
  }

  Future<void> addFrequencia(Frequencia value) async {
    frequencias.add(value);
    await _saveList('frequencias', frequencias, (e) => e.toJson());
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

  int nextPessoaId() => pessoas.isEmpty ? 1 : pessoas.map((e) => e.idPessoa).reduce((a, b) => a > b ? a : b) + 1;
  int nextDonativoId() => donativos.isEmpty ? 1 : donativos.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextFrequenciaId() => frequencias.isEmpty ? 1 : frequencias.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextExperienciaId() => experiencias.isEmpty ? 1 : experiencias.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextOnlineId() => onlineIdentificacoes.isEmpty ? 1 : onlineIdentificacoes.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  String nextReferenciaId() => 'REF${(referencias.length + 1).toString().padLeft(6, '0')}';

  double totalDonativosMes(DateTime date) {
    return donativos.where((d) => d.data.year == date.year && d.data.month == date.month).fold(0.0, (sum, d) => sum + d.valor);
  }

  int presencasMes(DateTime date) {
    return frequencias.where((f) => f.data.year == date.year && f.data.month == date.month).length;
  }

  List<DecendioResumo> decendios(DateTime date) {
    final ranges = [
      (1, '1 a 10', 1, 10),
      (2, '11 a 20', 11, 20),
      (3, '21 ao fim do mês', 21, 31),
    ];
    return ranges.map((r) {
      final dados = donativos.where((d) => d.data.year == date.year && d.data.month == date.month && d.data.day >= r.$3 && d.data.day <= r.$4).toList();
      return DecendioResumo(numero: r.$1, rotulo: r.$2, quantidade: dados.length, total: dados.fold(0.0, (sum, d) => sum + d.valor));
    }).toList();
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
        valor: (json['valor'] ?? 0).toDouble(),
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
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

double parseValor(String raw) {
  final clean = raw.trim().replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(clean) ?? 0;
}

void openSheet(BuildContext context, Widget child) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(heightFactor: 0.92, child: child),
  );
}

class FormScaffold extends StatelessWidget {
  const FormScaffold({super.key, required this.title, required this.children, required this.onSave});
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [TextButton(onPressed: onSave, child: const Text('Salvar'))],
        ),
        body: ListView(
          padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          children: children,
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
  const AppDropdown({super.key, required this.value, required this.items, required this.onChanged});
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Selecionar'),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
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

class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Pesquisar'),
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
