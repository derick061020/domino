import 'package:flutter/material.dart';
import '../models/country_model.dart';
import '../services/country_service.dart';

class CountryBackgroundWidget extends StatefulWidget {
  final Widget child;
  final bool useOverlay;

  const CountryBackgroundWidget({
    super.key,
    required this.child,
    this.useOverlay = true,
  });

  @override
  State<CountryBackgroundWidget> createState() => _CountryBackgroundWidgetState();
}

class _CountryBackgroundWidgetState extends State<CountryBackgroundWidget> {
  final CountryService _countryService = CountryService();
  Country? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _loadSelectedCountry();
  }

  Future<void> _loadSelectedCountry() async {
    final country = await _countryService.getSelectedCountry();
    if (mounted) {
      setState(() {
        _selectedCountry = country;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image or gradient
        Container(
          decoration: _selectedCountry != null
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getCountryColor(_selectedCountry!.code).withOpacity(0.8),
                      _getCountryColor(_selectedCountry!.code).withOpacity(0.4),
                    ],
                  ),
                )
              : const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1E1E2E),
                      Color(0xFF2D2D44),
                    ],
                  ),
                ),
        ),
        
        // Country flag pattern overlay
        if (_selectedCountry != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_getFlagPattern(_selectedCountry!.code)),
                    repeat: ImageRepeat.repeat,
                    scale: 3.0,
                  ),
                ),
              ),
            ),
          ),
        
        // Overlay for better readability
        if (widget.useOverlay)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),
        
        // Content
        widget.child,
      ],
    );
  }

  Color _getCountryColor(String countryCode) {
    switch (countryCode) {
      case 'DO':
        return const Color(0xFF002D62); // Azul dominicano
      case 'CU':
        return const Color(0xFF002A8F); // Azul cubano
      case 'PR':
        return const Color(0xFFED0000); // Rojo puertorriqueño
      case 'VE':
        return const Color(0xFFED0000); // Rojo venezolano
      case 'CO':
        return const Color(0xFF003893); // Azul colombiano
      case 'MX':
        return const Color(0xFF006847); // Verde mexicano
      case 'PA':
        return const Color(0xFFDA121A); // Rojo panameño
      case 'NI':
        return const Color(0xFF003893); // Azul nicaragüense
      case 'HN':
        return const Color(0xFF0073CF); // Azul hondureño
      case 'US':
        return const Color(0xFFB22234); // Rojo americano
      case 'ES':
        return const Color(0xFFAA151B); // Rojo español
      case 'IT':
        return const Color(0xFF009246); // Verde italiano
      case 'FR':
        return const Color(0xFF002395); // Azul francés
      case 'CN':
        return const Color(0xFFDE2910); // Rojo chino
      case 'PH':
        return const Color(0xFF0038A8); // Azul filipino
      case 'BR':
        return const Color(0xFF009739); // Verde brasileño
      case 'CA':
        return const Color(0xFFFF0000); // Rojo canadiense
      default:
        return const Color(0xFF1E1E2E);
    }
  }

  String _getFlagPattern(String countryCode) {
    // Por ahora, usamos el logo como patrón hasta que tengamos imágenes de banderas
    return 'assets/appLogo.png';
  }
}
