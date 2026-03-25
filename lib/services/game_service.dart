import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';

class GameService {
  static const String _gamesKey = 'domino_games';

  Future<List<DominoGame>> getGames() async {
    final prefs = await SharedPreferences.getInstance();
    final gamesJson = prefs.getString(_gamesKey) ?? '[]';
    
    try {
      final List<dynamic> gamesList = json.decode(gamesJson);
      return gamesList.map((game) => DominoGame.fromJson(game)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveGame(DominoGame game) async {
    final games = await getGames();
    final existingIndex = games.indexWhere((g) => g.id == game.id);
    
    if (existingIndex >= 0) {
      games[existingIndex] = game.copyWith(lastPlayed: DateTime.now());
    } else {
      games.add(game);
    }
    
    await _saveGames(games);
  }

  Future<void> deleteGame(String gameId) async {
    final games = await getGames();
    games.removeWhere((g) => g.id == gameId);
    await _saveGames(games);
  }

  Future<void> _saveGames(List<DominoGame> games) async {
    final prefs = await SharedPreferences.getInstance();
    final gamesJson = json.encode(games.map((g) => g.toJson()).toList());
    await prefs.setString(_gamesKey, gamesJson);
  }

  Future<DominoGame> createNewGame({required String name, String player1Name = 'Jugador 1', String player2Name = 'Jugador 2'}) async {
    final game = DominoGame(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      player1Rounds: [],
      player2Rounds: [],
      player1Name: player1Name,
      player2Name: player2Name,
    );
    
    await saveGame(game);
    return game;
  }
}
