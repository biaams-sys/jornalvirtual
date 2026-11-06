import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/constants/api_constants.dart';
import '../core/theme/app_colors.dart';
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

  String _urlStorage(String caminho) {
    var path = caminho;

    if (path.startsWith('midias/')) {
      path = path.substring('midias/'.length);
    }

    final baseUrl = ApiConstants.supabaseUrl.replaceFirst('/rest/v1', '');

    return '$baseUrl/storage/v1/object/public/midias/$path';
  }

  @override
  void initState() {
    super.initState();

    _quantidadeCurtidas = widget.publicacao.quantidadeCurtidas;

    _curtida =
        widget.usuarioId != null &&
        widget.publicacao.curtidaPorUsuario(widget.usuarioId!);
  }

  @override
  void didUpdateWidget(covariant PublicacaoCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.publicacao.id != widget.publicacao.id) {
      _quantidadeCurtidas = widget.publicacao.quantidadeCurtidas;

      _curtida =
          widget.usuarioId != null &&
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

    debugPrint('Autor da publicação: ${widget.publicacao.autor}');
    debugPrint('ID identificado: $id');

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

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PerfilScreen(usuarioId: id)));
  }

  String _tipoAutor() {
    final tipo = widget.publicacao.autor?['tipo'];

    switch (tipo) {
      case 'ADMINISTRADOR':
        return 'Administrador';
      case 'VERIFICADO':
        return 'Verificado';
      default:
        return 'Aluno';
    }
  }

  String? _fotoAutor() {
    final foto = widget.publicacao.autor?['fotoPerfil'];

    if (foto == null || foto.toString().isEmpty) {
      return null;
    }

    final fotoString = foto.toString();

    if (fotoString.startsWith('http://') || fotoString.startsWith('https://')) {
      return fotoString;
    }

    return _urlStorage(fotoString);
  }

  String _formatarData(DateTime data) {
    final diferenca = DateTime.now().difference(data);

    if (diferenca.inSeconds < 60) {
      return 'agora';
    }

    if (diferenca.inMinutes < 60) {
      return 'há ${diferenca.inMinutes} min';
    }

    if (diferenca.inHours < 24) {
      return 'há ${diferenca.inHours} h';
    }

    if (diferenca.inDays < 7) {
      return 'há ${diferenca.inDays} d';
    }

    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  Future<void> _excluirPublicacao() async {
    if (!_ehDonoPublicacao || _excluindoPublicacao) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      _excluindoPublicacao = true;
    });

    try {
      await _service.excluirPublicacao(widget.publicacao.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicação excluída com sucesso.')),
      );

      widget.atualizar?.call();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _excluindoPublicacao = false;
        });
      }
    }
  }

  Future<void> _alternarCurtida() async {
    if (_carregandoCurtida) return;

    setState(() {
      _carregandoCurtida = true;
    });

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
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregandoCurtida = false;
        });
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
  //return 'https://hepwnbumziimvfugvjbe.supabase.co/storage/v1/object/public/$path';

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
    debugPrint(
      'MÍDIAS DA PUBLICAÇÃO ${widget.publicacao.id}: ${widget.publicacao.midias}',
    );

    if (widget.publicacao.midias.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: widget.publicacao.midias.map((midia) {
        final url = _urlMidia(midia);

        if (url.isEmpty) {
          return const SizedBox.shrink();
        }

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
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return const SizedBox(
                        height: 250,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('ERRO AO CARREGAR MÍDIA: $error');

                      return Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F5F7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Não foi possível carregar a imagem.',
                              style: TextStyle(color: Colors.grey),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0DCE4)),
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
                  backgroundColor: const Color(0xFFF4D5E2),
                  backgroundImage: foto != null ? NetworkImage(foto) : null,
                  child: foto == null
                      ? const Icon(Icons.person, color: Color(0xFFC92768))
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF18213D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_tipoAutor()} · '
                      '${_formatarData(widget.publicacao.dataPublicacao)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
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
                    const PopupMenuItem<String>(
                      value: 'excluir',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Excluir publicação',
                            style: TextStyle(color: Colors.red),
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
                        : const Icon(
                            Icons.more_horiz,
                            color: AppColors.textSecondary,
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
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          if (widget.publicacao.hashtags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.publicacao.hashtags.map<Widget>((hashtag) {
                if (hashtag is! Map) {
                  return const SizedBox.shrink();
                }

                final nome = hashtag['nome']?.toString() ?? '';

                if (nome.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Text(
                  nome,
                  style: const TextStyle(
                    color: Color(0xFFC92768),
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ],
          _buildMidias(),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1E8ED)),
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
                        color: _curtida
                            ? const Color(0xFFE83272)
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_quantidadeCurtidas',
                        style: TextStyle(
                          color: _curtida
                              ? const Color(0xFFE83272)
                              : AppColors.textSecondary,
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
                    builder: (_) =>
                        ComentariosModal(publicacao: widget.publicacao),
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
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.publicacao.quantidadeComentarios}',
                        style: const TextStyle(color: AppColors.textSecondary),
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

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));

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
    if (!_controller.value.isInitialized) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(child: CircularProgressIndicator()),
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFC92768),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
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
