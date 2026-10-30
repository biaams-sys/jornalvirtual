import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/noticia.dart';
import '../../services/noticia_service.dart';
import '../configuracoes/config.dart';
import '../noticia/noticia_detalhes_screen.dart';
import '../feed/feed_screen.dart';
import '../perfil/perfil_screen.dart';
import '../../services/notificacao_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsService _newsService = NewsService();
  final TextEditingController _pesquisaController = TextEditingController();

  bool _notificacoesAtivas = false;
  String _termoBusca = '';
  late Future<List<Noticia>> _noticiasFuture;

  Future<void> _ativarNotificacoes() async {
    if (_notificacoesAtivas) {
      await NotificacaoService.definirNotificacoesAtivas(false);

      if (!mounted) return;

      setState(() {
        _notificacoesAtivas = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificações desativadas.')),
      );

      return;
    }

    final permitido = await NotificacaoService.solicitarPermissao();

    if (!permitido) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permita as notificações para receber avisos do Jornal Virtual.',
          ),
        ),
      );

      return;
    }

    await NotificacaoService.definirNotificacoesAtivas(true);

    if (!mounted) return;

    setState(() {
      _notificacoesAtivas = true;
    });

    await NotificacaoService.mostrar(
      id: 0,
      titulo: 'Jornal Virtual',
      mensagem: 'Notificações ativadas com sucesso!',
    );
  }

  @override
  void initState() {
    super.initState();
    _carregarNoticias();
    _carregarPreferenciaNotificacoes();
  }

  Future<void> _carregarPreferenciaNotificacoes() async {
    final ativo = await NotificacaoService.notificacoesEstaoAtivas();

    if (!mounted) return;

    setState(() {
      _notificacoesAtivas = ativo;
    });
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  void _carregarNoticias() {
    _noticiasFuture = _newsService.listarNoticias().then((noticias) async {
      await NotificacaoService.verificarNovasNoticias(noticias);
      return noticias;
    });
  }

  Future<void> _atualizarNoticias() async {
    setState(() {
      _carregarNoticias();
    });

    await _noticiasFuture;
  }

  List<Noticia> _filtrarNoticias(List<Noticia> noticias) {
    final termo = _termoBusca.trim().toLowerCase();

    if (termo.isEmpty) {
      return noticias;
    }

    return noticias.where((noticia) {
      final titulo = noticia.titulo.toLowerCase();
      final subtitulo = noticia.subtitulo?.toLowerCase() ?? '';
      final texto = noticia.texto.toLowerCase();
      final autor = noticia.autor?['nome']?.toString().toLowerCase() ?? '';

      return titulo.contains(termo) ||
          subtitulo.contains(termo) ||
          texto.contains(termo) ||
          autor.contains(termo);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _atualizarNoticias,
                color: AppColors.primary,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildSearch(),
                      const SizedBox(height: 30),
                      FutureBuilder<List<Noticia>>(
                        future: _noticiasFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingContent();
                          }

                          if (snapshot.hasError) {
                            return _buildError(
                              'Não foi possível carregar as notícias.',
                            );
                          }

                          final noticias = snapshot.data ?? [];

                          if (_termoBusca.trim().isNotEmpty) {
                            return _buildResultadosBusca(
                              _filtrarNoticias(noticias),
                            );
                          }

                          if (noticias.isEmpty) {
                            return _buildEmpty('Nenhuma notícia cadastrada.');
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Destaque do dia'),
                              const SizedBox(height: 14),
                              _buildFeaturedNews(noticias.first),
                              const SizedBox(height: 32),
                              _buildSectionTitle('Últimas notícias'),
                              const SizedBox(height: 14),
                              _buildNewsList(noticias),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.menu_rounded,
            size: 24,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 13),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Jornal',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              TextSpan(
                text: ' Virtual',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _ativarNotificacoes,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _notificacoesAtivas ? 1 : 0),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 1 + (value * 0.08),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _notificacoesAtivas
                        ? AppColors.primaryLight
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _notificacoesAtivas
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : AppColors.border,
                    ),
                  ),
                  child: Transform.rotate(
                    angle: value * 0.14,
                    child: Icon(
                      _notificacoesAtivas
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: _notificacoesAtivas
                          ? AppColors.primary
                          : AppColors.text,
                      size: 22,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: _pesquisaController,
              onChanged: (valor) {
                setState(() {
                  _termoBusca = valor;
                });
              },
              style: const TextStyle(color: AppColors.text, fontSize: 14),
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: 'Pesquisar notícias...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _termoBusca.isNotEmpty
                ? GestureDetector(
                    key: const ValueKey('limpar'),
                    onTap: () {
                      _pesquisaController.clear();
                      setState(() {
                        _termoBusca = '';
                      });
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  )
                : const SizedBox(key: ValueKey('vazio'), width: 20, height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 21,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ],
    );
  }

  Widget _buildFeaturedNews(Noticia noticia) {
    final imagem = _getImagem(noticia);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoticiaDetalhesScreen(noticia: noticia),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagem != null)
              SizedBox(
                height: 210,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(imagem, fit: BoxFit.cover),
                    Positioned(
                      left: 15,
                      top: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DESTAQUE',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 16, 17, 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noticia.titulo,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 21,
                      height: 1.16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    noticia.subtitulo?.isNotEmpty == true
                        ? noticia.subtitulo!
                        : noticia.texto,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primary,
                        size: 17,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          noticia.autor?['nome'] ?? 'Autor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.schedule_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatarData(noticia.dataPublicacao),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsList(List<Noticia> noticias) {
    final ultimasNoticias = noticias.length > 1
        ? noticias.sublist(1)
        : <Noticia>[];

    if (ultimasNoticias.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Não há outras notícias no momento.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return Column(
      children: ultimasNoticias.map((noticia) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildNewsCard(noticia),
        );
      }).toList(),
    );
  }

  Widget _buildNewsCard(Noticia noticia) {
    final imagem = _getImagem(noticia);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoticiaDetalhesScreen(noticia: noticia),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagem != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imagem,
                  width: 104,
                  height: 104,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 13),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3, right: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      noticia.titulo,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      noticia.subtitulo?.isNotEmpty == true
                          ? noticia.subtitulo!
                          : noticia.texto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatarData(noticia.dataPublicacao),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NoticiaDetalhesScreen(noticia: noticia),
                              ),
                            );
                          },
                          child: const Text(
                            'Leia mais',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadosBusca(List<Noticia> noticias) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Resultados da pesquisa'),
        const SizedBox(height: 14),
        if (noticias.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Nenhuma notícia encontrada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Tente pesquisar por outro termo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: noticias.map((noticia) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildNewsCard(noticia),
              );
            }).toList(),
          ),
      ],
    );
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

    if (caminho.startsWith('http://') || caminho.startsWith('https://')) {
      return caminho;
    }

    return '${ApiConstants.baseUrl}/$caminho';
  }

  Widget _buildLoadingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Destaque do dia'),
        const SizedBox(height: 14),
        Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionTitle('Últimas notícias'),
        const SizedBox(height: 14),
        _buildLoadingList(),
      ],
    );
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(2, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 126,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildError(String mensagem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _atualizarNoticias,
            child: const Text(
              'Tentar novamente',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String mensagem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        mensagem,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inMinutes < 1) {
      return 'Agora';
    }

    if (diferenca.inMinutes < 60) {
      return '${diferenca.inMinutes} min';
    }

    if (diferenca.inHours < 24) {
      return '${diferenca.inHours}h';
    }

    if (diferenca.inDays == 1) {
      return 'Ontem';
    }

    if (diferenca.inDays < 7) {
      return '${diferenca.inDays} dias';
    }

    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // INÍCIO
          Expanded(
            child: _NavigationItem(
              icon: Icons.home_rounded,
              label: 'Início',
              selected: true,
            ),
          ),

          // FEED
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeedScreen()),
                );
              },
              child: const _NavigationItem(
                icon: Icons.article_outlined,
                label: 'Feed',
                selected: false,
              ),
            ),
          ),

          // PERFIL
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PerfilScreen()),
                );
              },
              child: const _NavigationItem(
                icon: Icons.person_outline_rounded,
                label: 'Perfil',
                selected: false,
              ),
            ),
          ),

          // CONFIGURAÇÕES
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConfigScreen()),
                );
              },
              child: const _NavigationItem(
                icon: Icons.settings_outlined,
                label: 'Configurações',
                selected: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.04 : 1,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              size: 23,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
