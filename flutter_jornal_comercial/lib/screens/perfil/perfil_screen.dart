import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/usuario.dart';
import '../../services/noticia_service.dart';
import '../../services/publicacao_service.dart';
import '../../services/usuarios_service.dart';
import 'atividades_perfil_screen.dart';

class PerfilScreen extends StatefulWidget {
  final int? usuarioId;

  const PerfilScreen({super.key, this.usuarioId});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  final NewsService _newsService = NewsService();
  final PublicacaoService _publicacaoService = PublicacaoService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _bioController = TextEditingController();

  Usuario? _usuario;
  Future<_EstatisticasPerfil>? _estatisticasFuture;

  bool _carregando = true;
  bool _salvando = false;
  bool _uploadandoImagem = false;
  bool _ehMeuPerfil = true;

  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final usuarioLogado = await _usuarioService.buscarUsuarioLogado();

      final idSolicitado = widget.usuarioId;

      final usuario = idSolicitado == null || idSolicitado == usuarioLogado.id
          ? usuarioLogado
          : await _usuarioService.buscarUsuarioPorId(idSolicitado);

      if (!mounted) return;

      setState(() {
        _usuario = usuario;
        _ehMeuPerfil = usuario.id == usuarioLogado.id;
        _bioController.text = usuario.bio ?? '';
        _estatisticasFuture = _carregarEstatisticas(usuario);
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  Future<_EstatisticasPerfil> _carregarEstatisticas(Usuario usuario) async {
    final noticias = await _newsService.listarNoticias();
    final publicacoes = await _publicacaoService.listarPublicacoes();

    final quantidadeNoticias = noticias.where((noticia) {
      return _pertenceAoUsuario(noticia.autor, usuario.id);
    }).length;

    final quantidadePublicacoes = publicacoes.where((publicacao) {
      return _pertenceAoUsuario(publicacao.autor, usuario.id);
    }).length;

    final curtidasFeitas = publicacoes.where((publicacao) {
      return publicacao.curtidaPorUsuario(usuario.id);
    }).length;

    return _EstatisticasPerfil(
      noticias: quantidadeNoticias,
      publicacoes: quantidadePublicacoes,
      curtidas: curtidasFeitas,
    );
  }

  bool _pertenceAoUsuario(Map<String, dynamic>? autor, int usuarioId) {
    if (autor == null) return false;

    final id = autor['id'] ?? autor['usuarioId'];

    return id?.toString() == usuarioId.toString();
  }

  Future<void> _selecionarFotoPerfil() async {
    if (!_ehMeuPerfil || _usuario == null || _uploadandoImagem) {
      return;
    }

    try {
      final arquivo = await _picker.pickImage(source: ImageSource.gallery);

      if (arquivo == null) return;

      setState(() => _uploadandoImagem = true);

      await _usuarioService.atualizarFoto(arquivo);

      if (!mounted) return;

      await _carregarPerfil();

      if (!mounted) return;

      _mostrarMensagem('Foto de perfil atualizada com sucesso!');
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        e.toString().replaceFirst('Exception: ', ''),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() => _uploadandoImagem = false);
      }
    }
  }

