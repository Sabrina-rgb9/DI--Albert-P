import 'package:flutter/material.dart';
import 'screens/lobby_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PunchStarApp());
}

class PunchStarApp extends StatelessWidget {
  const PunchStarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Punch Star Arena',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const LobbyScreen(),
    );
  }
}
