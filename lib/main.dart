import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';
import 'screens/game_screen.dart';
import 'languages/app_localizations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(Locale locale) {
    _instance?.changeLocale(locale);
  }

  static _MyAppState? _instance;

  @override
  State<MyApp> createState() {
    _instance = _MyAppState();
    return _instance!;
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  late Future<DominoGame> _gameFuture;
  late Future<Locale> _localeFuture;

  @override
  void initState() {
    super.initState();
    _gameFuture = _loadInitialGame();
    _localeFuture = _loadLocale();
  }

  void changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  Future<Locale> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language') ?? 'es';
    return Locale(languageCode);
  }

  Future<DominoGame> _loadInitialGame() async {
    final prefs = await SharedPreferences.getInstance();
    return DominoGame(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Partida Rápida',
      createdAt: DateTime.now(),
      player1Rounds: [],
      player2Rounds: [],
      player3Rounds: [],
      player4Rounds: [],
      player1Name: prefs.getString('player1Name') ?? 'Home',
      player2Name: prefs.getString('player2Name') ?? 'Jugador 1',
      player3Name: prefs.getString('player3Name') ?? 'Jugador 2',
      player4Name: prefs.getString('player4Name') ?? 'Jugador 3',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Locale>(
      future: _localeFuture,
      builder: (context, localeSnapshot) {
        final currentLocale = _locale ?? localeSnapshot.data ?? const Locale('es');
        
        return MaterialApp(
          title: 'Domino Score',
          debugShowCheckedModeBanner: false,
          locale: currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es'),
            Locale('en'),
            Locale('pt'),
          ],
          theme: ThemeData(
            primarySwatch: Colors.red,
            scaffoldBackgroundColor: const Color(0xFF1E1E2E),
            fontFamily: 'Poppins',
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF2D2D44),
              elevation: 0,
              centerTitle: true,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF2D2D44),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
          ),
          home: FutureBuilder<DominoGame>(
            future: _gameFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return GameScreen(game: snapshot.data!);
              } else {
                return const Scaffold(
                  backgroundColor: Color(0xFF1E1E2E),
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFFE53935)),
                ),
              );
              }
            },
          ),
        );
      },
    );
  }
}