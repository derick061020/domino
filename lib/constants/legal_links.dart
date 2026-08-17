import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enlaces legales requeridos por Apple (Guideline 3.1.2) y Google Play.
class LegalLinks {
  static const String _baseUrl = 'https://sienna-trout-499246.hostingersite.com';

  // Términos y Condiciones (EULA propio). Requerido por App Store
  // Guideline 3.1.2(c) y por Google Play para suscripciones.
  // Fuente en el repo: terms.html
  static const String termsOfUse = '$_baseUrl/terms.html';

  // Política de Privacidad. Fuente en el repo: privacy.html
  static const String privacyPolicy = '$_baseUrl/privacy.html';

  // EULA estándar de Apple, como alternativa aceptada por App Store.
  static const String appleStandardEula =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  /// Abre [url] en el navegador externo. Devuelve false si no se pudo abrir.
  static Future<bool> open(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      debugPrint('No se pudo abrir la URL: $url');
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
