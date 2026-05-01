import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const kJcPadrao = 'Johrei Center Betim';
const kAccent = Color(0xFF1B5E20);
const kSoftGreen = Color(0xFFE8F5E9);
const kTextDark = Color(0xFF1F1F1F);

// Supabase - Projeto Shinken
const kSupabaseUrl = 'https://efjepzydpzmsgokpzhxm.supabase.co';
const kSupabasePublishableKey = 'sb_publishable_nwJNB7j7JB3Qwka7PpiHzA_a0XHrJbT';
const kComprovantesBucket = 'comprovantes';
const kExperienciasBucket = 'experiencias-fe';
const kPessoasFotosBucket = 'pessoas-fotos';
const kJohvensFotosBucket = 'johvens-fotos';
const kMaxArquivoExperienciaBytes = 5 * 1024 * 1024;
const kMaxFotoPessoaBytes = 2 * 1024 * 1024;
const kMaxFotoJohvemAtividadeBytes = 4 * 1024 * 1024;
const kLoginDominioInterno = 'projetoshinken.local';
const kTempoBloqueioPadrao = Duration(minutes: 15);

final kNavigatorKey = GlobalKey<NavigatorState>();
final kScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final brDate = DateFormat('dd/MM/yyyy');
final brMoney = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final brMoneyInput = NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2);

const kFiltroTodos = 'Todos';
const kFiltroTodasOrigens = 'Todas';
const kTiposPessoaDonativo = ['Membro', 'Frequentador', 'Outro'];
const kTiposPessoaFrequencia = ['Membro', 'Frequentador', '1ª vez'];
const kTiposDonativo = ['Mensal', 'Diário', 'Construção', 'Prece', 'Reconsagração', 'Revista', 'Sorei Saishi', 'Outro'];
const kOrigensDonativo = ['Urna', 'Transferência', 'Online'];
const kSubtipoOnlineOficial = 'Oficial acumulado';
const kSubtipoOnlineIdentificado = 'Identificado';
const kTiposOrigemNomeDonativo = ['Pessoa', 'Referencia'];
const kTiposEventoPadrao = ['Dia a dia', 'Culto Mensal', 'Oração pela Construção do Paraíso no Lar'];
const kBancosTransferencia = ['Itaú', 'Banco do Brasil', 'Bradesco'];
const kStatusExperiencia = ['Em produção', 'Revisar', 'Pronta', 'Apresentada', 'Arquivada'];
const kTagsExperiencia = ['Johrei', 'Gratidão', 'Doença', 'Pobreza', 'Conflito', 'Família', 'Trabalho', 'Belo', 'Encaminhamento', 'Milagre', 'Mudança interior', 'Dedicação'];
const kCursosEnsinoPadrao = {
  'Nível 1': 26,
  'Nível 2': 17,
  'Nível 3': 26,
  'Nível 4': 20,
  'Pós-Outorga': 6,
};
const kStatusTurmaEnsino = ['Em andamento', 'Concluída', 'Pausada'];
const kStatusAlunoEnsino = ['Em andamento', 'Concluído', 'Pausado', 'Desistente'];
const kStatusPosOutorga = ['Pendente', 'Em andamento', 'Concluído', 'Pausado'];
const kTotalAulasJohvem3 = 20;
const kStatusAlunoJohvem = ['Em andamento', 'Concluído', 'Pausado', 'Desistente'];
const kTiposAtividadeJohvem = ['Dedicação', 'Reunião', 'Culto', 'Vivência', 'Visita', 'Ação missionária', 'Estudo', 'Evento'];

String usuarioParaEmailInterno(String usuario) {
  final valor = usuario.trim();
  if (valor.contains('@')) return valor.toLowerCase();

  final normalizado = valor
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '');

  return '$normalizado@$kLoginDominioInterno';
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabasePublishableKey,
  );
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
          navigatorKey: kNavigatorKey,
          scaffoldMessengerKey: kScaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          title: 'Johrei Center Betim',
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
              : store.isAuthenticated
                  ? AutoLogoutShell(store: store, child: MainShell(store: store))
                  : LoginPage(store: store),
        );
      },
    );
  }
}

class IgrejaLogo extends StatelessWidget {
  const IgrejaLogo({super.key, this.height = 54});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo_igreja_messianica.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text(
        'Igreja Messiânica Mundial do Brasil',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}


class IgrejaSimbolo extends StatelessWidget {
  const IgrejaSimbolo({super.key, this.size = 42});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Image.asset(
          'assets/logo_igreja_messianica_simbolo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.blur_circular_rounded, color: kAccent, size: size * 0.72),
        ),
      ),
    );
  }
}

class IgrejaLogoCentral extends StatelessWidget {
  const IgrejaLogoCentral({super.key, this.height = 128});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/logo_igreja_messianica_central.png',
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const IgrejaLogo(height: 72),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.store});
  final AppStore store;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usuarioController = TextEditingController();
  final senhaController = TextEditingController();
  bool carregando = false;
  String? erro;

  @override
  void dispose() {
    usuarioController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    final usuario = usuarioController.text.trim();
    if (usuario.isEmpty || senhaController.text.isEmpty) {
      setState(() => erro = 'Informe usuário e senha.');
      return;
    }

    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      await widget.store.login(
        email: usuarioParaEmailInterno(usuarioController.text),
        senha: senhaController.text,
      );
    } catch (e) {
      setState(() => erro = limparMensagemErro(e));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const IgrejaLogoCentral(height: 130),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      kJcPadrao,
                      style: TextStyle(fontWeight: FontWeight.w800, color: kAccent),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Entre para acessar os dados no Supabase.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: usuarioController,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(labelText: 'Usuário'),
                    onSubmitted: (_) => entrar(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: senhaController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Senha'),
                    onSubmitted: (_) => entrar(),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 12),
                    Text(erro!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: carregando ? null : entrar,
                    icon: carregando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login),
                    label: const Text('Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class AutoLogoutShell extends StatefulWidget {
  const AutoLogoutShell({super.key, required this.store, required this.child});

  final AppStore store;
  final Widget child;

  @override
  State<AutoLogoutShell> createState() => _AutoLogoutShellState();
}

class _AutoLogoutShellState extends State<AutoLogoutShell> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _ultimaAtividade = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registrarAtividade();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final tempoParado = DateTime.now().difference(_ultimaAtividade);
      if (tempoParado >= kTempoBloqueioPadrao) {
        _bloquearPorInatividade();
      } else {
        _reiniciarTimer();
      }
    }
  }

  void _registrarAtividade() {
    _ultimaAtividade = DateTime.now();
    _reiniciarTimer();
  }

  void _reiniciarTimer() {
    _timer?.cancel();
    if (!widget.store.isAuthenticated) return;
    _timer = Timer(kTempoBloqueioPadrao, _bloquearPorInatividade);
  }

  Future<void> _bloquearPorInatividade() async {
    if (!mounted || !widget.store.isAuthenticated) return;

    kNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    await widget.store.logout();
    kScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Sessão bloqueada por inatividade. Entre novamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _registrarAtividade(),
      onPointerMove: (_) => _registrarAtividade(),
      onPointerSignal: (_) => _registrarAtividade(),
      child: widget.child,
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int index = 0;

  void selecionarAba(int novaAba) {
    setState(() => index = novaAba);
  }

  void abrirMenuMais() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void abrirPerfil() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar perfil',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: ContaSistemaPanel(store: widget.store),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(store: widget.store),
      DonativosPage(store: widget.store),
      FrequenciaPage(store: widget.store),
      EnsinoPage(store: widget.store),
      ExperienciasPage(store: widget.store),
    ];

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: MenuSistemaDrawer(store: widget.store),
      endDrawerEnableOpenDragGesture: true,
      appBar: AppBar(
        toolbarHeight: 92,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo_igreja_messianica_central.png',
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const IgrejaLogo(height: 34),
            ),
            const SizedBox(height: 6),
            const Text(
              kJcPadrao,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kAccent),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Minha conta',
            onPressed: abrirPerfil,
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Menu',
            onPressed: abrirMenuMais,
            icon: const Icon(Icons.menu_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Painel'),
          NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined), selectedIcon: Icon(Icons.volunteer_activism), label: 'Donativos'),
          NavigationDestination(icon: Icon(Icons.event_available_outlined), selectedIcon: Icon(Icons.event_available), label: 'Frequência'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Ensino'),
          NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'Experiências'),
        ],
      ),
    );
  }
}

class MenuSistemaDrawer extends StatelessWidget {
  const MenuSistemaDrawer({super.key, required this.store});
  final AppStore store;

