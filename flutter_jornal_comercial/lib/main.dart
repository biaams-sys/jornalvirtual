
import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'services/notificacao_service.dart';
import 'services/tema_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificacaoService.inicializar();

  runApp(const JornalApp());
}

class JornalApp extends StatelessWidget {
  const JornalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeData>(
      valueListenable: TemaService.temaAtual,
      builder: (context, tema, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Jornal Virtual',
          theme: tema,
          home: const LoginScreen(),
        );
      },
    );
  }
}
