import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';
import '../services/game_service.dart';
import '../services/domino_vision_service.dart';
import '../languages/app_localizations.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

class GameScreen extends StatefulWidget {
  final DominoGame game;

  const GameScreen({super.key, required this.game});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameService _gameService = GameService();
  final DominoVisionService _visionService = DominoVisionService();
  late DominoGame _currentGame;
  bool _isLoading = false;
  String _selectedBackground = 'default';
  int _maxPoints = 200; // Puntos para ganar
  int _playerCount = 2; // Número de jugadores

  @override
  void initState() {
    super.initState();
    _currentGame = widget.game;
    _loadBackground();
  }

  Future<void> _loadBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final background = prefs.getString('background') ?? 'default';
    final maxPoints = prefs.getInt('maxPoints') ?? 200;
    final playerCount = prefs.getInt('playerCount') ?? 2;
    print('Loading background: $background'); // Debug
    setState(() {
      _selectedBackground = background;
      _maxPoints = maxPoints;
      _playerCount = playerCount;
    });
  }

  Future<Map<String, String>> _loadPlayerNames() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'player1Name': prefs.getString('player1Name') ?? 'Home',
      'player2Name': prefs.getString('player2Name') ?? 'Jugador 1',
      'player3Name': prefs.getString('player3Name') ?? 'Jugador 2',
      'player4Name': prefs.getString('player4Name') ?? 'Jugador 3',
    };
  }

  Future<void> _saveGame() async {
    setState(() => _isLoading = true);
    await _gameService.saveGame(_currentGame);
    setState(() => _isLoading = false);
  }

  void _addPointsToPlayer(int player, int points) {
    setState(() {
      final newPlayer1Rounds = [..._currentGame.player1Rounds];
      final newPlayer2Rounds = [..._currentGame.player2Rounds];
      final newPlayer3Rounds = [..._currentGame.player3Rounds];
      final newPlayer4Rounds = [..._currentGame.player4Rounds];

      // Siempre crear una nueva ronda para cada puntaje agregado
      newPlayer1Rounds.add(player == 1 ? points : 0);
      newPlayer2Rounds.add(player == 2 ? points : 0);
      newPlayer3Rounds.add(player == 3 ? points : 0);
      newPlayer4Rounds.add(player == 4 ? points : 0);

      _currentGame = _currentGame.copyWith(
        player1Rounds: newPlayer1Rounds,
        player2Rounds: newPlayer2Rounds,
        player3Rounds: newPlayer3Rounds,
        player4Rounds: newPlayer4Rounds,
        lastPlayed: DateTime.now(),
      );
    });
  }

  void _showAddPointsDialog(int player) {
    final controller = TextEditingController();
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          '${localizations.get('add_points')} - ${player == 1 ? _currentGame.player1Name : player == 2 ? _currentGame.player2Name : player == 3 ? _currentGame.player3Name : _currentGame.player4Name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  final currentValue = int.tryParse(controller.text) ?? 0;
                  controller.text = (currentValue - 10 >= 0 ? currentValue - 10 : 0).toString();
                },
                icon: const Icon(Icons.remove, color: Color(0xFFE53935)),
                iconSize: 20,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '',
                    hintStyle: TextStyle(
                      color: Colors.white24,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final currentValue = int.tryParse(controller.text) ?? 0;
                  controller.text = (currentValue + 10).toString();
                },
                icon: const Icon(Icons.add, color: Color(0xFFE53935)),
                iconSize: 20,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.get('cancel'), style: const TextStyle(color: Color(0xFFE53935))),
          ),
          ElevatedButton(
            onPressed: () async {
              final points = int.tryParse(controller.text);
              if (points != null && points > 0) {
                _addPointsToPlayer(player, points);
                await _saveGame();
                Navigator.pop(context);
                _checkWinCondition();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              elevation: 4,
              shadowColor: const Color(0xFFE53935).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              localizations.get('add'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      // Se ejecuta cuando el popup se cierra por cualquier motivo
      _checkWinCondition();
    });
  }

  void _checkWinCondition() {
    if (_currentGame.player1Score >= _maxPoints || 
        _currentGame.player2Score >= _maxPoints || 
        _currentGame.player3Score >= _maxPoints || 
        _currentGame.player4Score >= _maxPoints) {
      // Marcar la partida como completada inmediatamente
      setState(() {
        _currentGame = _currentGame.copyWith(isCompleted: true);
      });
      _saveGame();
      _showGameFinishedDialog();
    }
  }

  void _showGameFinishedDialog() {
    final localizations = AppLocalizations.of(context);
    final winner = _currentGame.winner;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, _) {
          return _VictoryScreen(
            winner: winner,
            isTie: winner == 'Empate',
            localizations: localizations,
            maxPoints: _maxPoints,
            game: _currentGame,
            onRestart: () => _resetAndStartNewGame(),
          );
        },
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    ).then((_) {
      _saveAndResetGame();
    });
  }

  void _saveAndResetGame() async {
    // La partida ya está marcada como completada en _checkWinCondition
    // Cargar nombres de jugadores guardados
    final playerNames = await _loadPlayerNames();
    
    // Crear nueva partida y reemplazar la pantalla
    final newGame = DominoGame(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Partida Rápida',
      createdAt: DateTime.now(),
      player1Rounds: [],
      player2Rounds: [],
      player3Rounds: [],
      player4Rounds: [],
      player1Name: playerNames['player1Name']!,
      player2Name: playerNames['player2Name']!,
      player3Name: playerNames['player3Name']!,
      player4Name: playerNames['player4Name']!,
    );

    // Reemplazar la pantalla actual con la nueva partida
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(game: newGame),
      ),
    );
  }

  void _resetAndStartNewGame() async {
    // Guardar la partida actual antes de reiniciar
    await _saveGame();
    
    // Cargar nombres de jugadores guardados
    final playerNames = await _loadPlayerNames();
    
    // Crear nueva partida
    final newGame = DominoGame(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Partida Rápida',
      createdAt: DateTime.now(),
      player1Rounds: [],
      player2Rounds: [],
      player3Rounds: [],
      player4Rounds: [],
      player1Name: playerNames['player1Name']!,
      player2Name: playerNames['player2Name']!,
      player3Name: playerNames['player3Name']!,
      player4Name: playerNames['player4Name']!,
    );

    // Reemplazar la pantalla actual con la nueva partida
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(game: newGame),
      ),
    );
  }

  void _showMaxPointsDialog() {
    final controller = TextEditingController(text: _maxPoints.toString());
    
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          loc.get('points_to_win'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  final currentValue = int.tryParse(controller.text) ?? _maxPoints;
                  controller.text = (currentValue - 10 >= 50 ? currentValue - 10 : 50).toString();
                },
                icon: const Icon(Icons.remove, color: Color(0xFFE53935)),
                iconSize: 20,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '200',
                    hintStyle: TextStyle(
                      color: Colors.white24,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final currentValue = int.tryParse(controller.text) ?? _maxPoints;
                  controller.text = (currentValue + 10).toString();
                },
                icon: const Icon(Icons.add, color: Color(0xFFE53935)),
                iconSize: 20,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.get('cancel'), style: const TextStyle(color: Color(0xFFE53935))),
          ),
          ElevatedButton(
            onPressed: () async {
              final points = int.tryParse(controller.text);
              if (points != null && points > 0) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('maxPoints', points);
                setState(() {
                  _maxPoints = points;
                });
                _checkWinCondition();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              elevation: 4,
              shadowColor: const Color(0xFFE53935).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final points = int.tryParse(controller.text);
                  if (points != null && points > 0) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('maxPoints', points);
                    setState(() {
                      _maxPoints = points;
                    });
                    _checkWinCondition();
                    Navigator.pop(context);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.2),
                child: Text(
                  loc.get('save'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerCountDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          loc.get('player_count'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [2, 3, 4].map((count) {
            return RadioListTile<int>(
              value: count,
              groupValue: _playerCount,
              onChanged: (value) async {
                if (value != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('playerCount', value);
                  setState(() {
                    _playerCount = value;
                  });
                  Navigator.pop(context);
                  // Reiniciar partida con nuevo número de jugadores
                  _restartGameWithNewPlayerCount();
                }
              },
              title: Text(
                '$count ${loc.get('players_count')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              activeColor: const Color(0xFFE53935),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _restartGameWithNewPlayerCount() async {
    // Cargar nombres de jugadores guardados
    final playerNames = await _loadPlayerNames();
    
    // Crear nueva partida con el número de jugadores actualizado
    final newGame = DominoGame(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Partida Rápida',
      createdAt: DateTime.now(),
      player1Rounds: [],
      player2Rounds: [],
      player3Rounds: [],
      player4Rounds: [],
      player1Name: playerNames['player1Name']!,
      player2Name: playerNames['player2Name']!,
      player3Name: playerNames['player3Name']!,
      player4Name: playerNames['player4Name']!,
    );

    // Reemplazar la pantalla actual con la nueva partida
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(game: newGame),
      ),
    );
  }

  Widget _buildTwoPlayerLayout() {
    return Column(
      children: [
        // Panel de configuración (discreto)
        _buildConfigPanel(),
        // Layout horizontal para 2 jugadores
        Expanded(
          child: Row(
            children: [
              // Jugador 1
              Expanded(
                child: _buildPlayerSection(1, _currentGame.player1Name, _currentGame.player1Score),
              ),
              // Separador
              Container(
                width: 2,
                color: Colors.transparent,
              ),
              // Jugador 2
              Expanded(
                child: _buildPlayerSection(2, _currentGame.player2Name, _currentGame.player2Score),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultiPlayerLayout() {
    return Column(
      children: [
        // Panel de configuración (discreto)
        _buildConfigPanel(),
        // Grid 2x2 para 3-4 jugadores
        Expanded(
          child: Column(
            children: [
              // Primera fila
              Expanded(
                child: Row(
                  children: [
                    // Jugador 1
                    Expanded(
                      child: _buildPlayerSection(1, _currentGame.player1Name, _currentGame.player1Score),
                    ),
                    // Separador
                    Container(
                      width: 2,
                      color: Colors.transparent,
                    ),
                    // Jugador 2
                    Expanded(
                      child: _buildPlayerSection(2, _currentGame.player2Name, _currentGame.player2Score),
                    ),
                  ],
                ),
              ),
              // Separador horizontal
              Container(
                height: 2,
                color: Colors.transparent,
              ),
              // Segunda fila
              Expanded(
                child: Row(
                  children: [
                    // Jugador 3
                    if (_playerCount >= 3)
                      Expanded(
                        child: _buildPlayerSection(3, _currentGame.player3Name, _currentGame.player3Score),
                      ),
                    // Separador
                    if (_playerCount >= 3)
                      Container(
                        width: 2,
                        color: Colors.transparent,
                      ),
                    // Jugador 4 o espacio vacío
                    if (_playerCount >= 4)
                      Expanded(
                        child: _buildPlayerSection(4, _currentGame.player4Name, _currentGame.player4Score),
                      )
                    else if (_playerCount == 3)
                      Expanded(
                        child: Container(), // Espacio vacío para centrar
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Puntos para ganar (botón más grande)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showMaxPointsDialog,
              borderRadius: BorderRadius.circular(8),
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: const Color(0xFFE53935).withOpacity(0.2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE53935).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag,
                      color: const Color(0xFFE53935),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_maxPoints pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 30,
            width: 2,
            color: Colors.white.withOpacity(0.1),
          ),
          // Número de jugadores (botón más grande)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showPlayerCountDialog,
              borderRadius: BorderRadius.circular(8),
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: const Color(0xFFE53935).withOpacity(0.2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE53935).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people,
                      color: const Color(0xFFE53935),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_playerCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPlayerNameDialog(int playerNumber, String currentName) {
    final controller = TextEditingController(text: currentName);
    final localizations = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          '${localizations.get('edit_name')} - ${localizations.get('player')} $playerNumber',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: localizations.get('enter_name'),
            hintStyle: const TextStyle(
              color: Colors.white24,
              fontFamily: 'Poppins',
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE53935)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE53935)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.get('cancel'), style: const TextStyle(color: Color(0xFFE53935))),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                // Guardar el nombre en SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('player${playerNumber}Name', newName);
                
                // Actualizar el juego actual
                setState(() {
                  switch (playerNumber) {
                    case 1:
                      _currentGame = _currentGame.copyWith(player1Name: newName);
                      break;
                    case 2:
                      _currentGame = _currentGame.copyWith(player2Name: newName);
                      break;
                    case 3:
                      _currentGame = _currentGame.copyWith(player3Name: newName);
                      break;
                    case 4:
                      _currentGame = _currentGame.copyWith(player4Name: newName);
                      break;
                  }
                });
                
                await _saveGame();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: Text(localizations.get('save')),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSection(int playerNumber, String playerName, int score) {
    final localizations = AppLocalizations.of(context);
    final rounds = playerNumber == 1
        ? _currentGame.player1Rounds
        : playerNumber == 2
            ? _currentGame.player2Rounds
            : playerNumber == 3
                ? _currentGame.player3Rounds
                : _currentGame.player4Rounds;

    final scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients && scrollController.position.maxScrollExtent > 0) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Nombre del jugador + editar (compacto)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  playerName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showEditPlayerNameDialog(playerNumber, playerName),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFFE53935),
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Puntuación con fondo negro translúcido
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Botón de agregar puntos (compacto)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showAddPointsDialog(playerNumber),
              borderRadius: BorderRadius.circular(6),
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: const Color(0xFFE53935).withOpacity(0.5),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      localizations.get('add'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Historial de rondas - GRANDE y visible
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE53935).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.get('round_history'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: rounds.length,
                      itemBuilder: (context, index) {
                        final points = rounds[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              // Número de ronda
                              Text(
                                'R${index + 1}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Puntos
                              Expanded(
                                child: Text(
                                  points > 0 ? '+$points' : '-',
                                  style: TextStyle(
                                    color: points > 0
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.4),
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              // Botón eliminar
                              GestureDetector(
                                onTap: () => _deleteRound(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Color(0xFFE53935),
                                    size: 16,
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
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        border: Border(
          top: BorderSide(color: const Color(0xFFE53935).withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Historial
          _buildBottomBarItem(
            icon: Icons.history,
            label: AppLocalizations.of(context).get('history'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HistoryScreen(),
              ),
            ),
          ),
          // Cámara - Solo para 2 jugadores
          if (_playerCount == 2)
            _buildBottomBarItem(
              icon: Icons.camera_alt,
              label: AppLocalizations.of(context).get('scan'),
              onTap: () => _captureAndDetectPoints(),
            ),
          // Reiniciar
          _buildBottomBarItem(
            icon: Icons.refresh,
            label: AppLocalizations.of(context).get('restart'),
            onTap: () => _showResetDialog(),
          ),
          // Premium
          _buildBottomBarItem(
            icon: Icons.star,
            label: AppLocalizations.of(context).get('premium'),
            onTap: () => _showPremiumDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0xFFE53935).withOpacity(0.3),
        highlightColor: const Color(0xFFE53935).withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFFE53935),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 10,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          loc.get('restart_game'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          loc.get('restart_confirm'),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.get('cancel'), style: const TextStyle(color: Color(0xFFE53935))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAndStartNewGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              elevation: 4,
              shadowColor: const Color(0xFFE53935).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _resetAndStartNewGame();
                },
                borderRadius: BorderRadius.circular(8),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.2),
                child: Text(
                  loc.get('restart'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          loc.get('premium_title'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star,
              color: Color(0xFFE53935),
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              loc.get('unlock_premium'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.get('premium_features'),
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.get('coming_soon'),
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.get('close'), style: const TextStyle(color: Color(0xFFE53935))),
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

  void _deleteRound(int roundIndex) {
    setState(() {
      final p1Rounds = List<int>.from(_currentGame.player1Rounds);
      final p2Rounds = List<int>.from(_currentGame.player2Rounds);
      final p3Rounds = List<int>.from(_currentGame.player3Rounds);
      final p4Rounds = List<int>.from(_currentGame.player4Rounds);

      if (roundIndex < p1Rounds.length) p1Rounds.removeAt(roundIndex);
      if (roundIndex < p2Rounds.length) p2Rounds.removeAt(roundIndex);
      if (roundIndex < p3Rounds.length) p3Rounds.removeAt(roundIndex);
      if (roundIndex < p4Rounds.length) p4Rounds.removeAt(roundIndex);

      _currentGame = _currentGame.copyWith(
        player1Rounds: p1Rounds,
        player2Rounds: p2Rounds,
        player3Rounds: p3Rounds,
        player4Rounds: p4Rounds,
        lastPlayed: DateTime.now(),
      );
    });
    _saveGame();
  }

  Widget _buildBackground() {
    print('Building background with: $_selectedBackground'); // Debug
    
    if (_selectedBackground == 'default') {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E1E2E),
              Color(0xFF2D2D44),
            ],
          ),
        ),
      );
    }

    // Obtener la extensión correcta del archivo
    String imagePath = _getBackgroundImagePath(_selectedBackground);
    
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover, // Usar cover para llenar el espacio
          repeat: ImageRepeat.repeat, // Repetir imagen si es pequeña
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
        ),
      ),
    );
  }

  String _getBackgroundImagePath(String backgroundId) {
    // Mapear los IDs a las rutas correctas de archivo
    switch (backgroundId) {
      case 'cuban_flag':
        return 'assets/backgrounds/A0iScru-cuban-flag-wallpaper.jpg';
      case 'spanish_flag':
        return 'assets/backgrounds/E3oulkw-spanish-flag-wallpaper.jpg';
      case 'colombian_flag':
        return 'assets/backgrounds/wp11025257-colombian-flag-wallpapers.jpg';
      case 'mexican_flag':
        return 'assets/backgrounds/wp15254308-flag-of-mexico-wallpapers.jpg';
      case 'puerto_rico_flag':
        return 'assets/backgrounds/wp2465860-puerto-rico-flag-wallpapers.png';
      case 'panama_flag':
        return 'assets/backgrounds/wp3607255-panama-flag-wallpapers.jpg';
      case 'venezuela_flag':
        return 'assets/backgrounds/wp4209041-venezuela-flag-wallpapers.jpg';
      case 'costa_rica_flag':
        return 'assets/backgrounds/wp4209288-costa-rica-flag-wallpapers.jpg';
      case 'ecuador_flag':
        return 'assets/backgrounds/wp4209455-ecuador-flag-wallpapers.jpg';
      case 'dominican_flag':
        return 'assets/backgrounds/wp4209528-dominican-republic-flag-wallpapers.jpg';
      case 'jamaican':
        return 'assets/backgrounds/eN2cTld-jamaican-wallpaper.jpg';
      case 'nicaragua':
        return 'assets/backgrounds/wp2231756-nicaragua-wallpapers.jpg';
      case 'italian':
        return 'assets/backgrounds/wp6493991-phone-italian-wallpapers.jpg';
      case 'wine':
        return 'assets/backgrounds/wp15058984-4k-wine-wallpapers.webp';
      case 'gangster_money':
        return 'assets/backgrounds/wp13311949-gangster-money-wallpapers.jpg';
      case 'portuguese_dog_1':
        return 'assets/backgrounds/wp5473857-portuguese-water-dog-wallpapers.jpg';
      case 'portuguese_dog_2':
        return 'assets/backgrounds/wp5473896-portuguese-water-dog-wallpapers.jpg';
      case 'blue_label':
        return 'assets/backgrounds/wp9536291-blue-label-wallpapers.jpg';
      case 'abstract_1':
        return 'assets/backgrounds/uwp3683989.jpeg';
      case 'abstract_2':
        return 'assets/backgrounds/uwp4318756.jpeg';
      case 'abstract_3':
        return 'assets/backgrounds/uwp4957374.jpeg';
      case 'abstract_4':
        return 'assets/backgrounds/uwp4957375.jpeg';
      case 'abstract_5':
        return 'assets/backgrounds/uwp4998270.jpeg';
      case 'abstract_6':
        return 'assets/backgrounds/uwp5000378.jpeg';
      case 'abstract_7':
        return 'assets/backgrounds/uwp5000914.jpeg';
      default:
        return 'assets/backgrounds/default.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          Scaffold(
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
                  const Text(
                    'DOMINO SCORE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                    // Recargar el fondo al volver de configuración
                    _loadBackground();
                  },
                  icon: const Icon(Icons.settings, color: Colors.white),
                  tooltip: AppLocalizations.of(context).get('settings'),
                ),
                
              ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
                : Column(
                    children: [
                      Expanded(
                        child: _playerCount <= 2
                            ? _buildTwoPlayerLayout()
                            : _buildMultiPlayerLayout(),
                      ),
                      _buildBottomBar(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPlayerSelectionDialog(DominoDetectionResult result) async {
    if (result.detectedPoints.isEmpty) return;
    final loc = AppLocalizations.of(context);

    // Si solo hay un valor de puntos, asignarlo directamente
    if (result.detectedPoints.length == 1) {
      final points = result.detectedPoints.first;
      final selectedPlayer = await _showSinglePointSelectionDialog(points);
      if (selectedPlayer != null) {
        _addPointsToPlayer(selectedPlayer, points);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.get('points_assigned')}: ${_getPlayerName(selectedPlayer)}: $points'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }

    // Si hay múltiples valores de puntos, mostrar diálogo para seleccionar
    final selectedData = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Row(
          children: [
            const Icon(Icons.calculate, color: Color(0xFFE53935), size: 24),
            const SizedBox(width: 8),
            Text(
              loc.get('assign_points'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
                ),
                child: Text(
                  result.analysisInfo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.get('select_points_player'),
                style: const TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 16),
              ...result.detectedPoints.asMap().entries.map((entry) {
                final index = entry.key;
                final points = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE53935).withOpacity(0.5),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'P${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$points ${loc.get('points')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      loc.get('assign_to_player'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    trailing: PopupMenuButton<int>(
                      icon: const Icon(Icons.person_add, color: Color(0xFFE53935)),
                      color: const Color(0xFF2D2D44),
                      onSelected: (player) {
                        Navigator.of(context).pop({
                          'player': player, 
                          'points': points
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 1, child: Text(_getPlayerName(1))),
                        if (_playerCount >= 2) PopupMenuItem(value: 2, child: Text(_getPlayerName(2))),
                        if (_playerCount >= 3) PopupMenuItem(value: 3, child: Text(_getPlayerName(3))),
                        if (_playerCount >= 4) PopupMenuItem(value: 4, child: Text(_getPlayerName(4))),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.get('cancel'), style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );

    if (selectedData != null) {
      final player = selectedData['player'] as int;
      final points = selectedData['points'] as int;
      _addPointsToPlayer(player, points);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.get('points_assigned')}: ${_getPlayerName(player)}: $points'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<int?> _showSinglePointSelectionDialog(int points) async {
    final loc = AppLocalizations.of(context);
    return await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          loc.get('assign_n_points').replaceAll('%d', '$points'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.get('select_player'),
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ...[1, 2, 3, 4].where((p) => p <= _playerCount).map((player) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE53935),
                child: Text(
                  '$player',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                _getPlayerName(player), 
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => Navigator.of(context).pop(player),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.get('cancel'), style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }


  String _getPlayerName(int player) {
    switch (player) {
      case 1:
        return _currentGame.player1Name;
      case 2:
        return _currentGame.player2Name;
      case 3:
        return _currentGame.player3Name;
      case 4:
        return _currentGame.player4Name;
      default:
        return '${AppLocalizations.of(context).get('player')} $player';
    }
  }

  Future<void> _captureAndDetectPoints() async {
    final loc = AppLocalizations.of(context);
    try {
      // Abrir cámara directamente
      final imagePath = await _visionService.captureImage();

      if (imagePath == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.get('could_not_get_image')),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
        return;
      }

      // Procesar imagen y detectar puntos
      setState(() => _isLoading = true);

      final result = await _visionService.detectDominoPoints(
        imagePath,
        loc: loc,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      // Mostrar resultado y confirmar
      final confirmedResult = await _visionService.showImageAnalysisDialog(context, result);

      if (confirmedResult != null && confirmedResult.detectedPoints.isNotEmpty) {
        await _showPlayerSelectionDialog(confirmedResult);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }
}

// ─── Victory Screen con fuegos artificiales y confetti ───

class _VictoryScreen extends StatefulWidget {
  final String winner;
  final bool isTie;
  final AppLocalizations localizations;
  final int maxPoints;
  final DominoGame game;
  final VoidCallback onRestart;

  const _VictoryScreen({
    required this.winner,
    required this.isTie,
    required this.localizations,
    required this.maxPoints,
    required this.game,
    required this.onRestart,
  });

  @override
  State<_VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<_VictoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fireworksController;
  late AnimationController _contentController;
  late AnimationController _pulseController;
  late Animation<double> _contentScale;
  late Animation<double> _contentOpacity;
  late Animation<double> _pulseAnimation;

  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();

    // Controlador de partículas (fuegos/confetti) - loop
    _fireworksController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _fireworksController.addListener(() {
      _updateParticles();
      setState(() {});
    });

    // Animación de entrada del contenido
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentScale = CurvedAnimation(
      parent: _contentController,
      curve: Curves.elasticOut,
    );
    _contentOpacity = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeIn,
    );

    // Pulso del trofeo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  bool _initialBurstDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialBurstDone) {
      _initialBurstDone = true;
      _spawnBurst();
    }
  }

  void _spawnBurst() {
    final size = MediaQuery.of(context).size;
    // Varios puntos de explosión
    for (int burst = 0; burst < 5; burst++) {
      final ox = _rng.nextDouble() * size.width;
      final oy = _rng.nextDouble() * size.height * 0.5;
      for (int i = 0; i < 20; i++) {
        _particles.add(_Particle(
          x: ox,
          y: oy,
          vx: (_rng.nextDouble() - 0.5) * 6,
          vy: (_rng.nextDouble() - 0.8) * 5,
          color: _randomBrightColor(),
          life: 0.7 + _rng.nextDouble() * 0.3,
          size: 3 + _rng.nextDouble() * 5,
          isConfetti: _rng.nextBool(),
          rotation: _rng.nextDouble() * 6.28,
          rotationSpeed: (_rng.nextDouble() - 0.5) * 0.3,
        ));
      }
    }
  }

  void _updateParticles() {
    final size = MediaQuery.of(context).size;

    // Actualizar existentes
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.06; // gravedad
      p.life -= 0.008;
      p.rotation += p.rotationSpeed;
    }
    _particles.removeWhere((p) => p.life <= 0 || p.y > size.height + 20);

    // Generar nuevos fuegos periódicamente
    if (_rng.nextDouble() < 0.08) {
      final ox = _rng.nextDouble() * size.width;
      final oy = _rng.nextDouble() * size.height * 0.4;
      for (int i = 0; i < 12; i++) {
        _particles.add(_Particle(
          x: ox,
          y: oy,
          vx: (_rng.nextDouble() - 0.5) * 5,
          vy: (_rng.nextDouble() - 0.7) * 4,
          color: _randomBrightColor(),
          life: 0.6 + _rng.nextDouble() * 0.4,
          size: 2 + _rng.nextDouble() * 4,
          isConfetti: _rng.nextBool(),
          rotation: _rng.nextDouble() * 6.28,
          rotationSpeed: (_rng.nextDouble() - 0.5) * 0.3,
        ));
      }
    }

    // Confetti cayendo desde arriba
    if (_rng.nextDouble() < 0.15) {
      _particles.add(_Particle(
        x: _rng.nextDouble() * size.width,
        y: -10,
        vx: (_rng.nextDouble() - 0.5) * 1.5,
        vy: 1.5 + _rng.nextDouble() * 2,
        color: _randomBrightColor(),
        life: 0.8 + _rng.nextDouble() * 0.2,
        size: 4 + _rng.nextDouble() * 6,
        isConfetti: true,
        rotation: _rng.nextDouble() * 6.28,
        rotationSpeed: (_rng.nextDouble() - 0.5) * 0.2,
      ));
    }
  }

  Color _randomBrightColor() {
    const colors = [
      Color(0xFFE53935), // rojo
      Color(0xFFFFD600), // dorado
      Color(0xFF00E676), // verde
      Color(0xFF2979FF), // azul
      Color(0xFFFF6D00), // naranja
      Color(0xFFAA00FF), // púrpura
      Color(0xFF00E5FF), // cyan
      Color(0xFFFF4081), // rosa
    ];
    return colors[_rng.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _fireworksController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.localizations;
    final game = widget.game;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fondo oscuro semi-transparente
          Container(color: Colors.black.withValues(alpha: 0.85)),

          // Partículas (fuegos artificiales + confetti)
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ParticlePainter(_particles),
          ),

          // Contenido central
          Center(
            child: FadeTransition(
              opacity: _contentOpacity,
              child: ScaleTransition(
                scale: _contentScale,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2D2D44), Color(0xFF1A1A2E)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE53935).withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trofeo animado
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Text(
                          widget.isTie ? '🤝' : '🏆',
                          style: const TextStyle(fontSize: 72),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Título
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFD600), Color(0xFFFF6D00)],
                        ).createShader(bounds),
                        child: Text(
                          loc.get('game_over'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nombre del ganador con glow
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE53935).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.isTie
                                  ? loc.get('tie')
                                  : '${widget.winner} ${loc.get('winner')}!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: widget.isTie ? Colors.white : const Color(0xFFFFD600),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                shadows: widget.isTie
                                    ? null
                                    : [
                                        Shadow(
                                          color: const Color(0xFFFFD600).withValues(alpha: 0.6),
                                          blurRadius: 12,
                                        ),
                                      ],
                              ),
                            ),
                            if (!widget.isTie) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${loc.get('reached_points')} ${widget.maxPoints}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Puntuaciones
                      Text(
                        loc.get('final_score'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildScoreRow(game.player1Name, game.player1Score, loc),
                      _buildScoreRow(game.player2Name, game.player2Score, loc),
                      if (game.player3Score > 0)
                        _buildScoreRow(game.player3Name, game.player3Score, loc),
                      if (game.player4Score > 0)
                        _buildScoreRow(game.player4Name, game.player4Score, loc),

                      const SizedBox(height: 24),

                      // Botón reiniciar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onRestart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFFE53935).withValues(alpha: 0.5),
                          ),
                          child: Text(
                            loc.get('restart'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String name, int score, AppLocalizations loc) {
    final isWinner = name == widget.winner && !widget.isTie;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isWinner)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Text('👑', style: TextStyle(fontSize: 14)),
            ),
          Text(
            '$name: $score ${loc.get('points')}',
            style: TextStyle(
              color: isWinner ? const Color(0xFFFFD600) : const Color(0xFFE53935),
              fontSize: isWinner ? 17 : 15,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modelo de partícula ───

class _Particle {
  double x, y, vx, vy, life, size, rotation, rotationSpeed;
  final Color color;
  final bool isConfetti;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.life,
    required this.size,
    required this.isConfetti,
    required this.rotation,
    required this.rotationSpeed,
  });
}

// ─── Painter de partículas ───

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: (p.life).clamp(0.0, 1.0));

      if (p.isConfetti) {
        // Confetti: rectángulos rotados
        canvas.save();
        canvas.translate(p.x, p.y);
        canvas.rotate(p.rotation);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
        canvas.restore();
      } else {
        // Fuegos artificiales: círculos brillantes
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(p.x, p.y), p.size * 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
