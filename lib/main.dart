import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/game_menu_screen.dart';
import 'screens/country_selection_screen.dart';
import 'services/country_service.dart';

void main() {
  runApp(DominoScoreApp());
}

class DominoScoreApp extends StatelessWidget {
  const DominoScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Domino Score',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFF1E1E2E),
        textTheme: GoogleFonts.poppinsTextTheme(),
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
      home: InitialScreen(),
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  final CountryService _countryService = CountryService();
  bool _isLoading = true;
  bool _hasCountry = false;

  @override
  void initState() {
    super.initState();
    _checkCountrySelection();
  }

  Future<void> _checkCountrySelection() async {
    final country = await _countryService.getSelectedCountry();
    setState(() {
      _hasCountry = country != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
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
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFE53935)),
          ),
        ),
      );
    }

    return _hasCountry ? GameMenuScreen() : CountrySelectionScreen();
  }
}