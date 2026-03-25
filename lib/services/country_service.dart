import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/country_model.dart';

class CountryService {
  static const String _selectedCountryKey = 'selected_country';

  Future<Country?> getSelectedCountry() async {
    final prefs = await SharedPreferences.getInstance();
    final countryJson = prefs.getString(_selectedCountryKey);
    
    if (countryJson != null) {
      try {
        final Map<String, dynamic> countryMap = json.decode(countryJson);
        return Country(
          code: countryMap['code'],
          name: countryMap['name'],
          flag: countryMap['flag'],
          region: countryMap['region'],
          backgroundImage: countryMap['backgroundImage'],
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveSelectedCountry(Country country) async {
    final prefs = await SharedPreferences.getInstance();
    final countryJson = json.encode({
      'code': country.code,
      'name': country.name,
      'flag': country.flag,
      'region': country.region,
      'backgroundImage': country.backgroundImage,
    });
    await prefs.setString(_selectedCountryKey, countryJson);
  }

  Future<void> clearSelectedCountry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedCountryKey);
  }
}
