import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import '../languages/app_localizations.dart';
import '../constants/legal_links.dart';
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
  bool _showAllBackgrounds = false;

  final List<Map<String, dynamic>> _backgrounds = [
    {'id': 'default', 'name': 'Default', 'image': 'backgrounds/default.jpg'},
    {'id': 'cuban_flag', 'name': 'Cuba', 'image': 'backgrounds/A0iScru-cuban-flag-wallpaper.jpg'},
    {'id': 'spanish_flag', 'name': 'España', 'image': 'backgrounds/E3oulkw-spanish-flag-wallpaper.jpg'},
    {'id': 'colombian_flag', 'name': 'Colombia', 'image': 'backgrounds/wp11025257-colombian-flag-wallpapers.jpg'},
    {'id': 'mexican_flag', 'name': 'México', 'image': 'backgrounds/wp15254308-flag-of-mexico-wallpapers.jpg'},
    {'id': 'puerto_rico_flag', 'name': 'Puerto Rico', 'image': 'backgrounds/wp2465860-puerto-rico-flag-wallpapers.png'},
    {'id': 'panama_flag', 'name': 'Panamá', 'image': 'backgrounds/wp3607255-panama-flag-wallpapers.jpg'},
    {'id': 'venezuela_flag', 'name': 'Venezuela', 'image': 'backgrounds/wp4209041-venezuela-flag-wallpapers.jpg'},
    {'id': 'costa_rica_flag', 'name': 'Costa Rica', 'image': 'backgrounds/wp4209288-costa-rica-flag-wallpapers.jpg'},
    {'id': 'ecuador_flag', 'name': 'Ecuador', 'image': 'backgrounds/wp4209455-ecuador-flag-wallpapers.jpg'},
    {'id': 'dominican_flag', 'name': 'Rep. Dominicana', 'image': 'backgrounds/wp4209528-dominican-republic-flag-wallpapers.jpg'},
    {'id': 'jamaican', 'name': 'Jamaica', 'image': 'backgrounds/eN2cTld-jamaican-wallpaper.jpg'},
    {'id': 'nicaragua', 'name': 'Nicaragua', 'image': 'backgrounds/wp2231756-nicaragua-wallpapers.jpg'},
    {'id': 'italian', 'name': 'Italia', 'image': 'backgrounds/wp6493991-phone-italian-wallpapers.jpg'},
    {'id': 'abstract_1', 'name': 'Abstracto 1', 'image': 'backgrounds/uwp3683989.jpeg'},
    {'id': 'abstract_2', 'name': 'Abstracto 2', 'image': 'backgrounds/uwp4318756.jpeg'},
    {'id': 'abstract_3', 'name': 'Abstracto 3', 'image': 'backgrounds/uwp4957374.jpeg'},
    {'id': 'abstract_4', 'name': 'Abstracto 4', 'image': 'backgrounds/uwp4957375.jpeg'},
    {'id': 'abstract_5', 'name': 'Abstracto 5', 'image': 'backgrounds/uwp4998270.jpeg'},
    {'id': 'abstract_6', 'name': 'Abstracto 6', 'image': 'backgrounds/uwp5000378.jpeg'},
    {'id': 'abstract_7', 'name': 'Abstracto 7', 'image': 'backgrounds/uwp5000914.jpeg'},
    {'id': 'gangster_money', 'name': 'Gangster Money', 'image': 'backgrounds/wp13311949-gangster-money-wallpapers.jpg'},
    {'id': 'wine', 'name': 'Vino', 'image': 'backgrounds/wp15058984-4k-wine-wallpapers.webp'},
    {'id': 'portuguese_dog_1', 'name': 'Perro Portugués 1', 'image': 'backgrounds/wp5473857-portuguese-water-dog-wallpapers.jpg'},
    {'id': 'portuguese_dog_2', 'name': 'Perro Portugués 2', 'image': 'backgrounds/wp5473896-portuguese-water-dog-wallpapers.jpg'},
    {'id': 'blue_label', 'name': 'Blue Label', 'image': 'backgrounds/wp9536291-blue-label-wallpapers.jpg'},
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
    
    // Obtener idioma guardado o usar el idioma del dispositivo
    String savedLanguage = prefs.getString('language') ?? '';
    String deviceLanguage = 'es'; // valor por defecto
    
    if (savedLanguage.isEmpty) {
      // Si no hay idioma guardado, usar el del dispositivo
      final deviceLocale = ui.window.locale;
      deviceLanguage = deviceLocale.languageCode;
      
      // Mapear idiomas del dispositivo a los soportados
      if (['es', 'en', 'pt'].contains(deviceLanguage)) {
        // Usar el idioma del dispositivo si está soportado
      } else {
        // Si no está soportado, usar español como por defecto
        deviceLanguage = 'es';
      }
    }
    
    setState(() {
      _selectedBackground = prefs.getString('background') ?? 'default';
      _selectedLanguage = savedLanguage.isNotEmpty ? savedLanguage : deviceLanguage;
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
    
    // Navegar a la pantalla de juego después de seleccionar fondo
    Navigator.of(context).pop();
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
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _showAllBackgrounds ? _backgrounds.length : 9, // Mostrar solo 9 inicialmente
                    itemBuilder: (context, index) {
                      final bg = _backgrounds[index];
                      final isSelected = _selectedBackground == bg['id'];
                      return GestureDetector(
                        onTap: () => _saveBackground(bg['id']!),
                        child: Container(
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
                                width: double.infinity,
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
                                          width: double.infinity,
                                          height: double.infinity,
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
                    },
                  ),
                  const SizedBox(height: 12),
                  // Botón de Ver todos/Mostrar menos
                  if (_backgrounds.length > 9)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAllBackgrounds = !_showAllBackgrounds;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE53935).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _showAllBackgrounds 
                                  ? localizations.get('show_less') 
                                  : localizations.get('see_all'),
                              style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _showAllBackgrounds ? Icons.expand_less : Icons.expand_more,
                              color: const Color(0xFFE53935),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
                    onTap: () => LegalLinks.open(LegalLinks.privacyPolicy),
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
                    onTap: () => LegalLinks.open(LegalLinks.termsOfUse),
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
                  '${AppLocalizations.of(context).get('player')} $playerNumber',
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
