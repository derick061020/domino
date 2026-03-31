import 'package:flutter/material.dart';
import '../models/game_model.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(DominoScoreApp());
}

class DominoScoreApp extends StatelessWidget {
  const DominoScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Domino Score',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFF1E1E2E),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D2D44),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2D2D44),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFE53935),
          foregroundColor: Colors.white,
        ),
      ),
      home: GameScreen(
        game: DominoGame(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Partida Rápida',
          createdAt: DateTime.now(),
          player1Rounds: [],
          player2Rounds: [],
          player1Name: 'Home',
          player2Name: 'Jugador 1',
        ),
      ),
    );
  }
}