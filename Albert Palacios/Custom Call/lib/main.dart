import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'estado_app.dart';

Future<void> main() async {
  // En escritorio se configura la ventana para que tenga un tamaño mínimo.
  // En Chrome o móvil esta parte se ignora.
  try {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      WidgetsFlutterBinding.ensureInitialized();
      await WindowManager.instance.ensureInitialized();
      windowManager.waitUntilReadyToShow().then((_) async {
        await windowManager.setMinimumSize(const Size(900, 600));
        await windowManager.setTitle('Asistente de dibujo IA');
        await windowManager.show();
        await windowManager.focus();
      });
    }
  } catch (_) {
    // Si window_manager falla en web, la app puede continuar igualmente.
  }

  // Provider permite compartir EstadoApp con toda la aplicación.
  runApp(
    ChangeNotifierProvider(
      create: (_) => EstadoApp(),
      child: const App(),
    ),
  );
}
