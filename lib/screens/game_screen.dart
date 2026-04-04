import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';
import '../services/game_service.dart';
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
                setState(() {
                  // Crear nueva ronda sincronizada para todos los jugadores
                  final newPlayer1Rounds = [..._currentGame.player1Rounds];
                  final newPlayer2Rounds = [..._currentGame.player2Rounds];
                  final newPlayer3Rounds = [..._currentGame.player3Rounds];
                  final newPlayer4Rounds = [..._currentGame.player4Rounds];
                  
                  // Agregar puntos al jugador seleccionado y 0 a los demás
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
                await _saveGame();
                Navigator.pop(context);
                
                // Verificar condición de victoria después de cerrar el popup
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final points = int.tryParse(controller.text);
                  if (points != null && points > 0) {
                    setState(() {
                      // Crear nueva ronda sincronizada para todos los jugadores
                      final newPlayer1Rounds = [..._currentGame.player1Rounds];
                      final newPlayer2Rounds = [..._currentGame.player2Rounds];
                      final newPlayer3Rounds = [..._currentGame.player3Rounds];
                      final newPlayer4Rounds = [..._currentGame.player4Rounds];
                      
                      // Agregar puntos al jugador seleccionado y 0 a los demás
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
                    await _saveGame();
                    Navigator.pop(context);
                    
                    // Verificar condición de victoria después de cerrar el popup
                    _checkWinCondition();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: const Color(0xFFE53935).withOpacity(0.2),
                child: Text(
                  localizations.get('add'),
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
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          '🎉 ${localizations.get('game_over')} 🎉',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Poppins',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    winner == 'Empate' ? localizations.get('tie') : '¡$winner ${localizations.get('winner')}!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    winner == 'Empate' ? localizations.get('no_winner') : '${localizations.get('reached_points')} $_maxPoints',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.get('final_score'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_currentGame.player1Name}: ${_currentGame.player1Score} ${localizations.get('points')}\n${_currentGame.player2Name}: ${_currentGame.player2Score} ${localizations.get('points')}${_currentGame.player3Score > 0 ? '\n${_currentGame.player3Name}: ${_currentGame.player3Score} ${localizations.get('points')}' : ''}${_currentGame.player4Score > 0 ? '\n${_currentGame.player4Name}: ${_currentGame.player4Score} ${localizations.get('points')}' : ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _resetAndStartNewGame(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 4,
              shadowColor: const Color(0xFFE53935).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _resetAndStartNewGame(),
                borderRadius: BorderRadius.circular(8),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    localizations.get('restart'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      // Se ejecuta cuando el popup de victoria se cierra por cualquier motivo
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
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text(
          'Puntos para ganar',
          style: TextStyle(
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
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFFE53935))),
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
                child: const Text(
                  'Guardar',
                  style: TextStyle(
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text(
          'Número de jugadores',
          style: TextStyle(
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
                '$count jugadores',
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
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Nombre del jugador con botón de editar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                playerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 8),
              // Botón de editar nombre
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showEditPlayerNameDialog(playerNumber, playerName),
                  borderRadius: BorderRadius.circular(4),
                  splashColor: const Color(0xFFE53935).withOpacity(0.3),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE53935).withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xFFE53935),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Puntuación (más pequeña)
          Text(
            '$score',
            style: const TextStyle(
              color: Color(0xFFE53935),
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            localizations.get('points'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          // Botón de agregar puntos (más pequeño)
          GestureDetector(
            onTap: () => _showAddPointsDialog(playerNumber),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showAddPointsDialog(playerNumber),
                borderRadius: BorderRadius.circular(8),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: const Color(0xFFE53935).withOpacity(0.5),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        localizations.get('add'),
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
          ),
          const SizedBox(height: 12),
          // Historial de rondas del jugador (con scroll)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.get('round_history'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView.builder(
                      itemCount: playerNumber == 1 
                          ? _currentGame.player1Rounds.length
                          : playerNumber == 2
                              ? _currentGame.player2Rounds.length
                              : playerNumber == 3
                                  ? _currentGame.player3Rounds.length
                                  : playerNumber == 4
                                      ? _currentGame.player4Rounds.length
                                      : 0,
                      itemBuilder: (context, index) {
                        final points = playerNumber == 1
                            ? _currentGame.player1Rounds[index]
                            : playerNumber == 2
                                ? _currentGame.player2Rounds[index]
                                : playerNumber == 3
                                    ? _currentGame.player3Rounds[index]
                                    : playerNumber == 4
                                        ? _currentGame.player4Rounds[index]
                                        : 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            points > 0 ? '+$points' : '-',
                            style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 10,
                              fontFamily: 'Poppins',
                            ),
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
            label: 'Historial',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HistoryScreen(),
              ),
            ),
          ),
          // Reiniciar
          _buildBottomBarItem(
            icon: Icons.refresh,
            label: 'Reiniciar',
            onTap: () => _showResetDialog(),
          ),
          // Premium
          _buildBottomBarItem(
            icon: Icons.star,
            label: 'Premium',
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text(
          'Reiniciar Partida',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: const Text(
          '¿Estás seguro de que quieres reiniciar la partida actual? Se perderán todos los puntos acumulados.',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFFE53935))),
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
                child: const Text(
                  'Reiniciar',
                  style: TextStyle(
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text(
          'Premium',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              color: Color(0xFFE53935),
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Funciones Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Próximamente disponibles...',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Color(0xFFE53935))),
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

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/backgrounds/$_selectedBackground.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
        ),
      ),
    );
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
                  tooltip: 'Configuración',
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
}
