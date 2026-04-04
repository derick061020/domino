import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../languages/app_localizations.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedBackground = 'default';
  String _selectedLanguage = 'es';
  String _player1Name = 'Home';
  String _player2Name = 'Jugador 1';
  String _player3Name = 'Jugador 2';
  String _player4Name = 'Jugador 3';

  final List<Map<String, dynamic>> _backgrounds = [
    {'id': 'default', 'name': 'Predeterminado', 'image': 'backgrounds/default.jpg'},
    {'id': 'images', 'name': 'República Dominicana', 'image': 'backgrounds/images.jpeg'},
    {'id': 'cards', 'name': 'Cartas', 'image': 'backgrounds/cards.jpg'},
    {'id': 'dark', 'name': 'Oscuro', 'image': 'backgrounds/dark.jpg'},
    {'id': 'wood', 'name': 'Madera', 'image': 'backgrounds/wood.jpg'},
  ];

  final List<Map<String, String>> _languages = [
    {'code': 'es', 'name': 'Español'},
    {'code': 'en', 'name': 'English'},
    {'code': 'pt', 'name': 'Português'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedBackground = prefs.getString('background') ?? 'default';
      _selectedLanguage = prefs.getString('language') ?? 'es';
      _player1Name = prefs.getString('player1Name') ?? 'Home';
      _player2Name = prefs.getString('player2Name') ?? 'Jugador 1';
      _player3Name = prefs.getString('player3Name') ?? 'Jugador 2';
      _player4Name = prefs.getString('player4Name') ?? 'Jugador 3';
    });
  }

  Future<void> _saveBackground(String background) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background', background);
    print('Saving background: $background'); // Debug
    setState(() {
      _selectedBackground = background;
    });
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    setState(() {
      _selectedLanguage = language;
    });
    
    // Actualizar el idioma de la aplicación sin reiniciar
    MyApp.setLocale(Locale(language));
  }

  Future<void> _savePlayerName(int playerNumber, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player${playerNumber}Name', name);
    setState(() {
      switch (playerNumber) {
        case 1:
          _player1Name = name;
          break;
        case 2:
          _player2Name = name;
          break;
        case 3:
          _player3Name = name;
          break;
        case 4:
          _player4Name = name;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/appLogo.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 12),
            Text(
              localizations.get('settings'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Selector de fondos
            _buildSection(
              title: localizations.get('wallpaper'),
              icon: Icons.wallpaper,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _backgrounds.map((bg) {
                  final isSelected = _selectedBackground == bg['id'];
                  return GestureDetector(
                    onTap: () => _saveBackground(bg['id']!),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFE53935) : Colors.grey,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Fondo de imagen o color por defecto
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              color: Colors.grey[800],
                            ),
                            child: bg['id'] == 'default'
                                ? Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(9),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF1E1E2E),
                                          Color(0xFF2D2D44),
                                        ],
                                      ),
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: Image.asset(
                                      'assets/${bg['image']}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(9),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.grey[800]!,
                                                Colors.grey[900]!,
                                              ],
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.image,
                                            color: Colors.grey[600],
                                            size: 40,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                          // Indicador de selección
                          if (isSelected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE53935),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          // Nombre del fondo
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(9),
                                  bottomRight: Radius.circular(9),
                                ),
                                color: Colors.black.withOpacity(0.7),
                              ),
                              child: Text(
                                bg['name']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Selector de idioma
            _buildSection(
              title: localizations.get('language'),
              icon: Icons.language,
              child: Column(
                children: _languages.map((lang) {
                  return RadioListTile<String>(
                    value: lang['code']!,
                    groupValue: _selectedLanguage,
                    onChanged: (value) => _saveLanguage(value!),
                    title: Text(
                      localizations.get(lang['code'] == 'es' ? 'spanish' : 
                                       lang['code'] == 'en' ? 'english' : 'portuguese'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    activeColor: const Color(0xFFE53935),
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Nombres de jugadores
            _buildSection(
              title: localizations.get('player_names'),
              icon: Icons.people,
              child: Column(
                children: [
                  _buildPlayerNameTile(1, _player1Name),
                  _buildPlayerNameTile(2, _player2Name),
                  _buildPlayerNameTile(3, _player3Name),
                  _buildPlayerNameTile(4, _player4Name),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Compartir
            _buildSection(
              title: localizations.get('share'),
              icon: Icons.share,
              child: ListTile(
                onTap: () {
                  // TODO: Implementar compartir
                },
                leading: const Icon(Icons.share, color: Color(0xFFE53935)),
                title: Text(
                  localizations.get('share_app'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                contentPadding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: 24),

            // Privacidad y términos
            _buildSection(
              title: localizations.get('legal'),
              icon: Icons.gavel,
              child: Column(
                children: [
                  ListTile(
                    onTap: () {
                      // TODO: Implementar política de privacidad
                    },
                    leading: const Icon(Icons.privacy_tip, color: Color(0xFFE53935)),
                    title: Text(
                      localizations.get('privacy_policy'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    onTap: () {
                      // TODO: Implementar términos y condiciones
                    },
                    leading: const Icon(Icons.description, color: Color(0xFFE53935)),
                    title: Text(
                      localizations.get('terms_conditions'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerNameTile(int playerNumber, String currentName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Avatar del jugador
          CircleAvatar(
            backgroundColor: const Color(0xFFE53935),
            radius: 20,
            child: Text(
              '$playerNumber',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Información del jugador
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Jugador $playerNumber',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Poppins',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Botón de editar
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showEditPlayerNameDialog(playerNumber, currentName),
              borderRadius: BorderRadius.circular(8),
              splashColor: const Color(0xFFE53935).withOpacity(0.3),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE53935).withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFFE53935),
                  size: 18,
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
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                _savePlayerName(playerNumber, newName);
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFE53935), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