  void _abrirPagina(BuildContext context, Widget page) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      kNavigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => page));
    });
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final larguraMenu = largura < 430 ? largura * 0.86 : 360.0;

    return SizedBox(
      width: larguraMenu,
      child: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(26)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Menu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                          SizedBox(height: 2),
                          Text(kJcPadrao, style: TextStyle(color: kAccent, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                  children: [
                    MenuTile(
                      icon: Icons.account_balance_outlined,
                      title: 'Depósito JC',
                      subtitle: 'Transferências pendentes para lançar no site.',
                      onTap: () => _abrirPagina(context, DepositoJcPage(store: store)),
                    ),
                    MenuTile(
                      icon: Icons.people_alt_outlined,
                      title: 'Pessoas',
                      subtitle: '${store.pessoas.length} pessoa(s) cadastrada(s)',
                      onTap: () => _abrirPagina(
                        context,
                        ModulePageShell(title: 'Pessoas', child: PessoasPage(store: store)),
                      ),
                    ),
                    MenuTile(
                      icon: Icons.link,
                      title: 'Referências',
                      subtitle: '${store.referencias.length} referência(s)',
                      onTap: () => _abrirPagina(context, ReferenciasPage(store: store)),
                    ),
                    MenuTile(
                      icon: Icons.alternate_email,
                      title: 'Online',
                      subtitle: 'Oficial acumulado e identificados',
                      onTap: () => _abrirPagina(context, OnlinePage(store: store)),
                    ),
                    MenuTile(
                      icon: Icons.groups_2_outlined,
                      title: 'Johvens',
                      subtitle: '${store.johvensAutomaticos.length} johvem(ns) de 12 a 35 anos',
                      onTap: () => _abrirPagina(context, JohvensPage(store: store)),
                    ),
                    MenuTile(
                      icon: Icons.settings,
                      title: 'Configurações',
                      subtitle: 'JC fixo, atualização e conta.',
                      onTap: () => _abrirPagina(context, ConfigPage(store: store)),
                    ),
                    MenuTile(
                      icon: Icons.account_circle_outlined,
                      title: 'Minha Conta',
                      subtitle: 'Usuário, permissões e sair.',
                      onTap: () => _abrirPagina(context, MinhaContaPage(store: store)),
                    ),
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


class ContaSistemaPanel extends StatelessWidget {
  const ContaSistemaPanel({super.key, required this.store});
  final AppStore store;

  String get usuarioLogado {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    if (email.isEmpty) return 'Usuário logado';
    final usuario = email.split('@').first;
    if (usuario.isEmpty) return email;
    return '${usuario[0].toUpperCase()}${usuario.substring(1)}';
  }

  Future<void> _sair(BuildContext context) async {
    await store.logout();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final larguraMenu = largura < 430 ? largura * 0.86 : 360.0;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: larguraMenu,
        child: Drawer(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(26)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Minha Conta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                            SizedBox(height: 2),
                            Text(kJcPadrao, style: TextStyle(color: kAccent, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 28,
                                    backgroundColor: kSoftGreen,
                                    child: Icon(Icons.person, color: kAccent),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(usuarioLogado, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 2),
                                        const Text('Perfil: Admin', style: TextStyle(color: kAccent, fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const Text('Permissões', style: TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 8),
                              const Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(label: Text('Donativos')),
                                  Chip(label: Text('Frequência')),
                                  Chip(label: Text('Ensino')),
                                  Chip(label: Text('Experiências')),
                                  Chip(label: Text('Johvens')),
                                  Chip(label: Text('Pessoas')),
                                  Chip(label: Text('Configurações')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Controle de permissões detalhadas será ativado em uma próxima etapa. Por enquanto, este usuário está com acesso total.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.lock_clock_outlined),
                          title: Text('Bloqueio automático'),
                          subtitle: Text('Após 15 minutos sem uso, o app volta para o login.'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _sair(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('Sair da conta'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModulePageShell extends StatelessWidget {
  const ModulePageShell({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: child),
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
        const SectionTitle(kJcPadrao),
        const SizedBox(height: 8),
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
            KpiCard(
              title: 'Ensino',
              value: '${store.ensinoAlunosEmCurso}',
              subtitle: '${store.ensinoTurmasAtivas} turma(s) ativa(s)',
              icon: Icons.school_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EnsinoPage(store: store))),
            ),
            KpiCard(
              title: 'Johvens',
              value: '${store.johvensAutomaticos.length}',
              subtitle: '${store.johvem3AlunosEmCurso} no Johvem 3',
              icon: Icons.groups_2_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JohvensPage(store: store))),
            ),
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
    final temOnlineIdentificado = dados.any((item) => item.ehOnlineIdentificado);

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
        if (temOnlineIdentificado) ...[
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Online identificado aparece na lista e no histórico da pessoa, mas não entra no total oficial para evitar duplicidade.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${brDate.format(item.data)} • ${item.tipoDonativoExibicao} • ${item.origem} • ${item.subtipo}'),
                  if (item.origem == 'Transferência' && item.banco.trim().isNotEmpty)
                    Text('Banco: ${item.banco}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  if (item.ehOnlineOficial)
                    const Text('Online oficial: entra nos totais pelo acumulado.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  if (item.ehOnlineIdentificado)
                    const Text('Online identificado: histórico pessoal, sem somar no oficial.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  if (item.temComprovante) ...[
                    const SizedBox(height: 4),
                    Text('📎 ${item.nomeComprovante}', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
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
    await openSheet(context, FrequenciaContinuaPage(store: widget.store));
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
  String filtroTipo = kFiltroTodos;
  String filtroSituacao = kFiltroTodos;
  String filtroOutorga = kFiltroTodos;

  Future<void> abrirForm([Pessoa? pessoa]) async {
    await openSheet(context, PessoaForm(store: widget.store, initialValue: pessoa));
  }

  bool _passaFiltros(Pessoa pessoa) {
    final q = normalizeText(busca);
    final texto = normalizeText([
      pessoa.nome,
      pessoa.codigoMembro,
      pessoa.telefoneCelular,
      pessoa.telefoneResidencial,
      pessoa.bairro,
      pessoa.cidade,
    ].where((e) => e.trim().isNotEmpty).join(' '));

    if (q.isNotEmpty && !texto.contains(q)) return false;
    if (filtroTipo != kFiltroTodos && pessoa.tipoPessoaAtual != filtroTipo) return false;
    if (filtroSituacao != kFiltroTodos && pessoa.situacaoMembro != filtroSituacao) return false;
    if (filtroOutorga != kFiltroTodos && pessoa.tipoOutorga != filtroOutorga) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final dados = widget.store.pessoas.where(_passaFiltros).toList()
      ..sort((a, b) => normalizeText(a.nome).compareTo(normalizeText(b.nome)));
    final totalMembros = widget.store.pessoas.where((p) => p.codigoMembro.trim().isNotEmpty).length;
    final totalSemCodigo = widget.store.pessoas.length - totalMembros;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeaderWithAction(
          title: 'Pessoas',
          subtitle: 'Base central com membros, frequentadores e 1ª vez.',
          buttonLabel: 'Adicionar',
          onPressed: () => abrirForm(),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InfoChip(icon: Icons.groups_outlined, label: '${widget.store.pessoas.length} pessoas'),
            InfoChip(icon: Icons.verified_outlined, label: '$totalMembros membros'),
            InfoChip(icon: Icons.person_add_alt_1_outlined, label: '$totalSemCodigo sem código'),
          ],
        ),
        const SizedBox(height: 12),
        SearchBox(hintText: 'Buscar por nome, código, telefone, bairro ou cidade', onChanged: (v) => setState(() => busca = v)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 180,
              child: AppDropdown(
                value: filtroTipo,
                labelText: 'Tipo',
                items: const [kFiltroTodos, ...kTiposPessoaFrequencia],
                onChanged: (v) => setState(() => filtroTipo = v),
              ),
            ),
            SizedBox(
              width: 180,
              child: AppDropdown(
                value: filtroSituacao,
                labelText: 'Situação',
                items: const [kFiltroTodos, 'ATI', 'AFA'],
                onChanged: (v) => setState(() => filtroSituacao = v),
              ),
            ),
            SizedBox(
              width: 160,
              child: AppDropdown(
                value: filtroOutorga,
                labelText: 'Outorga',
                items: const [kFiltroTodos, 'OH', 'SH'],
                onChanged: (v) => setState(() => filtroOutorga = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final item in dados)
          Card(
            child: ListTile(
              onTap: () => abrirForm(item),
              leading: PessoaAvatar(store: widget.store, pessoa: item, radius: 24),
              title: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.descricaoPrincipal, style: const TextStyle(color: Colors.black54)),
                    if (item.descricaoContatoEndereco.isNotEmpty)
                      Text(item.descricaoContatoEndereco, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                  ],
                ),
              ),
              trailing: PopupMenuButton<String>(
                tooltip: 'Mais opções',
                onSelected: (value) {
                  if (value == 'editar') abrirForm(item);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                ],
              ),
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
          icon: Icons.account_balance_outlined,
          title: 'Depósito JC',
          subtitle: 'Transferências pendentes para lançar no site.',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DepositoJcPage(store: store))),
        ),
        MenuTile(
          icon: Icons.people_alt_outlined,
          title: 'Pessoas',
          subtitle: '${store.pessoas.length} pessoa(s) cadastrada(s)',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PessoasPage(store: store))),
        ),
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
          title: 'Online',
          subtitle: 'Oficial acumulado e identificados',
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

class DepositoJcPage extends StatefulWidget {
  const DepositoJcPage({super.key, required this.store});
  final AppStore store;

  @override
  State<DepositoJcPage> createState() => _DepositoJcPageState();
}

class _DepositoJcPageState extends State<DepositoJcPage> {
  bool mostrarLancados = false;

  List<Donativo> get dados {
    final lista = widget.store.donativos.where((item) {
      if (item.origem != 'Transferência') return false;
      return mostrarLancados ? item.depositoLancado : !item.depositoLancado;
    }).toList();
    lista.sort((a, b) => b.data.compareTo(a.data));
    return lista;
  }

  Future<void> copiar(String rotulo, String valor) async {
    final texto = valor.trim().isEmpty ? 'Não informado' : valor.trim();
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$rotulo copiado.')));
  }

  Future<void> visualizarComprovante(Donativo item) async {
    final arquivo = item.comprovanteArquivo;
    if (arquivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este lançamento não tem comprovante anexado.')));
      return;
    }

    try {
      final link = await widget.store.criarLinkTemporarioComprovante(item);
      if (link == null || link.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este lançamento não tem comprovante disponível na nuvem.')));
        return;
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => ComprovantePreviewDialog(
          arquivo: arquivo,
          link: link,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(limparMensagemErro(e))));
    }
  }

  Future<void> alternarStatus(Donativo item) async {
    await widget.store.marcarDepositoJc(item.id, lancado: !item.depositoLancado);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(item.depositoLancado ? 'Transferência voltou para pendente.' : 'Transferência marcada como lançada.')),
    );
  }

  Widget linhaCopiavel({required String rotulo, required String valorVisivel, required String valorCopiar, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E7DF)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: kSoftGreen,
            child: Icon(icon, size: 18, color: kAccent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotulo, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(valorVisivel.trim().isEmpty ? 'Não informado' : valorVisivel, style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Copiar $rotulo',
            onPressed: () => copiar(rotulo, valorCopiar),
            icon: const Icon(Icons.copy_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = dados;
    return Scaffold(
      appBar: AppBar(title: const Text('Depósito JC')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Transferências para lançar'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Copie banco, data e valor campo por campo usando o ícone de copiar. Depois confira o comprovante e conclua o lançamento.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: mostrarLancados,
                    title: const Text('Mostrar já lançados'),
                    onChanged: (v) => setState(() => mostrarLancados = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final item in lista)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.account_balance, color: kAccent)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.nome.isEmpty ? 'Sem nome' : item.nome, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${brDate.format(item.data)} • ${brMoney.format(item.valor)}', style: const TextStyle(color: Colors.black54)),
                              if (item.temComprovante) Text('Comprovante: ${item.nomeComprovante}', style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                        Chip(label: Text(item.depositoStatus)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    linhaCopiavel(
                      rotulo: 'Banco',
                      valorVisivel: item.banco.trim().isEmpty ? 'Não informado' : item.banco,
                      valorCopiar: item.banco,
                      icon: Icons.account_balance_outlined,
                    ),
                    linhaCopiavel(
                      rotulo: 'Data da transferência',
                      valorVisivel: brDate.format(item.data),
                      valorCopiar: brDate.format(item.data),
                      icon: Icons.calendar_today_outlined,
                    ),
                    linhaCopiavel(
                      rotulo: 'Valor',
                      valorVisivel: brMoney.format(item.valor),
                      valorCopiar: brMoneyInput.format(item.valor).trim(),
                      icon: Icons.attach_money,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: item.temComprovante ? () => visualizarComprovante(item) : null,
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Ver comprovante'),
                        ),
                        FilledButton.icon(
                          onPressed: () => alternarStatus(item),
                          icon: Icon(item.depositoLancado ? Icons.undo : Icons.check_circle_outline),
                          label: Text(item.depositoLancado ? 'Voltar para pendente' : 'Concluir lançamento'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          EmptyState(show: lista.isEmpty, message: mostrarLancados ? 'Nenhuma transferência lançada.' : 'Nenhuma transferência pendente.'),
        ],
      ),
    );
  }
}

class ComprovantePreviewDialog extends StatelessWidget {
  const ComprovantePreviewDialog({super.key, required this.arquivo, required this.link, this.titulo = 'Comprovante'});

  final ComprovanteArquivo arquivo;
  final String link;
  final String titulo;

  bool get _ehImagem {
    final ext = arquivo.extensao.toLowerCase().replaceAll('.', '').trim();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'].contains(ext) || contentTypeForFile(arquivo.nome).startsWith('image/');
  }

  Future<void> _abrirEmNovaAba(BuildContext context) async {
    final abriu = await launchUrl(Uri.parse(link), webOnlyWindowName: '_blank');
    if (!abriu && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o comprovante em nova aba.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.receipt_long, color: kAccent)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        Text(arquivo.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _ehImagem
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.04),
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 5,
                            child: Center(
                              child: Image.network(
                                link,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (_, __, ___) => const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('Não foi possível carregar a pré-visualização.'),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.picture_as_pdf_outlined, size: 64, color: kAccent),
                            const SizedBox(height: 12),
                            Text(arquivo.nome, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            const Text(
                              'Este tipo de arquivo abre melhor em uma nova aba.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _abrirEmNovaAba(context),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Abrir em nova aba'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ExperienciasPage extends StatefulWidget {
  const ExperienciasPage({super.key, required this.store});
  final AppStore store;

  @override
  State<ExperienciasPage> createState() => _ExperienciasPageState();
}

class _ExperienciasPageState extends State<ExperienciasPage> {
  final buscaController = TextEditingController();
  String busca = '';
  String statusFiltro = kFiltroTodos;
  String tagFiltro = kFiltroTodos;

  List<String> get tagsDisponiveis {
    final tags = <String>{...kTagsExperiencia};
    for (final item in widget.store.experiencias) {
      tags.addAll(item.tags);
    }
    final lista = tags.where((e) => e.trim().isNotEmpty).toList();
    lista.sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
    return [kFiltroTodos, ...lista];
  }

  List<String> get statusDisponiveis {
    final status = <String>{...kStatusExperiencia};
    for (final item in widget.store.experiencias) {
      if (item.status.trim().isNotEmpty) status.add(item.status.trim());
    }
    final lista = status.toList();
    lista.sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
    return [kFiltroTodos, ...lista];
  }

  List<ExperienciaFe> get dadosFiltrados {
    final termo = normalizeText(busca);
    final dados = widget.store.experiencias.where((item) {
      final texto = normalizeText('${item.nome} ${item.titulo} ${item.resumo} ${item.tema} ${item.observacao}');
      final matchBusca = termo.isEmpty || texto.contains(termo);
      final matchStatus = statusFiltro == kFiltroTodos || item.status == statusFiltro;
      final matchTag = tagFiltro == kFiltroTodos || item.tags.map(normalizeText).contains(normalizeText(tagFiltro));
      return matchBusca && matchStatus && matchTag;
    }).toList()
      ..sort((a, b) => b.dataRegistro.compareTo(a.dataRegistro));
    return dados;
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  Future<void> abrirForm([ExperienciaFe? item]) async {
    await openSheet(context, ExperienciaForm(store: widget.store, initialValue: item));
  }

  Future<void> excluir(ExperienciaFe item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir experiência?'),
        content: Text('Deseja excluir a experiência de ${item.nome}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await widget.store.deleteExperiencia(item.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Experiência excluída.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(limparMensagemErro(e))));
    }
  }

  Future<void> visualizarArquivo(ExperienciaFe item) async {
    final arquivo = item.arquivoExperiencia;
    if (arquivo == null) return;
    try {
      final link = await widget.store.criarLinkTemporarioExperiencia(item);
      if (link == null || link.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arquivo sem link disponível.')));
        return;
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => ComprovantePreviewDialog(
          arquivo: arquivo,
          link: link,
          titulo: 'Arquivo da experiência',
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(limparMensagemErro(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dados = dadosFiltrados;

    return Scaffold(
      appBar: AppBar(title: const Text('Experiência de Fé')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeaderWithAction(
            title: 'Experiências de Fé',
            subtitle: '${widget.store.experiencias.length} experiência(s) cadastrada(s)',
            buttonLabel: 'Nova',
            onPressed: () => abrirForm(),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Busca e filtros', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  SearchBox(
                    controller: buscaController,
                    hintText: 'Buscar por nome, resumo ou tag',
                    onChanged: (v) => setState(() => busca = v),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 220,
                        child: AppDropdown(
                          value: statusFiltro,
                          labelText: 'Status',
                          items: statusDisponiveis,
                          onChanged: (v) => setState(() => statusFiltro = v),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: AppDropdown(
                          value: tagFiltro,
                          labelText: 'Tag',
                          items: tagsDisponiveis,
                          onChanged: (v) => setState(() => tagFiltro = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final item in dados)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PessoaAvatar(store: widget.store, pessoa: widget.store.findPessoaById(item.idPessoa) ?? widget.store.findPessoaByName(item.nome), radius: 22, fallbackText: item.nome),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.titulo.isEmpty ? 'Sem título' : item.titulo, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(item.nome.isEmpty ? 'Sem pessoa' : item.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (item.resumo.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(item.resumo, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                              ],
                            ],
                          ),
                        ),
                        Chip(label: Text(item.status.isEmpty ? 'Em produção' : item.status)),
                      ],
                    ),
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final tag in item.tags) Chip(label: Text(tag))],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: item.temArquivo ? () => visualizarArquivo(item) : null,
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Ver arquivo'),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          tooltip: 'Mais opções',
                          onSelected: (value) async {
                            if (value == 'editar') {
                              await abrirForm(item);
                            }
                            if (value == 'excluir') {
                              await excluir(item);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'editar',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'excluir',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18),
                                  SizedBox(width: 8),
                                  Text('Excluir'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          EmptyState(show: dados.isEmpty, message: 'Nenhuma experiência encontrada.'),
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

  Future<void> _confirmarExclusao(BuildContext context, Donativo item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir registro online?'),
        content: Text('Deseja excluir ${item.ehOnlineOficial ? 'o acumulado oficial' : item.nome} de ${brDate.format(item.data)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmar != true) return;
    await store.deleteDonativo(item.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro online excluído.')));
  }

  @override
  Widget build(BuildContext context) {
    final oficiais = store.donativos.where((item) => item.ehOnlineOficial).toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    final identificados = store.donativos.where((item) => item.ehOnlineIdentificado).toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    final agora = DateTime.now();
    final onlineOficialMes = store.totalOnlineOficialMes(agora);
    final onlineIdentificadoMes = store.totalOnlineIdentificadoMes(agora);

    return Scaffold(
      appBar: AppBar(title: const Text('Online')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Online'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Controle limpo do Online', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text(
                    'Use “Oficial acumulado” para o valor que vem do site da Igreja. Use “Identificado” quando a pessoa mandar comprovante. O identificado não soma no total oficial para evitar duplicidade.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => openSheet(context, OnlineOficialForm(store: store)),
                        icon: const Icon(Icons.add_chart_outlined),
                        label: const Text('Oficial acumulado'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => openSheet(context, OnlineIdentificadoForm(store: store)),
                        icon: const Icon(Icons.person_add_alt_outlined),
                        label: const Text('Online identificado'),
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
              SummaryStatTile(
                icon: Icons.public_outlined,
                title: 'Online oficial/mês',
                value: brMoney.format(onlineOficialMes),
                subtitle: 'Soma nos totais',
              ),
              SummaryStatTile(
                icon: Icons.badge_outlined,
                title: 'Identificado/mês',
                value: brMoney.format(onlineIdentificadoMes),
                subtitle: 'Só histórico pessoal',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionTitle('Oficial acumulado do site'),
          for (final item in oficiais)
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.trending_up, color: kAccent)),
                title: Text(brMoney.format(item.valor), style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${brDate.format(item.data)} • acumulado oficial do mês'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'excluir') await _confirmarExclusao(context, item);
                  },
                  itemBuilder: (context) => const [PopupMenuItem(value: 'excluir', child: Text('Excluir'))],
                ),
              ),
            ),
          EmptyState(show: oficiais.isEmpty, message: 'Nenhum valor oficial acumulado cadastrado.'),
          const SizedBox(height: 20),
          const SectionTitle('Online identificado'),
          for (final item in identificados)
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.alternate_email, color: kAccent)),
                title: Text(item.nome.isEmpty ? 'Sem nome' : item.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${brDate.format(item.data)} • ${brMoney.format(item.valor)} • não soma no oficial'),
                    if (item.temComprovante) Text('📎 ${item.nomeComprovante}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'excluir') await _confirmarExclusao(context, item);
                  },
                  itemBuilder: (context) => const [PopupMenuItem(value: 'excluir', child: Text('Excluir'))],
                ),
              ),
            ),
          EmptyState(show: identificados.isEmpty, message: 'Nenhum online identificado cadastrado.'),
        ],
      ),
    );
  }
}

class OnlineOficialForm extends StatefulWidget {
  const OnlineOficialForm({super.key, required this.store});
  final AppStore store;

  @override
  State<OnlineOficialForm> createState() => _OnlineOficialFormState();
}

class _OnlineOficialFormState extends State<OnlineOficialForm> {
  final formKey = GlobalKey<FormState>();
  final dataController = TextEditingController(text: brDate.format(DateTime.now()));
  final valor = TextEditingController();

  @override
  void dispose() {
    dataController.dispose();
    valor.dispose();
    super.dispose();
  }

  Future<void> selecionarData() async {
    final atual = tryParseBrDate(dataController.text) ?? DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: atual,
    );
    if (selecionada == null) return;
    setState(() => dataController.text = brDate.format(selecionada));
  }

  Future<void> salvar() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;
    final data = tryParseBrDate(dataController.text)!;

    await widget.store.upsertDonativo(Donativo(
      id: widget.store.nextDonativoId(),
      data: data,
      nome: 'Online oficial acumulado',
      jc: kJcPadrao,
      tipoPessoa: 'Outro',
      tipoDonativo: 'Mensal',
      tipoDonativoManual: '',
      origem: 'Online',
      subtipo: kSubtipoOnlineOficial,
      banco: '',
      valor: parseValor(valor.text),
      comprovante: '',
      tipoOrigemNome: 'Referencia',
      idReferencia: '',
      depositoStatus: '',
      depositoLancadoEm: null,
    ));

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Online oficial acumulado',
      formKey: formKey,
      onSave: salvar,
      children: [
        const Text(
          'Lance aqui o valor acumulado que aparece no site da Igreja. Esse é o valor que entra nos totais oficiais.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        BrDateFormField(controller: dataController, labelText: 'Data da consulta', onPickDate: selecionarData),
        const SizedBox(height: 12),
        TextFormField(
          controller: valor,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [BrMoneyTextInputFormatter()],
          decoration: const InputDecoration(labelText: 'Valor acumulado no site', hintText: '0,00', prefixText: 'R\$ '),
          validator: (value) => parseValor(value ?? '') <= 0 ? 'Informe o valor acumulado.' : null,
        ),
      ],
    );
  }
}

class OnlineIdentificadoForm extends StatefulWidget {
  const OnlineIdentificadoForm({super.key, required this.store});
  final AppStore store;

  @override
  State<OnlineIdentificadoForm> createState() => _OnlineIdentificadoFormState();
}

class _OnlineIdentificadoFormState extends State<OnlineIdentificadoForm> {
  final formKey = GlobalKey<FormState>();
  final dataController = TextEditingController(text: brDate.format(DateTime.now()));
  final nome = TextEditingController();
  final valor = TextEditingController();
  final tipoManual = TextEditingController();
  String tipoPessoa = 'Membro';
  String tipoDonativo = 'Mensal';
  ComprovanteArquivo? comprovanteAtual;

  @override
  void dispose() {
    dataController.dispose();
    nome.dispose();
    valor.dispose();
    tipoManual.dispose();
    super.dispose();
  }

  Future<void> selecionarData() async {
    final atual = tryParseBrDate(dataController.text) ?? DateTime.now();
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
      preencherCategoria(selecionado);
    });
  }

  void preencherCategoria(String raw) {
    final pessoa = widget.store.findPessoaByName(raw);
    if (pessoa != null) tipoPessoa = valorSeguro(pessoa.tipoPessoaAtual, kTiposPessoaDonativo, fallback: 'Membro');
  }

  Future<void> selecionarComprovante({required bool imagem}) async {
    final resultado = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: imagem ? FileType.image : FileType.custom,
      allowedExtensions: imagem ? null : const ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'],
    );

    if (resultado == null || resultado.files.isEmpty) return;
    final arquivo = resultado.files.single;
    final bytes = arquivo.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível ler o arquivo selecionado.')));
      return;
    }

    const limiteBytes = 3 * 1024 * 1024;
    if (bytes.length > limiteBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arquivo muito grande. Use comprovante até 3 MB.')));
      return;
    }

    setState(() {
      comprovanteAtual = ComprovanteArquivo(
        nome: arquivo.name,
        extensao: arquivo.extension ?? '',
        tamanhoBytes: arquivo.size,
        base64: base64Encode(bytes),
        dataAnexo: DateTime.now(),
        path: '',
      );
    });
  }

  Future<void> tirarFotoComprovante() async {
    try {
      final picker = ImagePicker();
      final foto = await picker.pickImage(source: ImageSource.camera, imageQuality: 82, maxWidth: 1600);
      if (foto == null) return;
      final bytes = await foto.readAsBytes();
      if (bytes.isEmpty) return;

      const limiteBytes = 3 * 1024 * 1024;
      if (bytes.length > limiteBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto muito grande. Tire novamente ou use arquivo até 3 MB.')));
        return;
      }

      final nomeArquivo = foto.name.trim().isEmpty ? 'online_${DateTime.now().millisecondsSinceEpoch}.jpg' : foto.name;
      setState(() {
        comprovanteAtual = ComprovanteArquivo(
          nome: nomeArquivo,
          extensao: extensaoArquivo(nomeArquivo, fallback: 'jpg'),
          tamanhoBytes: bytes.length,
          base64: base64Encode(bytes),
          dataAnexo: DateTime.now(),
          path: '',
        );
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível abrir a câmera: ${limparMensagemErro(error)}')));
    }
  }

  Future<void> salvar() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;

    final data = tryParseBrDate(dataController.text)!;
    final pessoa = widget.store.findPessoaByName(nome.text);
    final novoId = widget.store.nextDonativoId();
    var comprovanteFinal = '';

    if (comprovanteAtual != null) {
      comprovanteFinal = await widget.store.salvarComprovanteNoSupabase(donativoId: novoId, comprovante: comprovanteAtual!);
    }

    await widget.store.upsertDonativo(Donativo(
      id: novoId,
      data: data,
      nome: nomeLimpoDeRotuloPessoa(nome.text),
      jc: kJcPadrao,
      tipoPessoa: pessoa?.tipoPessoaAtual ?? tipoPessoa,
      tipoDonativo: tipoDonativo,
      tipoDonativoManual: tipoDonativo == 'Outro' ? tipoManual.text.trim() : '',
      origem: 'Online',
      subtipo: kSubtipoOnlineIdentificado,
      banco: '',
      valor: parseValor(valor.text),
      comprovante: comprovanteFinal,
      tipoOrigemNome: 'Pessoa',
      idReferencia: '',
      depositoStatus: '',
      depositoLancadoEm: null,
    ));

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Online identificado',
      formKey: formKey,
      onSave: salvar,
      children: [
        const Text(
          'Use quando alguém fizer donativo online e mandar comprovante. Este valor fica no histórico da pessoa, mas não soma no total oficial.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        BrDateFormField(controller: dataController, labelText: 'Data do donativo', onPickDate: selecionarData),
        const SizedBox(height: 12),
        TextFormField(
          controller: nome,
          decoration: InputDecoration(
            labelText: 'Nome da pessoa',
            suffixIcon: IconButton(
              onPressed: widget.store.pessoas.isEmpty ? null : selecionarPessoa,
              icon: const Icon(Icons.search),
              tooltip: 'Selecionar da base',
            ),
          ),
          onChanged: (value) => setState(() => preencherCategoria(value)),
          validator: (value) => (value?.trim().isEmpty ?? true) ? 'Informe o nome.' : null,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: widget.store.pessoas.isEmpty ? null : selecionarPessoa,
          icon: const Icon(Icons.list_alt_outlined),
          label: Text('Selecionar da base de pessoas (${widget.store.pessoas.length})'),
        ),
        const SizedBox(height: 12),
        AppDropdown(value: tipoPessoa, labelText: 'Categoria da pessoa', items: kTiposPessoaDonativo, onChanged: (v) => setState(() => tipoPessoa = v)),
        const SizedBox(height: 12),
        TextFormField(
          controller: valor,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [BrMoneyTextInputFormatter()],
          decoration: const InputDecoration(labelText: 'Valor informado', hintText: '0,00', prefixText: 'R\$ '),
          validator: (value) => parseValor(value ?? '') <= 0 ? 'Informe o valor.' : null,
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
        const SizedBox(height: 20),
        ComprovantePickerCard(
          titulo: 'Comprovante online',
          descricao: 'Anexe o comprovante que a pessoa mandou pelo WhatsApp, Fotos ou Arquivos.',
          comprovante: comprovanteAtual,
          onTakePhoto: tirarFotoComprovante,
          onPickImage: () => selecionarComprovante(imagem: true),
          onPickFile: () => selecionarComprovante(imagem: false),
          onRemove: comprovanteAtual == null ? null : () => setState(() => comprovanteAtual = null),
        ),
      ],
    );
  }
}


class JohvensPage extends StatelessWidget {
  const JohvensPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Johvens')),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Lista'),
                Tab(text: 'Johvem 3'),
                Tab(text: 'Atividades'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  JohvensListaTab(store: store),
                  Johvem3Tab(store: store),
                  JohvemAtividadesTab(store: store),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JohvensListaTab extends StatefulWidget {
  const JohvensListaTab({super.key, required this.store});
  final AppStore store;

  @override
  State<JohvensListaTab> createState() => _JohvensListaTabState();
}

class _JohvensListaTabState extends State<JohvensListaTab> {
  String busca = '';

  @override
  Widget build(BuildContext context) {
    final lista = widget.store.johvensAutomaticos.where((p) {
      final texto = normalizeText('${p.nome} ${p.codigoMembro} ${p.tipoPessoaAtual} ${p.tipoOutorga}');
      return texto.contains(normalizeText(busca));
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            KpiCard(title: 'Johvens', value: '${widget.store.johvensAutomaticos.length}', icon: Icons.groups_2_outlined),
            KpiCard(title: 'Membros', value: '${widget.store.johvensMembros}', icon: Icons.verified_user_outlined),
            KpiCard(title: 'Johvem 3', value: '${widget.store.johvem3AlunosEmCurso}', subtitle: 'em curso', icon: Icons.school_outlined),
            KpiCard(title: 'Atividades', value: '${widget.store.johvemAtividades.length}', icon: Icons.photo_library_outlined),
          ],
        ),
        const SizedBox(height: 16),
        SearchBox(onChanged: (v) => setState(() => busca = v), hintText: 'Buscar johvem por nome, código ou tipo'),
        const SizedBox(height: 12),
        for (final pessoa in lista)
          Card(
            child: ListTile(
              leading: PessoaAvatar(store: widget.store, pessoa: pessoa, radius: 24, fallbackText: pessoa.nome),
              title: Text(pessoa.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text([
                '${widget.store.idadePessoa(pessoa)} anos',
                pessoa.tipoPessoaAtual,
                if (pessoa.codigoMembro.isNotEmpty) 'Cód. ${pessoa.codigoMembro}',
                if (pessoa.tipoOutorga.isNotEmpty) pessoa.tipoOutorga,
              ].join(' • ')),
            ),
          ),
        if (lista.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Nenhum johvem encontrado'),
              subtitle: Text('O app calcula automaticamente pessoas de 12 a 35 anos com data de nascimento cadastrada.'),
            ),
          ),
      ],
    );
  }
}

class Johvem3Tab extends StatelessWidget {
  const Johvem3Tab({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final alunos = [...store.johvem3Alunos]..sort((a, b) => normalizeText(a.nomePessoa).compareTo(normalizeText(b.nomePessoa)));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Curso Johvem 3', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('20 aulas • controle por checklist de presença'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => openSheet(context, Johvem3PresencaForm(store: store)),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Lançar presença'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => openSheet(context, Johvem3AlunoForm(store: store)),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('Adicionar aluna/o'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final aluno in alunos)
          Card(
            child: ListTile(
              leading: PessoaAvatar(store: store, pessoa: store.findPessoaById(aluno.idPessoa), radius: 24, fallbackText: aluno.nomePessoa),
              title: Text(aluno.nomePessoa, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${aluno.progressoAulas}/$kTotalAulasJohvem3 aulas • ${aluno.status}'),
              trailing: SizedBox(
                width: 76,
                child: LinearProgressIndicator(
                  value: kTotalAulasJohvem3 == 0 ? 0 : aluno.progressoAulas / kTotalAulasJohvem3,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        if (alunos.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.school_outlined),
              title: Text('Nenhum aluno no Johvem 3'),
              subtitle: Text('Adicione as alunas atuais para começar o controle de presença.'),
            ),
          ),
      ],
    );
  }
}

class Johvem3AlunoForm extends StatefulWidget {
  const Johvem3AlunoForm({super.key, required this.store});
  final AppStore store;

  @override
  State<Johvem3AlunoForm> createState() => _Johvem3AlunoFormState();
}

class _Johvem3AlunoFormState extends State<Johvem3AlunoForm> {
  String nome = '';
  String status = 'Em andamento';

  @override
  void initState() {
    super.initState();
    final opcoes = widget.store.johvensAutomaticos.map((e) => e.nome).toList()..sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
    nome = opcoes.isEmpty ? '' : opcoes.first;
  }

  Future<void> salvar() async {
    final pessoa = widget.store.findPessoaByName(nome);
    if (pessoa == null) throw Exception('Pessoa não encontrada.');
    await widget.store.upsertJohvem3Aluno(Johvem3Aluno(
      id: widget.store.nextJohvem3AlunoId(),
      idPessoa: pessoa.idPessoa,
      codigoMembro: pessoa.codigoMembro,
      nomePessoa: pessoa.nome,
      status: status,
      progressoAulas: 0,
      jc: kJcPadrao,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final opcoes = widget.store.johvensAutomaticos.map((e) => e.nome).toList()..sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
    return FormScaffold(
      title: 'Adicionar ao Johvem 3',
      onSave: salvar,
      children: [
        AppDropdown(value: nome, labelText: 'Johvem', items: opcoes, onChanged: (v) => setState(() => nome = v)),
        const SizedBox(height: 12),
        AppDropdown(value: status, labelText: 'Status', items: kStatusAlunoJohvem, onChanged: (v) => setState(() => status = v)),
      ],
    );
  }
}

class Johvem3PresencaForm extends StatefulWidget {
  const Johvem3PresencaForm({super.key, required this.store});
  final AppStore store;

  @override
  State<Johvem3PresencaForm> createState() => _Johvem3PresencaFormState();
}

class _Johvem3PresencaFormState extends State<Johvem3PresencaForm> {
  int aulaNumero = 1;
  DateTime data = DateTime.now();
  final presentes = <int, bool>{};

  @override
  void initState() {
    super.initState();
    aulaNumero = (widget.store.johvem3Presencas.map((p) => p.aulaNumero).fold<int>(0, (a, b) => a > b ? a : b) + 1).clamp(1, kTotalAulasJohvem3).toInt();
    for (final aluno in widget.store.johvem3Alunos) {
      final ja = widget.store.johvem3Presencas.where((p) => p.idAluno == aluno.id && p.aulaNumero == aulaNumero).toList();
      presentes[aluno.id] = ja.isNotEmpty ? ja.first.presente : true;
    }
  }

  Future<void> salvar() async {
    await widget.store.salvarPresencasJohvem3(aulaNumero: aulaNumero, data: data, presentes: presentes);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final alunos = [...widget.store.johvem3Alunos]..sort((a, b) => normalizeText(a.nomePessoa).compareTo(normalizeText(b.nomePessoa)));
    return FormScaffold(
      title: 'Presença Johvem 3',
      onSave: salvar,
      children: [
        AppDropdown(
          value: aulaNumero.toString(),
          labelText: 'Aula',
          items: List.generate(kTotalAulasJohvem3, (i) => '${i + 1}'),
          onChanged: (v) => setState(() => aulaNumero = int.tryParse(v) ?? 1),
        ),
        DateSelector(label: 'Data da aula', value: data, onChanged: (v) => setState(() => data = v)),
        const SizedBox(height: 8),
        const Text('Presença', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        for (final aluno in alunos)
          CheckboxListTile(
            value: presentes[aluno.id] ?? true,
            onChanged: (v) => setState(() => presentes[aluno.id] = v ?? false),
            title: Text(aluno.nomePessoa),
            subtitle: Text('${aluno.progressoAulas}/$kTotalAulasJohvem3 aulas'),
          ),
        if (alunos.isEmpty) const Text('Adicione alunos antes de lançar presença.'),
      ],
    );
  }
}

class JohvemAtividadesTab extends StatelessWidget {
  const JohvemAtividadesTab({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final atividades = [...store.johvemAtividades]..sort((a, b) => b.data.compareTo(a.data));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => openSheet(context, JohvemAtividadeForm(store: store)),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Registrar atividade'),
        ),
        const SizedBox(height: 12),
        for (final atividade in atividades) JohvemAtividadeCard(store: store, atividade: atividade),
        if (atividades.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.event_note_outlined),
              title: Text('Nenhuma atividade registrada'),
              subtitle: Text('Registre dedicações, reuniões, vivências e ações dos Johvens.'),
            ),
          ),
      ],
    );
  }
}

class JohvemAtividadeCard extends StatelessWidget {
  const JohvemAtividadeCard({super.key, required this.store, required this.atividade});
  final AppStore store;
  final JohvemAtividade atividade;

  @override
  Widget build(BuildContext context) {
    final participantes = store.participantesAtividade(atividade.id);
    final fotos = store.fotosAtividade(atividade.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(atividade.titulo, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 2),
                      Text('${atividade.tipo} • ${brDate.format(atividade.data)}'),
                    ],
                  ),
                ),
                Chip(label: Text('${participantes.length} part.')),
              ],
            ),
            if (atividade.descricao.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(atividade.descricao),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in participantes.take(4)) Chip(label: Text(p.nomePessoa)),
                if (participantes.length > 4) Chip(label: Text('+${participantes.length - 4}')),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: fotos.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => JohvemFotosPage(store: store, atividade: atividade))),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(fotos.isEmpty ? 'Sem fotos' : 'Ver fotos (${fotos.length})'),
            ),
          ],
        ),
      ),
    );
  }
}

class JohvemAtividadeForm extends StatefulWidget {
  const JohvemAtividadeForm({super.key, required this.store});
  final AppStore store;

  @override
  State<JohvemAtividadeForm> createState() => _JohvemAtividadeFormState();
}

class _JohvemAtividadeFormState extends State<JohvemAtividadeForm> {
  String tipo = kTiposAtividadeJohvem.first;
  DateTime data = DateTime.now();
  final titulo = TextEditingController();
  final descricao = TextEditingController();
  final responsavel = TextEditingController();
  final participantes = <int, bool>{};
  final fotos = <ComprovanteArquivo>[];

  @override
  void initState() {
    super.initState();
    for (final pessoa in widget.store.johvensAutomaticos) {
      participantes[pessoa.idPessoa] = false;
    }
  }

  Future<void> escolherFoto({required ImageSource source}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 78, maxWidth: 1600);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.length > kMaxFotoJohvemAtividadeBytes) throw Exception('Foto maior que 4 MB.');
    setState(() {
      fotos.add(ComprovanteArquivo(
        nome: picked.name,
        extensao: extensaoArquivo(picked.name, fallback: 'jpg'),
        tamanhoBytes: bytes.length,
        base64: base64Encode(bytes),
        dataAnexo: DateTime.now(),
      ));
    });
  }

  Future<void> salvar() async {
    if (titulo.text.trim().isEmpty) throw Exception('Informe o título da atividade.');
    final id = widget.store.nextJohvemAtividadeId();
    final atividade = JohvemAtividade(
      id: id,
      data: data,
      tipo: tipo,
      titulo: titulo.text.trim(),
      descricao: descricao.text.trim(),
      responsavel: responsavel.text.trim(),
      jc: kJcPadrao,
      createdAt: DateTime.now(),
    );
    await widget.store.upsertJohvemAtividade(atividade);

    final selecionados = widget.store.johvensAutomaticos.where((p) => participantes[p.idPessoa] ?? false).toList();
    var pid = widget.store.nextJohvemAtividadeParticipanteId();
    final parts = <JohvemAtividadeParticipante>[];
    for (final pessoa in selecionados) {
      parts.add(JohvemAtividadeParticipante(
        id: pid++,
        idAtividade: id,
        idPessoa: pessoa.idPessoa,
        codigoMembro: pessoa.codigoMembro,
        nomePessoa: pessoa.nome,
        presente: true,
        jc: kJcPadrao,
      ));
    }
    await widget.store.salvarParticipantesAtividade(idAtividade: id, participantes: parts);

    var fid = widget.store.nextJohvemAtividadeFotoId();
    final fotosAtividade = fotos.map((foto) => JohvemAtividadeFoto(
          id: fid++,
          idAtividade: id,
          arquivo: foto.toStorageString(),
          legenda: '',
          jc: kJcPadrao,
        )).toList();
    await widget.store.salvarFotosAtividade(idAtividade: id, fotos: fotosAtividade);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final johvens = widget.store.johvensAutomaticos;
    return FormScaffold(
      title: 'Registrar atividade Johvem',
      onSave: salvar,
      children: [
        AppDropdown(value: tipo, labelText: 'Tipo de atividade', items: kTiposAtividadeJohvem, onChanged: (v) => setState(() => tipo = v)),
        DateSelector(label: 'Data', value: data, onChanged: (v) => setState(() => data = v)),
        TextField(controller: titulo, decoration: const InputDecoration(labelText: 'Título')), 
        const SizedBox(height: 12),
        TextField(controller: responsavel, decoration: const InputDecoration(labelText: 'Responsável')), 
        const SizedBox(height: 12),
        TextField(controller: descricao, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Descrição/observação')), 
        const SizedBox(height: 16),
        const Text('Participantes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        for (final pessoa in johvens)
          CheckboxListTile(
            value: participantes[pessoa.idPessoa] ?? false,
            onChanged: (v) => setState(() => participantes[pessoa.idPessoa] = v ?? false),
            title: Text(pessoa.nome),
            subtitle: Text('${widget.store.idadePessoa(pessoa)} anos • ${pessoa.tipoPessoaAtual}'),
          ),
        const SizedBox(height: 16),
        const Text('Fotos da atividade', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(onPressed: () => escolherFoto(source: ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Tirar foto')),
            OutlinedButton.icon(onPressed: () => escolherFoto(source: ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Galeria')),
          ],
        ),
        const SizedBox(height: 8),
        for (final foto in fotos)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.image_outlined),
            title: Text(foto.nome),
            subtitle: Text(foto.tamanhoFormatado),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => fotos.remove(foto)),
            ),
          ),
      ],
    );
  }
}

class JohvemFotosPage extends StatelessWidget {
  const JohvemFotosPage({super.key, required this.store, required this.atividade});
  final AppStore store;
  final JohvemAtividade atividade;

  @override
  Widget build(BuildContext context) {
    final fotos = store.fotosAtividade(atividade.id);
    return Scaffold(
      appBar: AppBar(title: Text('Fotos - ${atividade.titulo}')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: fotos.length,
        itemBuilder: (context, index) {
          final foto = fotos[index];
          return FutureBuilder<String?>(
            future: store.criarLinkTemporarioJohvemFoto(foto),
            builder: (context, snapshot) {
              final link = snapshot.data;
              Widget child;
              if (foto.arquivoFoto?.base64.isNotEmpty ?? false) {
                child = Image.memory(base64Decode(foto.arquivoFoto!.base64), fit: BoxFit.cover);
              } else if (link != null && link.isNotEmpty) {
                child = Image.network(link, fit: BoxFit.cover);
              } else {
                child = const Center(child: Icon(Icons.image_outlined, size: 44));
              }
              return InkWell(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                    insetPadding: const EdgeInsets.all(16),
                    child: InteractiveViewer(child: child),
                  ),
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
              );
            },
          );
        },
      ),
    );
  }
}


class EnsinoPage extends StatelessWidget {
  const EnsinoPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ensino'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Turmas'),
              Tab(text: 'Cursando'),
              Tab(text: 'Pós-Outorga'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            EnsinoTurmasTab(store: store),
            EnsinoCursandoTab(store: store),
            EnsinoPosOutorgaTab(store: store),
          ],
        ),
      ),
    );
  }
}

class EnsinoTurmasTab extends StatelessWidget {
  const EnsinoTurmasTab({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final turmas = store.ensinoTurmas.toList()..sort((a, b) => normalizeText(a.nomeTurma).compareTo(normalizeText(b.nomeTurma)));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SummaryStatTile(icon: Icons.school_outlined, title: 'Alunos em curso', value: '${store.ensinoAlunosEmCurso}', subtitle: 'Turmas ativas'),
            SummaryStatTile(icon: Icons.groups_outlined, title: 'Turmas ativas', value: '${store.ensinoTurmasAtivas}', subtitle: 'Níveis 1 a 4'),
            SummaryStatTile(icon: Icons.assignment_late_outlined, title: 'Pós-Outorga pendente', value: '${store.posOutorgaPendentes}', subtitle: 'Acompanhamento individual'),
          ],
        ),
        const SizedBox(height: 16),
        HeaderWithAction(
          title: 'Turmas',
          subtitle: 'Níveis 1, 2, 3 e 4 com presença por checklist.',
          buttonLabel: 'Nova turma',
          onPressed: () => openSheet(context, EnsinoTurmaForm(store: store)),
        ),
        for (final turma in turmas)
          EnsinoTurmaCard(store: store, turma: turma),
        EmptyState(show: turmas.isEmpty, message: 'Nenhuma turma cadastrada.'),
      ],
    );
  }
}

