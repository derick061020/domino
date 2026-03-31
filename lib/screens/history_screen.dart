import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/game_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final GameService _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D44),
        elevation: 0,
        title: const Text(
          'Historial de Partidas',
          style: TextStyle(
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
                  const Text(
                    'No hay partidas guardadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Juega algunas partidas para verlas aquí',
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
                            game.name,
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
                            game.isCompleted ? 'Terminada' : 'En juego',
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
    // Calcular rondas máximas para mostrar
    int maxRounds = 0;
    maxRounds = maxRounds > game.player1Rounds.length ? maxRounds : game.player1Rounds.length;
    maxRounds = maxRounds > game.player2Rounds.length ? maxRounds : game.player2Rounds.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE53935).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Fila de nombres y puntuaciones totales
          Row(
            children: [
              // Jugador 1
              Expanded(
                child: Column(
                  children: [
                    Text(
                      game.player1Name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${game.player1Score} pts',
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
              // Separador
              Container(
                width: 2,
                height: 60,
                color: const Color(0xFFE53935).withOpacity(0.3),
              ),
              // Jugador 2
              Expanded(
                child: Column(
                  children: [
                    Text(
                      game.player2Name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${game.player2Score} pts',
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
              // Separador
              Container(
                width: 2,
                height: 60,
                color: const Color(0xFFE53935).withOpacity(0.3),
              ),
              // Jugador 3 (placeholder)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Jugador 3',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '0 pts',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              // Separador
              Container(
                width: 2,
                height: 60,
                color: const Color(0xFFE53935).withOpacity(0.3),
              ),
              // Jugador 4 (placeholder)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Jugador 4',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '0 pts',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (maxRounds > 0) ...[
            const SizedBox(height: 16),
            // Línea divisoria
            Container(
              height: 1,
              color: const Color(0xFFE53935).withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            // Historial de rondas (sin etiquetas R1, R2)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: maxRounds,
                itemBuilder: (context, index) {
                  final p1Score = index < game.player1Rounds.length ? game.player1Rounds[index] : 0;
                  final p2Score = index < game.player2Rounds.length ? game.player2Rounds[index] : 0;
                  
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE53935).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Puntuaciones de la ronda (sin etiqueta R1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              p1Score > 0 ? '+$p1Score' : '-',
                              style: TextStyle(
                                color: p1Score > 0 ? const Color(0xFFE53935) : Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              p2Score > 0 ? '+$p2Score' : '-',
                              style: TextStyle(
                                color: p2Score > 0 ? const Color(0xFF4CAF50) : Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
