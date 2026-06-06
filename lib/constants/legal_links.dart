import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enlaces legales requeridos por Apple (Guideline 3.1.2) y Google Play.
class LegalLinks {
  // Términos de Uso (EULA) propios, alojados en el sitio.
  static const String termsOfUse =
      'https://sienna-trout-499246.hostingersite.com/terms.html';

  // Política de Privacidad. IMPORTANTE: crear esta página en el hosting.
  static const String privacyPolicy =
      'https://sienna-trout-499246.hostingersite.com/privacy.html';

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
