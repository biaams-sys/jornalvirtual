
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/constants/api_constants.dart';
import '../models/publicacao.dart';
import '../services/publicacao_service.dart';
import '../screens/perfil/perfil_screen.dart';
import 'comentarios_modal.dart';

class PublicacaoCard extends StatefulWidget {
  final Publicacao publicacao;
  final int? usuarioId;
  final VoidCallback? atualizar;

  const PublicacaoCard({
    super.key,
    required this.publicacao,
    this.usuarioId,
    this.atualizar,
  });

  @override
  State<PublicacaoCard> createState() => _PublicacaoCardState();
}

class _PublicacaoCardState extends State<PublicacaoCard> {
  final PublicacaoService _service = PublicacaoService();

  late bool _curtida;
  late int _quantidadeCurtidas;

  bool _carregandoCurtida = false;
  bool _excluindoPublicacao = false;

  ColorScheme get _cores => Theme.of(context).colorScheme;

  String _urlStorage(String caminho) {
    var path = caminho.trim();

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    if (path.startsWith('midias/')) {
      path = path.substring('midias/'.length);
    }

    while (path.startsWith('/')) {
      path = path.substring(1);
    }

    final baseUrl = ApiConstants.supabaseUrl.replaceFirst('/rest/v1', '');

    return '$baseUrl/storage/v1/object/public/midias/$path';
  }

  @override
  void initState() {
    super.initState();

    _quantidadeCurtidas = widget.publicacao.quantidadeCurtidas;
    _curtida = widget.usuarioId != null &&
        widget.publicacao.curtidaPorUsuario(widget.usuarioId!);
  }

