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
    'edit': 'Editar',
    'add': 'Agregar',
    'settings': 'Configuración',
    'history': 'Historial',
    'points': 'puntos',
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
    'edit': 'Edit',
    'add': 'Add',
    'settings': 'Settings',
    'history': 'History',
    'points': 'points',
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
    'edit': 'Editar',
    'add': 'Adicionar',
    'settings': 'Configurações',
    'history': 'Histórico',
    'points': 'pontos',
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
