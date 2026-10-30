import 'package:flutter/material.dart';

import '../../models/noticia.dart';
import '../../models/publicacao.dart';
import '../../services/noticia_service.dart';
import '../../services/publicacao_service.dart';
import '../../widgets/publicacao_card.dart';

enum TipoAtividadePerfil { noticias, publicacoes, curtidas }

class AtividadesPerfilScreen extends StatefulWidget {
  final int usuarioId;
  final TipoAtividadePerfil tipo;

  const AtividadesPerfilScreen({
    super.key,
    required this.usuarioId,
    required this.tipo,
  });

  @override
  State<AtividadesPerfilScreen> createState() => _AtividadesPerfilScreenState();
}

class _AtividadesPerfilScreenState extends State<AtividadesPerfilScreen> {
  final NewsService _newsService = NewsService();
  final PublicacaoService _publicacaoService = PublicacaoService();

  bool _carregando = true;
  String? _erro;

  List<Noticia> _noticias = [];
  List<Publicacao> _publicacoes = [];

  String get _titulo {
    switch (widget.tipo) {
      case TipoAtividadePerfil.noticias:
        return 'Minhas notícias';
      case TipoAtividadePerfil.publicacoes:
        return 'Minhas publicações';
      case TipoAtividadePerfil.curtidas:
        return 'Curtidas feitas';
    }
  }

  IconData get _icone {
    switch (widget.tipo) {
      case TipoAtividadePerfil.noticias:
        return Icons.newspaper_outlined;
      case TipoAtividadePerfil.publicacoes:
        return Icons.article_outlined;
      case TipoAtividadePerfil.curtidas:
        return Icons.favorite_border;
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarAtividades();
  }

  bool _pertenceAoUsuario(Map<String, dynamic>? autor) {
    if (autor == null) return false;

    final id = autor['id'] ?? autor['usuarioId'];

    return id?.toString() == widget.usuarioId.toString();
  }

  Future<void> _carregarAtividades() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      if (widget.tipo == TipoAtividadePerfil.noticias) {
        final todas = await _newsService.listarNoticias();

        _noticias =
            todas.where((noticia) => _pertenceAoUsuario(noticia.autor)).toList()
              ..sort((a, b) => b.dataPublicacao.compareTo(a.dataPublicacao));
      } else {
        final todas = await _publicacaoService.listarPublicacoes();

        if (widget.tipo == TipoAtividadePerfil.publicacoes) {
          _publicacoes = todas.where((publicacao) {
            return _pertenceAoUsuario(publicacao.autor);
          }).toList();
        } else {
          _publicacoes = todas.where((publicacao) {
            return publicacao.curtidaPorUsuario(widget.usuarioId);
          }).toList();
        }

        _publicacoes.sort(
          (a, b) => b.dataPublicacao.compareTo(a.dataPublicacao),
        );
      }
    } catch (e) {
      _erro = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  Widget _cardNoticia(Noticia noticia) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0DCE4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.newspaper_outlined,
                color: Color(0xFFC92768),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatarData(noticia.dataPublicacao),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF817980),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            noticia.titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18213D),
            ),
          ),
          if ((noticia.subtitulo ?? '').isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              noticia.subtitulo!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF817980),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            noticia.texto,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF39343A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mensagemVazia() {
    String mensagem;

    switch (widget.tipo) {
      case TipoAtividadePerfil.noticias:
        mensagem = 'Você ainda não publicou nenhuma notícia.';
        break;
      case TipoAtividadePerfil.publicacoes:
        mensagem = 'Você ainda não fez nenhuma publicação.';
        break;
      case TipoAtividadePerfil.curtidas:
        mensagem = 'Você ainda não curtiu nenhuma publicação.';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icone, size: 52, color: const Color(0xFFE7A4BC)),
            const SizedBox(height: 14),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF817980)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFEF3F7A)),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 45,
                color: Color(0xFFC92768),
              ),
              const SizedBox(height: 12),
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _carregarAtividades,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final listaVazia = widget.tipo == TipoAtividadePerfil.noticias
        ? _noticias.isEmpty
        : _publicacoes.isEmpty;

    if (listaVazia) {
      return RefreshIndicator(
        color: const Color(0xFFEF3F7A),
        onRefresh: _carregarAtividades,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: _mensagemVazia(),
            ),
          ],
        ),
      );
    }

    if (widget.tipo == TipoAtividadePerfil.noticias) {
      return RefreshIndicator(
        color: const Color(0xFFEF3F7A),
        onRefresh: _carregarAtividades,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _noticias.length,
          itemBuilder: (context, index) {
            return _cardNoticia(_noticias[index]);
          },
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFEF3F7A),
      onRefresh: _carregarAtividades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _publicacoes.length,
        itemBuilder: (context, index) {
          return PublicacaoCard(
            publicacao: _publicacoes[index],
            usuarioId: widget.usuarioId,
            atualizar: () {
              _carregarAtividades();
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      appBar: AppBar(
        title: Text(
          _titulo,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFC92768),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _conteudo(),
    );
  }
}