class EnsinoTurmaCard extends StatelessWidget {
  const EnsinoTurmaCard({super.key, required this.store, required this.turma});
  final AppStore store;
  final EnsinoTurma turma;

  @override
  Widget build(BuildContext context) {
    final alunos = store.alunosDaTurma(turma.id);
    final totalAulas = store.totalAulasCurso(turma.cursoNome);
    final aulasLancadas = store.aulasLancadasTurma(turma.id);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.school_outlined, color: kAccent)),
        title: Text(turma.nomeTurma, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${turma.cursoNome} • ${alunos.length} aluno(s) • ${aulasLancadas.length}/$totalAulas aula(s) lançada(s)'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EnsinoTurmaDetalhePage(store: store, turmaId: turma.id))),
      ),
    );
  }
}

class EnsinoCursandoTab extends StatelessWidget {
  const EnsinoCursandoTab({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final alunos = store.ensinoTurmaAlunos.where((a) => a.status == 'Em andamento').toList()
      ..sort((a, b) => normalizeText(a.nomePessoa).compareTo(normalizeText(b.nomePessoa)));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Cursando agora'),
        for (final aluno in alunos)
          Builder(builder: (context) {
            final turma = store.findTurmaById(aluno.idTurma);
            final total = store.totalAulasCurso(turma?.cursoNome ?? '');
            final progresso = store.progressoAluno(aluno.id);
            final pessoa = store.findPessoaById(aluno.idPessoa);
            return Card(
              child: ListTile(
                leading: PessoaAvatar(store: store, pessoa: pessoa, fallbackText: aluno.nomePessoa),
                title: Text(aluno.nomePessoa, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${turma?.cursoNome ?? 'Curso'} • ${turma?.nomeTurma ?? 'Turma'} • $progresso/$total aula(s)'),
                trailing: Text('${total == 0 ? 0 : ((progresso / total) * 100).round()}%'),
              ),
            );
          }),
        EmptyState(show: alunos.isEmpty, message: 'Nenhum aluno em curso.'),
      ],
    );
  }
}

class EnsinoTurmaDetalhePage extends StatelessWidget {
  const EnsinoTurmaDetalhePage({super.key, required this.store, required this.turmaId});
  final AppStore store;
  final int turmaId;

  @override
  Widget build(BuildContext context) {
    final turma = store.findTurmaById(turmaId);
    if (turma == null) return const Scaffold(body: Center(child: Text('Turma não encontrada.')));
    final alunos = store.alunosDaTurma(turma.id);
    final totalAulas = store.totalAulasCurso(turma.cursoNome);
    final aulasLancadas = store.aulasLancadasTurma(turma.id);
    return Scaffold(
      appBar: AppBar(title: Text(turma.nomeTurma)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(turma.cursoNome, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('${alunos.length} aluno(s) • ${aulasLancadas.length}/$totalAulas aula(s) lançada(s) • ${turma.status}'),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => openSheet(context, EnsinoPresencaTurmaPage(store: store, turmaId: turma.id)),
                        icon: const Icon(Icons.checklist_outlined),
                        label: const Text('Lançar presença'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => openSheet(context, EnsinoAlunoTurmaForm(store: store, turma: turma)),
                        icon: const Icon(Icons.person_add_alt_outlined),
                        label: const Text('Adicionar aluno'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Alunos'),
          for (final aluno in alunos)
            Builder(builder: (context) {
              final pessoa = store.findPessoaById(aluno.idPessoa);
              final progresso = store.progressoAluno(aluno.id);
              return Card(
                child: ListTile(
                  leading: PessoaAvatar(store: store, pessoa: pessoa, fallbackText: aluno.nomePessoa),
                  title: Text(aluno.nomePessoa, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('$progresso/$totalAulas aula(s) • ${aluno.status}'),
                ),
              );
            }),
          EmptyState(show: alunos.isEmpty, message: 'Nenhum aluno nesta turma.'),
        ],
      ),
    );
  }
}

class EnsinoTurmaForm extends StatefulWidget {
  const EnsinoTurmaForm({super.key, required this.store});
  final AppStore store;

  @override
  State<EnsinoTurmaForm> createState() => _EnsinoTurmaFormState();
}

class _EnsinoTurmaFormState extends State<EnsinoTurmaForm> {
  final nome = TextEditingController();
  final anoSemestre = TextEditingController(text: '2026/1º');
  final responsavel = TextEditingController();
  final dataInicio = TextEditingController(text: brDate.format(DateTime.now()));
  String curso = 'Nível 1';
  String status = 'Em andamento';

  @override
  void dispose() {
    nome.dispose();
    anoSemestre.dispose();
    responsavel.dispose();
    dataInicio.dispose();
    super.dispose();
  }

  Future<void> selecionarData() async {
    final atual = tryParseBrDate(dataInicio.text) ?? DateTime.now();
    final selecionada = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: atual);
    if (selecionada != null) setState(() => dataInicio.text = brDate.format(selecionada));
  }

  Future<void> salvar() async {
    final nomeFinal = nome.text.trim().isEmpty ? '$curso - ${anoSemestre.text.trim()}' : nome.text.trim();
    await widget.store.upsertEnsinoTurma(EnsinoTurma(
      id: widget.store.nextEnsinoTurmaId(),
      idCurso: widget.store.idCursoPorNome(curso),
      cursoNome: curso,
      nomeTurma: nomeFinal,
      anoSemestre: anoSemestre.text.trim(),
      responsavel: responsavel.text.trim(),
      status: status,
      dataInicio: tryParseBrDate(dataInicio.text),
      jc: kJcPadrao,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Nova turma',
      onSave: salvar,
      children: [
        AppDropdown(value: curso, labelText: 'Curso', items: kCursosEnsinoPadrao.keys.where((e) => e != 'Pós-Outorga').toList(), onChanged: (v) => setState(() => curso = v)),
        const SizedBox(height: 12),
        TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome da turma', hintText: 'Ex.: Nível 1 - 2026/1º')),
        const SizedBox(height: 12),
        TextField(controller: anoSemestre, decoration: const InputDecoration(labelText: 'Ano/Semestre')),
        const SizedBox(height: 12),
        BrDateFormField(controller: dataInicio, labelText: 'Data de início', onPickDate: selecionarData),
        const SizedBox(height: 12),
        TextField(controller: responsavel, decoration: const InputDecoration(labelText: 'Responsável')),
        const SizedBox(height: 12),
        AppDropdown(value: status, labelText: 'Status', items: kStatusTurmaEnsino, onChanged: (v) => setState(() => status = v)),
      ],
    );
  }
}

class EnsinoAlunoTurmaForm extends StatefulWidget {
  const EnsinoAlunoTurmaForm({super.key, required this.store, required this.turma});
  final AppStore store;
  final EnsinoTurma turma;

  @override
  State<EnsinoAlunoTurmaForm> createState() => _EnsinoAlunoTurmaFormState();
}

class _EnsinoAlunoTurmaFormState extends State<EnsinoAlunoTurmaForm> {
  final nome = TextEditingController();
  String status = 'Em andamento';

  @override
  void dispose() {
    nome.dispose();
    super.dispose();
  }

  Future<void> selecionarPessoa() async {
    final selecionado = await pickStringFromList(context, title: 'Selecionar pessoa', options: widget.store.nomesPessoas());
    if (selecionado != null) setState(() => nome.text = selecionado);
  }

  Future<void> salvar() async {
    final pessoa = widget.store.findPessoaByName(nome.text);
    if (pessoa == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma pessoa da base.')));
      return;
    }
    if (widget.store.alunosDaTurma(widget.turma.id).any((a) => a.idPessoa == pessoa.idPessoa)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Essa pessoa já está na turma.')));
      return;
    }
    await widget.store.upsertEnsinoTurmaAluno(EnsinoTurmaAluno(
      id: widget.store.nextEnsinoTurmaAlunoId(),
      idTurma: widget.turma.id,
      idPessoa: pessoa.idPessoa,
      codigoMembro: pessoa.codigoMembro,
      nomePessoa: pessoa.nome,
      status: status,
      progressoAulas: 0,
      jc: kJcPadrao,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Adicionar aluno',
      onSave: salvar,
      children: [
        TextField(
          controller: nome,
          decoration: InputDecoration(
            labelText: 'Pessoa',
            suffixIcon: IconButton(onPressed: selecionarPessoa, icon: const Icon(Icons.search)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: selecionarPessoa, icon: const Icon(Icons.list_alt_outlined), label: Text('Selecionar da base (${widget.store.pessoas.length})')),
        const SizedBox(height: 12),
        AppDropdown(value: status, labelText: 'Status', items: kStatusAlunoEnsino, onChanged: (v) => setState(() => status = v)),
      ],
    );
  }
}

class EnsinoPresencaTurmaPage extends StatefulWidget {
  const EnsinoPresencaTurmaPage({super.key, required this.store, required this.turmaId});
  final AppStore store;
  final int turmaId;

  @override
  State<EnsinoPresencaTurmaPage> createState() => _EnsinoPresencaTurmaPageState();
}

class _EnsinoPresencaTurmaPageState extends State<EnsinoPresencaTurmaPage> {
  final dataController = TextEditingController(text: brDate.format(DateTime.now()));
  int aulaNumero = 1;
  final presentes = <int, bool>{};
  bool salvando = false;

  EnsinoTurma? get turma => widget.store.findTurmaById(widget.turmaId);
  List<EnsinoTurmaAluno> get alunos => widget.store.alunosDaTurma(widget.turmaId);

  @override
  void initState() {
    super.initState();
    final t = turma;
    if (t != null) {
      final lancadas = widget.store.aulasLancadasTurma(t.id);
      aulaNumero = lancadas.isEmpty ? 1 : (lancadas.last + 1).clamp(1, widget.store.totalAulasCurso(t.cursoNome)).toInt();
    }
    for (final aluno in alunos) {
      presentes[aluno.id] = false;
    }
    _carregarExistentes();
  }

  @override
  void dispose() {
    dataController.dispose();
    super.dispose();
  }

  void _carregarExistentes() {
    for (final aluno in alunos) {
      presentes[aluno.id] = false;
    }
    final existentes = widget.store.presencasDaTurmaAula(widget.turmaId, aulaNumero);
    for (final p in existentes) {
      presentes[p.idAluno] = p.presente;
    }
  }

  Future<void> selecionarData() async {
    final atual = tryParseBrDate(dataController.text) ?? DateTime.now();
    final selecionada = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: atual);
    if (selecionada != null) {
      setState(() => dataController.text = brDate.format(selecionada));
    }
  }

  Future<void> salvar() async {
    final t = turma;
    if (t == null || salvando) {
      return;
    }
    setState(() => salvando = true);
    try {
      await widget.store.salvarPresencasTurma(
        turma: t,
        aulaNumero: aulaNumero,
        data: tryParseBrDate(dataController.text) ?? DateTime.now(),
        presentes: presentes,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presenças salvas.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(limparMensagemErro(e))));
      }
    } finally {
      if (mounted) {
        setState(() => salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = turma;
    if (t == null) {
      return FormScaffold(
        title: 'Lançar presença',
        onSave: () => Navigator.pop(context),
        children: const [
          EmptyState(show: true, message: 'Turma não encontrada.'),
        ],
      );
    }
    final total = widget.store.totalAulasCurso(t.cursoNome);
    return FormScaffold(
      title: 'Lançar presença',
      onSave: salvar,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.nomeTurma, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${t.cursoNome} • ${alunos.length} aluno(s)', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 12),
                AppDropdown(
                  value: '$aulaNumero',
                  labelText: 'Aula',
                  items: [for (var i = 1; i <= total; i++) '$i'],
                  onChanged: (v) => setState(() {
                    aulaNumero = int.tryParse(v) ?? 1;
                    _carregarExistentes();
                  }),
                ),
                const SizedBox(height: 12),
                BrDateFormField(controller: dataController, labelText: 'Data da aula', onPickDate: selecionarData),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SectionTitle('Checklist • Aula $aulaNumero de $total'),
        for (final aluno in alunos)
          Card(
            child: SwitchListTile(
              value: presentes[aluno.id] ?? false,
              onChanged: (v) => setState(() => presentes[aluno.id] = v),
              title: Text(aluno.nomePessoa, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(t.cursoNome),
              secondary: PessoaAvatar(store: widget.store, pessoa: widget.store.findPessoaById(aluno.idPessoa), fallbackText: aluno.nomePessoa),
            ),
          ),
        EmptyState(show: alunos.isEmpty, message: 'Nenhum aluno nesta turma.'),
        if (salvando) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}

class EnsinoPosOutorgaTab extends StatelessWidget {
  const EnsinoPosOutorgaTab({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final itens = store.ensinoPosOutorgas.toList()..sort((a, b) => normalizeText(a.nomePessoa).compareTo(normalizeText(b.nomePessoa)));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeaderWithAction(
          title: 'Pós-Outorga individual',
          subtitle: '6 encontros por pessoa. Não usa turma.',
          buttonLabel: 'Novo',
          onPressed: () => openSheet(context, PosOutorgaForm(store: store)),
        ),
        for (final item in itens)
          PosOutorgaCard(store: store, item: item),
        EmptyState(show: itens.isEmpty, message: 'Nenhum acompanhamento de Pós-Outorga cadastrado.'),
      ],
    );
  }
}

class PosOutorgaCard extends StatelessWidget {
  const PosOutorgaCard({super.key, required this.store, required this.item});
  final AppStore store;
  final EnsinoPosOutorga item;

  @override
  Widget build(BuildContext context) {
    final encontros = store.encontrosPosOutorga(item.id);
    final pessoa = store.findPessoaById(item.idPessoa);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PessoaAvatar(store: store, pessoa: pessoa, fallbackText: item.nomePessoa),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.nomePessoa, style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text('Pós-Outorga: ${encontros.length}/6 • ${item.status}', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                Chip(label: Text(item.status)),
              ],
            ),
            if (item.dataOutorga != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Outorga: ${brDate.format(item.dataOutorga!)}')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => openSheet(context, PosOutorgaEncontroForm(store: store, acompanhamento: item)),
                  icon: const Icon(Icons.add_task_outlined),
                  label: const Text('Registrar encontro'),
                ),
              ],
            ),
            for (final encontro in encontros.take(3))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: kSoftGreen, child: Text('${encontro.numeroEncontro}')),
                title: Text(encontro.tema.isEmpty ? 'Encontro ${encontro.numeroEncontro}' : encontro.tema),
                subtitle: Text(brDate.format(encontro.data)),
              ),
          ],
        ),
      ),
    );
  }
}

class PosOutorgaForm extends StatefulWidget {
  const PosOutorgaForm({super.key, required this.store});
  final AppStore store;

  @override
  State<PosOutorgaForm> createState() => _PosOutorgaFormState();
}

class _PosOutorgaFormState extends State<PosOutorgaForm> {
  final nome = TextEditingController();
  final dataOutorga = TextEditingController();
  final responsavel = TextEditingController();
  final observacao = TextEditingController();
  String status = 'Pendente';

  @override
  void dispose() {
    nome.dispose();
    dataOutorga.dispose();
    responsavel.dispose();
    observacao.dispose();
    super.dispose();
  }

  Future<void> selecionarPessoa() async {
    final selecionado = await pickStringFromList(context, title: 'Selecionar pessoa', options: widget.store.nomesPessoas());
    if (selecionado == null) return;
    final pessoa = widget.store.findPessoaByName(selecionado);
    setState(() {
      nome.text = selecionado;
      if (pessoa?.dataOutorga != null) dataOutorga.text = brDate.format(pessoa!.dataOutorga!);
    });
  }

  Future<void> selecionarData() async {
    final atual = tryParseBrDate(dataOutorga.text) ?? DateTime.now();
    final selecionada = await showDatePicker(context: context, firstDate: DateTime(1900), lastDate: DateTime(2100), initialDate: atual);
    if (selecionada != null) setState(() => dataOutorga.text = brDate.format(selecionada));
  }

  Future<void> salvar() async {
    final pessoa = widget.store.findPessoaByName(nome.text);
    if (pessoa == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma pessoa da base.')));
      return;
    }
    await widget.store.upsertPosOutorga(EnsinoPosOutorga(
      id: widget.store.nextPosOutorgaId(),
      idPessoa: pessoa.idPessoa,
      codigoMembro: pessoa.codigoMembro,
      nomePessoa: pessoa.nome,
      dataOutorga: tryParseBrDate(dataOutorga.text),
      status: status,
      responsavel: responsavel.text.trim(),
      observacao: observacao.text.trim(),
      jc: kJcPadrao,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Novo Pós-Outorga',
      onSave: salvar,
      children: [
        TextField(controller: nome, decoration: InputDecoration(labelText: 'Pessoa', suffixIcon: IconButton(onPressed: selecionarPessoa, icon: const Icon(Icons.search)))),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: selecionarPessoa, icon: const Icon(Icons.list_alt_outlined), label: const Text('Selecionar da base')),
        const SizedBox(height: 12),
        BrDateFormField(controller: dataOutorga, labelText: 'Data da outorga', onPickDate: selecionarData),
        const SizedBox(height: 12),
        AppDropdown(value: status, labelText: 'Status', items: kStatusPosOutorga, onChanged: (v) => setState(() => status = v)),
        const SizedBox(height: 12),
        TextField(controller: responsavel, decoration: const InputDecoration(labelText: 'Responsável')),
        const SizedBox(height: 12),
        TextField(controller: observacao, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Observação')),
      ],
    );
  }
}

class PosOutorgaEncontroForm extends StatefulWidget {
  const PosOutorgaEncontroForm({super.key, required this.store, required this.acompanhamento});
  final AppStore store;
  final EnsinoPosOutorga acompanhamento;

  @override
  State<PosOutorgaEncontroForm> createState() => _PosOutorgaEncontroFormState();
}

class _PosOutorgaEncontroFormState extends State<PosOutorgaEncontroForm> {
  final dataController = TextEditingController(text: brDate.format(DateTime.now()));
  final tema = TextEditingController();
  final responsavel = TextEditingController();
  final observacao = TextEditingController();
  late int numero;

  @override
  void initState() {
    super.initState();
    numero = (widget.store.encontrosPosOutorga(widget.acompanhamento.id).length + 1).clamp(1, 6).toInt();
  }

  @override
  void dispose() {
    dataController.dispose();
    tema.dispose();
    responsavel.dispose();
    observacao.dispose();
    super.dispose();
  }

  Future<void> selecionarData() async {
    final atual = tryParseBrDate(dataController.text) ?? DateTime.now();
    final selecionada = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: atual);
    if (selecionada != null) setState(() => dataController.text = brDate.format(selecionada));
  }

  Future<void> salvar() async {
    await widget.store.upsertPosOutorgaEncontro(EnsinoPosOutorgaEncontro(
      id: widget.store.nextPosOutorgaEncontroId(),
      idPosOutorga: widget.acompanhamento.id,
      idPessoa: widget.acompanhamento.idPessoa,
      codigoMembro: widget.acompanhamento.codigoMembro,
      nomePessoa: widget.acompanhamento.nomePessoa,
      numeroEncontro: numero,
      data: tryParseBrDate(dataController.text) ?? DateTime.now(),
      tema: tema.text.trim(),
      responsavel: responsavel.text.trim(),
      observacao: observacao.text.trim(),
      jc: kJcPadrao,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Registrar encontro',
      onSave: salvar,
      children: [
        AppDropdown(value: '$numero', labelText: 'Encontro', items: [for (var i = 1; i <= 6; i++) '$i'], onChanged: (v) => setState(() => numero = int.tryParse(v) ?? 1)),
        const SizedBox(height: 12),
        BrDateFormField(controller: dataController, labelText: 'Data', onPickDate: selecionarData),
        const SizedBox(height: 12),
        TextField(controller: tema, decoration: const InputDecoration(labelText: 'Tema')),
        const SizedBox(height: 12),
        TextField(controller: responsavel, decoration: const InputDecoration(labelText: 'Responsável')),
        const SizedBox(height: 12),
        TextField(controller: observacao, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Observação')),
      ],
    );
  }
}



class MinhaContaPage extends StatelessWidget {
  const MinhaContaPage({super.key, required this.store});
  final AppStore store;

  String get usuarioLogado {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    if (email.isEmpty) return 'Usuário logado';
    final usuario = email.split('@').first;
    if (usuario.isEmpty) return email;
    return '${usuario[0].toUpperCase()}${usuario.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Conta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: kSoftGreen,
                        child: Icon(Icons.person, color: kAccent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(usuarioLogado, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            const Text('Perfil: Admin', style: TextStyle(color: kAccent, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Permissões', style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Donativos')),
                      Chip(label: Text('Frequência')),
                      Chip(label: Text('Ensino')),
                      Chip(label: Text('Experiências')),
                      Chip(label: Text('Pessoas')),
                      Chip(label: Text('Configurações')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Controle de permissões detalhadas será ativado em uma próxima etapa. Por enquanto, este usuário está com acesso total.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_clock_outlined),
              title: const Text('Bloqueio automático'),
              subtitle: const Text('Após 15 minutos sem uso, o app volta para o login.'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await store.logout();
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sair da conta'),
          ),
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
              leading: Icon(store.isAuthenticated ? Icons.cloud_done_outlined : Icons.cloud_off_outlined),
              title: const Text('Banco de dados'),
              subtitle: Text(store.statusSupabase),
              isThreeLine: true,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_clock_outlined),
              title: const Text('Bloqueio automático'),
              subtitle: const Text('Após 15 minutos sem uso, o app volta para o login.'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: store.isSyncing
                ? null
                : () async {
                    try {
                      await store.carregarDadosDoSupabase();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dados atualizados do banco.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(limparMensagemErro(e))),
                        );
                      }
                    }
                  },
            icon: const Icon(Icons.cloud_sync_outlined),
            label: const Text('Atualizar dados do banco'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await store.logout();
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sair da conta'),
          ),
        ],
      ),
    );
  }
}

class PessoaForm extends StatefulWidget {
  const PessoaForm({super.key, required this.store, this.initialValue});
  final AppStore store;
  final Pessoa? initialValue;

  bool get isEditing => initialValue != null;

  @override
  State<PessoaForm> createState() => _PessoaFormState();
}

class _PessoaFormState extends State<PessoaForm> {
  final formKey = GlobalKey<FormState>();
  final nome = TextEditingController();
  final codigoMembro = TextEditingController();
  final nascimento = TextEditingController();
  final outorga = TextEditingController();
  final logradouro = TextEditingController();
  final numero = TextEditingController();
  final complemento = TextEditingController();
  final bairro = TextEditingController();
  final cidade = TextEditingController();
  final estado = TextEditingController(text: 'MG');
  final telefoneResidencial = TextEditingController();
  final telefoneCelular = TextEditingController();

