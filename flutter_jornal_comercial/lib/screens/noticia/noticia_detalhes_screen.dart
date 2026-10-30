import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/noticia.dart';
import '../../services/historico_noticias_service.dart';

class NoticiaDetalhesScreen extends StatefulWidget {
  final Noticia noticia;

  const NoticiaDetalhesScreen({
    super.key,
    required this.noticia,
  });

  @override
  State<NoticiaDetalhesScreen> createState() => _NoticiaDetalhesScreenState();
}

class _NoticiaDetalhesScreenState extends State<NoticiaDetalhesScreen> {
  @override
  void initState() {
    super.initState();
    HistoricoNoticiasService().registrar(widget.noticia);
  }

  String? _getImagem() {
    if (widget.noticia.midias.isEmpty) {
      return null;
    }

    final primeiraMidia = widget.noticia.midias.first;

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

    return '${ApiConstants.baseUrl}/$caminho';
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
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
                        34,
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 58,
      width: double.infinity,
      color: AppColors.primary,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            padding: const EdgeInsets.only(left: 15),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Notícia',
            style: TextStyle(
              color: Colors.white,
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
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.primary,
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
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          widget.noticia.titulo,
          style: const TextStyle(
            color: AppColors.text,
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
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 17,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.border,
              ),
              bottom: BorderSide(
                color: AppColors.border,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      autor?.isNotEmpty == true ? autor! : 'Autor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Publicado em',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatarData(widget.noticia.dataPublicacao),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          widget.noticia.texto,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            height: 1.8,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}