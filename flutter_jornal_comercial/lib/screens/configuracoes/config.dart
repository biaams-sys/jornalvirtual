
import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../models/noticia.dart';
import '../../services/auth_service.dart';
import '../../services/historico_noticias_service.dart';
import '../auth/login_screen.dart';
import '../noticia/noticia_detalhes_screen.dart';
import '../../services/notificacao_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final AuthService _authService = AuthService();
  final HistoricoNoticiasService _historicoService =
      HistoricoNoticiasService();

  bool _notificacoesAtivas = false;
  String? _email;
  List<Noticia> _historico = [];
  bool _carregando = true;

  ColorScheme get _cores => Theme.of(context).colorScheme;
  Color get _fundo => Theme.of(context).scaffoldBackgroundColor;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _carregarPreferenciaNotificacoes();
  }

  Future<void> _carregarPreferenciaNotificacoes() async {
    final ativo = await NotificacaoService.notificacoesEstaoAtivas();

    if (!mounted) return;

    setState(() {
      _notificacoesAtivas = ativo;
    });
  }

  Future<void> _carregarDados() async {
    final email = await _authService.getEmail();
    final historico = await _historicoService.listar();

    if (!mounted) return;

    setState(() {
      _email = email;
      _historico = historico;
      _carregando = false;
    });
  }

  Future<void> _sair() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  String? _getImagem(Noticia noticia) {
    if (noticia.midias.isEmpty) {
      return null;
    }

    final primeiraMidia = noticia.midias.first;

    if (primeiraMidia is! Map) {
      return null;
    }

    final path = primeiraMidia['path'];

    if (path == null || path.toString().isEmpty) {
      return null;
    }

    final caminho = path.toString();

    if (caminho.startsWith('http://') ||
        caminho.startsWith('https://')) {
      return caminho;
    }

    final caminhoLimpo = caminho.startsWith('/')
        ? caminho.substring(1)
        : caminho;

    return '${ApiConstants.baseUrl}/$caminhoLimpo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _carregando
                  ? Center(
                      child: CircularProgressIndicator(
                        color: _cores.primary,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        28,
                        20,
                        36,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Minha conta'),
                          const SizedBox(height: 16),
                          _buildConta(),
                          const SizedBox(height: 30),
                          _buildSectionTitle('Preferências'),
                          const SizedBox(height: 16),
                          _buildPreferencias(),
                          const SizedBox(height: 34),
                          _buildSectionTitle('Histórico'),
                          const SizedBox(height: 5),
                          Text(
                            'Últimas notícias que você visualizou',
                            style: TextStyle(
                              color: _cores.secondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildHistorico(),
                          const SizedBox(height: 36),
                          _buildBotaoSair(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 58,
      width: double.infinity,
      color: _cores.primary,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            padding: const EdgeInsets.only(left: 15),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: _cores.onPrimary,
              size: 27,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Configurações',
            style: TextStyle(
              color: _cores.onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String titulo) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _cores.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          titulo,
          style: TextStyle(
            color: _cores.onSurface,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildConta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _cores.surface,
        border: Border.all(color: _cores.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInformacaoConta(
            icone: Icons.mail_outline_rounded,
            titulo: 'E-mail',
            valor: _email ?? 'E-mail não encontrado',
          ),
          Container(
            height: 1,
            color: _cores.outline.withValues(alpha: 0.6),
          ),
          _buildInformacaoConta(
            icone: Icons.lock_outline_rounded,
            titulo: 'Senha',
            valor: '••••••••',
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencias() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _cores.surface,
        border: Border.all(color: _cores.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        secondary: Icon(
          Icons.notifications_none_rounded,
          color: _cores.primary,
          size: 21,
        ),
        title: Text(
          'Notificações',
          style: TextStyle(
            color: _cores.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _notificacoesAtivas
              ? 'Receber avisos sobre novas notícias'
              : 'Notificações desativadas',
          style: TextStyle(
            color: _cores.secondary,
            fontSize: 11,
          ),
        ),
        activeTrackColor: _cores.primary,
        value: _notificacoesAtivas,
        onChanged: _alterarNotificacoes,
      ),
    );
  }

  Future<void> _alterarNotificacoes(bool ativo) async {
    if (ativo) {
      final permitido =
          await NotificacaoService.solicitarPermissao();

      if (!permitido) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Permita as notificações para receber avisos do Jornal Virtual.',
            ),
            backgroundColor: _cores.error,
          ),
        );

        return;
      }
    }

    await NotificacaoService.definirNotificacoesAtivas(ativo);

    if (!mounted) return;

    setState(() {
      _notificacoesAtivas = ativo;
    });
  }

  Widget _buildInformacaoConta({
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 17),
      child: Row(
        children: [
          Icon(
            icone,
            color: _cores.primary,
            size: 21,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: _cores.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _cores.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorico() {
    if (_historico.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 30,
        ),
        decoration: BoxDecoration(
          color: _cores.surface,
          border: Border.all(color: _cores.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              color: _cores.secondary,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              'Nenhuma notícia visualizada ainda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _cores.secondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _historico.map((noticia) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildNoticiaHistorico(noticia),
        );
      }).toList(),
    );
  }

  Widget _buildNoticiaHistorico(Noticia noticia) {
    final imagem = _getImagem(noticia);

    return Material(
      color: _cores.surface,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoticiaDetalhesScreen(
                noticia: noticia,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 2,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _cores.outline),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (imagem != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imagem,
                    width: 82,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 82,
                        height: 68,
                        color: _cores.primary.withValues(alpha: 0.08),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 13),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      noticia.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _cores.onSurface,
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _formatarData(noticia.dataPublicacao),
                      style: TextStyle(
                        color: _cores.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: _cores.secondary,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoSair() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _sair,
        icon: const Icon(
          Icons.logout_rounded,
          size: 19,
        ),
        label: const Text(
          'Sair da conta',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _cores.primary,
          side: BorderSide(color: _cores.primary),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
