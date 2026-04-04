class DominoGame {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? lastPlayed;
  final List<int> player1Rounds;
  final List<int> player2Rounds;
  final List<int> player3Rounds;
  final List<int> player4Rounds;
  final String player1Name;
  final String player2Name;
  final String player3Name;
  final String player4Name;
  final bool isCompleted;

  DominoGame({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lastPlayed,
    required this.player1Rounds,
    required this.player2Rounds,
    this.player3Rounds = const [],
    this.player4Rounds = const [],
    this.player1Name = 'Jugador 1',
    this.player2Name = 'Jugador 2',
    this.player3Name = 'Jugador 3',
    this.player4Name = 'Jugador 4',
    this.isCompleted = false,
  });

  int get player1Score => player1Rounds.fold(0, (a, b) => a + b);
  int get player2Score => player2Rounds.fold(0, (a, b) => a + b);
  int get player3Score => player3Rounds.fold(0, (a, b) => a + b);
  int get player4Score => player4Rounds.fold(0, (a, b) => a + b);
  
  String get winner {
    final scores = [
      {'name': player1Name, 'score': player1Score},
      {'name': player2Name, 'score': player2Score},
      {'name': player3Name, 'score': player3Score},
      {'name': player4Name, 'score': player4Score},
    ];
    
    scores.removeWhere((score) => score['score'] == 0);
    if (scores.isEmpty) return 'Empate';
    
    scores.sort((a, b) => (b['score']! as int).compareTo(a['score']! as int));
    if (scores.length == 1) return scores[0]['name']! as String;
    
    if ((scores[0]['score']! as int) == (scores[1]['score']! as int)) return 'Empate';
    return scores[0]['name']! as String;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastPlayed': lastPlayed?.toIso8601String(),
      'player1Rounds': player1Rounds,
      'player2Rounds': player2Rounds,
      'player3Rounds': player3Rounds,
      'player4Rounds': player4Rounds,
      'player1Name': player1Name,
      'player2Name': player2Name,
      'player3Name': player3Name,
      'player4Name': player4Name,
      'isCompleted': isCompleted,
    };
  }

  factory DominoGame.fromJson(Map<String, dynamic> json) {
    return DominoGame(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      lastPlayed: json['lastPlayed'] != null ? DateTime.parse(json['lastPlayed']) : null,
      player1Rounds: List<int>.from(json['player1Rounds'] ?? []),
      player2Rounds: List<int>.from(json['player2Rounds'] ?? []),
      player3Rounds: List<int>.from(json['player3Rounds'] ?? []),
      player4Rounds: List<int>.from(json['player4Rounds'] ?? []),
      player1Name: json['player1Name'] ?? 'Jugador 1',
      player2Name: json['player2Name'] ?? 'Jugador 2',
      player3Name: json['player3Name'] ?? 'Jugador 3',
      player4Name: json['player4Name'] ?? 'Jugador 4',
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
    List<int>? player3Rounds,
    List<int>? player4Rounds,
    String? player1Name,
    String? player2Name,
    String? player3Name,
    String? player4Name,
    bool? isCompleted,
  }) {
    return DominoGame(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      player1Rounds: player1Rounds ?? this.player1Rounds,
      player2Rounds: player2Rounds ?? this.player2Rounds,
      player3Rounds: player3Rounds ?? this.player3Rounds,
      player4Rounds: player4Rounds ?? this.player4Rounds,
      player1Name: player1Name ?? this.player1Name,
      player2Name: player2Name ?? this.player2Name,
      player3Name: player3Name ?? this.player3Name,
      player4Name: player4Name ?? this.player4Name,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
