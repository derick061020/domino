import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/country_model.dart';
import '../services/country_service.dart';
import 'game_menu_screen.dart';

class CountrySelectionScreen extends StatefulWidget {
  const CountrySelectionScreen({super.key});

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen> {
  final CountryService _countryService = CountryService();
  String _selectedRegion = 'Todos';
  List<Country> _filteredCountries = Country.getAllCountries();

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/appLogo.png',
                      height: 80,
                      width: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'DOMINO SCORE',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona tu país',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              // Region Filter
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D44),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRegion,
                    isExpanded: true,
                    style: GoogleFonts.poppins(color: Colors.white),
                    dropdownColor: const Color(0xFF2D2D44),
                    items: [
                      'Todos',
                      ...Country.getRegions(),
                    ].map((region) {
                      return DropdownMenuItem(
                        value: region,
                        child: Text(
                          region,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRegion = value!;
                        if (_selectedRegion == 'Todos') {
                          _filteredCountries = Country.getAllCountries();
                        } else {
                          _filteredCountries = Country.getByRegion(_selectedRegion);
                        }
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Countries List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filteredCountries.length,
                  itemBuilder: (context, index) {
                    final country = _filteredCountries[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        color: const Color(0xFF2D2D44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () => _selectCountry(country),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53935).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      country.flag,
                                      style: const TextStyle(fontSize: 30),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        country.name,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        country.region,
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey.shade400,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: const Color(0xFFE53935),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Skip Button
              Container(
                margin: const EdgeInsets.all(20),
                child: TextButton(
                  onPressed: () => _skipSelection(),
                  child: Text(
                    'Omitir selección',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectCountry(Country country) async {
    await _countryService.saveSelectedCountry(country);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => GameMenuScreen()),
      );
    }
  }

  void _skipSelection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => GameMenuScreen()),
    );
  }
}
