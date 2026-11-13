import 'package:flutter/material.dart';

import '../services/publicacao_service.dart';

class HashtagsEmAlta extends StatefulWidget {
  final ValueChanged<String>? onHashtagSelecionada;

  const HashtagsEmAlta({super.key, this.onHashtagSelecionada});

  @override
  State<HashtagsEmAlta> createState() => _HashtagsEmAltaState();
}

class _HashtagsEmAltaState extends State<HashtagsEmAlta> {
  final PublicacaoService _service = PublicacaoService();

  late Future<List<dynamic>> _hashtagsFuture;

  static const List<Color> _coresVibrantes = [
    Color(0xFF8E24AA),
    Color(0xFFD52B6D),
    Color(0xFF00ACC1),
  ];

  @override
  void initState() {
    super.initState();
    _hashtagsFuture = _carregarHashtags();
  }

  Future<List<dynamic>> _carregarHashtags() async {
    print('CARREGANDO HASHTAGS...');

    try {
      final resultado = await _service.listarRankingHashtags();

      print('HASHTAGS RECEBIDAS: $resultado');

      return resultado;
    } catch (e, stackTrace) {
      print('ERRO AO CARREGAR HASHTAGS: $e');
      print(stackTrace);
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
          return _vazio();
        }

        return _conteudoRanking(hashtags);
      },
    );
  }

  Widget _carregando() {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _decoracao(),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD52B6D),
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  Widget _erro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _decoracao(),
      child: const Column(
        children: [
          Icon(Icons.cloud_off_outlined, color: Color(0xFFD52B6D), size: 32),
          SizedBox(height: 8),
          Text(
            'Não foi possível carregar o ranking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _vazio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _decoracao(),
      child: const Column(
        children: [
          Icon(Icons.tag, color: Color(0xFFD52B6D), size: 32),
          SizedBox(height: 8),
          Text(
            'Ainda não existem hashtags no ranking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
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

          final quantidade =
              int.tryParse(item['quantidadePublicacoes']?.toString() ?? '0') ??
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
      return _vazio();
    }

    lista.sort((a, b) => b.quantidade.compareTo(a.quantidade));

    final ranking = lista.take(3).toList();

    final quantidadeMaior = ranking.first.quantidade;
    final quantidadeMenor = ranking.last.quantidade;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _decoracao(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assuntos do Momento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18213D),
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ranking.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 16, color: Color(0xFFF0F0F0)),
            itemBuilder: (context, index) {
              final item = ranking[index];
              final posicao = index + 1;
              final corDaHashtag =
                  _coresVibrantes[index % _coresVibrantes.length];

              final proporcao = quantidadeMaior == quantidadeMenor
                  ? 0.5
                  : (item.quantidade - quantidadeMenor) /
                        (quantidadeMaior - quantidadeMenor);

              final tamanhoFonte = 14.0 + (proporcao * 3.0);

              return InkWell(
                onTap: () {
                  widget.onHashtagSelecionada?.call(item.nome);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 2,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$posicaoº',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: corDaHashtag,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nome,
                              style: TextStyle(
                                fontSize: tamanhoFonte,
                                fontWeight: FontWeight.w700,
                                color: corDaHashtag,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.quantidade} ${item.quantidade == 1 ? 'publicação' : 'publicações'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  BoxDecoration _decoracao() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _HashtagItem {
  final String nome;
  final int quantidade;

  const _HashtagItem({required this.nome, required this.quantidade});
}
