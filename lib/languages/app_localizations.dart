import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations? from(Locale? locale) {
    if (locale == null) return null;
    return AppLocalizations(locale);
  }

  // Español
  static const Map<String, String> _es = {
    // General
    'app_title': 'Domino Score',
    'cancel': 'Cancelar',
    'save': 'Guardar',
    'close': 'Cerrar',
    'edit': 'Editar',
    'add': 'Agregar',
    'settings': 'Configuración',
    'history': 'Historial',
    'points': 'puntos',
    'pts': 'pts',
    'player': 'Jugador',
    'game_over': 'PARTIDA TERMINADA',
    'winner': 'ha ganado',
    'tie': 'EMPATE',
    'no_winner': 'No hay ganador',

    // Game Screen
    'quick_game': 'Partida Rápida',
    'add_points': 'Agregar puntos',
    'enter_points': 'Ingrese los puntos',
    'round_history': 'Historial',
    'final_score': 'Puntuación final',
    'reached_points': 'Alcanzó',
    'restart': 'REINICIAR',
    'points_to_win': 'Puntos para ganar',
    'player_count': 'Número de jugadores',
    'players_count': 'jugadores',
    'restart_game': 'Reiniciar Partida',
    'restart_confirm': '¿Estás seguro de que quieres reiniciar la partida actual? Se perderán todos los puntos acumulados.',
    'premium_title': 'DOMINO SCORE PREMIUM',
    'unlock_premium': 'Desbloquea funciones premium:',
    'premium_features': '· Sin anuncios\n· Estadísticas avanzadas\n· Personalización completa\n· Respaldo en la nube',
    'coming_soon': 'Próximamente disponibles...',

    // Bottom bar
    'scan': 'Escanear',
    'premium': 'Premium',

    // Camera / Vision
    'analyze_points': 'Análisis de Puntos',
    'detected_points': 'Puntos detectados:',
    'no_points_detected': 'No se detectaron puntos',
    'use_these_points': 'Usar estos puntos',
    'detected_n_points': 'Se detectaron %d puntos en la imagen',
    'no_points_hint': 'No se detectaron puntos. Acerca más el dominó, mejora la iluminación y evita sombras.',
    'analysis_error': 'Error en el análisis',
    'could_not_get_image': 'No se pudo obtener la imagen',
    'assign_points': 'Asignar Puntos',
    'assign_n_points': 'Asignar %d puntos',
    'select_points_player': 'Selecciona los puntos y el jugador:',
    'assign_to_player': 'Asignar a jugador',
    'select_player': 'Selecciona el jugador:',
    'points_assigned': 'Puntos asignados',

    // Settings Screen
    'wallpaper': 'Fondo de pantalla',
    'default': 'Predeterminado',
    'see_all': 'Ver todos',
    'show_less': 'Mostrar menos',
    'language': 'Idioma',
    'player_names': 'Nombres de jugadores',
    'share': 'Compartir',
    'share_app': 'Compartir aplicación',
    'legal': 'Legal',
    'privacy_policy': 'Política de privacidad',
    'terms_conditions': 'Términos y condiciones',
    'edit_name': 'Editar nombre',
    'enter_name': 'Ingrese el nombre',

    // History Screen
    'games_history': 'Historial de Partidas',
    'no_saved_games': 'No hay partidas guardadas',
    'play_to_see_games': 'Juega algunas partidas para verlas aquí',
    'finished': 'Terminada',
    'in_progress': 'En juego',

    // Languages
    'spanish': 'Español',
    'english': 'English',
    'portuguese': 'Português',
  };

  // English
  static const Map<String, String> _en = {
    // General
    'app_title': 'Domino Score',
    'cancel': 'Cancel',
    'save': 'Save',
    'close': 'Close',
    'edit': 'Edit',
    'add': 'Add',
    'settings': 'Settings',
    'history': 'History',
    'points': 'points',
    'pts': 'pts',
    'player': 'Player',
    'game_over': 'GAME OVER',
    'winner': 'has won',
    'tie': 'TIE',
    'no_winner': 'No winner',

    // Game Screen
    'quick_game': 'Quick Game',
    'add_points': 'Add points',
    'enter_points': 'Enter points',
    'round_history': 'History',
    'final_score': 'Final score',
    'reached_points': 'Reached',
    'restart': 'RESTART',
    'points_to_win': 'Points to win',
    'player_count': 'Number of players',
    'players_count': 'players',
    'restart_game': 'Restart Game',
    'restart_confirm': 'Are you sure you want to restart the current game? All accumulated points will be lost.',
    'premium_title': 'DOMINO SCORE PREMIUM',
    'unlock_premium': 'Unlock premium features:',
    'premium_features': '· No ads\n· Advanced statistics\n· Full customization\n· Cloud backup',
    'coming_soon': 'Coming soon...',

    // Bottom bar
    'scan': 'Scan',
    'premium': 'Premium',

    // Camera / Vision
    'analyze_points': 'Points Analysis',
    'detected_points': 'Detected points:',
    'no_points_detected': 'No points detected',
    'use_these_points': 'Use these points',
    'detected_n_points': '%d points detected in the image',
    'no_points_hint': 'No points detected. Get closer to the domino, improve lighting and avoid shadows.',
    'analysis_error': 'Analysis error',
    'could_not_get_image': 'Could not get the image',
    'assign_points': 'Assign Points',
    'assign_n_points': 'Assign %d points',
    'select_points_player': 'Select the points and the player:',
    'assign_to_player': 'Assign to player',
    'select_player': 'Select the player:',
    'points_assigned': 'Points assigned',

    // Settings Screen
    'wallpaper': 'Wallpaper',
    'default': 'Default',
    'see_all': 'See All',
    'show_less': 'Show Less',
    'language': 'Language',
    'player_names': 'Player Names',
    'share': 'Share',
    'share_app': 'Share app',
    'legal': 'Legal',
    'privacy_policy': 'Privacy Policy',
    'terms_conditions': 'Terms & Conditions',
    'edit_name': 'Edit name',
    'enter_name': 'Enter name',

    // History Screen
    'games_history': 'Games History',
    'no_saved_games': 'No saved games',
    'play_to_see_games': 'Play some games to see them here',
    'finished': 'Finished',
    'in_progress': 'In progress',

    // Languages
    'spanish': 'Español',
    'english': 'English',
    'portuguese': 'Português',
  };

  // Portuguese
  static const Map<String, String> _pt = {
    // General
    'app_title': 'Domino Score',
    'cancel': 'Cancelar',
    'save': 'Salvar',
    'close': 'Fechar',
    'edit': 'Editar',
    'add': 'Adicionar',
    'settings': 'Configurações',
    'history': 'Histórico',
    'points': 'pontos',
    'pts': 'pts',
    'player': 'Jogador',
    'game_over': 'PARTIDA TERMINADA',
    'winner': 'ganhou',
    'tie': 'EMPATE',
    'no_winner': 'Sem vencedor',

    // Game Screen
    'quick_game': 'Jogo Rápido',
    'add_points': 'Adicionar pontos',
    'enter_points': 'Digite os pontos',
    'round_history': 'Histórico',
    'final_score': 'Pontuação final',
    'reached_points': 'Alcançou',
    'restart': 'REINICIAR',
    'points_to_win': 'Pontos para ganhar',
    'player_count': 'Número de jogadores',
    'players_count': 'jogadores',
    'restart_game': 'Reiniciar Partida',
    'restart_confirm': 'Tem certeza que deseja reiniciar a partida atual? Todos os pontos acumulados serão perdidos.',
    'premium_title': 'DOMINO SCORE PREMIUM',
    'unlock_premium': 'Desbloqueie recursos premium:',
    'premium_features': '· Sem anúncios\n· Estatísticas avançadas\n· Personalização completa\n· Backup na nuvem',
    'coming_soon': 'Em breve...',

    // Bottom bar
    'scan': 'Escanear',
    'premium': 'Premium',

    // Camera / Vision
    'analyze_points': 'Análise de Pontos',
    'detected_points': 'Pontos detectados:',
    'no_points_detected': 'Nenhum ponto detectado',
    'use_these_points': 'Usar estes pontos',
    'detected_n_points': '%d pontos detectados na imagem',
    'no_points_hint': 'Nenhum ponto detectado. Aproxime-se do dominó, melhore a iluminação e evite sombras.',
    'analysis_error': 'Erro na análise',
    'could_not_get_image': 'Não foi possível obter a imagem',
    'assign_points': 'Atribuir Pontos',
    'assign_n_points': 'Atribuir %d pontos',
    'select_points_player': 'Selecione os pontos e o jogador:',
    'assign_to_player': 'Atribuir ao jogador',
    'select_player': 'Selecione o jogador:',
    'points_assigned': 'Pontos atribuídos',

    // Settings Screen
    'wallpaper': 'Papel de parede',
    'default': 'Padrão',
    'see_all': 'Ver todos',
    'show_less': 'Mostrar menos',
    'language': 'Idioma',
    'player_names': 'Nomes dos jogadores',
    'share': 'Compartilhar',
    'share_app': 'Compartilhar aplicativo',
    'legal': 'Legal',
    'privacy_policy': 'Política de privacidade',
    'terms_conditions': 'Termos e condições',
    'edit_name': 'Editar nome',
    'enter_name': 'Digite o nome',

    // History Screen
    'games_history': 'Histórico de Partidas',
    'no_saved_games': 'Nenhuma partida salva',
    'play_to_see_games': 'Jogue algumas partidas para vê-las aqui',
    'finished': 'Terminada',
    'in_progress': 'Em jogo',

    // Languages
    'spanish': 'Espanhol',
    'english': 'English',
    'portuguese': 'Português',
  };

  String get(String key) {
    Map<String, String>? translations;
    switch (locale.languageCode) {
      case 'en':
        translations = _en;
        break;
      case 'pt':
        translations = _pt;
        break;
      case 'es':
      default:
        translations = _es;
        break;
    }
    return translations[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en', 'pt'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
