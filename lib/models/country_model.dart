class Country {
  final String code;
  final String name;
  final String flag;
  final String region;
  final String backgroundImage;

  Country({
    required this.code,
    required this.name,
    required this.flag,
    required this.region,
    required this.backgroundImage,
  });

  static List<Country> getAllCountries() {
    return [
      // América Latina y el Caribe
      Country(
        code: 'DO',
        name: 'República Dominicana',
        flag: '🇩🇴',
        region: 'América Latina y el Caribe',
        backgroundImage: 'assets/flags/dominican_republic.jpg',
      ),
      Country(
        code: 'CU',
        name: 'Cuba',
        flag: '🇨🇺',
        region: 'América Latina y el Caribe',
        backgroundImage: 'assets/flags/cuba.jpg',
      ),
      Country(
        code: 'PR',
        name: 'Puerto Rico',
        flag: '🇵🇷',
        region: 'América Latina y el Caribe',
        backgroundImage: 'assets/flags/puerto_rico.jpg',
      ),
      Country(
        code: 'VE',
        name: 'Venezuela',
        flag: '🇻🇪',
        region: 'América Latina y el Caribe',
        backgroundImage: 'assets/flags/venezuela.jpg',
      ),
      Country(
        code: 'CO',
        name: 'Colombia',
        flag: '🇨🇴',
        region: 'América Latina y el Caribe',
        backgroundImage: 'assets/flags/colombia.jpg',
      ),
      Country(
        code: 'MX',
        name: 'México',
        flag: '🇲🇽',
        region: 'América Latina y el Caribe',
        backgroundImage: 'assets/flags/mexico.jpg',
      ),
      Country(
        code: 'PA',
        name: 'Panamá',
        flag: '🇵🇦',
        region: 'América Latina y el Caribe',
        backgroundImage: 'assets/flags/panama.jpg',
      ),
      Country(
        code: 'NI',
        name: 'Nicaragua',
        flag: '🇳🇮',
        region: 'América Latina y el Caribe',
        backgroundImage: 'assets/flags/nicaragua.jpg',
      ),
      Country(
        code: 'HN',
        name: 'Honduras',
        flag: '🇭🇳',
        region: 'América Latina y el Caribe',
        backgroundImage: 'assets/flags/honduras.jpg',
      ),

      // Estados Unidos
      Country(
        code: 'US',
        name: 'Estados Unidos',
        flag: '🇺🇸',
        region: 'Norteamérica',
        backgroundImage: 'assets/flags/usa.jpg',
      ),

      // Europa
      Country(
        code: 'ES',
        name: 'España',
        flag: '🇪🇸',
        region: 'Europa',
        backgroundImage: 'assets/flags/spain.jpg',
      ),
      Country(
        code: 'IT',
        name: 'Italia',
        flag: '🇮🇹',
        region: 'Europa',
        backgroundImage: 'assets/flags/italy.jpg',
      ),
      Country(
        code: 'FR',
        name: 'Francia',
        flag: '🇫🇷',
        region: 'Europa',
        backgroundImage: 'assets/flags/france.jpg',
      ),

      // Asia
      Country(
        code: 'CN',
        name: 'China',
        flag: '🇨🇳',
        region: 'Asia',
        backgroundImage: 'assets/flags/china.jpg',
      ),
      Country(
        code: 'PH',
        name: 'Filipinas',
        flag: '🇵🇭',
        region: 'Asia',
        backgroundImage: 'assets/flags/philippines.jpg',
      ),

      // Otros
      Country(
        code: 'BR',
        name: 'Brasil',
        flag: '🇧🇷',
        region: 'América Latina',
        backgroundImage: 'assets/flags/brazil.jpg',
      ),
      Country(
        code: 'CA',
        name: 'Canadá',
        flag: '🇨🇦',
        region: 'Norteamérica',
        backgroundImage: 'assets/flags/canada.jpg',
      ),
    ];
  }

  static List<Country> getByRegion(String region) {
    return getAllCountries().where((country) => country.region == region).toList();
  }

  static List<String> getRegions() {
    return getAllCountries()
        .map((country) => country.region)
        .toSet()
        .toList();
  }
}
