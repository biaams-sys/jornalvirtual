
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/tema_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  final _authService = AuthService();

  bool _carregando = false;
  bool _mostrarSenha = false;
  String? _erro;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      setState(() {
        _erro = 'Preencha seu e-mail e sua senha.';
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await _authService.login(
        email: email,
        senha: senha,
      );

      // Carrega o tema correspondente à empresa do usuário.
      await TemaService.carregarTema();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cores.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: cores.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Icon(
                            Icons.newspaper_rounded,
                            size: 29,
                            color: cores.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'JORNAL VIRTUAL',
                          style: TextStyle(
                            color: cores.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: 38,
                          height: 3,
                          decoration: BoxDecoration(
                            color: cores.primary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 62),

                  Text(
                    'Bem-vindo!',
                    style: TextStyle(
                      color: cores.onSurface,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Entre na plataforma para acompanhar as notícias e publicações da sua empresa.',
                    style: TextStyle(
                      color: cores.onSurface.withValues(alpha: 0.65),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 35),

                  _buildLabel('E-mail', cores.onSurface),

                  const SizedBox(height: 9),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      hint: 'seuemail@email.com',
                      icon: Icons.mail_outline_rounded,
                      cores: cores,
                    ),
                  ),

                  const SizedBox(height: 22),

                  _buildLabel('Senha', cores.onSurface),

                  const SizedBox(height: 9),

                  TextField(
                    controller: _senhaController,
                    obscureText: !_mostrarSenha,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    decoration: _inputDecoration(
                      hint: 'Digite sua senha',
                      icon: Icons.lock_outline_rounded,
                      cores: cores,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() {
                            _mostrarSenha = !_mostrarSenha;
                          });
                        },
                        icon: Icon(
                          _mostrarSenha
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: cores.onSurface.withValues(alpha: 0.55),
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: cores.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _erro!,
                            style: TextStyle(
                              color: cores.error,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cores.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            cores.primary.withValues(alpha: 0.55),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: _carregando
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 42),

                  Center(
                    child: Text(
                      'Informação que conecta.',
                      style: TextStyle(
                        color: cores.onSurface.withValues(alpha: 0.55),
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String texto, Color cor) {
    return Text(
      texto,
      style: TextStyle(
        color: cor,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required ColorScheme cores,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: cores.onSurface.withValues(alpha: 0.4),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: cores.onSurface.withValues(alpha: 0.55),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: cores.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cores.outline.withValues(alpha: 0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cores.outline.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cores.primary,
          width: 1.5,
        ),
      ),
    );
  }
}
