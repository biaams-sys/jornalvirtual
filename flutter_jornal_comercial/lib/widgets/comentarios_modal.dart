
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/publicacao.dart';
import '../services/publicacao_service.dart';

class ComentariosModal extends StatefulWidget {
  final Publicacao publicacao;

  const ComentariosModal({
    super.key,
    required this.publicacao,
  });

  @override
  State<ComentariosModal> createState() => _ComentariosModalState();
}

class _ComentariosModalState extends State<ComentariosModal> {
  final PublicacaoService _service = PublicacaoService();
  final TextEditingController _controller = TextEditingController();

  List<dynamic> _comentarios = [];

  bool _carregando = true;
  bool _enviando = false;
  int? _usuarioId;
  int? _comentarioRespondendo;
  int? _excluindoComentarioId;

  ColorScheme get _cores => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
    _carregarComentarios();
  }

  Future<void> _carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _usuarioId = prefs.getInt('usuarioId');
    });
  }

  Future<void> _carregarComentarios() async {
    try {
      final comentarios = await _service.listarComentarios(
        widget.publicacao.id,
      );

      if (!mounted) return;

      setState(() {
        _comentarios = comentarios;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: _cores.error,
        ),
      );
    }
  }

  Future<void> _enviarComentario() async {
    final texto = _controller.text.trim();

    if (texto.isEmpty) return;

    setState(() {
      _enviando = true;
    });

    try {
      await _service.criarComentario(
        publicacaoId: widget.publicacao.id,
        texto: texto,
        comentarioPaiId: _comentarioRespondendo,
      );

      _controller.clear();

      if (!mounted) return;

      setState(() {
        _comentarioRespondendo = null;
      });

      await _carregarComentarios();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: _cores.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  String _nome(dynamic comentario) {
    if (comentario is! Map) return 'Usuário';

    final autor = comentario['autor'];

    if (autor is Map && autor['nome'] != null) {
      return autor['nome'].toString();
    }

    return 'Usuário';
  }

  String _nomeResposta(dynamic resposta) {
    return _nome(resposta);
  }

  String _texto(dynamic item) {
    if (item is! Map) return '';

    return item['texto']?.toString() ?? '';
  }

  int? _obterId(dynamic item) {
    if (item is! Map) return null;

    final id = item['id'];

    if (id == null) return null;

    return int.tryParse(id.toString());
  }

  int? _obterAutorId(dynamic item) {
    if (item is! Map) return null;

    final usuarioId = item['usuarioId'];

    if (usuarioId != null) {
      return int.tryParse(usuarioId.toString());
    }

    final autor = item['autor'];

    if (autor is Map && autor['id'] != null) {
      return int.tryParse(autor['id'].toString());
    }

    return null;
  }

  bool _ehDono(dynamic item) {
    if (_usuarioId == null) return false;

    return _obterAutorId(item) == _usuarioId;
  }

  Future<void> _excluirComentario(dynamic item) async {
    final comentarioId = _obterId(item);

    if (comentarioId == null ||
        !_ehDono(item) ||
        _excluindoComentarioId != null) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final cores = Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor: cores.surface,
          title: Text(
            'Excluir comentário',
            style: TextStyle(color: cores.onSurface),
          ),
          content: Text(
            'Tem certeza de que deseja excluir este comentário?',
            style: TextStyle(color: cores.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: TextStyle(color: cores.primary),
              ),
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

    setState(() {
      _excluindoComentarioId = comentarioId;
    });

    try {
      await _service.excluirComentario(comentarioId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Comentário excluído com sucesso.'),
          backgroundColor: _cores.primary,
        ),
      );

      if (_comentarioRespondendo == comentarioId) {
        setState(() {
          _comentarioRespondendo = null;
        });
      }

      await _carregarComentarios();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: _cores.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _excluindoComentarioId = null;
        });
      }
    }
  }

  Widget _menuExcluir(dynamic item) {
    if (!_ehDono(item)) {
      return const SizedBox.shrink();
    }

    final id = _obterId(item);
    final excluindo = id != null && id == _excluindoComentarioId;

    if (excluindo) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _cores.primary,
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Opções do comentário',
      enabled: _excluindoComentarioId == null,
      onSelected: (opcao) {
        if (opcao == 'excluir') {
          _excluirComentario(item);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'excluir',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: _cores.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Excluir comentário',
                style: TextStyle(color: _cores.error),
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.more_vert,
          size: 20,
          color: _cores.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _avatar({double raio = 18, double tamanhoIcone = 19}) {
    return CircleAvatar(
      radius: raio,
      backgroundColor: _cores.primaryContainer,
      child: Icon(
        Icons.person,
        size: tamanhoIcone,
        color: _cores.onPrimaryContainer,
      ),
    );
  }

  Widget _comentarioWidget(dynamic comentario) {
    if (comentario is! Map) {
      return const SizedBox.shrink();
    }

    final respostas = comentario['respostas'] is List
        ? comentario['respostas'] as List<dynamic>
        : <dynamic>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cores.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nome(comentario),
                        style: TextStyle(
                          color: _cores.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _texto(comentario),
                        style: TextStyle(
                          color: _cores.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _menuExcluir(comentario),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 48,
              top: 5,
            ),
            child: TextButton(
              onPressed: () {
                final id = _obterId(comentario);

                if (id != null) {
                  setState(() {
                    _comentarioRespondendo = id;
                  });
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: _cores.primary,
              ),
              child: const Text('Responder'),
            ),
          ),
          if (respostas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Column(
                children: respostas.map<Widget>((resposta) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _cores.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _cores.outlineVariant,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _avatar(
                          raio: 15,
                          tamanhoIcone: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nomeResposta(resposta),
                                style: TextStyle(
                                  color: _cores.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _texto(resposta),
                                style: TextStyle(
                                  color: _cores.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _menuExcluir(resposta),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _cores.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _cores.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Comentários',
                        style: tema.textTheme.titleLarge?.copyWith(
                          color: _cores.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: _cores.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _carregando
                    ? Center(
                        child: CircularProgressIndicator(
                          color: _cores.primary,
                        ),
                      )
                    : _comentarios.isEmpty
                        ? Center(
                            child: Text(
                              'Ainda não há comentários.',
                              style: TextStyle(
                                color: _cores.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            itemCount: _comentarios.length,
                            itemBuilder: (context, index) {
                              return _comentarioWidget(
                                _comentarios[index],
                              );
                            },
                          ),
              ),
              if (_comentarioRespondendo != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 7,
                  ),
                  color: _cores.primaryContainer,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Respondendo a um comentário',
                          style: TextStyle(
                            color: _cores.onPrimaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _comentarioRespondendo = null;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: _cores.primary,
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 3,
                          style: TextStyle(
                            color: _cores.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Escreva um comentário...',
                            hintStyle: TextStyle(
                              color: _cores.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: _cores.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(
                                color: _cores.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(
                                color: _cores.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(
                                color: _cores.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _enviando ? null : _enviarComentario,
                        icon: _enviando
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _cores.primary,
                                ),
                              )
                            : Icon(
                                Icons.send,
                                color: _cores.primary,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
