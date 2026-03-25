import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_model.dart';
import '../services/game_service.dart';
import '../widgets/country_background_widget.dart';

class GameScreen extends StatefulWidget {
  final DominoGame game;

  const GameScreen({super.key, required this.game});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameService _gameService = GameService();
  late DominoGame _currentGame;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentGame = widget.game;
  }

  Future<void> _saveGame() async {
    setState(() => _isLoading = true);
    await _gameService.saveGame(_currentGame);
    setState(() => _isLoading = false);
  }

  void _showAddPointsDialog(int player) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          'Agregar puntos - ${player == 1 ? _currentGame.player1Name : _currentGame.player2Name}',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Puntos',
            labelStyle: TextStyle(color: Color(0xFFE53935)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE53935)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE53935)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFFE53935))),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text) ?? 0;
              if (value > 0) {
                setState(() {
                  if (player == 1) {
                    _currentGame = _currentGame.copyWith(
                      player1Rounds: [..._currentGame.player1Rounds, value],
                      lastPlayed: DateTime.now(),
                    );
                  } else {
                    _currentGame = _currentGame.copyWith(
                      player2Rounds: [..._currentGame.player2Rounds, value],
                      lastPlayed: DateTime.now(),
                    );
                  }
                });
                _saveGame();
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showFinishGameDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          'Finalizar Partida',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Deseas finalizar esta partida?',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        _currentGame.player1Name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_currentGame.player1Score} pts',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'VS',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _currentGame.player2Name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_currentGame.player2Score} pts',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFFE53935))),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _currentGame = _currentGame.copyWith(isCompleted: true);
              });
              await _saveGame();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _undoLastRound() {
    if (_currentGame.player1Rounds.isNotEmpty || _currentGame.player2Rounds.isNotEmpty) {
      setState(() {
        final p1Rounds = List<int>.from(_currentGame.player1Rounds);
        final p2Rounds = List<int>.from(_currentGame.player2Rounds);
        
        if (p2Rounds.length > p1Rounds.length) {
          p2Rounds.removeLast();
        } else if (p1Rounds.isNotEmpty) {
          p1Rounds.removeLast();
        }
        
        _currentGame = _currentGame.copyWith(
          player1Rounds: p1Rounds,
          player2Rounds: p2Rounds,
          lastPlayed: DateTime.now(),
        );
      });
      _saveGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxRounds = (_currentGame.player1Rounds.length > _currentGame.player2Rounds.length)
        ? _currentGame.player1Rounds.length
        : _currentGame.player2Rounds.length;

    return CountryBackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Image.asset(
                'assets/appLogo.png',
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentGame.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Ronda ${maxRounds + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (!_currentGame.isCompleted)
              IconButton(
                onPressed: _undoLastRound,
                icon: const Icon(Icons.undo, color: Color(0xFFE53935)),
                tooltip: 'Deshacer última ronda',
              ),
            if (!_currentGame.isCompleted)
              IconButton(
                onPressed: _showFinishGameDialog,
                icon: const Icon(Icons.flag, color: Colors.green),
                tooltip: 'Finalizar partida',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
            : Column(
                children: [
                  // Score Board
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF2D2D44), const Color(0xFF3A3A5C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: const Color(0xFFE53935),
                                    child: Text(
                                      _currentGame.player1Name.isNotEmpty
                                          ? _currentGame.player1Name[0].toUpperCase()
                                          : 'P',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _currentGame.player1Name,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53935),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_currentGame.player1Score}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE53935).withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'VS',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: const Color(0xFF4CAF50),
                                    child: Text(
                                      _currentGame.player2Name.isNotEmpty
                                          ? _currentGame.player2Name[0].toUpperCase()
                                          : 'P',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _currentGame.player2Name,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_currentGame.player2Score}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Rounds History
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D44).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Historial de Rondas',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (_currentGame.isCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Ganador: ${_currentGame.winner}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: maxRounds == 0
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.history,
                                          size: 60,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hay rondas jugadas aún',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey.shade300,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: maxRounds,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E1E2E),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE53935),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${index + 1}',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                index < _currentGame.player1Rounds.length
                                                    ? '${_currentGame.player1Rounds[index]} pts'
                                                    : '-',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade700,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'R${index + 1}',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                index < _currentGame.player2Rounds.length
                                                    ? '${_currentGame.player2Rounds[index]} pts'
                                                    : '-',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        floatingActionButton: _currentGame.isCompleted
            ? null
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'p1',
                    onPressed: () => _showAddPointsDialog(1),
                    backgroundColor: const Color(0xFFE53935),
                    icon: const Icon(Icons.add),
                    label: Text(_currentGame.player1Name),
                  ),
                  const SizedBox(width: 20),
                  FloatingActionButton.extended(
                    heroTag: 'p2',
                    onPressed: () => _showAddPointsDialog(2),
                    backgroundColor: const Color(0xFFE53935),
                    icon: const Icon(Icons.add),
                    label: Text(_currentGame.player2Name),
                  ),
                ],
              ),
      ),
    );
  }
}
