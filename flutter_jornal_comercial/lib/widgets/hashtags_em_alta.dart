
import 'package:flutter/material.dart';

import '../services/publicacao_service.dart';

class HashtagsEmAlta extends StatefulWidget {
  final ValueChanged<String>? onHashtagSelecionada;

  const HashtagsEmAlta({
    super.key,
    this.onHashtagSelecionada,
  });

  @override
  State<HashtagsEmAlta> createState() => _HashtagsEmAltaState();
}

class _HashtagsEmAltaState extends State<HashtagsEmAlta> {
  final PublicacaoService _service = PublicacaoService();

  late Future<List<dynamic>> _hashtagsFuture;

  static const List<Color> _coresVibrantes = [
    Color(0xFF8E24AA),
    Color(0xFFD52B6D),
    Color(0xFF008F9C),
  ];

  ColorScheme get _cores => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _hashtagsFuture = _carregarHashtags();
  }

  Future<List<dynamic>> _carregarHashtags() async {
    try {
      return await _service.listarRankingHashtags();
    } catch (e, stackTrace) {
      debugPrint('ERRO AO CARREGAR HASHTAGS: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  void atualizarRanking() {
    setState(() {
      _hashtagsFuture = _carregarHashtags();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _hashtagsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _carregando();
        }

        if (snapshot.hasError) {
          return _erro();
        }

        final hashtags = snapshot.data ?? [];

        if (hashtags.isEmpty) {
          return const SizedBox.shrink();
        }

        return _conteudoRanking(hashtags);
      },
    );
  }

  Widget _carregando() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: _cores.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _erro() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: _cores.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Não foi possível carregar os assuntos em alta.',
              style: TextStyle(
                color: _cores.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudoRanking(List<dynamic> hashtags) {
    final lista = hashtags
        .whereType<Map>()
        .map((item) {
          final nome = item['nome']?.toString().trim() ?? '';

          final quantidade = int.tryParse(
                item['quantidadePublicacoes']?.toString() ?? '0',
              ) ??
              0;

          return _HashtagItem(
            nome: nome.isEmpty
                ? '#sem_nome'
                : nome.startsWith('#')
                    ? nome
                    : '#$nome',
            quantidade: quantidade,
          );
        })
        .where((item) => item.nome.isNotEmpty)
        .toList();

    if (lista.isEmpty) {
      return const SizedBox.shrink();
    }

    lista.sort((a, b) => b.quantidade.compareTo(a.quantidade));

    final ranking = lista.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cores.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _cores.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: _cores.primary,
                size: 21,
              ),
              const SizedBox(width: 7),
              Text(
                'Assuntos em alta',
                style: TextStyle(
                  color: _cores.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(ranking.length, (index) {
              final item = ranking[index];
              final cor = _coresVibrantes[
                  index % _coresVibrantes.length];

              return InkWell(
                onTap: () {
                  widget.onHashtagSelecionada?.call(item.nome);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${index + 1}º',
                            style: TextStyle(
                              color: cor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              item.nome,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.quantidade} '
                        '${item.quantidade == 1 ? 'publicação' : 'publicações'}',
                        style: TextStyle(
                          color: _cores.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HashtagItem {
  final String nome;
  final int quantidade;

  const _HashtagItem({
    required this.nome,
    required this.quantidade,
  });
}