  @override
  void didUpdateWidget(covariant PublicacaoCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.publicacao.id != widget.publicacao.id) {
      _quantidadeCurtidas = widget.publicacao.quantidadeCurtidas;
      _curtida = widget.usuarioId != null &&
          widget.publicacao.curtidaPorUsuario(widget.usuarioId!);
    }
  }

  int? _idAutor() {
    final autor = widget.publicacao.autor;
    if (autor == null) return null;

    final id = autor['id'] ?? autor['usuarioId'] ?? autor['usuario_id'];

    if (id is int) return id;

    return int.tryParse(id?.toString() ?? '');
  }

  bool get _ehDonoPublicacao {
    final idAutor = _idAutor();

    return widget.usuarioId != null &&
        idAutor != null &&
        idAutor == widget.usuarioId;
  }

  String _nomeAutor() {
    return widget.publicacao.autor?['nome']?.toString() ?? 'Usuário';
  }

  void _abrirPerfilAutor() {
    final id = _idAutor();

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível identificar o autor desta publicação.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PerfilScreen(usuarioId: id),
      ),
    );
  }

  String _tipoAutor() {
    final tipo = widget.publicacao.autor?['tipo'];

    switch (tipo) {
      case 'ADMINISTRADOR':
        return 'Administrador';
      case 'VERIFICADO':
        return 'Verificado';
      default:
        return 'Usuário';
    }
  }

  String? _fotoAutor() {
    final foto = widget.publicacao.autor?['fotoPerfil'];

    if (foto == null || foto.toString().isEmpty) {
      return null;
    }

    final fotoString = foto.toString();

    if (fotoString.startsWith('http://') ||
        fotoString.startsWith('https://')) {
      return fotoString;
    }

    return _urlStorage(fotoString);
  }

  String _formatarData(DateTime data) {
    final diferenca = DateTime.now().difference(data);

    if (diferenca.inSeconds < 60) return 'agora';
    if (diferenca.inMinutes < 60) return 'há ${diferenca.inMinutes} min';
    if (diferenca.inHours < 24) return 'há ${diferenca.inHours} h';
    if (diferenca.inDays < 7) return 'há ${diferenca.inDays} d';

    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  Future<void> _excluirPublicacao() async {
    if (!_ehDonoPublicacao || _excluindoPublicacao) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final cores = Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor: cores.surface,
          title: const Text('Excluir publicação'),
          content: const Text(
            'Tem certeza de que deseja excluir esta publicação? '
            'Essa ação não poderá ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: cores.error,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    setState(() => _excluindoPublicacao = true);

    try {
      await _service.excluirPublicacao(widget.publicacao.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicação excluída com sucesso.'),
        ),
      );

      widget.atualizar?.call();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _excluindoPublicacao = false);
      }
    }
  }

  Future<void> _alternarCurtida() async {
    if (_carregandoCurtida) return;

    setState(() => _carregandoCurtida = true);

    try {
      if (_curtida) {
        await _service.descurtir(widget.publicacao.id);

        if (!mounted) return;

        setState(() {
          _curtida = false;
          if (_quantidadeCurtidas > 0) {
            _quantidadeCurtidas--;
          }
        });
      } else {
        await _service.curtir(widget.publicacao.id);

        if (!mounted) return;

        setState(() {
          _curtida = true;
          _quantidadeCurtidas++;
        });
      }

      widget.atualizar?.call();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _carregandoCurtida = false);
      }
    }
  }

  String _urlMidia(dynamic midia) {
    if (midia is! Map) return '';

    final path = midia['path']?.toString() ?? '';

    if (path.isEmpty) return '';

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    return _urlStorage(path);
  }

  bool _ehVideo(dynamic midia) {
    if (midia is! Map) return false;

    final mimeType = midia['mimeType']?.toString().toLowerCase();

    if (mimeType != null && mimeType.startsWith('video/')) {
      return true;
    }

    final nomeArquivo = midia['nomeArquivo']?.toString().toLowerCase() ?? '';

    return nomeArquivo.endsWith('.mp4') ||
        nomeArquivo.endsWith('.webm') ||
        nomeArquivo.endsWith('.mkv');
  }

  Widget _buildMidias() {
    if (widget.publicacao.midias.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: widget.publicacao.midias.map((midia) {
        final url = _urlMidia(midia);

        if (url.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: _ehVideo(midia)
              ? _VideoPublicacao(url: url)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;

                      return const SizedBox(
                        height: 250,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      final cores = Theme.of(context).colorScheme;

                      return Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cores.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 40,
                              color: cores.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Não foi possível carregar a imagem.',
                              style: TextStyle(
                                color: cores.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foto = _fotoAutor();
    final tema = Theme.of(context);
    final cores = tema.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cores.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cores.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: _abrirPerfilAutor,
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: cores.primaryContainer,
                  backgroundImage: foto != null ? NetworkImage(foto) : null,
                  child: foto == null
                      ? Icon(
                          Icons.person,
                          color: cores.onPrimaryContainer,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _abrirPerfilAutor,
                      child: Text(
                        _nomeAutor(),
                        style: tema.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_tipoAutor()} · '
                      '${_formatarData(widget.publicacao.dataPublicacao)}',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: cores.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_ehDonoPublicacao)
                PopupMenuButton<String>(
                  tooltip: 'Opções da publicação',
                  enabled: !_excluindoPublicacao,
                  onSelected: (opcao) {
                    if (opcao == 'excluir') {
                      _excluirPublicacao();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'excluir',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: cores.error),
                          const SizedBox(width: 8),
                          Text(
                            'Excluir publicação',
                            style: TextStyle(color: cores.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _excluindoPublicacao
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.more_horiz,
                            color: cores.onSurfaceVariant,
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.publicacao.texto != null &&
              widget.publicacao.texto!.isNotEmpty)
            Text(
              widget.publicacao.texto!,
              style: tema.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          if (widget.publicacao.hashtags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.publicacao.hashtags.map<Widget>((hashtag) {
                if (hashtag is! Map) return const SizedBox.shrink();

                final nome = hashtag['nome']?.toString() ?? '';

                if (nome.isEmpty) return const SizedBox.shrink();

                return Text(
                  nome,
                  style: TextStyle(
                    color: cores.primary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ],
          _buildMidias(),
          const SizedBox(height: 16),
          Divider(height: 1, color: cores.outlineVariant),
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: _alternarCurtida,
                borderRadius: BorderRadius.circular(30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _curtida ? Icons.favorite : Icons.favorite_border,
                        size: 21,
                        color: _curtida ? Colors.redAccent : cores.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_quantidadeCurtidas',
                        style: TextStyle(
                          color: _curtida ? Colors.redAccent : cores.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ComentariosModal(
                      publicacao: widget.publicacao,
                    ),
                  );

                  if (!mounted) return;
                  widget.atualizar?.call();
                },
                borderRadius: BorderRadius.circular(30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: cores.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.publicacao.quantidadeComentarios}',
                        style: TextStyle(color: cores.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VideoPublicacao extends StatefulWidget {
  final String url;

  const _VideoPublicacao({required this.url});

  @override
  State<_VideoPublicacao> createState() => _VideoPublicacaoState();
}

class _VideoPublicacaoState extends State<_VideoPublicacao> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    );

    _inicializarVideo();
  }

  Future<void> _inicializarVideo() async {
    try {
      await _controller.initialize();

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Erro ao carregar vídeo: $e');

      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    if (!_controller.value.isInitialized) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cores.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _controller.value.isPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: cores.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: cores.onPrimary,
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 4,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