  Future<void> _selecionarTemplate() async {
    if (!_ehMeuPerfil || _usuario == null || _uploadandoImagem) {
      return;
    }

    try {
      final arquivo = await _picker.pickImage(source: ImageSource.gallery);

      if (arquivo == null) return;

      setState(() => _uploadandoImagem = true);

      await _usuarioService.atualizarTemplate(_usuario!.id, arquivo);

      if (!mounted) return;

      await _carregarPerfil();

      if (!mounted) return;

      _mostrarMensagem('Template atualizado com sucesso!');
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        e.toString().replaceFirst('Exception: ', ''),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() => _uploadandoImagem = false);
      }
    }
  }

  Future<void> _salvarBio() async {
    if (!_ehMeuPerfil || _usuario == null || _salvando) {
      return;
    }

    setState(() => _salvando = true);

    try {
      final usuarioAtualizado = await _usuarioService.atualizarUsuario(
        usuarioId: _usuario!.id,
        bio: _bioController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _usuario = usuarioAtualizado;
        _bioController.text = usuarioAtualizado.bio ?? '';
        _estatisticasFuture = _carregarEstatisticas(usuarioAtualizado);
        _salvando = false;
      });

      Navigator.pop(context);
      _mostrarMensagem('Perfil atualizado com sucesso!');
    } catch (e) {
      if (!mounted) return;

      setState(() => _salvando = false);

      _mostrarMensagem(
        e.toString().replaceFirst('Exception: ', ''),
        erro: true,
      );
    }
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _abrirEdicao() {
    if (!_ehMeuPerfil || _usuario == null) return;

    _bioController.text = _usuario!.bio ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Editar Perfil',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF18213D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Atualize sua bio',
                    style: TextStyle(color: Color(0xFF817980)),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Bio',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18213D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: 'Escreva uma descrição sobre você...',
                      filled: true,
                      fillColor: const Color(0xFFFFF7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF3F7A),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _salvarBio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF3F7A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Salvar alterações'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _tipoUsuario(String tipo) {
    switch (tipo) {
      case 'ADMINISTRADOR':
        return 'Administradora';
      case 'VERIFICADO':
        return 'Verificado';
      default:
        return 'Usuário';
    }
  }

  String _montarUrlImagem(String? caminho) {
    if (caminho == null || caminho.isEmpty) return '';

    if (caminho.startsWith('http://') || caminho.startsWith('https://')) {
      return caminho;
    }

    if (caminho.startsWith('/')) {
      return '${ApiConstants.baseUrl}$caminho';
    }

    return '${ApiConstants.baseUrl}/$caminho';
  }

  Widget _fotoPadrao({bool carregando = false}) {
    return Container(
      width: 112,
      height: 112,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFE1EA),
      ),
      child: carregando
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFEF3F7A),
              ),
            )
          : Center(
              child: Text(
                _usuario?.nome.isNotEmpty == true
                    ? _usuario!.nome[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEF3F7A),
                ),
              ),
            ),
    );
  }

  Widget _fotoPerfil() {
    final url = _montarUrlImagem(_usuario?.fotoPerfil);

    Widget foto = url.isEmpty
        ? _fotoPadrao()
        : Image.network(
            url,
            width: 112,
            height: 112,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _fotoPadrao();
            },
            loadingBuilder: (context, child, progresso) {
              if (progresso == null) return child;
              return _fotoPadrao(carregando: true);
            },
          );

    return ClipOval(
      child: Stack(
        alignment: Alignment.center,
        children: [
          foto,
          if (_uploadandoImagem)
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.45),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _templatePadrao() {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC92768), Color(0xFFEF3F7A), Color(0xFFFF709F)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -45,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _template() {
    final url = _montarUrlImagem(_usuario?.template);

    final template = url.isEmpty
        ? _templatePadrao()
        : Image.network(
            url,
            width: double.infinity,
            height: 190,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _templatePadrao();
            },
          );

    return Stack(
      children: [
        template,
        if (_uploadandoImagem)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
        if (_ehMeuPerfil)
          Positioned(
            right: 14,
            bottom: 14,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _uploadandoImagem ? null : _selecionarTemplate,
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 21,
                ),
                tooltip: 'Alterar template',
              ),
            ),
          ),
      ],
    );
  }

  Widget _informacaoCard({
    required String numero,
    required String titulo,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xFFF1E7EA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.045),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icone, color: const Color(0xFFEF3F7A), size: 21),
                const SizedBox(height: 5),
                Text(
                  numero,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF18213D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF817980),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirAtividades(TipoAtividadePerfil tipo) {
    if (_usuario == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AtividadesPerfilScreen(usuarioId: _usuario!.id, tipo: tipo),
      ),
    );
  }

  Widget _cardsEstatisticas() {
    final future = _estatisticasFuture;

    if (future == null) return const SizedBox.shrink();

    return FutureBuilder<_EstatisticasPerfil>(
      future: future,
      builder: (context, snapshot) {
        final estatisticas = snapshot.data;

        return Row(
          children: [
            _informacaoCard(
              numero: estatisticas?.noticias.toString() ?? '...',
              titulo: 'Notícias',
              icone: Icons.newspaper_outlined,
              onTap: () {
                _abrirAtividades(TipoAtividadePerfil.noticias);
              },
            ),
            const SizedBox(width: 10),
            _informacaoCard(
              numero: estatisticas?.publicacoes.toString() ?? '...',
              titulo: 'Publicações',
              icone: Icons.article_outlined,
              onTap: () {
                _abrirAtividades(TipoAtividadePerfil.publicacoes);
              },
            ),
            const SizedBox(width: 10),
            _informacaoCard(
              numero: estatisticas?.curtidas.toString() ?? '...',
              titulo: 'Curtidas feitas',
              icone: Icons.favorite_border,
              onTap: () {
                _abrirAtividades(TipoAtividadePerfil.curtidas);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFEF3F7A),
          strokeWidth: 2.5,
        ),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 45, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Não foi possível carregar o perfil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18213D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF817980)),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _carregarPerfil,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_usuario == null) {
      return const Center(child: Text('Usuário não encontrado.'));
    }

    final empresa = _usuario!.empresa;

    return RefreshIndicator(
      color: const Color(0xFFEF3F7A),
      onRefresh: _carregarPerfil,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: !_ehMeuPerfil || _uploadandoImagem
                    ? null
                    : _selecionarTemplate,
                child: _template(),
              ),
              Positioned(
                bottom: -57,
                child: GestureDetector(
                  onTap: !_ehMeuPerfil || _uploadandoImagem
                      ? null
                      : _selecionarFotoPerfil,
                  child: Container(
                    width: 126,
                    height: 126,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 16,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: _fotoPerfil(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 73),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  _usuario!.nome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF18213D),
                  ),
                ),
                const SizedBox(height: 7),
                if (empresa != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.business_outlined,
                        size: 16,
                        color: Color(0xFF817980),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          empresa['nome']?.toString() ?? '',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF817980),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: (_usuario!.bio ?? '').isNotEmpty
                      ? Text(
                          _usuario!.bio!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF817980),
                          ),
                        )
                      : const Text(
                          'Este usuário ainda não adicionou uma bio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFAAA3A8),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4EC),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _tipoUsuario(_usuario!.tipo),
                    style: const TextStyle(
                      color: Color(0xFFEF3F7A),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _cardsEstatisticas(),
                const SizedBox(height: 22),
                if (_ehMeuPerfil)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _abrirEdicao,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text(
                        'Editar Perfil',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF3F7A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 35),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      appBar: AppBar(
        title: Text(
          _ehMeuPerfil ? 'Meu Perfil' : 'Perfil',
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

class _EstatisticasPerfil {
  final int noticias;
  final int publicacoes;
  final int curtidas;

  const _EstatisticasPerfil({
    required this.noticias,
    required this.publicacoes,
    required this.curtidas,
  });
}
