import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/game_model.dart';
import '../services/game_service.dart';
import '../widgets/country_background_widget.dart';
import 'game_screen.dart';

class GameMenuScreen extends StatefulWidget {
  const GameMenuScreen({super.key});

  @override
  State<GameMenuScreen> createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  final GameService _gameService = GameService();
  List<DominoGame> _games = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    final games = await _gameService.getGames();
    setState(() {
      _games = games..sort((a, b) => (b.lastPlayed ?? b.createdAt).compareTo(a.lastPlayed ?? a.createdAt));
      _isLoading = false;
    });
  }

  void _showNewGameDialog() {
    final nameController = TextEditingController();
    final player1Controller = TextEditingController(text: 'Jugador 1');
    final player2Controller = TextEditingController(text: 'Jugador 2');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          'Nueva Partida',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre de la partida',
                labelStyle: TextStyle(color: Color(0xFFE53935)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE53935)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE53935)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: player1Controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre Jugador 1',
                labelStyle: TextStyle(color: Color(0xFFE53935)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE53935)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE53935)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: player2Controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre Jugador 2',
                labelStyle: TextStyle(color: Color(0xFFE53935)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE53935)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE53935)),
                ),
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
              if (nameController.text.trim().isNotEmpty) {
                final game = await _gameService.createNewGame(
                  name: nameController.text.trim(),
                  player1Name: player1Controller.text.trim(),
                  player2Name: player2Controller.text.trim(),
                );
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GameScreen(game: game)),
                ).then((_) => _loadGames());
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _continueGame(DominoGame game) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(game: game)),
    ).then((_) => _loadGames());
  }

  Future<void> _deleteGame(DominoGame game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          'Eliminar Partida',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${game.name}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFFE53935))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _gameService.deleteGame(game.id);
      _loadGames();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Text(
                'DOMINO SCORE',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE53935),
                ),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
            : _games.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.casino_outlined,
                          size: 120,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '¡No hay partidas aún!',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            color: Colors.grey.shade300,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Crea tu primera partida para empezar',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _games.length,
                    itemBuilder: (context, index) {
                      final game = _games[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          color: const Color(0xFF2D2D44).withOpacity(0.9),
                          child: InkWell(
                            onTap: () => _continueGame(game),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          game.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      if (game.isCompleted)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Finalizada',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              game.player1Name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            Text(
                                              '${game.player1Score} pts',
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE53935),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'VS',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              game.player2Name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            Text(
                                              '${game.player2Score} pts',
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(game.lastPlayed ?? game.createdAt),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (!game.isCompleted)
                                            IconButton(
                                              onPressed: () => _continueGame(game),
                                              icon: const Icon(Icons.play_arrow, color: Color(0xFFE53935)),
                                            ),
                                          IconButton(
                                            onPressed: () => _deleteGame(game),
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showNewGameDialog,
          icon: const Icon(Icons.add),
          label: const Text('Nueva Partida'),
        ),
      ),
    );
  }
}
