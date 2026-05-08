import 'package:flutter/cupertino.dart';
import 'pantalla_principal.dart';

/// Widget raíz de la aplicación.
/// Se usa CupertinoApp para mantener un estilo parecido al proyecto de referencia.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: PantallaPrincipal(titulo: 'Asistente de dibujo IA'),
    );
  }
}
