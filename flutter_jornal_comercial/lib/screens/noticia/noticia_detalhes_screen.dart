
import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../models/noticia.dart';
import '../../services/historico_noticias_service.dart';

class NoticiaDetalhesScreen extends StatefulWidget {
  final Noticia noticia;

  const NoticiaDetalhesScreen({
    super.key,
    required this.noticia,
  });

  @override
  State<NoticiaDetalhesScreen> createState() =>
      _NoticiaDetalhesScreenState();
}

class _NoticiaDetalhesScreenState
    extends State<NoticiaDetalhesScreen> {
  ColorScheme get _cores => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    HistoricoNoticiasService().registrar(widget.noticia);
  }

  String? _getImagem() {
    for (final midia in widget.noticia.midias) {
      if (midia is! Map) continue;

      final mimeType = midia['mimeType']?.toString() ?? '';

      if (!mimeType.startsWith('image/')) continue;

      final path = midia['path'];

      if (path == null || path.toString().isEmpty) continue;

      var caminho = path.toString();

      if (caminho.startsWith('http://') ||
          caminho.startsWith('https://')) {
        return caminho;
      }

      caminho = caminho.replaceFirst(RegExp(r'^/+'), '');

      if (caminho.startsWith('midias/')) {
        caminho = caminho.substring('midias/'.length);
      }

      final baseUrl =
          ApiConstants.supabaseUrl.replaceFirst('/rest/v1', '');

      return '$baseUrl/storage/v1/object/public/midias/$caminho';
    }

    return null;
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    final imagem = _getImagem();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imagem != null) _buildImagem(imagem),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        30,
                        20,
                        40,
                      ),
                      child: _buildConteudo(),
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

  Widget _buildHeader() {
    return Container(
      height: 58,
      width: double.infinity,
      color: _cores.primary,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            padding: const EdgeInsets.only(left: 15),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: _cores.onPrimary,
              size: 27,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Notícia',
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

  Widget _buildImagem(String imagem) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          imagem,
          width: double.infinity,
          height: 225,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 225,
              color: _cores.primaryContainer,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: _cores.onPrimaryContainer,
                  size: 40,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    final autor = widget.noticia.autor?['nome']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 86,
          height: 4,
          decoration: BoxDecoration(
            color: _cores.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        const SizedBox(height: 18),

        Text(
          widget.noticia.titulo,
          style: TextStyle(
            color: _cores.onSurface,
            fontSize: 30,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),

        if (widget.noticia.subtitulo?.isNotEmpty == true) ...[
          const SizedBox(height: 14),
          Text(
            widget.noticia.subtitulo!,
            style: TextStyle(
              color: _cores.onSurfaceVariant,
              fontSize: 17,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _cores.outlineVariant),
              bottom: BorderSide(color: _cores.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _cores.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: _cores.onPrimaryContainer,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      autor?.isNotEmpty == true ? autor! : 'Autor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _cores.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Publicado em',
                      style: TextStyle(
                        color: _cores.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                _formatarData(widget.noticia.dataPublicacao),
                style: TextStyle(
                  color: _cores.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        Text(
          widget.noticia.texto,
          style: TextStyle(
            color: _cores.onSurface,
            fontSize: 16,
            height: 1.8,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