  String tipo = 'Membro';
  String sexo = '';
  String tipoOutorga = '';
  String situacaoMembro = '';
  String possuiSs = '';
  ComprovanteArquivo? fotoAtual;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialValue;
    nome.text = item?.nome ?? '';
    codigoMembro.text = item?.codigoMembro ?? '';
    nascimento.text = item?.dataNascimento == null ? '' : brDate.format(item!.dataNascimento!);
    outorga.text = item?.dataOutorga == null ? '' : brDate.format(item!.dataOutorga!);
    logradouro.text = item?.logradouro ?? '';
    numero.text = item?.numero ?? '';
    complemento.text = item?.complemento ?? '';
    bairro.text = item?.bairro ?? '';
    cidade.text = item?.cidade ?? '';
    estado.text = item?.estado.isNotEmpty == true ? item!.estado : 'MG';
    telefoneResidencial.text = item?.telefoneResidencial ?? '';
    telefoneCelular.text = item?.telefoneCelular ?? '';
    tipo = valorSeguro(item?.tipoPessoaAtual, kTiposPessoaFrequencia, fallback: 'Membro');
    sexo = valorSeguro(item?.sexo, const ['', 'F', 'M'], fallback: '');
    tipoOutorga = valorSeguro(item?.tipoOutorga, const ['', 'OH', 'SH'], fallback: '');
    situacaoMembro = valorSeguro(item?.situacaoMembro, const ['', 'ATI', 'AFA'], fallback: '');
    possuiSs = valorSeguro(item?.possuiSs, const ['', 'S', 'N'], fallback: '');
    fotoAtual = item?.fotoArquivo;
  }

  @override
  void dispose() {
    nome.dispose();
    codigoMembro.dispose();
    nascimento.dispose();
    outorga.dispose();
    logradouro.dispose();
    numero.dispose();
    complemento.dispose();
    bairro.dispose();
    cidade.dispose();
    estado.dispose();
    telefoneResidencial.dispose();
    telefoneCelular.dispose();
    super.dispose();
  }

  Future<void> selecionarFoto({required bool camera}) async {
    try {
      final picker = ImagePicker();
      final foto = await picker.pickImage(source: camera ? ImageSource.camera : ImageSource.gallery, imageQuality: 78, maxWidth: 1200);
      if (foto == null) return;
      final bytes = await foto.readAsBytes();
      if (bytes.length > kMaxFotoPessoaBytes) throw Exception('Foto maior que 2 MB. Escolha uma imagem mais leve.');
      final nomeArquivo = foto.name.trim().isEmpty ? 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg' : foto.name;
      setState(() {
        fotoAtual = ComprovanteArquivo(
          nome: nomeArquivo,
          extensao: extensaoArquivo(nomeArquivo, fallback: 'jpg'),
          tamanhoBytes: bytes.length,
          base64: base64Encode(bytes),
          dataAnexo: DateTime.now(),
        );
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(limparMensagemErro(e))));
    }
  }

  Future<void> selecionarData(TextEditingController controller) async {
    final atual = tryParseBrDate(controller.text) ?? DateTime.now();
    final selecionada = await showDatePicker(context: context, firstDate: DateTime(1900), lastDate: DateTime(2100), initialDate: atual);
    if (selecionada == null) return;
    setState(() => controller.text = brDate.format(selecionada));
  }

  Future<void> salvar() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;
    if (salvando) return;

    setState(() => salvando = true);
    try {
      final id = widget.initialValue?.idPessoa ?? widget.store.nextPessoaId();
      var fotoStorage = fotoAtual?.toStorageString() ?? '';
      if (fotoAtual != null && fotoAtual!.base64.isNotEmpty) {
        fotoStorage = await widget.store.salvarFotoPessoaNoSupabase(pessoaId: id, foto: fotoAtual!);
      }

      final pessoa = Pessoa(
        idPessoa: id,
        nome: nome.text.trim(),
        tipoPessoaAtual: tipo,
        primeiraPresenca: widget.initialValue?.primeiraPresenca ?? DateTime.now(),
        ultimaPresenca: widget.initialValue?.ultimaPresenca ?? DateTime.now(),
        qtdPresencas: widget.initialValue?.qtdPresencas ?? 0,
        jc: widget.initialValue?.jc ?? kJcPadrao,
        foto: fotoStorage,
        codigoMembro: codigoMembro.text.trim(),
        sexo: sexo,
        dataNascimento: parseNullableDate(nascimento.text),
        tipoOutorga: tipoOutorga,
        dataOutorga: parseNullableDate(outorga.text),
        situacaoMembro: situacaoMembro,
        possuiSs: possuiSs,
        logradouro: logradouro.text.trim(),
        numero: numero.text.trim(),
        complemento: complemento.text.trim(),
        bairro: bairro.text.trim(),
        cidade: cidade.text.trim(),
        estado: estado.text.trim().toUpperCase(),
        telefoneResidencial: telefoneResidencial.text.trim(),
        telefoneCelular: telefoneCelular.text.trim(),
      );

      await widget.store.upsertPessoa(pessoa);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(limparMensagemErro(e))));
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pessoaPreview = widget.initialValue?.copyWith(
          nome: nome.text.trim().isEmpty ? widget.initialValue!.nome : nome.text.trim(),
          tipoPessoaAtual: tipo,
          foto: fotoAtual?.toStorageString() ?? '',
        ) ??
        Pessoa(
          idPessoa: 0,
          nome: nome.text.trim(),
          tipoPessoaAtual: tipo,
          primeiraPresenca: DateTime.now(),
          ultimaPresenca: DateTime.now(),
          qtdPresencas: 0,
          jc: kJcPadrao,
          foto: fotoAtual?.toStorageString() ?? '',
        );

    return FormScaffold(
      title: widget.isEditing ? 'Editar pessoa' : 'Nova pessoa',
      formKey: formKey,
      onSave: salvar,
      children: [
        Center(child: PessoaAvatar(store: widget.store, pessoa: pessoaPreview, radius: 46)),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(onPressed: () => selecionarFoto(camera: true), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Tirar foto')),
            OutlinedButton.icon(onPressed: () => selecionarFoto(camera: false), icon: const Icon(Icons.photo_library_outlined), label: const Text('Galeria')),
            if (fotoAtual != null) TextButton.icon(onPressed: () => setState(() => fotoAtual = null), icon: const Icon(Icons.close), label: const Text('Remover foto')),
          ],
        ),
        const SizedBox(height: 16),
        const SectionTitle('Dados básicos'),
        TextFormField(
          controller: nome,
          decoration: const InputDecoration(labelText: 'Nome'),
          onChanged: (_) => setState(() {}),
          validator: (value) => (value?.trim().isEmpty ?? true) ? 'Informe o nome.' : null,
        ),
        const SizedBox(height: 12),
        AppDropdown(value: tipo, labelText: 'Tipo atual', items: kTiposPessoaFrequencia, onChanged: (v) => setState(() => tipo = v)),
        const SizedBox(height: 12),
        AppDropdown(value: sexo, labelText: 'Sexo', items: const ['', 'F', 'M'], onChanged: (v) => setState(() => sexo = v)),
        const SizedBox(height: 12),
        TextFormField(
          controller: nascimento,
          decoration: InputDecoration(labelText: 'Nascimento', suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => selecionarData(nascimento))),
          inputFormatters: [BrDateTextInputFormatter()],
        ),
        const SizedBox(height: 20),
        const SectionTitle('Dados de membro'),
        TextFormField(controller: codigoMembro, decoration: const InputDecoration(labelText: 'Código do membro')),
        const SizedBox(height: 12),
        AppDropdown(value: tipoOutorga, labelText: 'Tipo de outorga', items: const ['', 'OH', 'SH'], onChanged: (v) => setState(() => tipoOutorga = v)),
        const SizedBox(height: 12),
        TextFormField(
          controller: outorga,
          decoration: InputDecoration(labelText: 'Data da outorga', suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => selecionarData(outorga))),
          inputFormatters: [BrDateTextInputFormatter()],
        ),
        const SizedBox(height: 12),
        AppDropdown(value: situacaoMembro, labelText: 'Situação do membro', items: const ['', 'ATI', 'AFA'], onChanged: (v) => setState(() => situacaoMembro = v)),
        const SizedBox(height: 12),
        AppDropdown(value: possuiSs, labelText: 'Sorei-Saishi/SS', items: const ['', 'S', 'N'], onChanged: (v) => setState(() => possuiSs = v)),
        const SizedBox(height: 20),
        const SectionTitle('Contato'),
        TextFormField(controller: telefoneCelular, decoration: const InputDecoration(labelText: 'Telefone celular'), keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        TextFormField(controller: telefoneResidencial, decoration: const InputDecoration(labelText: 'Telefone residencial'), keyboardType: TextInputType.phone),
        const SizedBox(height: 20),
        const SectionTitle('Endereço'),
        TextFormField(controller: logradouro, decoration: const InputDecoration(labelText: 'Logradouro')),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextFormField(controller: numero, decoration: const InputDecoration(labelText: 'Nº'))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: complemento, decoration: const InputDecoration(labelText: 'Complemento'))),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(controller: bairro, decoration: const InputDecoration(labelText: 'Bairro')),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 3, child: TextFormField(controller: cidade, decoration: const InputDecoration(labelText: 'Cidade'))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: estado, decoration: const InputDecoration(labelText: 'Estado'))),
          ],
        ),
      ],
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

  String origem = 'Urna';
  String tipoPessoa = 'Membro';
  String tipoDonativo = 'Mensal';
  String subtipo = 'Presencial';
  String tipoOrigemNome = 'Pessoa';
  String bancoSelecionado = kBancosTransferencia.first;
  ComprovanteArquivo? comprovanteAtual;

  bool get ehUrna => origem == 'Urna';
  bool get ehTransferencia => origem == 'Transferência';
  bool get ehOnline => origem == 'Online';
  bool get ehOnlineOficial => ehOnline && subtipo == kSubtipoOnlineOficial;
  bool get ehOnlineIdentificado => ehOnline && subtipo == kSubtipoOnlineIdentificado;
  bool get exigePessoa => !ehOnlineOficial;
  bool get permiteComprovante => ehTransferencia || ehOnlineIdentificado;

  List<String> get subtiposDisponiveis => ehOnline
      ? const [kSubtipoOnlineOficial, kSubtipoOnlineIdentificado]
      : subtiposPorOrigem(origem);
  List<String> get nomesBase => tipoOrigemNome == 'Pessoa' ? widget.store.nomesPessoas() : widget.store.nomesReferencias();

  @override
  void initState() {
    super.initState();
    final item = widget.initialValue;
    final dataInicial = item?.data ?? DateTime.now();

    origem = valorSeguro(item?.origem, kOrigensDonativo, fallback: 'Urna');
    subtipo = valorSeguro(item?.subtipo, subtiposDisponiveis, fallback: subtiposDisponiveis.first);
    nome.text = item?.ehOnlineOficial == true ? '' : (item?.nome ?? '');
    valor.text = item == null ? '' : formatValorInput(item.valor);
    tipoManual.text = item?.tipoDonativoManual ?? '';
    bancoSelecionado = valorSeguro(item?.banco, kBancosTransferencia, fallback: kBancosTransferencia.first);
    dataController.text = brDate.format(dataInicial);
    tipoPessoa = valorSeguro(item?.tipoPessoa, kTiposPessoaDonativo, fallback: 'Membro');
    tipoDonativo = valorSeguro(item?.tipoDonativo, kTiposDonativo, fallback: 'Mensal');
    tipoOrigemNome = valorSeguro(item?.tipoOrigemNome, kTiposOrigemNomeDonativo, fallback: 'Pessoa');
    comprovanteAtual = ComprovanteArquivo.fromStorageString(item?.comprovante ?? '');

    if (ehOnline && !subtiposDisponiveis.contains(subtipo)) {
      subtipo = kSubtipoOnlineOficial;
    }
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

  void alterarOrigem(String novaOrigem) {
    setState(() {
      origem = novaOrigem;
      subtipo = subtiposPorOrigem(origem).first;
      if (origem == 'Online') {
        subtipo = kSubtipoOnlineOficial;
        tipoOrigemNome = 'Pessoa';
        tipoPessoa = 'Membro';
        nome.clear();
        comprovanteAtual = null;
      }
      if (origem == 'Transferência') {
        bancoSelecionado = kBancosTransferencia.first;
      }
    });
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

  Future<void> selecionarComprovante({required bool imagem}) async {
    final resultado = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: imagem ? FileType.image : FileType.custom,
      allowedExtensions: imagem ? null : const ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'],
    );

    if (resultado == null || resultado.files.isEmpty) return;

    final arquivo = resultado.files.single;
    final bytes = arquivo.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível ler o arquivo selecionado.')),
      );
      return;
    }

    const limiteBytes = 3 * 1024 * 1024;
    if (bytes.length > limiteBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo muito grande. Use comprovante até 3 MB.')),
      );
      return;
    }

    setState(() {
      comprovanteAtual = ComprovanteArquivo(
        nome: arquivo.name,
        extensao: arquivo.extension ?? '',
        tamanhoBytes: arquivo.size,
        base64: base64Encode(bytes),
        dataAnexo: DateTime.now(),
        path: '',
      );
    });
  }

  Future<void> tirarFotoComprovante() async {
    try {
      final picker = ImagePicker();
      final foto = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1600,
      );

      if (foto == null) return;

      final bytes = await foto.readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível ler a foto tirada.')),
        );
        return;
      }

      const limiteBytes = 3 * 1024 * 1024;
      if (bytes.length > limiteBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto muito grande. Tire novamente ou use arquivo até 3 MB.')),
        );
        return;
      }

      final nomeArquivo = foto.name.trim().isEmpty
          ? 'comprovante_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : foto.name;

      setState(() {
        comprovanteAtual = ComprovanteArquivo(
          nome: nomeArquivo,
          extensao: extensaoArquivo(nomeArquivo, fallback: 'jpg'),
          tamanhoBytes: bytes.length,
          base64: base64Encode(bytes),
          dataAnexo: DateTime.now(),
          path: '',
        );
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir a câmera: ${limparMensagemErro(error)}')),
      );
    }
  }

  void removerComprovante() {
    setState(() => comprovanteAtual = null);
  }

  Future<void> salvar() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;

    final dataLancamento = tryParseBrDate(dataController.text)!;
    final referencia = tipoOrigemNome == 'Referencia' && exigePessoa ? widget.store.findReferenciaByName(nome.text) : null;
    final pessoa = tipoOrigemNome == 'Pessoa' && exigePessoa ? widget.store.findPessoaByName(nome.text) : null;

    final novoId = widget.initialValue?.id ?? widget.store.nextDonativoId();
    var comprovanteFinal = '';
    if (permiteComprovante && comprovanteAtual != null) {
      comprovanteFinal = await widget.store.salvarComprovanteNoSupabase(
        donativoId: novoId,
        comprovante: comprovanteAtual!,
      );
    }

    final nomeFinal = ehOnlineOficial ? 'Online oficial acumulado' : nomeLimpoDeRotuloPessoa(nome.text);
    final tipoOrigemFinal = ehOnlineOficial ? '' : tipoOrigemNome;
    final tipoPessoaFinal = ehOnlineOficial
        ? ''
        : (tipoOrigemNome == 'Referencia' ? 'Outro' : (pessoa?.tipoPessoaAtual ?? tipoPessoa));

    final novo = Donativo(
      id: novoId,
      data: dataLancamento,
      nome: nomeFinal,
      jc: widget.initialValue?.jc ?? kJcPadrao,
      tipoPessoa: tipoPessoaFinal,
      tipoDonativo: tipoDonativo,
      tipoDonativoManual: tipoDonativo == 'Outro' ? tipoManual.text.trim() : '',
      origem: origem,
      subtipo: subtipo,
      banco: ehTransferencia ? bancoSelecionado : '',
      valor: parseValor(valor.text),
      comprovante: comprovanteFinal,
      depositoStatus: ehTransferencia ? (widget.initialValue?.depositoStatus ?? 'Pendente') : '',
      depositoLancadoEm: ehTransferencia ? widget.initialValue?.depositoLancadoEm : null,
      tipoOrigemNome: tipoOrigemFinal,
      idReferencia: referencia?.idReferencia ?? widget.initialValue?.idReferencia ?? '',
    );

    try {
      await widget.store.upsertDonativo(novo);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: ${limparMensagemErro(error)}')),
      );
    }
  }

  Widget campoOrigem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionLabel('Origem do donativo'),
        AppDropdown(
          value: origem,
          labelText: 'Selecione como será lançado',
          items: kOrigensDonativo,
          onChanged: alterarOrigem,
        ),
        const SizedBox(height: 12),
        if (ehOnline)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kSoftGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Online oficial é o acumulado do site da Igreja. Online identificado serve para vincular pessoa e comprovante sem duplicar o total oficial.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget camposPessoa() {
    if (!exigePessoa) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionLabel(ehOnlineIdentificado ? 'Pessoa identificada' : 'Identificação'),
        AppDropdown(
          value: tipoOrigemNome,
          labelText: 'Base do nome',
          items: kTiposOrigemNomeDonativo,
          enabled: !ehOnlineIdentificado,
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
            if (!exigePessoa) return null;
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
            label: Text(tipoOrigemNome == 'Pessoa'
                ? 'Selecionar da base de pessoas (${widget.store.pessoas.length})'
                : 'Selecionar da base de referências (${widget.store.referencias.length})'),
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
      ],
    );
  }

  Widget camposLancamento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionLabel(ehOnlineOficial ? 'Acumulado oficial do site' : 'Dados do lançamento'),
        BrDateFormField(
          controller: dataController,
          labelText: ehOnlineOficial ? 'Data da consulta' : 'Data',
          onPickDate: selecionarData,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: valor,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [BrMoneyTextInputFormatter()],
          decoration: InputDecoration(
            labelText: ehOnlineOficial ? 'Valor acumulado no site' : 'Valor',
            hintText: '0,00',
            prefixText: 'R\$ ',
          ),
          validator: (value) {
            final atual = parseValor(value ?? '');
            if (atual <= 0) return 'Informe um valor maior que zero.';
            return null;
          },
        ),
        const SizedBox(height: 12),
        AppDropdown(
          value: tipoDonativo,
          labelText: 'Tipo de donativo',
          items: kTiposDonativo,
          onChanged: (v) => setState(() => tipoDonativo = v),
        ),
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
      ],
    );
  }

  Widget camposEspecificos() {
    if (ehOnline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          AppDropdown(
            value: subtipo,
            labelText: 'Tipo de online',
            items: const [kSubtipoOnlineOficial, kSubtipoOnlineIdentificado],
            onChanged: (v) {
              setState(() {
                subtipo = v;
                if (ehOnlineOficial) {
                  nome.clear();
                  comprovanteAtual = null;
                }
              });
            },
          ),
          if (ehOnlineIdentificado) ...[
            const SizedBox(height: 20),
            camposPessoa(),
            ComprovantePickerCard(
              titulo: 'Comprovante online',
              comprovante: comprovanteAtual,
              onTakePhoto: tirarFotoComprovante,
              onPickImage: () => selecionarComprovante(imagem: true),
              onPickFile: () => selecionarComprovante(imagem: false),
              onRemove: comprovanteAtual == null ? null : removerComprovante,
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        AppDropdown(
          value: subtipo,
          labelText: 'Subtipo',
          items: subtiposDisponiveis,
          onChanged: (v) => setState(() => subtipo = v),
        ),
        if (ehTransferencia) ...[
          const SizedBox(height: 12),
          AppDropdown(
            value: bancoSelecionado,
            labelText: 'Banco da transferência',
            items: kBancosTransferencia,
            onChanged: (v) => setState(() => bancoSelecionado = v),
          ),
          const SizedBox(height: 20),
          ComprovantePickerCard(
            comprovante: comprovanteAtual,
            onTakePhoto: tirarFotoComprovante,
            onPickImage: () => selecionarComprovante(imagem: true),
            onPickFile: () => selecionarComprovante(imagem: false),
            onRemove: comprovanteAtual == null ? null : removerComprovante,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: widget.isEditing ? 'Editar donativo' : 'Novo donativo',
      formKey: formKey,
      onSave: salvar,
      children: [
        campoOrigem(),
        const SizedBox(height: 20),
        if (!ehOnline) camposPessoa(),
        camposLancamento(),
        camposEspecificos(),
      ],
    );
  }
}

class FrequenciaContinuaPage extends StatefulWidget {
  const FrequenciaContinuaPage({super.key, required this.store});
  final AppStore store;

  @override
  State<FrequenciaContinuaPage> createState() => _FrequenciaContinuaPageState();
}

class _FrequenciaContinuaPageState extends State<FrequenciaContinuaPage> {
  final formKey = GlobalKey<FormState>();
  final nome = TextEditingController();
  final obs = TextEditingController();
  final dataController = TextEditingController(text: brDate.format(DateTime.now()));
  final nomeFocus = FocusNode();
  String tipoEvento = 'Dia a dia';
  String tipoPessoa = 'Membro';
  bool salvando = false;

  List<String> get tiposEvento {
    final set = <String>{...kTiposEventoPadrao, ...widget.store.frequencias.map((e) => e.tipoEvento).where((e) => e.trim().isNotEmpty)};
    final lista = set.toList()..sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
    return lista;
  }

  DateTime get dataSelecionada => tryParseBrDate(dataController.text) ?? DateTime.now();

  List<Frequencia> get lancamentosDoDia {
    final data = dateOnly(dataSelecionada);
    final lista = widget.store.frequencias.where((item) => dateOnly(item.data) == data && item.tipoEvento == tipoEvento).toList();
    lista.sort((a, b) => normalizeText(a.nome).compareTo(normalizeText(b.nome)));
    return lista;
  }

  @override
  void dispose() {
    nome.dispose();
    obs.dispose();
    nomeFocus.dispose();
    super.dispose();
  }

  Future<void> selecionarData() async {
    final selecionada = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: dataSelecionada,
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
    nomeFocus.requestFocus();
  }

  void preencherCategoriaPelaBase(String raw) {
    final pessoa = widget.store.findPessoaByName(raw);
    if (pessoa != null) tipoPessoa = valorSeguro(pessoa.tipoPessoaAtual, kTiposPessoaFrequencia, fallback: 'Membro');
  }

  Future<void> salvar({required bool continuar}) async {
    final form = formKey.currentState;
    if (form == null || !form.validate() || salvando) return;

    final data = tryParseBrDate(dataController.text)!;
    final pessoa = widget.store.findPessoaByName(nome.text);
    final categoriaHistorica = pessoa?.tipoPessoaAtual ?? tipoPessoa;
    final nomeAtual = nomeLimpoDeRotuloPessoa(nome.text);

    final duplicado = widget.store.existeFrequenciaDuplicada(nome: nomeAtual, data: data, tipoEvento: tipoEvento);
    if (duplicado) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Essa pessoa já foi lançada nesse dia e evento.')));
      nomeFocus.requestFocus();
      return;
    }

    setState(() => salvando = true);
    try {
      await widget.store.upsertFrequencia(Frequencia(
        id: widget.store.nextFrequenciaId(),
        data: data,
        tipoEvento: tipoEvento,
        nome: nomeAtual,
        tipoPessoaInformado: categoriaHistorica,
        tipoPessoaAtual: categoriaHistorica,
        jc: kJcPadrao,
        observacao: obs.text.trim(),
        dataLancamento: DateTime.now(),
        horaLancamento: TimeOfDay.now().format(context),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nomeAtual lançado.')));
      if (!continuar) {
        Navigator.pop(context);
        return;
      }
      setState(() {
        nome.clear();
        obs.clear();
        tipoPessoa = 'Membro';
      });
      nomeFocus.requestFocus();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(limparMensagemErro(e))));
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lancados = lancamentosDoDia;
    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Scaffold(
        appBar: AppBar(title: const Text('Lançamento contínuo')),
        body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dados fixos do lançamento', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    BrDateFormField(controller: dataController, labelText: 'Data', onPickDate: selecionarData),
                    const SizedBox(height: 12),
                    AppDropdown(value: tipoEvento, labelText: 'Tipo de evento', items: tiposEvento, onChanged: (v) => setState(() => tipoEvento = v)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Adicionar pessoa', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    TextFormField(
                      focusNode: nomeFocus,
                      controller: nome,
                      decoration: InputDecoration(
                        labelText: 'Nome da pessoa',
                        suffixIcon: IconButton(
                          onPressed: widget.store.pessoas.isEmpty ? null : selecionarPessoa,
                          icon: const Icon(Icons.search),
                          tooltip: 'Selecionar da base',
                        ),
                      ),
                      onChanged: (value) => setState(() => preencherCategoriaPelaBase(value)),
                      validator: (value) => (value?.trim().isEmpty ?? true) ? 'Informe o nome.' : null,
                      onFieldSubmitted: (_) => salvar(continuar: true),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: widget.store.pessoas.isEmpty ? null : selecionarPessoa,
                      icon: const Icon(Icons.list_alt_outlined),
                      label: Text('Selecionar da base de pessoas (${widget.store.pessoas.length})'),
                    ),
                    const SizedBox(height: 12),
                    AppDropdown(value: tipoPessoa, labelText: 'Categoria histórica', items: kTiposPessoaFrequencia, onChanged: (v) => setState(() => tipoPessoa = v)),
                    const SizedBox(height: 12),
                    TextFormField(controller: obs, decoration: const InputDecoration(labelText: 'Observação')), 
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: salvando ? null : () => salvar(continuar: true),
                          icon: const Icon(Icons.add_task),
                          label: const Text('Salvar e continuar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: salvando ? null : () => salvar(continuar: false),
                          icon: const Icon(Icons.check),
                          label: const Text('Salvar e fechar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SectionTitle('Lançados em ${brDate.format(dataSelecionada)} • $tipoEvento'),
            for (final item in lancados)
              Card(
                child: ListTile(
                  dense: true,
                  leading: const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.person, color: kAccent)),
                  title: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(item.tipoPessoaAtual),
                ),
              ),
            EmptyState(show: lancados.isEmpty, message: 'Ainda não há presença lançada para essa data/evento.'),
          ],
        ),
      ),
    ),
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
      nome: nomeLimpoDeRotuloPessoa(nome.text),
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
      nome: nomeLimpoDeRotuloPessoa(nome.text),
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
  const ExperienciaForm({super.key, required this.store, this.initialValue});
  final AppStore store;
  final ExperienciaFe? initialValue;

  bool get isEditing => initialValue != null;

  @override
  State<ExperienciaForm> createState() => _ExperienciaFormState();
}

class _ExperienciaFormState extends State<ExperienciaForm> {
  final formKey = GlobalKey<FormState>();
  final nome = TextEditingController();
  final titulo = TextEditingController();
  final resumo = TextEditingController();
  final observacao = TextEditingController();
  final dataController = TextEditingController();
  String status = 'Em produção';
  String tipoPessoa = 'Membro';
  int idPessoa = 0;
  final tagsSelecionadas = <String>{};
  ComprovanteArquivo? arquivoAtual;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialValue;
    nome.text = item?.nome ?? '';
    titulo.text = item?.titulo ?? '';
    resumo.text = item?.resumo ?? '';
    observacao.text = item?.observacao ?? '';
    dataController.text = brDate.format(item?.dataExperiencia ?? DateTime.now());
    status = valorSeguro(item?.status, kStatusExperiencia, fallback: 'Em produção');
    tipoPessoa = valorSeguro(item?.tipoPessoa, kTiposPessoaFrequencia, fallback: 'Membro');
    idPessoa = item?.idPessoa ?? 0;
    tagsSelecionadas.addAll(item?.tags ?? const []);
    arquivoAtual = item?.arquivoExperiencia;
  }

  @override
  void dispose() {
    nome.dispose();
    titulo.dispose();
    resumo.dispose();
    observacao.dispose();
    dataController.dispose();
    super.dispose();
  }

  Future<void> selecionarData() async {
    final atual = tryParseBrDate(dataController.text) ?? DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: atual,
    );
    if (selecionada == null) return;
    setState(() => dataController.text = brDate.format(selecionada));
  }

  void preencherPessoa(String raw) {
    final pessoa = widget.store.findPessoaByName(raw);
    if (pessoa != null) {
      idPessoa = pessoa.idPessoa;
      tipoPessoa = valorSeguro(pessoa.tipoPessoaAtual, kTiposPessoaFrequencia, fallback: tipoPessoa);
    }
  }

  Future<void> selecionarPessoa() async {
    final selecionado = await pickStringFromList(context, title: 'Selecionar pessoa', options: widget.store.nomesPessoas());
    if (selecionado == null) return;
    setState(() {
      nome.text = selecionado;
      preencherPessoa(selecionado);
    });
  }

  Future<void> selecionarArquivo({required bool imagem, bool camera = false}) async {
    try {
      if (!imagem) {
        final resultado = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['pdf', 'doc', 'docx'],
          withData: true,
        );
        if (resultado == null || resultado.files.isEmpty) return;
        final file = resultado.files.first;
        final bytes = file.bytes;
        if (bytes == null) throw Exception('Não foi possível ler o arquivo selecionado.');
        if (bytes.length > kMaxArquivoExperienciaBytes) throw Exception('Arquivo maior que 5 MB.');
        setState(() {
          arquivoAtual = ComprovanteArquivo(
            nome: file.name,
            extensao: extensaoArquivo(file.name, fallback: file.extension ?? ''),
            tamanhoBytes: bytes.length,
            base64: base64Encode(bytes),
            dataAnexo: DateTime.now(),
          );
        });
        return;
      }

      final picker = ImagePicker();
      final foto = await picker.pickImage(source: camera ? ImageSource.camera : ImageSource.gallery, imageQuality: 82);
      if (foto == null) return;
      final bytes = await foto.readAsBytes();
      if (bytes.length > kMaxArquivoExperienciaBytes) throw Exception('Arquivo maior que 5 MB.');
      final nomeArquivo = foto.name.trim().isEmpty ? 'experiencia_${DateTime.now().millisecondsSinceEpoch}.jpg' : foto.name;
      setState(() {
        arquivoAtual = ComprovanteArquivo(
          nome: nomeArquivo,
          extensao: extensaoArquivo(nomeArquivo, fallback: 'jpg'),
          tamanhoBytes: bytes.length,
          base64: base64Encode(bytes),
          dataAnexo: DateTime.now(),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(limparMensagemErro(e))));
    }
  }

  Future<void> salvar() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;
    if (salvando) return;

    setState(() => salvando = true);
    try {
      final id = widget.initialValue?.id ?? widget.store.nextExperienciaId();
      var arquivoStorage = arquivoAtual?.toStorageString() ?? '';
      if (arquivoAtual != null && arquivoAtual!.base64.isNotEmpty) {
        arquivoStorage = await widget.store.salvarArquivoExperienciaNoSupabase(experienciaId: id, arquivo: arquivoAtual!);
      }

      final experiencia = ExperienciaFe(
        id: id,
        dataRegistro: widget.initialValue?.dataRegistro ?? DateTime.now(),
        dataExperiencia: tryParseBrDate(dataController.text) ?? DateTime.now(),
        idPessoa: idPessoa,
        nome: nomeLimpoDeRotuloPessoa(nome.text),
        tipoPessoa: tipoPessoa,
        jc: kJcPadrao,
        titulo: titulo.text.trim(),
        resumo: resumo.text.trim(),
        categoria: '',
        tema: tagsSelecionadas.join('|'),
        status: status,
        responsavelRegistro: '',
        observacao: observacao.text.trim(),
        arquivo: arquivoStorage,
        foiEnviada: status == 'Pronta' || status == 'Apresentada',
        aprovada: status == 'Pronta' || status == 'Apresentada',
        foiApresentada: status == 'Apresentada',
      );

      await widget.store.upsertExperiencia(experiencia);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(limparMensagemErro(e))));
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: widget.isEditing ? 'Editar experiência' : 'Nova experiência',
      formKey: formKey,
      onSave: salvar,
      children: [
        FormSectionLabel('Pessoa e identificação'),
        BrDateFormField(controller: dataController, labelText: 'Data da experiência', onPickDate: selecionarData),
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
          onChanged: (value) => setState(() => preencherPessoa(value)),
          validator: (value) => (value?.trim().isEmpty ?? true) ? 'Informe o nome da pessoa.' : null,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: widget.store.pessoas.isEmpty ? null : selecionarPessoa,
          icon: const Icon(Icons.list_alt_outlined),
          label: Text('Selecionar da base de pessoas (${widget.store.pessoas.length})'),
        ),
        const SizedBox(height: 12),
        AppDropdown(value: tipoPessoa, labelText: 'Categoria', items: kTiposPessoaFrequencia, onChanged: (v) => setState(() => tipoPessoa = v)),
        const SizedBox(height: 20),
        FormSectionLabel('Conteúdo'),
        TextFormField(
          controller: titulo,
          decoration: const InputDecoration(labelText: 'Título'),
          validator: (value) => (value?.trim().isEmpty ?? true) ? 'Informe o título.' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: resumo,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'Resumo'),
          validator: (value) => (value?.trim().isEmpty ?? true) ? 'Informe um resumo.' : null,
        ),
        const SizedBox(height: 12),
        AppDropdown(value: status, labelText: 'Status', items: kStatusExperiencia, onChanged: (v) => setState(() => status = v)),
        const SizedBox(height: 20),
        FormSectionLabel('Tags'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in kTagsExperiencia)
              FilterChip(
                label: Text(tag),
                selected: tagsSelecionadas.contains(tag),
                onSelected: (selecionado) {
                  setState(() {
                    if (selecionado) {
                      tagsSelecionadas.add(tag);
                    } else {
                      tagsSelecionadas.remove(tag);
                    }
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 20),
        ComprovantePickerCard(
          titulo: 'Arquivo da experiência',
          descricao: 'Anexe o arquivo principal da experiência em Word ou PDF. Limite inicial: 5 MB por arquivo.',
          comprovante: arquivoAtual,
          onPickFile: () => selecionarArquivo(imagem: false),
          onRemove: arquivoAtual == null ? null : () => setState(() => arquivoAtual = null),
          fileButtonLabel: 'Word / PDF',
        ),
        const SizedBox(height: 12),
        TextFormField(controller: observacao, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Observação')), 
        if (salvando) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
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
  bool isAuthenticated = false;
  bool isSyncing = false;
  String statusSupabase = 'Não conectado';
  late SharedPreferences prefs;

  SupabaseClient get supabase => Supabase.instance.client;

  List<Pessoa> pessoas = [];
  List<Donativo> donativos = [];
  List<Frequencia> frequencias = [];
  List<ExperienciaFe> experiencias = [];
  List<ReferenciaNome> referencias = [];
  List<OnlineIdentificacao> onlineIdentificacoes = [];
  List<EnsinoCurso> ensinoCursos = [];
  List<EnsinoTurma> ensinoTurmas = [];
  List<EnsinoTurmaAluno> ensinoTurmaAlunos = [];
  List<EnsinoPresenca> ensinoPresencas = [];
  List<EnsinoPosOutorga> ensinoPosOutorgas = [];
  List<EnsinoPosOutorgaEncontro> ensinoPosOutorgaEncontros = [];
  List<Johvem3Aluno> johvem3Alunos = [];
  List<Johvem3Presenca> johvem3Presencas = [];
  List<JohvemAtividade> johvemAtividades = [];
  List<JohvemAtividadeParticipante> johvemAtividadeParticipantes = [];
  List<JohvemAtividadeFoto> johvemAtividadeFotos = [];

  static const _seedImportedKey = 'seed_excel_importado_v1';

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    pessoas = _loadList('pessoas', Pessoa.fromJson);
    donativos = _loadList('donativos', Donativo.fromJson);
    frequencias = _loadList('frequencias', Frequencia.fromJson);
    experiencias = _loadList('experiencias', ExperienciaFe.fromJson);
    referencias = _loadList('referencias', ReferenciaNome.fromJson);
    onlineIdentificacoes = _loadList('online_identificacoes', OnlineIdentificacao.fromJson);
    ensinoCursos = _loadList('ensino_cursos', EnsinoCurso.fromJson);
    ensinoTurmas = _loadList('ensino_turmas', EnsinoTurma.fromJson);
    ensinoTurmaAlunos = _loadList('ensino_turma_alunos', EnsinoTurmaAluno.fromJson);
    ensinoPresencas = _loadList('ensino_presencas', EnsinoPresenca.fromJson);
    ensinoPosOutorgas = _loadList('ensino_pos_outorga', EnsinoPosOutorga.fromJson);
    ensinoPosOutorgaEncontros = _loadList('ensino_pos_outorga_encontros', EnsinoPosOutorgaEncontro.fromJson);
    johvem3Alunos = _loadList('johvem3_alunos', Johvem3Aluno.fromJson);
    johvem3Presencas = _loadList('johvem3_presencas', Johvem3Presenca.fromJson);
    johvemAtividades = _loadList('johvem_atividades', JohvemAtividade.fromJson);
    johvemAtividadeParticipantes = _loadList('johvem_atividade_participantes', JohvemAtividadeParticipante.fromJson);
    johvemAtividadeFotos = _loadList('johvem_atividade_fotos', JohvemAtividadeFoto.fromJson);

    final jaImportouSeed = prefs.getBool(_seedImportedKey) ?? false;
    final bancoLocalVazio = pessoas.isEmpty && donativos.isEmpty && frequencias.isEmpty && experiencias.isEmpty && referencias.isEmpty && onlineIdentificacoes.isEmpty && ensinoTurmas.isEmpty && johvemAtividades.isEmpty;

    if (!jaImportouSeed && bancoLocalVazio) {
      await importarDadosDoExcel(notificar: false);
    }

    isAuthenticated = supabase.auth.currentSession != null;
    if (isAuthenticated) {
      await carregarDadosDoSupabase(substituirSomenteSeHouverDados: true);
    }

    await garantirJohvem3InicialLocal();

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


  Future<void> garantirBasePessoasReferenciasLocal() async {
    if (pessoas.isNotEmpty && referencias.isNotEmpty) return;

    final raw = await rootBundle.loadString('assets/seed_data.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (pessoas.isEmpty) {
      pessoas = _seedList(data, 'pessoas', Pessoa.fromJson);
      await _saveRawList('pessoas', pessoas, (e) => e.toJson());
    }

    if (referencias.isEmpty) {
      referencias = _seedList(data, 'referencias', ReferenciaNome.fromJson);
      await _saveRawList('referencias', referencias, (e) => e.toJson());
    }
  }

  Future<void> login({required String email, required String senha}) async {
    final response = await supabase.auth.signInWithPassword(email: email, password: senha);
    if (response.session == null) {
      throw Exception('Não foi possível entrar. Confira usuário e senha.');
    }
    isAuthenticated = true;
    statusSupabase = 'Conectado';
    await carregarDadosDoSupabase(substituirSomenteSeHouverDados: true);
    notifyListeners();
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    isAuthenticated = false;
    statusSupabase = 'Desconectado';
    notifyListeners();
  }

  Future<void> carregarDadosDoSupabase({bool substituirSomenteSeHouverDados = false}) async {
    if (!isAuthenticated) return;
    isSyncing = true;
    statusSupabase = 'Sincronizando...';
    notifyListeners();

    try {
      final rawPessoas = await supabase.from('pessoas').select().order('nome');
      final rawReferencias = await supabase.from('referencias').select().order('nome_referencia');
      final rawDonativos = await supabase.from('donativos').select().order('data', ascending: false);
      final rawFrequencias = await supabase.from('frequencias').select().order('data', ascending: false);
      final rawExperiencias = await supabase.from('experiencias_fe').select().order('data_registro', ascending: false);

      final pessoasRemote = rows(rawPessoas).map(Pessoa.fromSupabase).toList();
      final referenciasRemote = rows(rawReferencias).map(ReferenciaNome.fromSupabase).toList();
      final donativosRemote = rows(rawDonativos).map(Donativo.fromSupabase).toList();
      final frequenciasRemote = rows(rawFrequencias).map(Frequencia.fromSupabase).toList();
      final experienciasRemote = rows(rawExperiencias).map(ExperienciaFe.fromSupabase).toList();
      await _carregarEnsinoDoSupabaseSeguro();
      await _carregarJohvensDoSupabaseSeguro();

      final remotoTemDados = pessoasRemote.isNotEmpty || referenciasRemote.isNotEmpty || donativosRemote.isNotEmpty || frequenciasRemote.isNotEmpty || experienciasRemote.isNotEmpty || ensinoTurmas.isNotEmpty || ensinoPosOutorgas.isNotEmpty || johvemAtividades.isNotEmpty || johvem3Alunos.isNotEmpty;
      if (!substituirSomenteSeHouverDados) {
        pessoas = pessoasRemote;
        referencias = referenciasRemote;
        donativos = donativosRemote;
        frequencias = frequenciasRemote;
        experiencias = experienciasRemote;
      } else if (remotoTemDados) {
        if (pessoasRemote.isNotEmpty) pessoas = pessoasRemote;
        if (referenciasRemote.isNotEmpty) referencias = referenciasRemote;
        if (donativosRemote.isNotEmpty) donativos = donativosRemote;
        if (frequenciasRemote.isNotEmpty) frequencias = frequenciasRemote;
        if (experienciasRemote.isNotEmpty) experiencias = experienciasRemote;
      }

      if (pessoas.isEmpty || referencias.isEmpty) {
        await garantirBasePessoasReferenciasLocal();
      }

      await _saveRawList('pessoas', pessoas, (e) => e.toJson());
      await _saveRawList('referencias', referencias, (e) => e.toJson());
      await _saveRawList('donativos', donativos, (e) => e.toJson());
      await _saveRawList('frequencias', frequencias, (e) => e.toJson());
      await _saveRawList('experiencias', experiencias, (e) => e.toJson());
      await _saveEnsinoLocal();
      await _saveJohvensLocal();
      statusSupabase = remotoTemDados ? 'Dados carregados do Supabase' : 'Supabase conectado, mantendo base local';
    } catch (e) {
      statusSupabase = 'Erro no Supabase: ${limparMensagemErro(e)}';
      rethrow;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> enviarDadosLocaisParaSupabase() async {
    if (!isAuthenticated) throw Exception('Entre no app antes de enviar dados.');
    isSyncing = true;
    statusSupabase = 'Enviando dados locais...';
    notifyListeners();

    try {
      if (pessoas.isNotEmpty) await supabase.from('pessoas').upsert(pessoas.map((e) => e.toSupabase()).toList());
      if (referencias.isNotEmpty) await supabase.from('referencias').upsert(referencias.map((e) => e.toSupabase()).toList());
      if (donativos.isNotEmpty) await supabase.from('donativos').upsert(donativos.map((e) => e.toSupabase()).toList());
      if (frequencias.isNotEmpty) await supabase.from('frequencias').upsert(frequencias.map((e) => e.toSupabase()).toList());
      if (experiencias.isNotEmpty) await supabase.from('experiencias_fe').upsert(experiencias.map((e) => e.toSupabase()).toList());
      if (johvem3Alunos.isNotEmpty) await supabase.from('johvem3_alunos').upsert(johvem3Alunos.map((e) => e.toSupabase()).toList());
      if (johvem3Presencas.isNotEmpty) await supabase.from('johvem3_presencas').upsert(johvem3Presencas.map((e) => e.toSupabase()).toList());
      if (johvemAtividades.isNotEmpty) await supabase.from('johvem_atividades').upsert(johvemAtividades.map((e) => e.toSupabase()).toList());
      if (johvemAtividadeParticipantes.isNotEmpty) await supabase.from('johvem_atividade_participantes').upsert(johvemAtividadeParticipantes.map((e) => e.toSupabase()).toList());
      if (johvemAtividadeFotos.isNotEmpty) await supabase.from('johvem_atividade_fotos').upsert(johvemAtividadeFotos.map((e) => e.toSupabase()).toList());
      statusSupabase = 'Dados locais enviados para o Supabase';
    } catch (e) {
      statusSupabase = 'Erro ao enviar: ${limparMensagemErro(e)}';
      rethrow;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<String> salvarComprovanteNoSupabase({required int donativoId, required ComprovanteArquivo comprovante}) async {
    if (!isAuthenticated || comprovante.base64.isEmpty) return comprovante.toStorageString();

    final bytes = base64Decode(comprovante.base64);
    final nomeSeguro = sanitizeFileName(comprovante.nome);
    final path = 'donativos/$donativoId/${DateTime.now().millisecondsSinceEpoch}_$nomeSeguro';
    await supabase.storage.from(kComprovantesBucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentTypeForFile(comprovante.nome),
          ),
        );
    return comprovante.copyWith(base64: '', path: path).toStorageString();
  }


  Future<String> salvarArquivoExperienciaNoSupabase({required int experienciaId, required ComprovanteArquivo arquivo}) async {
    if (!isAuthenticated || arquivo.base64.isEmpty) return arquivo.toStorageString();

    final bytes = base64Decode(arquivo.base64);
    final nomeSeguro = sanitizeFileName(arquivo.nome);
    final agora = DateTime.now();
    final path = 'experiencias/${agora.year}/${agora.month.toString().padLeft(2, '0')}/$experienciaId/${agora.millisecondsSinceEpoch}_$nomeSeguro';
    await supabase.storage.from(kExperienciasBucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentTypeForFile(arquivo.nome),
          ),
        );
    return arquivo.copyWith(base64: '', path: path).toStorageString();
  }

  Future<String> salvarFotoPessoaNoSupabase({required int pessoaId, required ComprovanteArquivo foto}) async {
    if (!isAuthenticated || foto.base64.isEmpty) return foto.toStorageString();

    final bytes = base64Decode(foto.base64);
    final nomeSeguro = sanitizeFileName(foto.nome);
    final path = 'pessoas/$pessoaId/${DateTime.now().millisecondsSinceEpoch}_$nomeSeguro';
    await supabase.storage.from(kPessoasFotosBucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentTypeForFile(foto.nome),
          ),
        );
    return foto.copyWith(base64: '', path: path).toStorageString();
  }


  Future<String> salvarFotoJohvemAtividadeNoSupabase({required int atividadeId, required ComprovanteArquivo foto}) async {
    if (!isAuthenticated || foto.base64.isEmpty) return foto.toStorageString();

    final bytes = base64Decode(foto.base64);
    final nomeSeguro = sanitizeFileName(foto.nome);
    final path = 'atividades/$atividadeId/${DateTime.now().millisecondsSinceEpoch}_$nomeSeguro';
    await supabase.storage.from(kJohvensFotosBucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentTypeForFile(foto.nome),
          ),
        );
    return foto.copyWith(base64: '', path: path).toStorageString();
  }

  Future<String?> criarLinkTemporarioJohvemFoto(JohvemAtividadeFoto foto) async {
    final path = foto.arquivoFoto?.path ?? '';
    if (path.isEmpty || !isAuthenticated) return null;
    return supabase.storage.from(kJohvensFotosBucket).createSignedUrl(path, 60 * 10);
  }


  List<Map<String, dynamic>> rows(dynamic value) {
    if (value is List) {
      return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  Future<void> _carregarEnsinoDoSupabaseSeguro() async {
    try {
      final rawCursos = await supabase.from('ensino_cursos').select().order('ordem');
      final rawTurmas = await supabase.from('ensino_turmas').select().order('nome_turma');
      final rawAlunos = await supabase.from('ensino_turma_alunos').select().order('nome_pessoa');
      final rawPresencas = await supabase.from('ensino_presencas').select().order('data', ascending: false);
      final rawPos = await supabase.from('ensino_pos_outorga').select().order('nome_pessoa');
      final rawPosEncontros = await supabase.from('ensino_pos_outorga_encontros').select().order('data', ascending: false);

      ensinoCursos = rows(rawCursos).map(EnsinoCurso.fromSupabase).toList();
      ensinoTurmas = rows(rawTurmas).map(EnsinoTurma.fromSupabase).toList();
      ensinoTurmaAlunos = rows(rawAlunos).map(EnsinoTurmaAluno.fromSupabase).toList();
      ensinoPresencas = rows(rawPresencas).map(EnsinoPresenca.fromSupabase).toList();
      ensinoPosOutorgas = rows(rawPos).map(EnsinoPosOutorga.fromSupabase).toList();
      ensinoPosOutorgaEncontros = rows(rawPosEncontros).map(EnsinoPosOutorgaEncontro.fromSupabase).toList();
    } catch (_) {
      // As tabelas do Ensino são criadas pela migration v12. Antes disso, mantemos o app funcionando.
    }
  }

  Future<void> _saveEnsinoLocal() async {
    await _saveRawList('ensino_cursos', ensinoCursos, (e) => e.toJson());
    await _saveRawList('ensino_turmas', ensinoTurmas, (e) => e.toJson());
    await _saveRawList('ensino_turma_alunos', ensinoTurmaAlunos, (e) => e.toJson());
    await _saveRawList('ensino_presencas', ensinoPresencas, (e) => e.toJson());
    await _saveRawList('ensino_pos_outorga', ensinoPosOutorgas, (e) => e.toJson());
    await _saveRawList('ensino_pos_outorga_encontros', ensinoPosOutorgaEncontros, (e) => e.toJson());
  }


  Future<void> _carregarJohvensDoSupabaseSeguro() async {
    try {
      final rawAlunos = await supabase.from('johvem3_alunos').select().order('nome_pessoa');
      final rawPresencas = await supabase.from('johvem3_presencas').select().order('data', ascending: false);
      final rawAtividades = await supabase.from('johvem_atividades').select().order('data', ascending: false);
      final rawParticipantes = await supabase.from('johvem_atividade_participantes').select().order('nome_pessoa');
      final rawFotos = await supabase.from('johvem_atividade_fotos').select().order('id');

      johvem3Alunos = rows(rawAlunos).map(Johvem3Aluno.fromSupabase).toList();
      johvem3Presencas = rows(rawPresencas).map(Johvem3Presenca.fromSupabase).toList();
      johvemAtividades = rows(rawAtividades).map(JohvemAtividade.fromSupabase).toList();
      johvemAtividadeParticipantes = rows(rawParticipantes).map(JohvemAtividadeParticipante.fromSupabase).toList();
      johvemAtividadeFotos = rows(rawFotos).map(JohvemAtividadeFoto.fromSupabase).toList();
    } catch (_) {
      // As tabelas dos Johvens são criadas pela migration v13. Antes disso, mantemos o app funcionando.
    }
  }

  Future<void> _saveJohvensLocal() async {
    await _saveRawList('johvem3_alunos', johvem3Alunos, (e) => e.toJson());
    await _saveRawList('johvem3_presencas', johvem3Presencas, (e) => e.toJson());
    await _saveRawList('johvem_atividades', johvemAtividades, (e) => e.toJson());
    await _saveRawList('johvem_atividade_participantes', johvemAtividadeParticipantes, (e) => e.toJson());
    await _saveRawList('johvem_atividade_fotos', johvemAtividadeFotos, (e) => e.toJson());
  }

  Future<void> garantirJohvem3InicialLocal() async {
    if (johvem3Alunos.isNotEmpty || pessoas.isEmpty) return;
    final nomes = [
      'Ana Carolina Silva Almeida',
      'Catherine Marcele Fernandez do Espirito Santo Rosolem',
    ];
    var id = 1;
    for (final nome in nomes) {
      final pessoa = findPessoaByName(nome);
      if (pessoa == null) continue;
      johvem3Alunos.add(Johvem3Aluno(
        id: id++,
        idPessoa: pessoa.idPessoa,
        codigoMembro: pessoa.codigoMembro,
        nomePessoa: pessoa.nome,
        status: 'Em andamento',
        progressoAulas: 0,
        jc: kJcPadrao,
      ));
    }
    if (johvem3Alunos.isNotEmpty) await _saveJohvensLocal();
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

  Future<void> addPessoa(Pessoa value) => upsertPessoa(value);

  Future<void> upsertPessoa(Pessoa value) async {
    final index = pessoas.indexWhere((item) => item.idPessoa == value.idPessoa);
    if (index >= 0) {
      pessoas[index] = value;
    } else {
      pessoas.add(value);
    }
    if (isAuthenticated) await supabase.from('pessoas').upsert(value.toSupabase());
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
    if (isAuthenticated) await supabase.from('donativos').upsert(value.toSupabase());
    await _saveList('donativos', donativos, (e) => e.toJson());
  }

  Future<void> deleteDonativo(int id) async {
    donativos.removeWhere((item) => item.id == id);
    if (isAuthenticated) await supabase.from('donativos').delete().eq('id', id);
    await _saveList('donativos', donativos, (e) => e.toJson());
  }

  Future<void> marcarDepositoJc(int id, {required bool lancado}) async {
    final index = donativos.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final atualizado = donativos[index].copyWith(
      depositoStatus: lancado ? 'Lançado' : 'Pendente',
      depositoLancadoEm: lancado ? DateTime.now() : null,
      limparDepositoLancadoEm: !lancado,
    );
    await upsertDonativo(atualizado);
  }

  Future<String?> criarLinkTemporarioComprovante(Donativo item) async {
    final path = item.comprovanteArquivo?.path ?? '';
    if (path.isEmpty || !isAuthenticated) return null;
    return supabase.storage.from(kComprovantesBucket).createSignedUrl(path, 60 * 10);
  }

  Future<void> addFrequencia(Frequencia value) => upsertFrequencia(value);

  Future<void> upsertFrequencia(Frequencia value) async {
    final index = frequencias.indexWhere((item) => item.id == value.id);
    if (index >= 0) {
      frequencias[index] = value;
    } else {
      frequencias.add(value);
    }
    if (isAuthenticated) await supabase.from('frequencias').upsert(value.toSupabase());
    await _saveList('frequencias', frequencias, (e) => e.toJson());
  }

  Future<void> deleteFrequencia(int id) async {
    frequencias.removeWhere((item) => item.id == id);
    if (isAuthenticated) await supabase.from('frequencias').delete().eq('id', id);
    await _saveList('frequencias', frequencias, (e) => e.toJson());
  }

  bool existeFrequenciaDuplicada({required String nome, required DateTime data, required String tipoEvento, int? ignorarId}) {
    final alvoNome = normalizeText(nomeLimpoDeRotuloPessoa(nome));
    final alvoData = dateOnly(data);
    final alvoEvento = normalizeText(tipoEvento);
    return frequencias.any((item) {
      if (ignorarId != null && item.id == ignorarId) return false;
      return normalizeText(item.nome) == alvoNome && dateOnly(item.data) == alvoData && normalizeText(item.tipoEvento) == alvoEvento;
    });
  }

  Future<void> addExperiencia(ExperienciaFe value) => upsertExperiencia(value);

  Future<void> upsertExperiencia(ExperienciaFe value) async {
    final index = experiencias.indexWhere((item) => item.id == value.id);
    if (index >= 0) {
      experiencias[index] = value;
    } else {
      experiencias.add(value);
    }
    if (isAuthenticated) await supabase.from('experiencias_fe').upsert(value.toSupabase());
    await _saveList('experiencias', experiencias, (e) => e.toJson());
  }

  Future<void> deleteExperiencia(int id) async {
    experiencias.removeWhere((item) => item.id == id);
    if (isAuthenticated) await supabase.from('experiencias_fe').delete().eq('id', id);
    await _saveList('experiencias', experiencias, (e) => e.toJson());
  }

  Future<String?> criarLinkTemporarioExperiencia(ExperienciaFe item) async {
    final path = item.arquivoExperiencia?.path ?? '';
    if (path.isEmpty || !isAuthenticated) return null;
    return supabase.storage.from(kExperienciasBucket).createSignedUrl(path, 60 * 10);
  }

  Future<String?> criarLinkTemporarioPessoaFoto(Pessoa? pessoa) async {
    final path = pessoa?.fotoArquivo?.path ?? '';
    if (path.isEmpty || !isAuthenticated) return null;
    return supabase.storage.from(kPessoasFotosBucket).createSignedUrl(path, 60 * 10);
  }

  Future<void> addReferencia(ReferenciaNome value) async {
    referencias.add(value);
    if (isAuthenticated) await supabase.from('referencias').upsert(value.toSupabase());
    await _saveList('referencias', referencias, (e) => e.toJson());
  }

  Future<void> addOnline(OnlineIdentificacao value) async {
    onlineIdentificacoes.add(value);
    await _saveList('online_identificacoes', onlineIdentificacoes, (e) => e.toJson());
  }

  Pessoa? findPessoaByName(String nome) {
    final alvoOriginal = nome.trim();
    final codigo = codigoMembroFromRotulo(alvoOriginal);
    if (codigo.isNotEmpty) {
      for (final pessoa in pessoas) {
        if (pessoa.codigoMembro == codigo) return pessoa;
      }
    }

    final alvo = normalizeText(nomeLimpoDeRotuloPessoa(alvoOriginal));
    for (final pessoa in pessoas) {
      if (normalizeText(pessoa.nome) == alvo) return pessoa;
    }
    return null;
  }


  Pessoa? findPessoaById(int idPessoa) {
    if (idPessoa <= 0) return null;
    for (final pessoa in pessoas) {
      if (pessoa.idPessoa == idPessoa) return pessoa;
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
    final nomesNormalizados = <String, int>{};
    for (final pessoa in pessoas) {
      final key = normalizeText(pessoa.nome);
      if (key.isEmpty) continue;
      nomesNormalizados[key] = (nomesNormalizados[key] ?? 0) + 1;
    }

    final opcoes = pessoas.where((item) => item.nome.trim().isNotEmpty).map((item) {
      final duplicado = (nomesNormalizados[normalizeText(item.nome)] ?? 0) > 1;
      if (!duplicado && item.codigoMembro.trim().isEmpty) return item.nome.trim();
      final detalhes = <String>[];
      if (item.codigoMembro.trim().isNotEmpty) detalhes.add('Cód. ${item.codigoMembro}');
      if (item.dataNascimento != null) detalhes.add('Nasc. ${brDate.format(item.dataNascimento!)}');
      if (item.tipoOutorga.trim().isNotEmpty) detalhes.add(item.tipoOutorga);
      return detalhes.isEmpty ? item.nome.trim() : '${item.nome.trim()} • ${detalhes.join(' • ')}';
    }).toList();

    opcoes.sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
    return opcoes;
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


  int get ensinoAlunosEmCurso => ensinoTurmaAlunos.where((a) => a.status == 'Em andamento').length;
  int get ensinoTurmasAtivas => ensinoTurmas.where((t) => t.status == 'Em andamento').length;
  int get posOutorgaPendentes => ensinoPosOutorgas.where((p) => p.status == 'Pendente').length;

  int idCursoPorNome(String nome) {
    for (final curso in ensinoCursos) {
      if (normalizeText(curso.nome) == normalizeText(nome)) return curso.id;
    }
    final index = kCursosEnsinoPadrao.keys.toList().indexWhere((e) => normalizeText(e) == normalizeText(nome));
    return index >= 0 ? index + 1 : 0;
  }

  int totalAulasCurso(String nome) {
    for (final curso in ensinoCursos) {
      if (normalizeText(curso.nome) == normalizeText(nome)) return curso.totalAulas;
    }
    return kCursosEnsinoPadrao[nome] ?? 0;
  }

  EnsinoTurma? findTurmaById(int id) {
    for (final turma in ensinoTurmas) {
      if (turma.id == id) return turma;
    }
    return null;
  }

  List<EnsinoTurmaAluno> alunosDaTurma(int idTurma) {
    final lista = ensinoTurmaAlunos.where((a) => a.idTurma == idTurma).toList();
    lista.sort((a, b) => normalizeText(a.nomePessoa).compareTo(normalizeText(b.nomePessoa)));
    return lista;
  }

  List<int> aulasLancadasTurma(int idTurma) {
    final aulas = ensinoPresencas.where((p) => p.idTurma == idTurma).map((p) => p.aulaNumero).toSet().toList()..sort();
    return aulas;
  }

  List<EnsinoPresenca> presencasDaTurmaAula(int idTurma, int aulaNumero) {
    return ensinoPresencas.where((p) => p.idTurma == idTurma && p.aulaNumero == aulaNumero).toList();
  }

  int progressoAluno(int idAluno) {
    return ensinoPresencas.where((p) => p.idAluno == idAluno && p.presente).map((p) => p.aulaNumero).toSet().length;
  }

  Future<void> upsertEnsinoTurma(EnsinoTurma value) async {
    final index = ensinoTurmas.indexWhere((item) => item.id == value.id);
    if (index >= 0) {
      ensinoTurmas[index] = value;
    } else {
      ensinoTurmas.add(value);
    }
    if (isAuthenticated) await supabase.from('ensino_turmas').upsert(value.toSupabase());
    await _saveEnsinoLocal();
    notifyListeners();
  }

  Future<void> upsertEnsinoTurmaAluno(EnsinoTurmaAluno value) async {
    final index = ensinoTurmaAlunos.indexWhere((item) => item.id == value.id);
    if (index >= 0) {
      ensinoTurmaAlunos[index] = value;
    } else {
      ensinoTurmaAlunos.add(value);
    }
    if (isAuthenticated) await supabase.from('ensino_turma_alunos').upsert(value.toSupabase());
    await _saveEnsinoLocal();
    notifyListeners();
  }

  Future<void> salvarPresencasTurma({required EnsinoTurma turma, required int aulaNumero, required DateTime data, required Map<int, bool> presentes}) async {
    final novos = <EnsinoPresenca>[];
    for (final aluno in alunosDaTurma(turma.id)) {
      final existente = ensinoPresencas.where((p) => p.idTurma == turma.id && p.idAluno == aluno.id && p.aulaNumero == aulaNumero).toList();
      final presenca = EnsinoPresenca(
        id: existente.isNotEmpty ? existente.first.id : nextEnsinoPresencaId() + novos.length,
        idTurma: turma.id,
        idAluno: aluno.id,
        idPessoa: aluno.idPessoa,
        codigoMembro: aluno.codigoMembro,
        nomePessoa: aluno.nomePessoa,
        aulaNumero: aulaNumero,
        data: data,
        presente: presentes[aluno.id] ?? false,
        observacao: '',
        jc: kJcPadrao,
      );
      final idx = ensinoPresencas.indexWhere((p) => p.id == presenca.id);
      if (idx >= 0) {
        ensinoPresencas[idx] = presenca;
      } else {
        ensinoPresencas.add(presenca);
      }
      novos.add(presenca);
    }
    if (isAuthenticated && novos.isNotEmpty) await supabase.from('ensino_presencas').upsert(novos.map((e) => e.toSupabase()).toList());

    final atualizados = <EnsinoTurmaAluno>[];
    for (final aluno in alunosDaTurma(turma.id)) {
      final progresso = progressoAluno(aluno.id);
      final atualizado = aluno.copyWith(progressoAulas: progresso, status: progresso >= totalAulasCurso(turma.cursoNome) ? 'Concluído' : aluno.status);
      final idx = ensinoTurmaAlunos.indexWhere((a) => a.id == aluno.id);
      if (idx >= 0) ensinoTurmaAlunos[idx] = atualizado;
      atualizados.add(atualizado);
    }
    if (isAuthenticated && atualizados.isNotEmpty) await supabase.from('ensino_turma_alunos').upsert(atualizados.map((e) => e.toSupabase()).toList());
    await _saveEnsinoLocal();
    notifyListeners();
  }

  List<EnsinoPosOutorgaEncontro> encontrosPosOutorga(int idPosOutorga) {
    final lista = ensinoPosOutorgaEncontros.where((e) => e.idPosOutorga == idPosOutorga).toList();
    lista.sort((a, b) => a.numeroEncontro.compareTo(b.numeroEncontro));
    return lista;
  }

  Future<void> upsertPosOutorga(EnsinoPosOutorga value) async {
    final index = ensinoPosOutorgas.indexWhere((item) => item.id == value.id);
    if (index >= 0) {
      ensinoPosOutorgas[index] = value;
    } else {
      ensinoPosOutorgas.add(value);
    }
    if (isAuthenticated) await supabase.from('ensino_pos_outorga').upsert(value.toSupabase());
    await _saveEnsinoLocal();
    notifyListeners();
  }

  Future<void> upsertPosOutorgaEncontro(EnsinoPosOutorgaEncontro value) async {
    final index = ensinoPosOutorgaEncontros.indexWhere((item) => item.id == value.id);
    if (index >= 0) {
      ensinoPosOutorgaEncontros[index] = value;
    } else {
      ensinoPosOutorgaEncontros.add(value);
    }
    if (isAuthenticated) await supabase.from('ensino_pos_outorga_encontros').upsert(value.toSupabase());
    final acompanhamento = ensinoPosOutorgas.firstWhere((p) => p.id == value.idPosOutorga, orElse: () => EnsinoPosOutorga.vazio());
    if (acompanhamento.id != 0) {
      final total = encontrosPosOutorga(acompanhamento.id).length;
      final novoStatus = total >= 6 ? 'Concluído' : 'Em andamento';
      await upsertPosOutorga(acompanhamento.copyWith(status: novoStatus));
    }
    await _saveEnsinoLocal();
    notifyListeners();
  }

  int nextEnsinoTurmaId() => ensinoTurmas.isEmpty ? 1 : ensinoTurmas.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextEnsinoTurmaAlunoId() => ensinoTurmaAlunos.isEmpty ? 1 : ensinoTurmaAlunos.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextEnsinoPresencaId() => ensinoPresencas.isEmpty ? 1 : ensinoPresencas.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextPosOutorgaId() => ensinoPosOutorgas.isEmpty ? 1 : ensinoPosOutorgas.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextPosOutorgaEncontroId() => ensinoPosOutorgaEncontros.isEmpty ? 1 : ensinoPosOutorgaEncontros.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;

  int idadePessoa(Pessoa pessoa, {DateTime? referencia}) {
    final nasc = pessoa.dataNascimento;
    if (nasc == null) return -1;
    final hoje = referencia ?? DateTime.now();
    var idade = hoje.year - nasc.year;
    final fezAniversario = hoje.month > nasc.month || (hoje.month == nasc.month && hoje.day >= nasc.day);
    if (!fezAniversario) idade--;
    return idade;
  }

  bool pessoaEhJohvem(Pessoa pessoa) {
    final idade = idadePessoa(pessoa);
    return idade >= 12 && idade <= 35;
  }

  List<Pessoa> get johvensAutomaticos {
    final lista = pessoas.where(pessoaEhJohvem).toList();
    lista.sort((a, b) => normalizeText(a.nome).compareTo(normalizeText(b.nome)));
    return lista;
  }

  int get johvensMembros => johvensAutomaticos.where((p) => normalizeText(p.tipoPessoaAtual) == 'membro').length;
  int get johvem3AlunosEmCurso => johvem3Alunos.where((a) => a.status == 'Em andamento').length;

  List<Johvem3Presenca> presencasJohvem3Aula(int aulaNumero) {
    return johvem3Presencas.where((p) => p.aulaNumero == aulaNumero).toList();
  }

  int progressoJohvem3Aluno(int idAluno) {
    return johvem3Presencas.where((p) => p.idAluno == idAluno && p.presente).map((p) => p.aulaNumero).toSet().length;
  }

  List<JohvemAtividadeParticipante> participantesAtividade(int idAtividade) {
    final lista = johvemAtividadeParticipantes.where((p) => p.idAtividade == idAtividade).toList();
    lista.sort((a, b) => normalizeText(a.nomePessoa).compareTo(normalizeText(b.nomePessoa)));
    return lista;
  }

  List<JohvemAtividadeFoto> fotosAtividade(int idAtividade) {
    return johvemAtividadeFotos.where((f) => f.idAtividade == idAtividade).toList();
  }

  Future<void> upsertJohvem3Aluno(Johvem3Aluno value) async {
    final index = johvem3Alunos.indexWhere((item) => item.id == value.id);
    if (index >= 0) {
      johvem3Alunos[index] = value;
    } else {
      johvem3Alunos.add(value);
    }
    if (isAuthenticated) await supabase.from('johvem3_alunos').upsert(value.toSupabase());
    await _saveJohvensLocal();
    notifyListeners();
  }

  Future<void> salvarPresencasJohvem3({required int aulaNumero, required DateTime data, required Map<int, bool> presentes}) async {
    final novos = <Johvem3Presenca>[];
    for (final aluno in johvem3Alunos) {
      final existente = johvem3Presencas.where((p) => p.idAluno == aluno.id && p.aulaNumero == aulaNumero).toList();
      final presenca = Johvem3Presenca(
        id: existente.isNotEmpty ? existente.first.id : nextJohvem3PresencaId() + novos.length,
        idAluno: aluno.id,
        idPessoa: aluno.idPessoa,
        codigoMembro: aluno.codigoMembro,
        nomePessoa: aluno.nomePessoa,
        aulaNumero: aulaNumero,
        data: data,
        presente: presentes[aluno.id] ?? false,
        observacao: '',
        jc: kJcPadrao,
      );
      final idx = johvem3Presencas.indexWhere((p) => p.id == presenca.id);
      if (idx >= 0) {
        johvem3Presencas[idx] = presenca;
      } else {
        johvem3Presencas.add(presenca);
      }
      novos.add(presenca);
    }
    if (isAuthenticated && novos.isNotEmpty) await supabase.from('johvem3_presencas').upsert(novos.map((e) => e.toSupabase()).toList());

    final atualizados = <Johvem3Aluno>[];
    for (final aluno in johvem3Alunos) {
      final progresso = progressoJohvem3Aluno(aluno.id);
      final atualizado = aluno.copyWith(progressoAulas: progresso, status: progresso >= kTotalAulasJohvem3 ? 'Concluído' : aluno.status);
      final idx = johvem3Alunos.indexWhere((a) => a.id == aluno.id);
      if (idx >= 0) johvem3Alunos[idx] = atualizado;
      atualizados.add(atualizado);
    }
    if (isAuthenticated && atualizados.isNotEmpty) await supabase.from('johvem3_alunos').upsert(atualizados.map((e) => e.toSupabase()).toList());
    await _saveJohvensLocal();
    notifyListeners();
  }

  Future<void> upsertJohvemAtividade(JohvemAtividade value) async {
    final index = johvemAtividades.indexWhere((item) => item.id == value.id);
    if (index >= 0) {
      johvemAtividades[index] = value;
    } else {
      johvemAtividades.add(value);
    }
    if (isAuthenticated) await supabase.from('johvem_atividades').upsert(value.toSupabase());
    await _saveJohvensLocal();
    notifyListeners();
  }

  Future<void> salvarParticipantesAtividade({required int idAtividade, required List<JohvemAtividadeParticipante> participantes}) async {
    johvemAtividadeParticipantes.removeWhere((p) => p.idAtividade == idAtividade);
    johvemAtividadeParticipantes.addAll(participantes);
    if (isAuthenticated) {
      await supabase.from('johvem_atividade_participantes').delete().eq('id_atividade', idAtividade);
      if (participantes.isNotEmpty) await supabase.from('johvem_atividade_participantes').upsert(participantes.map((e) => e.toSupabase()).toList());
    }
    await _saveJohvensLocal();
    notifyListeners();
  }

  Future<void> salvarFotosAtividade({required int idAtividade, required List<JohvemAtividadeFoto> fotos}) async {
    final salvas = <JohvemAtividadeFoto>[];
    for (final foto in fotos) {
      var atualizado = foto;
      final arquivo = foto.arquivoFoto;
      if (arquivo != null && arquivo.base64.isNotEmpty) {
        final storage = await salvarFotoJohvemAtividadeNoSupabase(atividadeId: idAtividade, foto: arquivo);
        atualizado = foto.copyWith(arquivo: storage);
      }
      salvas.add(atualizado);
    }
    johvemAtividadeFotos.removeWhere((f) => f.idAtividade == idAtividade);
    johvemAtividadeFotos.addAll(salvas);
    if (isAuthenticated) {
      await supabase.from('johvem_atividade_fotos').delete().eq('id_atividade', idAtividade);
      if (salvas.isNotEmpty) await supabase.from('johvem_atividade_fotos').upsert(salvas.map((e) => e.toSupabase()).toList());
    }
    await _saveJohvensLocal();
    notifyListeners();
  }

  int nextJohvem3AlunoId() => johvem3Alunos.isEmpty ? 1 : johvem3Alunos.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextJohvem3PresencaId() => johvem3Presencas.isEmpty ? 1 : johvem3Presencas.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextJohvemAtividadeId() => johvemAtividades.isEmpty ? 1 : johvemAtividades.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextJohvemAtividadeParticipanteId() => johvemAtividadeParticipantes.isEmpty ? 1 : johvemAtividadeParticipantes.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  int nextJohvemAtividadeFotoId() => johvemAtividadeFotos.isEmpty ? 1 : johvemAtividadeFotos.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;

  double totalDonativosMes(DateTime date) {
    return totalizarDonativos(donativos.where((d) => d.data.year == date.year && d.data.month == date.month));
  }

  int presencasMes(DateTime date) {
    return frequencias.where((f) => f.data.year == date.year && f.data.month == date.month).length;
  }

  double totalOnlineOficialMes(DateTime date) {
    return _onlineAcumuladoAte(donativos, date.year, date.month, 31);
  }

  double totalOnlineIdentificadoMes(DateTime date) {
    return donativos
        .where((d) => d.ehOnlineIdentificado && d.data.year == date.year && d.data.month == date.month)
        .fold(0.0, (sum, item) => sum + item.valor);
  }

  double totalizarDonativos(Iterable<Donativo> values) {
    final itens = values.toList();
    final totalNormal = itens
        .where((item) => item.origem != 'Online')
        .fold(0.0, (sum, item) => sum + item.valor);
    return totalNormal + _totalOnlineOficialAcumulado(itens);
  }

  double _totalOnlineOficialAcumulado(Iterable<Donativo> values) {
    final itens = values.where((item) => item.ehOnlineOficial).toList();
    final meses = <String>{for (final item in itens) '${item.data.year}-${item.data.month}'};
    var total = 0.0;
    for (final chave in meses) {
      final partes = chave.split('-');
      total += _onlineAcumuladoAte(itens, int.parse(partes[0]), int.parse(partes[1]), 31);
    }
    return total;
  }

  double _onlineAcumuladoAte(Iterable<Donativo> values, int ano, int mes, int diaLimite) {
    final candidatos = values
        .where((item) => item.ehOnlineOficial && item.data.year == ano && item.data.month == mes && item.data.day <= diaLimite)
        .toList();
    if (candidatos.isEmpty) return 0;
    candidatos.sort((a, b) {
      final byDate = b.data.compareTo(a.data);
      if (byDate != 0) return byDate;
      return b.id.compareTo(a.id);
    });
    return candidatos.first.valor;
  }

  List<DecendioResumo> resumirDecendios(Iterable<Donativo> values) {
    final ranges = [
      (1, '1 a 10', 1, 10, 0),
      (2, '11 a 20', 11, 20, 10),
      (3, '21 ao fim do mês', 21, 31, 20),
    ];
    final itens = values.toList();
    final mesesOnline = <String>{for (final item in itens.where((e) => e.ehOnlineOficial)) '${item.data.year}-${item.data.month}'};

    return ranges.map((r) {
      final dadosNormais = itens.where((item) => item.origem != 'Online' && item.data.day >= r.$3 && item.data.day <= r.$4).toList();
      var totalOnline = 0.0;
      var qtdOnline = 0;
      for (final chave in mesesOnline) {
        final partes = chave.split('-');
        final ano = int.parse(partes[0]);
        final mes = int.parse(partes[1]);
        final acumuladoAtual = _onlineAcumuladoAte(itens, ano, mes, r.$4);
        final acumuladoAnterior = _onlineAcumuladoAte(itens, ano, mes, r.$5);
        final diferenca = acumuladoAtual - acumuladoAnterior;
        if (diferenca > 0) {
          totalOnline += diferenca;
          qtdOnline++;
        }
      }
      final totalNormal = dadosNormais.fold(0.0, (sum, item) => sum + item.valor);
      return DecendioResumo(numero: r.$1, rotulo: r.$2, quantidade: dadosNormais.length + qtdOnline, total: totalNormal + totalOnline);
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
    ensinoCursos.clear();
    ensinoTurmas.clear();
    ensinoTurmaAlunos.clear();
    ensinoPresencas.clear();
    ensinoPosOutorgas.clear();
    ensinoPosOutorgaEncontros.clear();
    notifyListeners();
  }
}



class Johvem3Aluno {
  Johvem3Aluno({required this.id, required this.idPessoa, required this.codigoMembro, required this.nomePessoa, required this.status, required this.progressoAulas, required this.jc});
  final int id;
  final int idPessoa;
  final String codigoMembro;
  final String nomePessoa;
  final String status;
  final int progressoAulas;
  final String jc;

  Johvem3Aluno copyWith({String? status, int? progressoAulas}) => Johvem3Aluno(
        id: id,
        idPessoa: idPessoa,
        codigoMembro: codigoMembro,
        nomePessoa: nomePessoa,
        status: status ?? this.status,
        progressoAulas: progressoAulas ?? this.progressoAulas,
        jc: jc,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'idPessoa': idPessoa,
        'codigoMembro': codigoMembro,
        'nomePessoa': nomePessoa,
        'status': status,
        'progressoAulas': progressoAulas,
        'jc': jc,
      };

  factory Johvem3Aluno.fromJson(Map<String, dynamic> json) => Johvem3Aluno(
        id: json['id'] ?? 0,
        idPessoa: json['idPessoa'] ?? 0,
        codigoMembro: (json['codigoMembro'] ?? '').toString(),
        nomePessoa: (json['nomePessoa'] ?? '').toString(),
        status: (json['status'] ?? 'Em andamento').toString(),
        progressoAulas: json['progressoAulas'] is num ? (json['progressoAulas'] as num).toInt() : 0,
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'id_pessoa': idPessoa,
        'codigo_membro': codigoMembro,
        'nome_pessoa': nomePessoa,
        'status': status,
        'progresso_aulas': progressoAulas,
        'jc': jc,
      };

  factory Johvem3Aluno.fromSupabase(Map<String, dynamic> json) => Johvem3Aluno(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        idPessoa: json['id_pessoa'] is num ? (json['id_pessoa'] as num).toInt() : 0,
        codigoMembro: (json['codigo_membro'] ?? '').toString(),
        nomePessoa: (json['nome_pessoa'] ?? '').toString(),
        status: (json['status'] ?? 'Em andamento').toString(),
        progressoAulas: json['progresso_aulas'] is num ? (json['progresso_aulas'] as num).toInt() : 0,
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );
}

class Johvem3Presenca {
  Johvem3Presenca({required this.id, required this.idAluno, required this.idPessoa, required this.codigoMembro, required this.nomePessoa, required this.aulaNumero, required this.data, required this.presente, required this.observacao, required this.jc});
  final int id;
  final int idAluno;
  final int idPessoa;
  final String codigoMembro;
  final String nomePessoa;
  final int aulaNumero;
  final DateTime data;
  final bool presente;
  final String observacao;
  final String jc;

  Map<String, dynamic> toJson() => {
        'id': id,
        'idAluno': idAluno,
        'idPessoa': idPessoa,
        'codigoMembro': codigoMembro,
        'nomePessoa': nomePessoa,
        'aulaNumero': aulaNumero,
        'data': data.toIso8601String(),
        'presente': presente,
        'observacao': observacao,
        'jc': jc,
      };

  factory Johvem3Presenca.fromJson(Map<String, dynamic> json) => Johvem3Presenca(
        id: json['id'] ?? 0,
        idAluno: json['idAluno'] ?? 0,
        idPessoa: json['idPessoa'] ?? 0,
        codigoMembro: (json['codigoMembro'] ?? '').toString(),
        nomePessoa: (json['nomePessoa'] ?? '').toString(),
        aulaNumero: json['aulaNumero'] is num ? (json['aulaNumero'] as num).toInt() : 1,
        data: parseDate(json['data']),
        presente: json['presente'] == true,
        observacao: (json['observacao'] ?? '').toString(),
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'id_aluno': idAluno,
        'id_pessoa': idPessoa,
        'codigo_membro': codigoMembro,
        'nome_pessoa': nomePessoa,
        'aula_numero': aulaNumero,
        'data': sqlDate(data),
        'presente': presente,
        'observacao': observacao,
        'jc': jc,
      };

  factory Johvem3Presenca.fromSupabase(Map<String, dynamic> json) => Johvem3Presenca(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        idAluno: json['id_aluno'] is num ? (json['id_aluno'] as num).toInt() : 0,
        idPessoa: json['id_pessoa'] is num ? (json['id_pessoa'] as num).toInt() : 0,
        codigoMembro: (json['codigo_membro'] ?? '').toString(),
        nomePessoa: (json['nome_pessoa'] ?? '').toString(),
        aulaNumero: json['aula_numero'] is num ? (json['aula_numero'] as num).toInt() : 1,
        data: parseDate(json['data']),
        presente: json['presente'] == true,
        observacao: (json['observacao'] ?? '').toString(),
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );
}

class JohvemAtividade {
  JohvemAtividade({required this.id, required this.data, required this.tipo, required this.titulo, required this.descricao, required this.responsavel, required this.jc, required this.createdAt});
  final int id;
  final DateTime data;
  final String tipo;
  final String titulo;
  final String descricao;
  final String responsavel;
  final String jc;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.toIso8601String(),
        'tipo': tipo,
        'titulo': titulo,
        'descricao': descricao,
        'responsavel': responsavel,
        'jc': jc,
        'createdAt': createdAt.toIso8601String(),
      };

  factory JohvemAtividade.fromJson(Map<String, dynamic> json) => JohvemAtividade(
        id: json['id'] ?? 0,
        data: parseDate(json['data']),
        tipo: (json['tipo'] ?? '').toString(),
        titulo: (json['titulo'] ?? '').toString(),
        descricao: (json['descricao'] ?? '').toString(),
        responsavel: (json['responsavel'] ?? '').toString(),
        jc: (json['jc'] ?? kJcPadrao).toString(),
        createdAt: parseDate(json['createdAt']),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'data': sqlDate(data),
        'tipo': tipo,
        'titulo': titulo,
        'descricao': descricao,
        'responsavel': responsavel,
        'jc': jc,
        'created_at': createdAt.toIso8601String(),
      };

  factory JohvemAtividade.fromSupabase(Map<String, dynamic> json) => JohvemAtividade(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        data: parseDate(json['data']),
        tipo: (json['tipo'] ?? '').toString(),
        titulo: (json['titulo'] ?? '').toString(),
        descricao: (json['descricao'] ?? '').toString(),
        responsavel: (json['responsavel'] ?? '').toString(),
        jc: (json['jc'] ?? kJcPadrao).toString(),
        createdAt: parseDate(json['created_at']),
      );
}

class JohvemAtividadeParticipante {
  JohvemAtividadeParticipante({required this.id, required this.idAtividade, required this.idPessoa, required this.codigoMembro, required this.nomePessoa, required this.presente, required this.jc});
  final int id;
  final int idAtividade;
  final int idPessoa;
  final String codigoMembro;
  final String nomePessoa;
  final bool presente;
  final String jc;

  Map<String, dynamic> toJson() => {
        'id': id,
        'idAtividade': idAtividade,
        'idPessoa': idPessoa,
        'codigoMembro': codigoMembro,
        'nomePessoa': nomePessoa,
        'presente': presente,
        'jc': jc,
      };

  factory JohvemAtividadeParticipante.fromJson(Map<String, dynamic> json) => JohvemAtividadeParticipante(
        id: json['id'] ?? 0,
        idAtividade: json['idAtividade'] ?? 0,
        idPessoa: json['idPessoa'] ?? 0,
        codigoMembro: (json['codigoMembro'] ?? '').toString(),
        nomePessoa: (json['nomePessoa'] ?? '').toString(),
        presente: json['presente'] != false,
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'id_atividade': idAtividade,
        'id_pessoa': idPessoa,
        'codigo_membro': codigoMembro,
        'nome_pessoa': nomePessoa,
        'presente': presente,
        'jc': jc,
      };

  factory JohvemAtividadeParticipante.fromSupabase(Map<String, dynamic> json) => JohvemAtividadeParticipante(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        idAtividade: json['id_atividade'] is num ? (json['id_atividade'] as num).toInt() : 0,
        idPessoa: json['id_pessoa'] is num ? (json['id_pessoa'] as num).toInt() : 0,
        codigoMembro: (json['codigo_membro'] ?? '').toString(),
        nomePessoa: (json['nome_pessoa'] ?? '').toString(),
        presente: json['presente'] != false,
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );
}

class JohvemAtividadeFoto {
  JohvemAtividadeFoto({required this.id, required this.idAtividade, required this.arquivo, required this.legenda, required this.jc});
  final int id;
  final int idAtividade;
  final String arquivo;
  final String legenda;
  final String jc;

  ComprovanteArquivo? get arquivoFoto => ComprovanteArquivo.fromStorageString(arquivo);

  JohvemAtividadeFoto copyWith({String? arquivo}) => JohvemAtividadeFoto(
        id: id,
        idAtividade: idAtividade,
        arquivo: arquivo ?? this.arquivo,
        legenda: legenda,
        jc: jc,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'idAtividade': idAtividade,
        'arquivo': arquivo,
        'legenda': legenda,
        'jc': jc,
      };

  factory JohvemAtividadeFoto.fromJson(Map<String, dynamic> json) => JohvemAtividadeFoto(
        id: json['id'] ?? 0,
        idAtividade: json['idAtividade'] ?? 0,
        arquivo: (json['arquivo'] ?? '').toString(),
        legenda: (json['legenda'] ?? '').toString(),
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );

  Map<String, dynamic> toSupabase() {
    final foto = arquivoFoto;
    return {
      'id': id,
      'id_atividade': idAtividade,
      'arquivo_path': foto?.path ?? '',
      'arquivo_nome': foto?.nome ?? '',
      'arquivo_tipo': foto == null ? '' : contentTypeForFile(foto.nome),
      'legenda': legenda,
      'jc': jc,
    };
  }

  factory JohvemAtividadeFoto.fromSupabase(Map<String, dynamic> json) {
    final path = (json['arquivo_path'] ?? '').toString();
    final nome = (json['arquivo_nome'] ?? '').toString();
    final arquivo = path.isEmpty
        ? ''
        : ComprovanteArquivo(
            nome: nome.isEmpty ? path.split('/').last : nome,
            extensao: extensaoArquivo(nome.isEmpty ? path : nome),
            tamanhoBytes: 0,
            base64: '',
            dataAnexo: DateTime.now(),
            path: path,
          ).toStorageString();
    return JohvemAtividadeFoto(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      idAtividade: json['id_atividade'] is num ? (json['id_atividade'] as num).toInt() : 0,
      arquivo: arquivo,
      legenda: (json['legenda'] ?? '').toString(),
      jc: (json['jc'] ?? kJcPadrao).toString(),
    );
  }
}


class EnsinoCurso {
  EnsinoCurso({required this.id, required this.nome, required this.categoria, required this.totalAulas, required this.ativo, required this.ordem, required this.jc});
  final int id;
  final String nome;
  final String categoria;
  final int totalAulas;
  final bool ativo;
  final int ordem;
  final String jc;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'categoria': categoria,
        'totalAulas': totalAulas,
        'ativo': ativo,
        'ordem': ordem,
        'jc': jc,
      };

  factory EnsinoCurso.fromJson(Map<String, dynamic> json) => EnsinoCurso(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        nome: (json['nome'] ?? '').toString(),
        categoria: (json['categoria'] ?? '').toString(),
        totalAulas: json['totalAulas'] is num ? (json['totalAulas'] as num).toInt() : 0,
        ativo: json['ativo'] is bool ? json['ativo'] as bool : true,
        ordem: json['ordem'] is num ? (json['ordem'] as num).toInt() : 0,
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'nome': nome,
        'categoria': categoria,
        'total_aulas': totalAulas,
        'ativo': ativo,
        'ordem': ordem,
        'jc': jc,
      };

  factory EnsinoCurso.fromSupabase(Map<String, dynamic> json) => EnsinoCurso(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        nome: (json['nome'] ?? '').toString(),
        categoria: (json['categoria'] ?? '').toString(),
        totalAulas: json['total_aulas'] is num ? (json['total_aulas'] as num).toInt() : 0,
        ativo: json['ativo'] is bool ? json['ativo'] as bool : true,
        ordem: json['ordem'] is num ? (json['ordem'] as num).toInt() : 0,
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );
}

class EnsinoTurma {
  EnsinoTurma({required this.id, required this.idCurso, required this.cursoNome, required this.nomeTurma, required this.anoSemestre, required this.responsavel, required this.status, required this.dataInicio, required this.jc});
  final int id;
  final int idCurso;
  final String cursoNome;
  final String nomeTurma;
  final String anoSemestre;
  final String responsavel;
  final String status;
  final DateTime? dataInicio;
  final String jc;

  Map<String, dynamic> toJson() => {
        'id': id,
        'idCurso': idCurso,
        'cursoNome': cursoNome,
        'nomeTurma': nomeTurma,
        'anoSemestre': anoSemestre,
        'responsavel': responsavel,
        'status': status,
        'dataInicio': dataInicio?.toIso8601String(),
        'jc': jc,
      };

  factory EnsinoTurma.fromJson(Map<String, dynamic> json) => EnsinoTurma(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        idCurso: json['idCurso'] is num ? (json['idCurso'] as num).toInt() : 0,
        cursoNome: (json['cursoNome'] ?? '').toString(),
        nomeTurma: (json['nomeTurma'] ?? '').toString(),
        anoSemestre: (json['anoSemestre'] ?? '').toString(),
        responsavel: (json['responsavel'] ?? '').toString(),
        status: (json['status'] ?? 'Em andamento').toString(),
        dataInicio: parseNullableDate(json['dataInicio']),
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'id_curso': idCurso,
        'curso_nome': cursoNome,
        'nome_turma': nomeTurma,
        'ano_semestre': anoSemestre,
        'responsavel': responsavel,
        'status': status,
        'data_inicio': dataInicio == null ? null : sqlDate(dataInicio!),
        'jc': jc,
      };

  factory EnsinoTurma.fromSupabase(Map<String, dynamic> json) => EnsinoTurma(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        idCurso: json['id_curso'] is num ? (json['id_curso'] as num).toInt() : 0,
        cursoNome: (json['curso_nome'] ?? '').toString(),
        nomeTurma: (json['nome_turma'] ?? '').toString(),
        anoSemestre: (json['ano_semestre'] ?? '').toString(),
        responsavel: (json['responsavel'] ?? '').toString(),
        status: (json['status'] ?? 'Em andamento').toString(),
        dataInicio: parseNullableDate(json['data_inicio']),
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );
}

class EnsinoTurmaAluno {
  EnsinoTurmaAluno({required this.id, required this.idTurma, required this.idPessoa, required this.codigoMembro, required this.nomePessoa, required this.status, required this.progressoAulas, required this.jc});
  final int id;
  final int idTurma;
  final int idPessoa;
  final String codigoMembro;
  final String nomePessoa;
  final String status;
  final int progressoAulas;
  final String jc;

  EnsinoTurmaAluno copyWith({int? progressoAulas, String? status}) => EnsinoTurmaAluno(
        id: id,
        idTurma: idTurma,
        idPessoa: idPessoa,
        codigoMembro: codigoMembro,
        nomePessoa: nomePessoa,
        status: status ?? this.status,
        progressoAulas: progressoAulas ?? this.progressoAulas,
        jc: jc,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'idTurma': idTurma,
        'idPessoa': idPessoa,
        'codigoMembro': codigoMembro,
        'nomePessoa': nomePessoa,
        'status': status,
        'progressoAulas': progressoAulas,
        'jc': jc,
      };

  factory EnsinoTurmaAluno.fromJson(Map<String, dynamic> json) => EnsinoTurmaAluno(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        idTurma: json['idTurma'] is num ? (json['idTurma'] as num).toInt() : 0,
        idPessoa: json['idPessoa'] is num ? (json['idPessoa'] as num).toInt() : 0,
        codigoMembro: (json['codigoMembro'] ?? '').toString(),
        nomePessoa: (json['nomePessoa'] ?? '').toString(),
        status: (json['status'] ?? 'Em andamento').toString(),
        progressoAulas: json['progressoAulas'] is num ? (json['progressoAulas'] as num).toInt() : 0,
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'id_turma': idTurma,
        'id_pessoa': idPessoa == 0 ? null : idPessoa,
        'codigo_membro': codigoMembro,
        'nome_pessoa': nomePessoa,
        'status': status,
        'progresso_aulas': progressoAulas,
        'jc': jc,
      };

  factory EnsinoTurmaAluno.fromSupabase(Map<String, dynamic> json) => EnsinoTurmaAluno(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        idTurma: json['id_turma'] is num ? (json['id_turma'] as num).toInt() : 0,
        idPessoa: json['id_pessoa'] is num ? (json['id_pessoa'] as num).toInt() : 0,
        codigoMembro: (json['codigo_membro'] ?? '').toString(),
        nomePessoa: (json['nome_pessoa'] ?? '').toString(),
        status: (json['status'] ?? 'Em andamento').toString(),
        progressoAulas: json['progresso_aulas'] is num ? (json['progresso_aulas'] as num).toInt() : 0,
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );
}

class EnsinoPresenca {
  EnsinoPresenca({required this.id, required this.idTurma, required this.idAluno, required this.idPessoa, required this.codigoMembro, required this.nomePessoa, required this.aulaNumero, required this.data, required this.presente, required this.observacao, required this.jc});
  final int id;
  final int idTurma;
  final int idAluno;
  final int idPessoa;
  final String codigoMembro;
  final String nomePessoa;
  final int aulaNumero;
  final DateTime data;
  final bool presente;
  final String observacao;
  final String jc;

  Map<String, dynamic> toJson() => {
        'id': id,
        'idTurma': idTurma,
        'idAluno': idAluno,
        'idPessoa': idPessoa,
        'codigoMembro': codigoMembro,
        'nomePessoa': nomePessoa,
        'aulaNumero': aulaNumero,
        'data': data.toIso8601String(),
        'presente': presente,
        'observacao': observacao,
        'jc': jc,
      };

  factory EnsinoPresenca.fromJson(Map<String, dynamic> json) => EnsinoPresenca(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        idTurma: json['idTurma'] is num ? (json['idTurma'] as num).toInt() : 0,
        idAluno: json['idAluno'] is num ? (json['idAluno'] as num).toInt() : 0,
        idPessoa: json['idPessoa'] is num ? (json['idPessoa'] as num).toInt() : 0,
        codigoMembro: (json['codigoMembro'] ?? '').toString(),
        nomePessoa: (json['nomePessoa'] ?? '').toString(),
        aulaNumero: json['aulaNumero'] is num ? (json['aulaNumero'] as num).toInt() : 1,
        data: parseDate(json['data']),
        presente: json['presente'] is bool ? json['presente'] as bool : false,
        observacao: (json['observacao'] ?? '').toString(),
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'id_turma': idTurma,
        'id_aluno': idAluno,
        'id_pessoa': idPessoa == 0 ? null : idPessoa,
        'codigo_membro': codigoMembro,
        'nome_pessoa': nomePessoa,
        'aula_numero': aulaNumero,
        'data': sqlDate(data),
        'presente': presente,
        'observacao': observacao,
        'jc': jc,
      };

  factory EnsinoPresenca.fromSupabase(Map<String, dynamic> json) => EnsinoPresenca(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        idTurma: json['id_turma'] is num ? (json['id_turma'] as num).toInt() : 0,
        idAluno: json['id_aluno'] is num ? (json['id_aluno'] as num).toInt() : 0,
        idPessoa: json['id_pessoa'] is num ? (json['id_pessoa'] as num).toInt() : 0,
        codigoMembro: (json['codigo_membro'] ?? '').toString(),
        nomePessoa: (json['nome_pessoa'] ?? '').toString(),
        aulaNumero: json['aula_numero'] is num ? (json['aula_numero'] as num).toInt() : 1,
        data: parseDate(json['data']),
        presente: json['presente'] is bool ? json['presente'] as bool : false,
        observacao: (json['observacao'] ?? '').toString(),
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );
}

class EnsinoPosOutorga {
  EnsinoPosOutorga({required this.id, required this.idPessoa, required this.codigoMembro, required this.nomePessoa, required this.dataOutorga, required this.status, required this.responsavel, required this.observacao, required this.jc});
  final int id;
  final int idPessoa;
  final String codigoMembro;
  final String nomePessoa;
  final DateTime? dataOutorga;
  final String status;
  final String responsavel;
  final String observacao;
  final String jc;

  static EnsinoPosOutorga vazio() => EnsinoPosOutorga(id: 0, idPessoa: 0, codigoMembro: '', nomePessoa: '', dataOutorga: null, status: '', responsavel: '', observacao: '', jc: kJcPadrao);

  EnsinoPosOutorga copyWith({String? status}) => EnsinoPosOutorga(
        id: id,
        idPessoa: idPessoa,
        codigoMembro: codigoMembro,
        nomePessoa: nomePessoa,
        dataOutorga: dataOutorga,
        status: status ?? this.status,
        responsavel: responsavel,
        observacao: observacao,
        jc: jc,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'idPessoa': idPessoa,
        'codigoMembro': codigoMembro,
        'nomePessoa': nomePessoa,
        'dataOutorga': dataOutorga?.toIso8601String(),
        'status': status,
        'responsavel': responsavel,
        'observacao': observacao,
        'jc': jc,
      };

  factory EnsinoPosOutorga.fromJson(Map<String, dynamic> json) => EnsinoPosOutorga(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        idPessoa: json['idPessoa'] is num ? (json['idPessoa'] as num).toInt() : 0,
        codigoMembro: (json['codigoMembro'] ?? '').toString(),
        nomePessoa: (json['nomePessoa'] ?? '').toString(),
        dataOutorga: parseNullableDate(json['dataOutorga']),
        status: (json['status'] ?? 'Pendente').toString(),
        responsavel: (json['responsavel'] ?? '').toString(),
        observacao: (json['observacao'] ?? '').toString(),
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'id_pessoa': idPessoa == 0 ? null : idPessoa,
        'codigo_membro': codigoMembro,
        'nome_pessoa': nomePessoa,
        'data_outorga': dataOutorga == null ? null : sqlDate(dataOutorga!),
        'status': status,
        'responsavel': responsavel,
        'observacao': observacao,
        'jc': jc,
      };

  factory EnsinoPosOutorga.fromSupabase(Map<String, dynamic> json) => EnsinoPosOutorga(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        idPessoa: json['id_pessoa'] is num ? (json['id_pessoa'] as num).toInt() : 0,
        codigoMembro: (json['codigo_membro'] ?? '').toString(),
        nomePessoa: (json['nome_pessoa'] ?? '').toString(),
        dataOutorga: parseNullableDate(json['data_outorga']),
        status: (json['status'] ?? 'Pendente').toString(),
        responsavel: (json['responsavel'] ?? '').toString(),
        observacao: (json['observacao'] ?? '').toString(),
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );
}

class EnsinoPosOutorgaEncontro {
  EnsinoPosOutorgaEncontro({required this.id, required this.idPosOutorga, required this.idPessoa, required this.codigoMembro, required this.nomePessoa, required this.numeroEncontro, required this.data, required this.tema, required this.responsavel, required this.observacao, required this.jc});
  final int id;
  final int idPosOutorga;
  final int idPessoa;
  final String codigoMembro;
  final String nomePessoa;
  final int numeroEncontro;
  final DateTime data;
  final String tema;
  final String responsavel;
  final String observacao;
  final String jc;

  Map<String, dynamic> toJson() => {
        'id': id,
        'idPosOutorga': idPosOutorga,
        'idPessoa': idPessoa,
        'codigoMembro': codigoMembro,
        'nomePessoa': nomePessoa,
        'numeroEncontro': numeroEncontro,
        'data': data.toIso8601String(),
        'tema': tema,
        'responsavel': responsavel,
        'observacao': observacao,
        'jc': jc,
      };

  factory EnsinoPosOutorgaEncontro.fromJson(Map<String, dynamic> json) => EnsinoPosOutorgaEncontro(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        idPosOutorga: json['idPosOutorga'] is num ? (json['idPosOutorga'] as num).toInt() : 0,
        idPessoa: json['idPessoa'] is num ? (json['idPessoa'] as num).toInt() : 0,
        codigoMembro: (json['codigoMembro'] ?? '').toString(),
        nomePessoa: (json['nomePessoa'] ?? '').toString(),
        numeroEncontro: json['numeroEncontro'] is num ? (json['numeroEncontro'] as num).toInt() : 1,
        data: parseDate(json['data']),
        tema: (json['tema'] ?? '').toString(),
        responsavel: (json['responsavel'] ?? '').toString(),
        observacao: (json['observacao'] ?? '').toString(),
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'id_pos_outorga': idPosOutorga,
        'id_pessoa': idPessoa == 0 ? null : idPessoa,
        'codigo_membro': codigoMembro,
        'nome_pessoa': nomePessoa,
        'numero_encontro': numeroEncontro,
        'data': sqlDate(data),
        'tema': tema,
        'responsavel': responsavel,
        'observacao': observacao,
        'jc': jc,
      };

  factory EnsinoPosOutorgaEncontro.fromSupabase(Map<String, dynamic> json) => EnsinoPosOutorgaEncontro(
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        idPosOutorga: json['id_pos_outorga'] is num ? (json['id_pos_outorga'] as num).toInt() : 0,
        idPessoa: json['id_pessoa'] is num ? (json['id_pessoa'] as num).toInt() : 0,
        codigoMembro: (json['codigo_membro'] ?? '').toString(),
        nomePessoa: (json['nome_pessoa'] ?? '').toString(),
        numeroEncontro: json['numero_encontro'] is num ? (json['numero_encontro'] as num).toInt() : 1,
        data: parseDate(json['data']),
        tema: (json['tema'] ?? '').toString(),
        responsavel: (json['responsavel'] ?? '').toString(),
        observacao: (json['observacao'] ?? '').toString(),
        jc: (json['jc'] ?? kJcPadrao).toString(),
      );
}

class Pessoa {
  Pessoa({
    required this.idPessoa,
    required this.nome,
    required this.tipoPessoaAtual,
    required this.primeiraPresenca,
    required this.ultimaPresenca,
    required this.qtdPresencas,
    required this.jc,
    this.foto = '',
    this.codigoMembro = '',
    this.sexo = '',
    this.dataNascimento,
    this.tipoOutorga = '',
    this.dataOutorga,
    this.situacaoMembro = '',
    this.possuiSs = '',
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
    this.telefoneResidencial = '',
    this.telefoneCelular = '',
  });

  final int idPessoa;
  final String nome;
  final String tipoPessoaAtual;
  final DateTime primeiraPresenca;
  final DateTime ultimaPresenca;
  final int qtdPresencas;
  final String jc;
  final String foto;
  final String codigoMembro;
  final String sexo;
  final DateTime? dataNascimento;
  final String tipoOutorga;
  final DateTime? dataOutorga;
  final String situacaoMembro;
  final String possuiSs;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final String telefoneResidencial;
  final String telefoneCelular;

  ComprovanteArquivo? get fotoArquivo => ComprovanteArquivo.fromStorageString(foto);

  String get situacaoMembroLabel {
    if (situacaoMembro == 'ATI') return 'Ativo';
    if (situacaoMembro == 'AFA') return 'Afastado';
    return '';
  }

  String get descricaoPrincipal {
    final partes = <String>[tipoPessoaAtual];
    if (codigoMembro.trim().isNotEmpty) partes.add('Cód. $codigoMembro');
    if (tipoOutorga.trim().isNotEmpty) partes.add(tipoOutorga);
    if (situacaoMembroLabel.isNotEmpty) partes.add(situacaoMembroLabel);
    if (dataNascimento != null) partes.add('Nasc. ${brDate.format(dataNascimento!)}');
    return partes.where((e) => e.trim().isNotEmpty).join(' • ');
  }

  String get descricaoContatoEndereco {
    final partes = <String>[];
    if (telefoneCelular.trim().isNotEmpty) partes.add(telefoneCelular);
    if (bairro.trim().isNotEmpty) partes.add(bairro);
    if (cidade.trim().isNotEmpty) partes.add(cidade);
    return partes.join(' • ');
  }

  Pessoa copyWith({
    String? nome,
    String? tipoPessoaAtual,
    DateTime? primeiraPresenca,
    DateTime? ultimaPresenca,
    int? qtdPresencas,
    String? jc,
    String? foto,
    String? codigoMembro,
    String? sexo,
    DateTime? dataNascimento,
    String? tipoOutorga,
    DateTime? dataOutorga,
    String? situacaoMembro,
    String? possuiSs,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? estado,
    String? telefoneResidencial,
    String? telefoneCelular,
  }) {
    return Pessoa(
      idPessoa: idPessoa,
      nome: nome ?? this.nome,
      tipoPessoaAtual: tipoPessoaAtual ?? this.tipoPessoaAtual,
      primeiraPresenca: primeiraPresenca ?? this.primeiraPresenca,
      ultimaPresenca: ultimaPresenca ?? this.ultimaPresenca,
      qtdPresencas: qtdPresencas ?? this.qtdPresencas,
      jc: jc ?? this.jc,
      foto: foto ?? this.foto,
      codigoMembro: codigoMembro ?? this.codigoMembro,
      sexo: sexo ?? this.sexo,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      tipoOutorga: tipoOutorga ?? this.tipoOutorga,
      dataOutorga: dataOutorga ?? this.dataOutorga,
      situacaoMembro: situacaoMembro ?? this.situacaoMembro,
      possuiSs: possuiSs ?? this.possuiSs,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      telefoneResidencial: telefoneResidencial ?? this.telefoneResidencial,
      telefoneCelular: telefoneCelular ?? this.telefoneCelular,
    );
  }

  Map<String, dynamic> toJson() => {
        'idPessoa': idPessoa,
        'nome': nome,
        'tipoPessoaAtual': tipoPessoaAtual,
        'primeiraPresenca': primeiraPresenca.toIso8601String(),
        'ultimaPresenca': ultimaPresenca.toIso8601String(),
        'qtdPresencas': qtdPresencas,
        'jc': jc,
        'foto': foto,
        'codigoMembro': codigoMembro,
        'sexo': sexo,
        'dataNascimento': dataNascimento?.toIso8601String(),
        'tipoOutorga': tipoOutorga,
        'dataOutorga': dataOutorga?.toIso8601String(),
        'situacaoMembro': situacaoMembro,
        'possuiSs': possuiSs,
        'logradouro': logradouro,
        'numero': numero,
        'complemento': complemento,
        'bairro': bairro,
        'cidade': cidade,
        'estado': estado,
        'telefoneResidencial': telefoneResidencial,
        'telefoneCelular': telefoneCelular,
      };

  factory Pessoa.fromJson(Map<String, dynamic> json) => Pessoa(
        idPessoa: json['idPessoa'] ?? 0,
        nome: json['nome'] ?? '',
        tipoPessoaAtual: json['tipoPessoaAtual'] ?? '',
        primeiraPresenca: parseDate(json['primeiraPresenca']),
        ultimaPresenca: parseDate(json['ultimaPresenca']),
        qtdPresencas: json['qtdPresencas'] ?? 0,
        jc: json['jc'] ?? kJcPadrao,
        foto: json['foto'] ?? '',
        codigoMembro: (json['codigoMembro'] ?? '').toString(),
        sexo: (json['sexo'] ?? '').toString(),
        dataNascimento: parseNullableDate(json['dataNascimento']),
        tipoOutorga: (json['tipoOutorga'] ?? '').toString(),
        dataOutorga: parseNullableDate(json['dataOutorga']),
        situacaoMembro: (json['situacaoMembro'] ?? '').toString(),
        possuiSs: (json['possuiSs'] ?? '').toString(),
        logradouro: (json['logradouro'] ?? '').toString(),
        numero: (json['numero'] ?? '').toString(),
        complemento: (json['complemento'] ?? '').toString(),
        bairro: (json['bairro'] ?? '').toString(),
        cidade: (json['cidade'] ?? '').toString(),
        estado: (json['estado'] ?? '').toString(),
        telefoneResidencial: (json['telefoneResidencial'] ?? '').toString(),
        telefoneCelular: (json['telefoneCelular'] ?? '').toString(),
      );

  Map<String, dynamic> toSupabase() {
    final arquivo = fotoArquivo;
    return {
      'id_pessoa': idPessoa,
      'nome': nome,
      'tipo_pessoa_atual': tipoPessoaAtual,
      'primeira_presenca': sqlDate(primeiraPresenca),
      'ultima_presenca': sqlDate(ultimaPresenca),
      'qtd_presencas': qtdPresencas,
      'jc': jc,
      'foto_path': arquivo?.path ?? '',
      'foto_nome': arquivo?.nome ?? '',
      'foto_tipo': arquivo == null ? '' : contentTypeForFile(arquivo.nome),
      'codigo_membro': codigoMembro,
      'sexo': sexo,
      'data_nascimento': dataNascimento == null ? null : sqlDate(dataNascimento!),
      'tipo_outorga': tipoOutorga,
      'data_outorga': dataOutorga == null ? null : sqlDate(dataOutorga!),
      'situacao_membro': situacaoMembro,
      'possui_ss': possuiSs,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'telefone_residencial': telefoneResidencial,
      'telefone_celular': telefoneCelular,
    };
  }

  factory Pessoa.fromSupabase(Map<String, dynamic> json) {
    final fotoPath = (json['foto_path'] ?? '').toString();
    final fotoNome = (json['foto_nome'] ?? '').toString();
    final foto = fotoPath.isEmpty
        ? ''
        : ComprovanteArquivo(
            nome: fotoNome.isEmpty ? fotoPath.split('/').last : fotoNome,
            extensao: extensaoArquivo(fotoNome.isEmpty ? fotoPath : fotoNome),
            tamanhoBytes: 0,
            base64: '',
            dataAnexo: DateTime.now(),
            path: fotoPath,
          ).toStorageString();

    return Pessoa(
      idPessoa: json['id_pessoa'] is num ? (json['id_pessoa'] as num).toInt() : 0,
      nome: (json['nome'] ?? '').toString(),
      tipoPessoaAtual: (json['tipo_pessoa_atual'] ?? '').toString(),
      primeiraPresenca: parseDate(json['primeira_presenca']),
      ultimaPresenca: parseDate(json['ultima_presenca']),
      qtdPresencas: json['qtd_presencas'] is num ? (json['qtd_presencas'] as num).toInt() : 0,
      jc: (json['jc'] ?? kJcPadrao).toString(),
      foto: foto,
      codigoMembro: (json['codigo_membro'] ?? '').toString(),
      sexo: (json['sexo'] ?? '').toString(),
      dataNascimento: parseNullableDate(json['data_nascimento']),
      tipoOutorga: (json['tipo_outorga'] ?? '').toString(),
      dataOutorga: parseNullableDate(json['data_outorga']),
      situacaoMembro: (json['situacao_membro'] ?? '').toString(),
      possuiSs: (json['possui_ss'] ?? '').toString(),
      logradouro: (json['logradouro'] ?? '').toString(),
      numero: (json['numero'] ?? '').toString(),
      complemento: (json['complemento'] ?? '').toString(),
      bairro: (json['bairro'] ?? '').toString(),
      cidade: (json['cidade'] ?? '').toString(),
      estado: (json['estado'] ?? '').toString(),
      telefoneResidencial: (json['telefone_residencial'] ?? '').toString(),
      telefoneCelular: (json['telefone_celular'] ?? '').toString(),
    );
  }
}

class ComprovanteArquivo {
  ComprovanteArquivo({required this.nome, required this.extensao, required this.tamanhoBytes, required this.base64, required this.dataAnexo, this.path = ''});
  final String nome;
  final String extensao;
  final int tamanhoBytes;
  final String base64;
  final DateTime dataAnexo;
  final String path;

  String get tamanhoFormatado {
    if (tamanhoBytes <= 0) return 'tamanho não informado';
    if (tamanhoBytes < 1024) return '$tamanhoBytes B';
    if (tamanhoBytes < 1024 * 1024) return '${(tamanhoBytes / 1024).toStringAsFixed(1)} KB';
    return '${(tamanhoBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  ComprovanteArquivo copyWith({String? nome, String? extensao, int? tamanhoBytes, String? base64, DateTime? dataAnexo, String? path}) {
    return ComprovanteArquivo(
      nome: nome ?? this.nome,
      extensao: extensao ?? this.extensao,
      tamanhoBytes: tamanhoBytes ?? this.tamanhoBytes,
      base64: base64 ?? this.base64,
      dataAnexo: dataAnexo ?? this.dataAnexo,
      path: path ?? this.path,
    );
  }

  String toStorageString() => jsonEncode({
        'versao': 1,
        'nome': nome,
        'extensao': extensao,
        'tamanhoBytes': tamanhoBytes,
        'base64': base64,
        'path': path,
        'dataAnexo': dataAnexo.toIso8601String(),
      });

  static ComprovanteArquivo? fromStorageString(String raw) {
    final texto = raw.trim();
    if (texto.isEmpty) return null;

    try {
      final decoded = jsonDecode(texto);
      if (decoded is Map<String, dynamic>) {
        return ComprovanteArquivo(
          nome: (decoded['nome'] ?? 'Comprovante').toString(),
          extensao: (decoded['extensao'] ?? '').toString(),
          tamanhoBytes: decoded['tamanhoBytes'] is num ? (decoded['tamanhoBytes'] as num).toInt() : 0,
          base64: (decoded['base64'] ?? '').toString(),
          dataAnexo: parseDate(decoded['dataAnexo']),
          path: (decoded['path'] ?? decoded['comprovante_path'] ?? '').toString(),
        );
      }
    } catch (_) {
      return ComprovanteArquivo(
        nome: texto,
        extensao: '',
        tamanhoBytes: 0,
        base64: '',
        dataAnexo: DateTime.now(),
        path: '',
      );
    }

    return null;
  }
}

class Donativo {
  Donativo({required this.id, required this.data, required this.nome, required this.jc, required this.tipoPessoa, required this.tipoDonativo, required this.tipoDonativoManual, required this.origem, required this.subtipo, required this.banco, required this.valor, required this.comprovante, required this.tipoOrigemNome, required this.idReferencia, required this.depositoStatus, this.depositoLancadoEm});
  final int id;
  final DateTime data;
  final String nome;
  final String jc;
  final String tipoPessoa;
  final String tipoDonativo;
  final String tipoDonativoManual;
  final String origem;
  final String subtipo;
  final String banco;
  final double valor;
  final String comprovante;
  final String tipoOrigemNome;
  final String idReferencia;
  final String depositoStatus;
  final DateTime? depositoLancadoEm;

  bool get depositoLancado => depositoStatus == 'Lançado';
  bool get ehOnline => origem == 'Online';
  bool get ehOnlineIdentificado => ehOnline && subtipo == kSubtipoOnlineIdentificado;
  bool get ehOnlineOficial => ehOnline && !ehOnlineIdentificado;

  Donativo copyWith({String? banco, String? depositoStatus, DateTime? depositoLancadoEm, bool limparDepositoLancadoEm = false}) {
    return Donativo(
      id: id,
      data: data,
      nome: nome,
      jc: jc,
      tipoPessoa: tipoPessoa,
      tipoDonativo: tipoDonativo,
      tipoDonativoManual: tipoDonativoManual,
      origem: origem,
      subtipo: subtipo,
      banco: banco ?? this.banco,
      valor: valor,
      comprovante: comprovante,
      tipoOrigemNome: tipoOrigemNome,
      idReferencia: idReferencia,
      depositoStatus: depositoStatus ?? this.depositoStatus,
      depositoLancadoEm: limparDepositoLancadoEm ? null : (depositoLancadoEm ?? this.depositoLancadoEm),
    );
  }

  String get tipoDonativoExibicao => tipoDonativo == 'Outro' && tipoDonativoManual.trim().isNotEmpty ? tipoDonativoManual.trim() : tipoDonativo;
  String get tipoOrigemNomeExibicao => tipoOrigemNome == 'Referencia' ? 'Referência' : 'Pessoa';
  ComprovanteArquivo? get comprovanteArquivo => ComprovanteArquivo.fromStorageString(comprovante);
  bool get temComprovante => comprovanteArquivo != null;
  String get nomeComprovante => comprovanteArquivo?.nome ?? 'Comprovante anexado';

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
        'banco': banco,
        'valor': valor,
        'comprovante': comprovante,
        'tipoOrigemNome': tipoOrigemNome,
        'idReferencia': idReferencia,
        'depositoStatus': depositoStatus,
        'depositoLancadoEm': depositoLancadoEm?.toIso8601String(),
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
        banco: json['banco'] ?? '',
        valor: json['valor'] is num ? (json['valor'] as num).toDouble() : parseValor((json['valor'] ?? 0).toString()),
        comprovante: json['comprovante'] ?? '',
        tipoOrigemNome: json['tipoOrigemNome'] ?? '',
        idReferencia: json['idReferencia'] ?? '',
        depositoStatus: json['depositoStatus'] ?? 'Pendente',
        depositoLancadoEm: parseNullableDate(json['depositoLancadoEm']),
      );

  Map<String, dynamic> toSupabase() {
    final arquivo = comprovanteArquivo;
    return {
      'id': id,
      'data': sqlDate(data),
      'nome': nome,
      'jc': jc,
      'tipo_pessoa': tipoPessoa,
      'tipo_donativo': tipoDonativo,
      'tipo_donativo_manual': tipoDonativoManual,
      'origem': origem,
      'subtipo': subtipo,
      'banco': banco,
      'valor': valor,
      'comprovante_path': arquivo?.path ?? '',
      'comprovante_nome': arquivo?.nome ?? '',
      'comprovante_tipo': arquivo?.extensao ?? '',
      'tipo_origem_nome': tipoOrigemNome,
      'id_referencia': idReferencia,
      'deposito_status': depositoStatus,
      'deposito_lancado_em': depositoLancadoEm?.toIso8601String(),
    };
  }

  factory Donativo.fromSupabase(Map<String, dynamic> json) {
    final path = (json['comprovante_path'] ?? '').toString();
    final nomeComprovante = (json['comprovante_nome'] ?? '').toString();
    final tipoComprovante = (json['comprovante_tipo'] ?? '').toString();
    final comprovanteJson = path.isEmpty
        ? ''
        : ComprovanteArquivo(
            nome: nomeComprovante.isEmpty ? 'Comprovante' : nomeComprovante,
            extensao: tipoComprovante,
            tamanhoBytes: 0,
            base64: '',
            dataAnexo: DateTime.now(),
            path: path,
          ).toStorageString();

    return Donativo(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      data: parseDate(json['data']),
      nome: (json['nome'] ?? '').toString(),
      jc: (json['jc'] ?? kJcPadrao).toString(),
      tipoPessoa: (json['tipo_pessoa'] ?? '').toString(),
      tipoDonativo: (json['tipo_donativo'] ?? '').toString(),
      tipoDonativoManual: (json['tipo_donativo_manual'] ?? '').toString(),
      origem: (json['origem'] ?? '').toString(),
      subtipo: (json['subtipo'] ?? '').toString(),
      banco: (json['banco'] ?? '').toString(),
      valor: json['valor'] is num ? (json['valor'] as num).toDouble() : parseValor((json['valor'] ?? 0).toString()),
      comprovante: comprovanteJson,
      tipoOrigemNome: (json['tipo_origem_nome'] ?? '').toString(),
      idReferencia: (json['id_referencia'] ?? '').toString(),
      depositoStatus: (json['deposito_status'] ?? 'Pendente').toString(),
      depositoLancadoEm: parseNullableDate(json['deposito_lancado_em']),
    );
  }
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

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'data': sqlDate(data),
        'nome': nome,
        'tipo_pessoa': tipoPessoaAtual.isNotEmpty ? tipoPessoaAtual : tipoPessoaInformado,
        'tipo_evento': tipoEvento,
        'observacao': observacao,
        'jc': jc,
      };

  factory Frequencia.fromSupabase(Map<String, dynamic> json) {
    final tipoPessoa = (json['tipo_pessoa'] ?? '').toString();
    return Frequencia(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      data: parseDate(json['data']),
      tipoEvento: (json['tipo_evento'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      tipoPessoaInformado: tipoPessoa,
      tipoPessoaAtual: tipoPessoa,
      jc: (json['jc'] ?? kJcPadrao).toString(),
      observacao: (json['observacao'] ?? '').toString(),
      dataLancamento: DateTime.now(),
      horaLancamento: '',
    );
  }
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

  List<String> get tags => tema
      .split('|')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  ComprovanteArquivo? get arquivoExperiencia => ComprovanteArquivo.fromStorageString(arquivo);
  bool get temArquivo => arquivoExperiencia != null;

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
        id: json['id'] is num ? (json['id'] as num).toInt() : 0,
        dataRegistro: parseDate(json['dataRegistro']),
        dataExperiencia: parseDate(json['dataExperiencia']),
        idPessoa: json['idPessoa'] is num ? (json['idPessoa'] as num).toInt() : 0,
        nome: (json['nome'] ?? '').toString(),
        tipoPessoa: (json['tipoPessoa'] ?? '').toString(),
        jc: (json['jc'] ?? kJcPadrao).toString(),
        titulo: (json['titulo'] ?? '').toString(),
        resumo: (json['resumo'] ?? '').toString(),
        categoria: (json['categoria'] ?? '').toString(),
        tema: (json['tema'] ?? '').toString(),
        status: (json['status'] ?? 'Em produção').toString(),
        responsavelRegistro: (json['responsavelRegistro'] ?? '').toString(),
        observacao: (json['observacao'] ?? '').toString(),
        arquivo: (json['arquivo'] ?? '').toString(),
        foiEnviada: json['foiEnviada'] is bool ? json['foiEnviada'] as bool : false,
        aprovada: json['aprovada'] is bool ? json['aprovada'] as bool : false,
        foiApresentada: json['foiApresentada'] is bool ? json['foiApresentada'] as bool : false,
      );

  Map<String, dynamic> toSupabase() {
    final arquivoAtual = arquivoExperiencia;
    return {
      'id': id,
      'data_registro': dataRegistro.toIso8601String(),
      'data_experiencia': sqlDate(dataExperiencia),
      'id_pessoa': idPessoa == 0 ? null : idPessoa,
      'nome': nome,
      'tipo_pessoa': tipoPessoa,
      'jc': jc,
      'titulo': titulo,
      'resumo': resumo,
      'tags': tema,
      'status': status,
      'observacao': observacao,
      'arquivo_path': arquivoAtual?.path ?? '',
      'arquivo_nome': arquivoAtual?.nome ?? '',
      'arquivo_tipo': arquivoAtual?.extensao ?? '',
      'foi_enviada': foiEnviada,
      'aprovada': aprovada,
      'foi_apresentada': foiApresentada,
    };
  }

  factory ExperienciaFe.fromSupabase(Map<String, dynamic> json) {
    final path = (json['arquivo_path'] ?? '').toString();
    final nomeArquivo = (json['arquivo_nome'] ?? '').toString();
    final tipoArquivo = (json['arquivo_tipo'] ?? '').toString();
    final arquivoJson = path.isEmpty
        ? ''
        : ComprovanteArquivo(
            nome: nomeArquivo.isEmpty ? 'Arquivo da experiência' : nomeArquivo,
            extensao: tipoArquivo,
            tamanhoBytes: 0,
            base64: '',
            dataAnexo: DateTime.now(),
            path: path,
          ).toStorageString();

    return ExperienciaFe(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      dataRegistro: parseDate(json['data_registro']),
      dataExperiencia: parseDate(json['data_experiencia']),
      idPessoa: json['id_pessoa'] is num ? (json['id_pessoa'] as num).toInt() : 0,
      nome: (json['nome'] ?? '').toString(),
      tipoPessoa: (json['tipo_pessoa'] ?? '').toString(),
      jc: (json['jc'] ?? kJcPadrao).toString(),
      titulo: (json['titulo'] ?? '').toString(),
      resumo: (json['resumo'] ?? '').toString(),
      categoria: '',
      tema: (json['tags'] ?? '').toString(),
      status: (json['status'] ?? 'Em produção').toString(),
      responsavelRegistro: '',
      observacao: (json['observacao'] ?? '').toString(),
      arquivo: arquivoJson,
      foiEnviada: json['foi_enviada'] is bool ? json['foi_enviada'] as bool : false,
      aprovada: json['aprovada'] is bool ? json['aprovada'] as bool : false,
      foiApresentada: json['foi_apresentada'] is bool ? json['foi_apresentada'] as bool : false,
    );
  }
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

  Map<String, dynamic> toSupabase() => {
        'id_referencia': idReferencia,
        'nome_referencia': nomeReferencia,
        'tipo_referencia': tipoReferencia,
        'ativo': ativo,
      };

  factory ReferenciaNome.fromSupabase(Map<String, dynamic> json) => ReferenciaNome(
        idReferencia: (json['id_referencia'] ?? '').toString(),
        nomeReferencia: (json['nome_referencia'] ?? '').toString(),
        tipoReferencia: (json['tipo_referencia'] ?? '').toString(),
        idPessoaVinculada: 0,
        nomePessoaVinculada: '',
        jc: kJcPadrao,
        observacao: '',
        ativo: json['ativo'] is bool ? json['ativo'] as bool : true,
        dataCadastro: DateTime.now(),
        horaCadastro: '',
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

DateTime? parseNullableDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw) ?? tryParseBrDate(raw);
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

String sqlDate(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

String codigoMembroFromRotulo(String raw) {
  final match = RegExp(r'Cód\.\s*([0-9]+)').firstMatch(raw);
  return match?.group(1) ?? '';
}

String nomeLimpoDeRotuloPessoa(String raw) {
  final marker = raw.indexOf(' • Cód.');
  if (marker >= 0) return raw.substring(0, marker).trim();
  return raw.trim();
}


DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

double parseValor(String raw) {
  final clean = raw.trim().replaceAll('R\$', '').replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(clean) ?? 0;
}

String formatValorInput(double value) => brMoneyInput.format(value).trim();

String extensaoArquivo(String nomeArquivo, {String fallback = ''}) {
  final partes = nomeArquivo.split('.');
  if (partes.length < 2) return fallback;
  final ext = partes.last.trim().toLowerCase();
  return ext.isEmpty ? fallback : ext;
}

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
String sanitizeFileName(String raw) {
  final safe = raw.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  return safe.isEmpty ? 'comprovante' : safe;
}

String contentTypeForFile(String name) {
  final lower = name.toLowerCase().trim();
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.doc')) return 'application/msword';
  if (lower.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic')) return 'image/heic';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return 'application/octet-stream';
}

String limparMensagemErro(Object error) {
  final texto = error.toString();
  return texto.replaceFirst('Exception: ', '').replaceFirst('AuthException(message: ', '').replaceAll(')', '').trim();
}


List<String> subtiposPorOrigem(String origem) {
  switch (origem) {
    case 'Transferência':
      return const ['PIX', 'TED', 'Depósito', 'Boleto'];
    case 'Online':
      return const [kSubtipoOnlineOficial, kSubtipoOnlineIdentificado];
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


class PessoaAvatar extends StatelessWidget {
  const PessoaAvatar({super.key, required this.store, this.pessoa, this.radius = 22, this.fallbackText = ''});
  final AppStore store;
  final Pessoa? pessoa;
  final double radius;
  final String fallbackText;

  String get iniciais {
    final base = (pessoa?.nome.trim().isNotEmpty ?? false) ? pessoa!.nome.trim() : fallbackText.trim();
    if (base.isEmpty) return '?';
    final partes = base.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (partes.length == 1) return partes.first.characters.first.toUpperCase();
    return '${partes.first.characters.first}${partes.last.characters.first}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final foto = pessoa?.fotoArquivo;
    Widget fallback() => CircleAvatar(
          radius: radius,
          backgroundColor: kSoftGreen,
          child: Text(iniciais, style: const TextStyle(color: kAccent, fontWeight: FontWeight.w900)),
        );

    if (foto == null) return fallback();
    if (foto.base64.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: MemoryImage(base64Decode(foto.base64)));
    }
    if (foto.path.isEmpty) return fallback();

    return FutureBuilder<String?>(
      future: store.criarLinkTemporarioPessoaFoto(pessoa),
      builder: (context, snapshot) {
        final link = snapshot.data;
        if (link == null || link.isEmpty) return fallback();
        return CircleAvatar(radius: radius, backgroundImage: NetworkImage(link));
      },
    );
  }
}

class ComprovantePickerCard extends StatelessWidget {
  const ComprovantePickerCard({
    super.key,
    required this.comprovante,
    this.onTakePhoto,
    this.onPickImage,
    required this.onPickFile,
    required this.onRemove,
    this.titulo = 'Comprovante da transferência',
    this.descricao = 'Anexe imagem, PDF ou tire foto do comprovante. No iPhone, você também pode salvar o comprovante do WhatsApp em Fotos/Arquivos e selecionar por aqui.',
    this.fileButtonLabel = 'Arquivos / PDF',
  });
  final ComprovanteArquivo? comprovante;
  final VoidCallback? onTakePhoto;
  final VoidCallback? onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback? onRemove;
  final String titulo;
  final String descricao;
  final String fileButtonLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSoftGreen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: kAccent),
                const SizedBox(width: 8),
                Expanded(child: Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
              ],
            ),
            const SizedBox(height: 8),
            Text(descricao),
            const SizedBox(height: 12),
            if (comprovante == null)
              const Text('Nenhum comprovante anexado.', style: TextStyle(color: Colors.black54))
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDADFD8)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: kSoftGreen, child: Icon(Icons.description_outlined, color: kAccent)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(comprovante!.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(comprovante!.tamanhoFormatado, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: onRemove, icon: const Icon(Icons.close), tooltip: 'Remover comprovante'),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onTakePhoto != null)
                  FilledButton.icon(onPressed: onTakePhoto, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Tirar foto')),
                if (onPickImage != null)
                  OutlinedButton.icon(onPressed: onPickImage, icon: const Icon(Icons.photo_library_outlined), label: const Text('Galeria')),
                OutlinedButton.icon(onPressed: onPickFile, icon: const Icon(Icons.folder_open_outlined), label: Text(fileButtonLabel)),
              ],
            ),
          ],
        ),
      ),
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
  const KpiCard({super.key, required this.title, required this.value, required this.icon, this.subtitle, this.onTap});
  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
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
                  if (subtitle != null) Text(subtitle!, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                ],
              ),
            ],
          ),
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
