class DominoGame {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? lastPlayed;
  final List<int> player1Rounds;
  final List<int> player2Rounds;
  final String player1Name;
  final String player2Name;
  final bool isCompleted;

  DominoGame({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lastPlayed,
    required this.player1Rounds,
    required this.player2Rounds,
    this.player1Name = 'Jugador 1',
    this.player2Name = 'Jugador 2',
    this.isCompleted = false,
  });

  int get player1Score => player1Rounds.fold(0, (a, b) => a + b);
  int get player2Score => player2Rounds.fold(0, (a, b) => a + b);
  
  String get winner {
    if (player1Score > player2Score) return player1Name;
    if (player2Score > player1Score) return player2Name;
    return 'Empate';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastPlayed': lastPlayed?.toIso8601String(),
      'player1Rounds': player1Rounds,
      'player2Rounds': player2Rounds,
      'player1Name': player1Name,
      'player2Name': player2Name,
      'isCompleted': isCompleted,
    };
  }

  factory DominoGame.fromJson(Map<String, dynamic> json) {
    return DominoGame(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      lastPlayed: json['lastPlayed'] != null ? DateTime.parse(json['lastPlayed']) : null,
      player1Rounds: List<int>.from(json['player1Rounds']),
      player2Rounds: List<int>.from(json['player2Rounds']),
      player1Name: json['player1Name'] ?? 'Jugador 1',
      player2Name: json['player2Name'] ?? 'Jugador 2',
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  DominoGame copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastPlayed,
    List<int>? player1Rounds,
    List<int>? player2Rounds,
    String? player1Name,
    String? player2Name,
    bool? isCompleted,
  }) {
    return DominoGame(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      player1Rounds: player1Rounds ?? this.player1Rounds,
      player2Rounds: player2Rounds ?? this.player2Rounds,
      player1Name: player1Name ?? this.player1Name,
      player2Name: player2Name ?? this.player2Name,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
