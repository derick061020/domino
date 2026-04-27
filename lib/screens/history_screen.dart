import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_service.dart';
import '../languages/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final GameService _gameService = GameService();

  String _localizedGameName(String rawName, AppLocalizations loc) {
    if (rawName == 'Partida Rápida' || rawName == 'Quick Game' || rawName == 'Jogo Rápido') {
      return loc.get('quick_game');
    }
    return rawName;
  }

  String _localizedPlayerName(String rawName, AppLocalizations loc) {
    final defaults = {
      'Jugador 1': 1,
      'Jugador 2': 2,
      'Jugador 3': 3,
      'Player 1': 1,
      'Player 2': 2,
      'Player 3': 3,
      'Jogador 1': 1,
      'Jogador 2': 2,
      'Jogador 3': 3,
    };
    final number = defaults[rawName];
    if (number != null) {
      return '${loc.get('player')} $number';
    }
    return rawName;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D44),
        elevation: 0,
        title: Text(
          loc.get('games_history'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE53935)),
        ),
      ),
      body: FutureBuilder(
        future: _gameService.getGames(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            );
          }
          
          final games = snapshot.data as List<DominoGame>;
          if (games.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.get('no_saved_games'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.get('play_to_see_games'),
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D44).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: game.isCompleted 
                        ? const Color(0xFF4CAF50).withOpacity(0.3)
                        : const Color(0xFFE53935).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header de la partida
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _localizedGameName(game.name, loc),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: game.isCompleted 
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            game.isCompleted ? loc.get('finished') : loc.get('in_progress'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Fecha y hora
                    Text(
                      '${game.createdAt.day.toString().padLeft(2, '0')}/${game.createdAt.month.toString().padLeft(2, '0')}/${game.createdAt.year.toString()} - ${game.createdAt.hour.toString().padLeft(2, '0')}:${game.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Puntuaciones horizontales
                    _buildScoresRow(game),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScoresRow(DominoGame game) {
    // Crear lista de jugadores que tienen puntos
    final players = [
      {'name': game.player1Name, 'score': game.player1Score},
      {'name': game.player2Name, 'score': game.player2Score},
      {'name': game.player3Name, 'score': game.player3Score},
      {'name': game.player4Name, 'score': game.player4Score},
    ];
    
    // Filtrar jugadores que tienen puntos o son los primeros 2
    final activePlayers = players.where((player) => (player['score']! as int) > 0).toList();
    if (activePlayers.isEmpty) {
      // Si nadie tiene puntos, mostrar los primeros 2 jugadores
      activePlayers.addAll(players.take(2));
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE53935).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: List.generate(activePlayers.length, (index) {
          final player = activePlayers[index];
          final isLast = index == activePlayers.length - 1;
          
          return [
            Expanded(
              child: Column(
                children: [
                  Text(
                    _localizedPlayerName(player['name'] as String, AppLocalizations.of(context)),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${player['score']} ${AppLocalizations.of(context).get('pts')}',
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: const Color(0xFFE53935).withOpacity(0.3),
              ),
          ];
        }).expand((e) => e).toList(),
      ),
    );
  }
}
