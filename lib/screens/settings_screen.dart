import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedBackground = 'default';
  String _selectedLanguage = 'es';

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
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'CONFIGURACIÓN',
              style: TextStyle(
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
              title: 'Fondo de pantalla',
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
              title: 'Idioma',
              icon: Icons.language,
              child: Column(
                children: _languages.map((lang) {
                  return RadioListTile<String>(
                    value: lang['code']!,
                    groupValue: _selectedLanguage,
                    onChanged: (value) => _saveLanguage(value!),
                    title: Text(
                      lang['name']!,
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

            // Compartir
            _buildSection(
              title: 'Compartir',
              icon: Icons.share,
              child: ListTile(
                onTap: () {
                  // TODO: Implementar compartir
                },
                leading: const Icon(Icons.share, color: Color(0xFFE53935)),
                title: const Text(
                  'Compartir aplicación',
                  style: TextStyle(
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
              title: 'Legal',
              icon: Icons.gavel,
              child: Column(
                children: [
                  ListTile(
                    onTap: () {
                      // TODO: Implementar política de privacidad
                    },
                    leading: const Icon(Icons.privacy_tip, color: Color(0xFFE53935)),
                    title: const Text(
                      'Política de privacidad',
                      style: TextStyle(
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
                    title: const Text(
                      'Términos y condiciones',
                      style: TextStyle(
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
